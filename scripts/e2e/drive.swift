// End-to-end driver for MyClicky checks: keys, mouse and Accessibility (AX) reads/presses.
// Build: swiftc -O scripts/e2e/drive.swift -o .build/e2e-drive
// Needs the calling app (Terminal / VS Code) in Privacy & Security → Accessibility.
//
//   down ctrl,opt | up ctrl,opt          hold / release modifiers (ctrl opt cmd shift fn)
//   tap ctrl [times]                     tap a modifier (double-tap = 2)
//   key <name|code> [mods]               press a key: return esc space tab delete a…z 0…9 left right up down
//   type <text>                          type text
//   move|click|rightclick <x> <y>        global coordinates, origin top-left (like AX frames)
//   apps                                 running apps: pid bundle name
//   tree <bundle> [depth]                dump the UI tree: role "title" [value] {x,y,w,h}
//   find <bundle> <text> [role]          elements whose title/value/description/identifier contains text
//   press <bundle> <text> [role] [n]     AXPress the first (or n-th, from 0) match
//   setvalue <bundle> <text> <value> [role]   set the value of the first match (text fields)
//   focused                              focused app + element role and value
//   windows <bundle>                     window titles and frames
//   audio [seconds]                      watch the default output/input devices: is anything playing / recording?
import AppKit
import ApplicationServices
import CoreAudio

let args = Array(CommandLine.arguments.dropFirst())
func fail(_ s: String) -> Never { FileHandle.standardError.write((s + "\n").data(using: .utf8)!); exit(1) }
guard let command = args.first else { fail("usage: see the header of drive.swift") }

// MARK: Keys

let modifierKeys: [String: (code: CGKeyCode, flag: CGEventFlags)] = [
    "ctrl": (59, .maskControl), "opt": (58, .maskAlternate), "cmd": (55, .maskCommand),
    "shift": (56, .maskShift), "fn": (63, .maskSecondaryFn),
]
let keyCodes: [String: CGKeyCode] = [
    "return": 36, "esc": 53, "space": 49, "tab": 48, "delete": 51, "left": 123, "right": 124, "down": 125, "up": 126,
    "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14,
    "r": 15, "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "9": 25, "7": 26, "8": 28, "0": 29,
    "o": 31, "u": 32, "i": 34, "p": 35, "l": 37, "j": 38, "k": 40, "n": 45, "m": 46, ",": 43, ".": 47,
]
let source = CGEventSource(stateID: .hidSystemState)
func mods(_ list: String) -> [String] { list.split(separator: ",").map(String.init).filter { !$0.isEmpty } }
func flags(_ names: [String]) -> CGEventFlags { names.reduce(into: CGEventFlags()) { $0.insert(modifierKeys[$1]!.flag) } }
func post(_ e: CGEvent?) { e?.post(tap: .cghidEventTap); usleep(12_000) }

/// Modifier presses are flagsChanged events carrying the full set of modifiers held after the change.
func modifiers(_ names: [String], down: Bool) {
    var current = down ? [String]() : names
    for name in names {
        guard let key = modifierKeys[name] else { fail("unknown modifier \(name)") }
        if down { current.append(name) } else { current.removeAll { $0 == name } }
        let e = CGEvent(keyboardEventSource: source, virtualKey: key.code, keyDown: down)
        e?.type = .flagsChanged
        e?.flags = flags(current)
        post(e)
    }
}

func keyPress(_ code: CGKeyCode, _ modNames: [String]) {
    let f = flags(modNames)
    let d = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true); d?.flags = f; post(d)
    let u = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false); u?.flags = f; post(u)
}

func typeText(_ text: String) {
    for ch in text {
        let utf16 = Array(String(ch).utf16)
        let d = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        d?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16); post(d)
        let u = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        u?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16); post(u)
    }
}

// MARK: AX

