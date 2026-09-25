import Foundation

/// The notch's open/close rules (spec 003): rest 150 ms on the shape to open; leave the panel for 500 ms to close
/// (unless typing or a menu is open); click outside or Esc closes; pop out turns the panel into a window.
public struct NotchState: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case collapsed
        case hovering(since: TimeInterval)
        case expanded(outsideSince: TimeInterval?)
        case poppedOut
    }

    public static let restDelay: TimeInterval = 0.15
    public static let graceDelay: TimeInterval = 0.5

    public private(set) var phase: Phase = .collapsed

    public init() {}

    public var isExpanded: Bool {
        if case .expanded = phase { return true }
        return false
    }

    /// Feed pointer position and time. `inShape`: over the collapsed shape. `inPanel`: over the open panel.
    /// Returns true when the phase changed.
    @discardableResult
    public mutating func pointer(inShape: Bool, inPanel: Bool, now: TimeInterval, isBusy: Bool = false) -> Bool {
        let old = phase
        switch phase {
        case .collapsed:
            if inShape { phase = .hovering(since: now) }
        case .hovering(let since):
            if !inShape { phase = .collapsed } else if now - since >= Self.restDelay { phase = .expanded(outsideSince: nil) }
        case .expanded(let outsideSince):
            if inPanel || inShape || isBusy {
                phase = .expanded(outsideSince: nil)
            } else if let since = outsideSince {
                if now - since >= Self.graceDelay { phase = .collapsed }
            } else {
                phase = .expanded(outsideSince: now)
            }
        case .poppedOut:
            break
        }
        return phase != old
    }

    public mutating func outsideClick(isBusy: Bool = false) {
        if isExpanded && !isBusy { phase = .collapsed }
    }

    public mutating func escape() {
        if isExpanded { phase = .collapsed }
    }

    public mutating func open() { if phase != .poppedOut { phase = .expanded(outsideSince: nil) } }
    public mutating func popOut() { phase = .poppedOut }
    public mutating func closeWindow() { if phase == .poppedOut { phase = .collapsed } }
    public mutating func collapse() { if phase != .poppedOut { phase = .collapsed } }
}
