import Foundation

/// Modifier keys MyClicky can use in shortcuts.
public enum Modifier: String, Codable, CaseIterable, Comparable, Sendable {
    case control, option, shift, command, fn

    public static func < (a: Modifier, b: Modifier) -> Bool {
        allCases.firstIndex(of: a)! < allCases.firstIndex(of: b)!
    }
}

/// The four actions on the Shortcuts page (ref 07).
public enum ShortcutAction: String, Codable, CaseIterable, Sendable {
    case pushToTalk, textMode, dictate, handsFreeDictation
}

/// hold = keep modifiers down (push to talk) · doubleTap = tap the modifiers twice · press = modifiers + a key.
public enum Gesture: String, Codable, Sendable { case hold, doubleTap, press }

public struct KeyChord: Codable, Equatable, Hashable, Sendable {
    public var modifiers: Set<Modifier>
    public var keyCode: UInt16?

    public init(_ modifiers: Set<Modifier>, keyCode: UInt16? = nil) {
        self.modifiers = modifiers
        self.keyCode = keyCode
    }
}

public struct ShortcutBinding: Codable, Equatable, Sendable {
    public var action: ShortcutAction
    public var chord: KeyChord
    public var gesture: Gesture

    public init(_ action: ShortcutAction, _ chord: KeyChord, _ gesture: Gesture) {
        self.action = action
        self.chord = chord
        self.gesture = gesture
    }

    /// HeyClicky's defaults (ref 07): fn · ⌃⌃ · ⌃fn · ⌃fn ⌃fn.
    public static let defaults: [ShortcutBinding] = [
        ShortcutBinding(.pushToTalk, KeyChord([.fn]), .hold),
        ShortcutBinding(.textMode, KeyChord([.control]), .doubleTap),
        ShortcutBinding(.dictate, KeyChord([.control, .fn]), .hold),
        ShortcutBinding(.handsFreeDictation, KeyChord([.control, .fn]), .doubleTap),
    ]

    public var isValid: Bool {
        switch gesture {
        case .hold, .doubleTap: return !chord.modifiers.isEmpty && chord.keyCode == nil
        case .press: return chord.keyCode != nil
        }
    }

    /// The action already using the same keys and gesture, if any.
    public static func conflict(for candidate: ShortcutBinding, in bindings: [ShortcutBinding]) -> ShortcutAction? {
        bindings.first { $0.action != candidate.action && $0.chord == candidate.chord && $0.gesture == candidate.gesture }?.action
    }

    /// Full list with defaults for any missing action, in page order.
    public static func normalized(_ bindings: [ShortcutBinding]) -> [ShortcutBinding] {
        ShortcutAction.allCases.map { action in
            bindings.first { $0.action == action && $0.isValid } ?? defaults.first { $0.action == action }!
        }
    }
}

extension ShortcutAction {
    public var title: String {
        switch self {
        case .pushToTalk: "Push to talk"
        case .textMode: "Text mode"
        case .dictate: "Dictate"
        case .handsFreeDictation: "Hands-free dictation"
        }
    }

    public var subtitle: String {
        switch self {
        case .pushToTalk: "Hold to talk to MyClicky. Release to send."
        case .textMode: "Press to type to MyClicky instead of talking."
        case .dictate: "Hold and speak. Release to insert what you said at your cursor."
        case .handsFreeDictation: "Dictate without holding a key down. Press to start, press again to stop."
        }
    }
}
