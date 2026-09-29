import AppKit

/// ⌘C ⌘V ⌘X ⌘A ⌘Z ⇧⌘Z in every MyClicky text box. Mac apps normally get these from the Edit menu, but MyClicky has no
/// menu bar and the notch panel doesn't make the app active, so the shortcuts are sent to the focused text box here.
@MainActor
enum EditShortcuts {
    private static var monitor: Any?

    static func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let action = action(for: event) else { return event }
            return NSApp.sendAction(action, to: nil, from: nil) ? nil : event
        }
    }

    private static func action(for event: NSEvent) -> Selector? {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.capsLock, .numericPad, .function])
        guard let key = event.charactersIgnoringModifiers?.lowercased() else { return nil }
        if mods == [.command] {
            switch key {
            case "x": return #selector(NSText.cut(_:))
            case "c": return #selector(NSText.copy(_:))
            case "v": return #selector(NSText.paste(_:))
            case "a": return #selector(NSText.selectAll(_:))
            case "z": return Selector(("undo:"))
            default: return nil
            }
        }
        if mods == [.command, .shift], key == "z" { return Selector(("redo:")) }
        return nil
    }
}
