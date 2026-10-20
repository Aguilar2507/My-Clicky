import AppKit
import MyClickyCore

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

        // Navy glass (spec 014): the page behind shows through, blurred and tinted.
        let background = NSView(frame: CGRect(origin: .zero, size: size))
        background.wantsLayer = true
        background.layer?.cornerRadius = 16
        background.layer?.cornerCurve = .continuous
        background.layer?.masksToBounds = true
        let blur = GlassView.make()
        blur.frame = background.bounds
        blur.isHidden = DisplayPrefs.shared.solidSurfaces
        background.addSubview(blur)
        let glass = NSView(frame: background.bounds)
        glass.wantsLayer = true
        glass.layer?.backgroundColor = GlassView.cgColor(GlassView.tint)
        glass.layer?.cornerRadius = 16
        glass.layer?.cornerCurve = .continuous
        glass.layer?.borderColor = GlassView.cgColor(DisplayPrefs.shared.increaseContrast ? .tertiaryLabelColor : .separatorColor)
        glass.layer?.borderWidth = 1
        let edge = CAGradientLayer()
        edge.frame = glass.bounds
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        edge.colors = [NSColor.white.withAlphaComponent(isDark ? 0.12 : 0).cgColor, NSColor.clear.cgColor]
        edge.startPoint = CGPoint(x: 0.5, y: 1)
        edge.endPoint = CGPoint(x: 0.5, y: 0.5)
        glass.layer?.addSublayer(edge)
        background.addSubview(glass)

        field.frame = CGRect(x: 16, y: 12, width: size.width - 32, height: 22)
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.textColor = .labelColor
        field.font = TypeStyle.callout.nsFont
        field.stringValue = ""
        field.placeholderAttributedString = NSAttributedString(
            string: "Ask MyClicky…", attributes: [.foregroundColor: NSColor.placeholderTextColor,
                                                  .font: TypeStyle.callout.nsFont])
        field.delegate = self
        background.addSubview(field)
        panel.contentView = background
        if let model = AppServices.shared.map({ _ in AppModel.shared }) { WindowSharing.apply(to: panel, model: model) }
        // Materializes next to the cursor: a quick fade and a small scale-up (a fade only with Reduce Motion).
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(field)
        if let layer = background.layer {
            layer.add(Motion.caSpring("transform.scale", from: DisplayPrefs.shared.reduceMotion ? 1 : 0.96, to: 1), forKey: "grow")
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = MotionSpec.fadeDuration
            panel.animator().alphaValue = 1
        }
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
