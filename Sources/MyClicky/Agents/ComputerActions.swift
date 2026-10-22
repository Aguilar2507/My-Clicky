import AppKit
import CoreGraphics
import MyClickyCore

/// Performs computer-use tools for agents with MyClicky's own permissions (spec 009 US3, research R3).
/// Every click/type is shown by the companion flying to the spot first, so you can watch.
@MainActor
final class ComputerActions {
    let companion: CompanionController
    /// Last screenshots per chat, for mapping screenshot pixels → screen points.
    private var lastShots: [String: [Screenshot]] = [:]
    /// Set when you touch the mouse/keyboard during a run; the next action asks "Continue?".
    private(set) var interrupted: Set<String> = []
    private var monitor: Any?

    init(companion: CompanionController) {
        self.companion = companion
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown, .mouseMoved]) { [weak self] event in
            // Our own clicks carry our process ID; anything else is you. (A 0.8 s quiet window after each of our
            // clicks used to hide your input during fast click runs, so the "Continue?" pause never came.)
            let poster = event.cgEvent?.getIntegerValueField(.eventSourceUnixProcessID) ?? 0
            guard poster != Int64(getpid()) else { return }
            DispatchQueue.main.async { self?.userActed() } // not assumeIsolated: see CompanionController.init
        }
    }

    /// Chats currently using the computer (so user input pauses them).
    var activeChats: Set<String> = []

    private func userActed() {
        guard !activeChats.isEmpty else { return }
        interrupted.formUnion(activeChats)
    }

    func clearInterruption(_ chatID: String) { interrupted.remove(chatID) }

    func perform(_ tool: String, input: [String: JSONValue], chatID: String) async -> BridgeResponse {
        let id = UUID().uuidString
        activeChats.insert(chatID)
        switch tool {
        case "screenshot":
            guard let shots = try? await ScreenCapture.captureAll(), !shots.isEmpty else {
                return BridgeResponse(id: id, ok: false, content: [.text("Screen Recording permission is missing.")])
            }
            lastShots[chatID] = shots
            let index = max(0, min(shots.count - 1, Int(input["screen"]?.double ?? 1) - 1))
            let shot = shots[index]
            return BridgeResponse(id: id, ok: true, content: [
                .text("Screen \(index + 1) of \(shots.count), \(shot.pixelWidth)x\(shot.pixelHeight) pixels. Use these pixel coordinates."),
                .image(base64: shot.jpeg.base64EncodedString()),
            ])
        case "click", "move":
            guard let point = await point(input, chatID: chatID) else {
                return BridgeResponse(id: id, ok: false, content: [.text("Take a screenshot first, then use its pixel coordinates.")])
            }
            await show(point)
            if tool == "move" {
                post(mouse: .mouseMoved, at: point)
            } else {
                let right = input["button"]?.string == "right"
                let count = Int(input["count"]?.double ?? 1)
                for n in 1...max(1, min(count, 3)) {
                    post(mouse: right ? .rightMouseDown : .leftMouseDown, at: point, clicks: n, right: right)
                    post(mouse: right ? .rightMouseUp : .leftMouseUp, at: point, clicks: n, right: right)
                }
            }
            return BridgeResponse(id: id, ok: true, content: [.text("ok")])
        case "type":
            let text = input["text"]?.string ?? ""
            await show(companion.position)
            type(text)
            return BridgeResponse(id: id, ok: true, content: [.text("ok")])
        case "key":
            guard let (code, flags) = Self.parse(combo: input["combo"]?.string ?? "") else {
                return BridgeResponse(id: id, ok: false, content: [.text("Unknown key combination")])
            }
            press(code, flags: flags)
            return BridgeResponse(id: id, ok: true, content: [.text("ok")])
        case "scroll":
            let dy = Int32(input["dy"]?.double ?? 0), dx = Int32(input["dx"]?.double ?? 0)
            CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: -dy, wheel2: dx, wheel3: 0)?.post(tap: .cghidEventTap)
            return BridgeResponse(id: id, ok: true, content: [.text("ok")])
        default:
            return BridgeResponse(id: id, ok: false, content: [.text("Unknown tool \(tool)")])
        }
    }

    func runEnded(_ chatID: String) {
        activeChats.remove(chatID)
        interrupted.remove(chatID)
        lastShots[chatID] = nil
    }

    // MARK: Helpers

    private func point(_ input: [String: JSONValue], chatID: String) async -> CGPoint? {
        guard let x = input["x"]?.double, let y = input["y"]?.double else { return nil }
        if lastShots[chatID] == nil { lastShots[chatID] = try? await ScreenCapture.captureAll() }
        guard let shots = lastShots[chatID], !shots.isEmpty else { return nil }
        let index = max(0, min(shots.count - 1, Int(input["screen"]?.double ?? 1) - 1))
        return shots[index].globalPoint(x: x, y: y)
    }

    /// The companion flies to the spot and pulses before the action (research R3).
    private func show(_ point: CGPoint) async {
        companion.point(at: point, label: "")
        try? await Task.sleep(for: .milliseconds(450))
    }

    /// AppKit global (bottom-left) → Quartz global (top-left of the main display).
    private func quartz(_ point: CGPoint) -> CGPoint {
        let mainHeight = NSScreen.screens.first?.frame.maxY ?? 0
        return CGPoint(x: point.x, y: mainHeight - point.y)
    }

    private func post(mouse type: CGEventType, at point: CGPoint, clicks: Int = 1, right: Bool = false) {
        let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: quartz(point),
                            mouseButton: right ? .right : .left)
        event?.setIntegerValueField(.mouseEventClickState, value: Int64(clicks))
        event?.post(tap: .cghidEventTap)
    }

    private func type(_ text: String) {
        for chunk in text.chunked(20) {
            let utf16 = Array(chunk.utf16)
            let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            down?.post(tap: .cghidEventTap)
            let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
            up?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            up?.post(tap: .cghidEventTap)
        }
    }

    private func press(_ code: CGKeyCode, flags: CGEventFlags) {
        let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }

    /// "cmd+shift+4", "return", "esc", "space", "a".
    static func parse(combo: String) -> (CGKeyCode, CGEventFlags)? {
        var flags = CGEventFlags()
        var key: String?
        for part in combo.lowercased().split(separator: "+").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            switch part {
            case "cmd", "command": flags.insert(.maskCommand)
            case "shift": flags.insert(.maskShift)
            case "opt", "option", "alt": flags.insert(.maskAlternate)
            case "ctrl", "control": flags.insert(.maskControl)
            case "fn": flags.insert(.maskSecondaryFn)
            default: key = part
            }
        }
        guard let key else { return nil }
        let named: [String: CGKeyCode] = ["return": 36, "enter": 36, "tab": 48, "space": 49, "delete": 51, "backspace": 51,
                                          "esc": 53, "escape": 53, "left": 123, "right": 124, "down": 125, "up": 126,
                                          "home": 115, "end": 119, "pageup": 116, "pagedown": 121]
        if let code = named[key] { return (code, flags) }
        let letters = "asdfhgzxcv bqweryt123465=97-80]ou[ip lj'k;\\,/nm."
        if key.count == 1, let index = letters.firstIndex(of: Character(key)) {
            return (CGKeyCode(letters.distance(from: letters.startIndex, to: index)), flags)
        }
        return nil
    }
}

private extension String {
    func chunked(_ size: Int) -> [String] {
        stride(from: 0, to: count, by: size).map {
            let start = index(startIndex, offsetBy: $0)
            return String(self[start..<(index(start, offsetBy: size, limitedBy: endIndex) ?? endIndex)])
        }
    }
}
