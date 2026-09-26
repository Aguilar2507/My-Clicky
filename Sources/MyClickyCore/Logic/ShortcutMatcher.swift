import Foundation

/// Turns raw modifier/key events into shortcut actions (spec 004, research R3). Pure: time is passed in.
///
/// - hold: `began` when exactly the chord's modifiers are down (no key pressed in this press), `ended` on release,
///   `cancelled` if a regular key is pressed meanwhile (⌃C never triggers anything). If the same modifiers also
///   have a double-tap binding, `began` waits until they've been held 0.3 s (a quicker press is a tap).
/// - doubleTap: two taps (press + release under 0.35 s, no keys) of the same modifiers within 0.35 s → `triggered`.
/// - press: modifiers + key → `triggered`, and that key event should be swallowed.
public struct ShortcutMatcher: Sendable {
    public enum Event: Equatable, Sendable {
        case began(ShortcutAction), ended(ShortcutAction), cancelled(ShortcutAction), triggered(ShortcutAction)
    }

    public static let holdDelay: TimeInterval = 0.3
    public static let tapMaxDuration: TimeInterval = 0.35
    public static let doubleTapGap: TimeInterval = 0.35

    public var bindings: [ShortcutBinding]

    private var mods: Set<Modifier> = []
    private var sessionStart: TimeInterval?
    private var sessionMax: Set<Modifier> = []
    private var sessionHadKey = false
    private var lastTap: (mods: Set<Modifier>, end: TimeInterval)?
    private var pendingHold: (action: ShortcutAction, since: TimeInterval)?
    private var activeHold: ShortcutAction?

    public init(bindings: [ShortcutBinding]) { self.bindings = bindings }

    /// True while a delayed hold is waiting; call `tick` ~30×/s meanwhile.
    public var needsTick: Bool { pendingHold != nil }

    public mutating func flagsChanged(_ newMods: Set<Modifier>, at t: TimeInterval) -> [Event] {
        var events: [Event] = []
        let old = mods
        mods = newMods
        if old.isEmpty && !newMods.isEmpty {
            sessionStart = t
            sessionMax = []
            sessionHadKey = false
        }
        sessionMax.formUnion(newMods)

        // Leaving the active hold's chord ends it.
        if let hold = activeHold, chord(of: hold) != newMods {
            events.append(.ended(hold))
            activeHold = nil
        }
        pendingHold = nil

        // Entering a hold chord.
        if activeHold == nil, !sessionHadKey, !newMods.isEmpty,
           let hold = bindings.first(where: { $0.gesture == .hold && $0.chord.modifiers == newMods }) {
            if hasDoubleTap(newMods) {
                pendingHold = (hold.action, t)
            } else {
                activeHold = hold.action
                events.append(.began(hold.action))
            }
        }

        // Session over: was it a tap? A second tap soon after the first is a double tap.
        if newMods.isEmpty, let start = sessionStart {
            let isTap = !sessionHadKey && t - start < Self.tapMaxDuration && !events.contains(where: isEnded)
            if isTap {
                if let last = lastTap, last.mods == sessionMax, start - last.end <= Self.doubleTapGap,
                   let double = bindings.first(where: { $0.gesture == .doubleTap && $0.chord.modifiers == sessionMax }) {
                    events.append(.triggered(double.action))
                    lastTap = nil
                } else {
                    lastTap = (sessionMax, t)
                }
            } else {
                lastTap = nil
            }
            sessionStart = nil
        }
        return events
    }

    /// Returns events plus whether the key event should be swallowed (a `press` binding fired).
    public mutating func keyDown(_ code: UInt16, at t: TimeInterval) -> (events: [Event], swallow: Bool) {
        sessionHadKey = true
        lastTap = nil
        pendingHold = nil
        if let press = bindings.first(where: { $0.gesture == .press && $0.chord.keyCode == code && $0.chord.modifiers == mods }) {
            return ([.triggered(press.action)], true)
        }
        if let hold = activeHold {
            activeHold = nil
            return ([.cancelled(hold)], false)
        }
        return ([], false)
    }

    public mutating func tick(at t: TimeInterval) -> [Event] {
        guard let pending = pendingHold, t - pending.since >= Self.holdDelay, chord(of: pending.action) == mods else { return [] }
        pendingHold = nil
        activeHold = pending.action
        return [.began(pending.action)]
    }

    private func chord(of action: ShortcutAction) -> Set<Modifier>? {
        bindings.first { $0.action == action }?.chord.modifiers
    }

    private func hasDoubleTap(_ modifiers: Set<Modifier>) -> Bool {
        bindings.contains { $0.gesture == .doubleTap && $0.chord.modifiers == modifiers }
    }

    private func isEnded(_ e: Event) -> Bool {
        if case .ended = e { return true }
        return false
    }
}

/// Captures a new shortcut on the Shortcuts page: a key combo, a double tap, or a hold.
public struct ShortcutRecorderLogic: Sendable {
    public enum Result: Equatable, Sendable { case recorded(KeyChord, Gesture), waiting }

    private var mods: Set<Modifier> = []
    private var sessionStart: TimeInterval?
    private var sessionMax: Set<Modifier> = []
    private var firstTap: (mods: Set<Modifier>, end: TimeInterval)?
    private var heldLongEnough = false

    public init() {}

    /// The modifiers currently held (for the live key caps).
    public var liveModifiers: Set<Modifier> { mods.isEmpty ? (firstTap?.mods ?? []) : mods }

    public mutating func flagsChanged(_ newMods: Set<Modifier>, at t: TimeInterval) -> Result {
        if mods.isEmpty && !newMods.isEmpty {
            sessionStart = t
            sessionMax = []
        }
        mods = newMods
        sessionMax.formUnion(newMods)
        guard newMods.isEmpty, let start = sessionStart else { return .waiting }
        sessionStart = nil
        let duration = t - start
        if duration >= ShortcutMatcher.holdDelay {
            firstTap = nil
            return .recorded(KeyChord(sessionMax), .hold)
        }
        if let first = firstTap, first.mods == sessionMax, start - first.end <= ShortcutMatcher.doubleTapGap {
            firstTap = nil
            return .recorded(KeyChord(sessionMax), .doubleTap)
        }
        firstTap = (sessionMax, t)
        return .waiting
    }

    /// A single short tap with no follow-up becomes a hold after the double-tap window passes.
    public mutating func tick(at t: TimeInterval) -> Result {
        guard mods.isEmpty, let first = firstTap, t - first.end > ShortcutMatcher.doubleTapGap else { return .waiting }
        firstTap = nil
        return .recorded(KeyChord(first.mods), .hold)
    }

    public mutating func keyDown(_ code: UInt16) -> Result {
        firstTap = nil
        return .recorded(KeyChord(mods, keyCode: code), .press)
    }
}
