import AppKit
import CoreGraphics
import MyClickyCore

/// Listens to modifier and key events in every app through a CGEvent tap (spec 004, research R1).
/// Needs Accessibility + Input Monitoring. Only `press` shortcut keys are swallowed; modifier events always pass
/// through, so other apps never see stuck modifiers.
@MainActor
final class HotkeyTap {
    /// Return true to swallow a key-down event.
    var onFlags: (Set<Modifier>) -> Void = { _ in }
    var onKeyDown: (UInt16) -> Bool = { _ in false }

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    var isRunning: Bool { tap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }

    /// Starts the tap. Returns false if macOS refused (permissions missing).
    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        let mask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                                          eventsOfInterest: CGEventMask(mask), callback: hotkeyTapCallback,
                                          userInfo: refcon) else { return false }
        self.tap = tap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        tap = nil
        source = nil
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Bool {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) } // macOS turned it off; turn it back on
            return false
        case .flagsChanged:
            onFlags(Self.modifiers(event.flags))
            return false
        case .keyDown:
            guard event.getIntegerValueField(.keyboardEventAutorepeat) == 0 else { return false }
            return onKeyDown(UInt16(event.getIntegerValueField(.keyboardEventKeycode)))
        default:
            return false
        }
    }

    static func modifiers(_ flags: CGEventFlags) -> Set<Modifier> {
        var set = Set<Modifier>()
        if flags.contains(.maskControl) { set.insert(.control) }
        if flags.contains(.maskAlternate) { set.insert(.option) }
        if flags.contains(.maskShift) { set.insert(.shift) }
        if flags.contains(.maskCommand) { set.insert(.command) }
        if flags.contains(.maskSecondaryFn) { set.insert(.fn) }
        return set
    }
}

private func hotkeyTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                               refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<HotkeyTap>.fromOpaque(refcon).takeUnretainedValue()
    // Event taps are delivered on the main run loop (we added the source there).
    let swallow = MainActor.assumeIsolated { tap.handle(type: type, event: event) }
    return swallow ? nil : Unmanaged.passUnretained(event)
}