func attr(_ e: AXUIElement, _ name: String) -> AnyObject? {
    var v: AnyObject?
    return AXUIElementCopyAttributeValue(e, name as CFString, &v) == .success ? v : nil
}
func str(_ e: AXUIElement, _ name: String) -> String? {
    if let s = attr(e, name) as? String { return s }
    if let n = attr(e, name) as? NSNumber { return n.stringValue }
    return nil
}
func frame(_ e: AXUIElement) -> CGRect? {
    guard let p = attr(e, kAXPositionAttribute), let s = attr(e, kAXSizeAttribute) else { return nil }
    var point = CGPoint.zero, size = CGSize.zero
    AXValueGetValue(p as! AXValue, .cgPoint, &point); AXValueGetValue(s as! AXValue, .cgSize, &size)
    return CGRect(origin: point, size: size)
}
func children(_ e: AXUIElement) -> [AXUIElement] { (attr(e, kAXChildrenAttribute) as? [AXUIElement]) ?? [] }
func describe(_ e: AXUIElement) -> String {
    let role = str(e, kAXRoleAttribute) ?? "?"
    let title = str(e, kAXTitleAttribute) ?? str(e, kAXDescriptionAttribute) ?? ""
    var value = str(e, kAXValueAttribute) ?? ""
    if value.count > 80 { value = String(value.prefix(80)) + "…" }
    let id = str(e, kAXIdentifierAttribute) ?? ""
    let f = frame(e).map { "{\(Int($0.minX)),\(Int($0.minY)),\(Int($0.width)),\(Int($0.height))}" } ?? ""
    return "\(role) \"\(title)\"\(value.isEmpty ? "" : " [\(value)]")\(id.isEmpty ? "" : " #\(id)") \(f)"
}
func app(_ bundle: String) -> AXUIElement {
    guard let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundle).first
            ?? NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == bundle }) else { fail("not running: \(bundle)") }
    let e = AXUIElementCreateApplication(running.processIdentifier)
    AXUIElementSetMessagingTimeout(e, 3)
    return e
}
func roots(_ a: AXUIElement) -> [AXUIElement] {
    var r = (attr(a, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    if r.isEmpty { r = children(a) } // the Dock and menu-bar-only apps have no windows
    if let bar = attr(a, kAXMenuBarAttribute) { r.append(bar as! AXUIElement) }
    if let extras = attr(a, "AXExtrasMenuBar") { r.append(extras as! AXUIElement) }
    return r
}
func walk(_ e: AXUIElement, depth: Int, max: Int, _ visit: (AXUIElement, Int) -> Bool) {
    guard depth <= max, visit(e, depth) else { return }
    for c in children(e) { walk(c, depth: depth + 1, max: max, visit) }
}
func matches(_ bundle: String, _ text: String, role: String?) -> [AXUIElement] {
    var found: [AXUIElement] = []
    let needle = text.lowercased()
    for root in roots(app(bundle)) {
        walk(root, depth: 0, max: 40) { e, _ in
            if let role, str(e, kAXRoleAttribute) != role { return true }
            let hay = [kAXTitleAttribute, kAXValueAttribute, kAXDescriptionAttribute, kAXIdentifierAttribute, kAXHelpAttribute]
                .compactMap { str(e, $0)?.lowercased() }
            if needle.isEmpty || hay.contains(where: { $0.contains(needle) }) { found.append(e) }
            return true
        }
    }
    return found
}

// MARK: Commands

switch command {
case "down": modifiers(mods(args[1]), down: true)
case "up": modifiers(mods(args[1]), down: false)
case "tap":
    let times = args.count > 2 ? Int(args[2]) ?? 1 : 1
    for i in 0..<times {
        modifiers(mods(args[1]), down: true); usleep(40_000); modifiers(mods(args[1]), down: false)
        if i < times - 1 { usleep(120_000) }
    }
case "key":
    let name = args[1].lowercased()
    let code = keyCodes[name] ?? CGKeyCode(Int(name) ?? 0)
    keyPress(code, args.count > 2 ? mods(args[2]) : [])
case "type": typeText(args.dropFirst().joined(separator: " "))
case "rightclick":
    let p = CGPoint(x: Double(args[1])!, y: Double(args[2])!)
    post(CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .right))
    post(CGEvent(mouseEventSource: source, mouseType: .rightMouseDown, mouseCursorPosition: p, mouseButton: .right))
    post(CGEvent(mouseEventSource: source, mouseType: .rightMouseUp, mouseCursorPosition: p, mouseButton: .right))
case "move", "click":
    let p = CGPoint(x: Double(args[1])!, y: Double(args[2])!)
    post(CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left))
    if command == "click" {
        post(CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: p, mouseButton: .left))
        post(CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: p, mouseButton: .left))
    }
