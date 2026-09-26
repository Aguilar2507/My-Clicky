import AppKit
import ApplicationServices
import MyClickyCore

/// Types dictated text where the user's text cursor is (spec 008 research R1): checks the focused element through
/// Accessibility (never password fields), then pastes with ⌘V and puts the clipboard back afterwards.
@MainActor
enum TextInserter {
    enum Outcome: Equatable { case inserted, copiedNoField, refusedSecure }

    struct Focus {
        let element: AXUIElement?
        let isSecure: Bool
        let isEditable: Bool
        let previousCharacter: Character?
    }

    static func focusedElement() -> Focus {
        let system = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &value) == .success,
              let element = value, CFGetTypeID(element) == AXUIElementGetTypeID() else {
            return Focus(element: nil, isSecure: false, isEditable: false, previousCharacter: nil)
        }
        let ax = element as! AXUIElement
        let role = string(ax, kAXRoleAttribute)
        let subrole = string(ax, kAXSubroleAttribute)
        let secure = subrole == (kAXSecureTextFieldSubrole as String)
        var settable = DarwinBoolean(false)
        AXUIElementIsAttributeSettable(ax, kAXValueAttribute as CFString, &settable)
        let textRoles: Set<String> = [kAXTextFieldRole as String, kAXTextAreaRole as String, kAXComboBoxRole as String, "AXSearchField"]
        let editable = textRoles.contains(role ?? "") || settable.boolValue || attributeExists(ax, "AXEditableAncestor")
        return Focus(element: ax, isSecure: secure, isEditable: editable, previousCharacter: previousCharacter(ax))
    }

    /// Inserts text at the cursor, or leaves it on the clipboard when no text field is focused.
    @discardableResult
    static func insert(_ text: String) -> Outcome {
        let focus = focusedElement()
        if focus.isSecure { return .refusedSecure }
        guard focus.isEditable else {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            return .copiedNoField
        }
        let prefix = SpacingRule.needsLeadingSpace(before: text, previousCharacter: focus.previousCharacter) ? " " : ""
        paste(prefix + text)
        return .inserted
    }

    /// Paste through the clipboard, restoring everything that was on it (all types) 0.4 s later.
    static func paste(_ text: String) {
        let pasteboard = NSPasteboard.general
        let saved: [[NSPasteboard.PasteboardType: Data]] = (pasteboard.pasteboardItems ?? []).map { item in
            Dictionary(uniqueKeysWithValues: item.types.compactMap { type in item.data(forType: type).map { (type, $0) } })
        }
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let ourChange = pasteboard.changeCount

        let source = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true) // V
        let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard pasteboard.changeCount == ourChange else { return } // the user copied something new meanwhile
            pasteboard.clearContents()
            let items = saved.map { entries -> NSPasteboardItem in
                let item = NSPasteboardItem()
                entries.forEach { item.setData($0.value, forType: $0.key) }
                return item
            }
            if !items.isEmpty { pasteboard.writeObjects(items) }
        }
    }

    // MARK: Accessibility helpers

    private static func string(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? String
    }

    private static func attributeExists(_ element: AXUIElement, _ attribute: String) -> Bool {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success && value != nil
    }

    /// The character just before the caret, when the app exposes value + selection (best-effort, research R5).
    private static func previousCharacter(_ element: AXUIElement) -> Character? {
        guard let text = string(element, kAXValueAttribute) else { return nil }
        var rangeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeValue) == .success,
              let axValue = rangeValue, CFGetTypeID(axValue) == AXValueGetTypeID() else { return nil }
        var range = CFRange()
        guard AXValueGetValue(axValue as! AXValue, .cfRange, &range), range.location > 0 else { return nil }
        let utf16 = Array(text.utf16)
        guard range.location <= utf16.count else { return nil }
        return String(utf16: Array(utf16[(range.location - 1)..<range.location])).first
    }
}

private extension String {
    init(utf16 units: [UInt16]) { self = String(decoding: units, as: UTF16.self) }
}
