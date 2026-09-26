import AppKit

/// Text mode (spec 006 US5): double-tap ⌃ opens "Ask MyClicky…" right next to the cursor. Return sends, Esc closes.
@MainActor
final class TextModeField: NSObject, NSTextFieldDelegate {
    private var panel: KeyPanel?
    private let field = NSTextField()
    var onSubmit: (String) -> Void = { _ in }

    var isOpen: Bool { panel?.isVisible ?? false }

    func show(near point: CGPoint) {
        close()
        let size = CGSize(width: 380, height: 46)
        let screen = NSScreen.screens.first { $0.frame.contains(point) }?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        var origin = CGPoint(x: point.x + 16, y: point.y - 22 - size.height)
        origin.x = min(max(origin.x, screen.minX + 8), screen.maxX - size.width - 8)
        origin.y = min(max(origin.y, screen.minY + 8), screen.maxY - size.height - 8)

        let panel = KeyPanel(contentRect: CGRect(origin: origin, size: size),
                             styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .popUpMenu
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.onResign = { [weak self] in self?.close() }

        let background = NSView(frame: CGRect(origin: .zero, size: size))
        background.wantsLayer = true
        background.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.88).cgColor
        background.layer?.cornerRadius = 14
        background.layer?.borderColor = NSColor.white.withAlphaComponent(0.1).cgColor
        background.layer?.borderWidth = 1

        field.frame = CGRect(x: 16, y: 12, width: size.width - 32, height: 22)
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.textColor = .white
        field.font = .systemFont(ofSize: 15)
        field.stringValue = ""
        field.placeholderAttributedString = NSAttributedString(
            string: "Ask MyClicky…", attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.45),
                                                  .font: NSFont.systemFont(ofSize: 15)])
        field.delegate = self
        background.addSubview(field)
        panel.contentView = background
        if let model = AppServices.shared.map({ _ in AppModel.shared }) { WindowSharing.apply(to: panel, model: model) }
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(field)
        self.panel = panel
    }

    func close() {
        panel?.onResign = nil
        panel?.orderOut(nil)
        panel = nil
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            close()
            if !text.isEmpty {
                // Let the field disappear before the screenshot (it's excluded anyway, belt and braces).
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in self?.onSubmit(text) }
            }
            return true
        }
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            close()
            return true
        }
        return false
    }
}

/// A borderless panel that can take keyboard focus without activating MyClicky.
final class KeyPanel: NSPanel {
    var onResign: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override func resignKey() {
        super.resignKey()
        onResign?()
    }
}