case "apps":
    for a in NSWorkspace.shared.runningApplications where a.activationPolicy != .prohibited {
        print(a.processIdentifier, a.bundleIdentifier ?? "-", a.localizedName ?? "-", a.isActive ? "(active)" : "")
    }
case "tree":
    let max = args.count > 2 ? Int(args[2]) ?? 12 : 12
    for root in roots(app(args[1])) {
        walk(root, depth: 0, max: max) { e, d in print(String(repeating: "  ", count: d) + describe(e)); return true }
    }
case "find":
    for e in matches(args[1], args[2], role: args.count > 3 ? args[3] : nil) { print(describe(e)) }
case "press":
    let all = matches(args[1], args[2], role: args.count > 3 ? args[3] : nil)
    let n = args.count > 4 ? Int(args[4]) ?? 0 : 0
    guard all.indices.contains(n) else { fail("no match: \(args[2]) #\(n)") }
    let e = all[n]
    let r = AXUIElementPerformAction(e, kAXPressAction as CFString)
    print(r == .success ? "pressed \(describe(e))" : "press failed (\(r.rawValue)) \(describe(e))")
case "setvalue":
    guard let e = matches(args[1], args[2], role: args.count > 4 ? args[4] : nil).first else { fail("no match: \(args[2])") }
    AXUIElementSetAttributeValue(e, kAXFocusedAttribute as CFString, kCFBooleanTrue)
    let r = AXUIElementSetAttributeValue(e, kAXValueAttribute as CFString, args[3] as CFString)
    print(r == .success ? "set \(describe(e))" : "set failed (\(r.rawValue))")
case "focused":
    let system = AXUIElementCreateSystemWide()
    print("app:", NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "?")
    if let f = attr(system, kAXFocusedUIElementAttribute) {
        let e = f as! AXUIElement
        let value = str(e, kAXValueAttribute) ?? ""
        print("element:", str(e, kAXRoleAttribute) ?? "?", str(e, kAXSubroleAttribute) ?? "", "chars=\(value.count)")
        print("value:", value)
    } else { print("element: none") }
case "windows":
    for w in (attr(app(args[1]), kAXWindowsAttribute) as? [AXUIElement]) ?? [] { print(describe(w)) }
case "audio":
    func device(_ selector: AudioObjectPropertySelector) -> AudioObjectID {
        var id = AudioObjectID(0), size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &id)
        return id
    }
    func running(_ id: AudioObjectID) -> Bool {
        var value = UInt32(0), size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                                                 mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value)
        return value != 0
    }
    let seconds = args.count > 1 ? Double(args[1]) ?? 0 : 0
    var playedAny = false, recordedAny = false
    let end = Date().addingTimeInterval(seconds)
    repeat {
        playedAny = playedAny || running(device(kAudioHardwarePropertyDefaultOutputDevice))
        recordedAny = recordedAny || running(device(kAudioHardwarePropertyDefaultInputDevice))
        usleep(100_000)
    } while Date() < end
    print("output=\(playedAny ? "playing" : "silent") input=\(recordedAny ? "recording" : "idle")")
default: fail("unknown command \(command)")
}
