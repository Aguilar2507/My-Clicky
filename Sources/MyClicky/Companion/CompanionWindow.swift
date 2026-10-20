import AppKit
import MyClickyCore

/// Transparent, click-through window for one display. Holds the companion, bubble, label and drawings layers.
///
/// It is only as big as what it shows (the companion and its bubble), and covers the whole display only while
/// pointing or drawing. A display-sized transparent window on every Space made Mission Control show full-screen
/// Spaces as black thumbnails (fixed 2026-09-29).
final class CompanionWindow: NSWindow {
    let overlay: CompanionOverlayView
    /// The display this window belongs to (global coordinates).
    let screenFrame: CGRect
    /// The bubble's last rectangle (global) and until when it's still animating away.
    var fadingBubble: (rect: CGRect, until: CFTimeInterval)?

    init(screen: NSScreen) {
        screenFrame = screen.frame
        overlay = CompanionOverlayView(frame: CGRect(origin: .zero, size: screen.frame.size))
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
        animationBehavior = .none
        contentView = overlay
        setFrame(screen.frame, display: false)
    }

    /// Global AppKit point → this window's layer coordinates.
    func local(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x - frame.minX, y: point.y - frame.minY) }
    func local(_ rect: CGRect) -> CGRect { CGRect(origin: local(rect.origin), size: rect.size) }

    var hasDrawings: Bool { !(overlay.drawings.sublayers ?? []).isEmpty }

    /// Resizes to `rect` (global), or hides when there's nothing to show.
    func fit(_ rect: CGRect?) {
        guard let rect, !rect.isEmpty else {
            if isVisible { orderOut(nil) }
            return
        }
        let snapped = rect.integral
        if frame != snapped {
            setFrame(snapped, display: false)
            // Drawings are positioned for the full display; keep their layer where the display is.
            overlay.drawings.frame = CGRect(origin: CGPoint(x: screenFrame.minX - snapped.minX, y: screenFrame.minY - snapped.minY),
                                            size: screenFrame.size)
        }
        if !isVisible { orderFrontRegardless() }
    }
}

/// The layer stack of one companion window. Each layer lives in its own host view so the order is fixed:
/// drawings → bubble (navy glass, spec 014) → label → companion.
final class CompanionOverlayView: NSView {
    let drawings = CALayer()
    let companion = CompanionLayer()
    let bubble = BubbleLayer()
    let label = LabelPillLayer()
    private let bubbleView = BubbleGlassView()
    private(set) var bubbleShown = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        for sub in [drawings, bubble, label, companion] as [CALayer] { sub.contentsScale = scale }

        addSubview(Self.host(drawings, frame: bounds))
        bubbleView.contentLayer.addSublayer(bubble)
        bubbleView.isHidden = true
        addSubview(bubbleView)
        addSubview(Self.host(label, frame: bounds))
        addSubview(Self.host(companion, frame: bounds))

        drawings.frame = bounds
        companion.isHidden = true
        label.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    private static func host(_ layer: CALayer, frame: CGRect) -> NSView {
        let view = NSView(frame: frame)
        view.autoresizingMask = [.width, .height]
        view.wantsLayer = true
        view.layer?.addSublayer(layer)
        return view
    }

    /// Places the bubble; the first time after being hidden it grows out of the corner nearest `source` (the cursor).
    func showBubble(frame: CGRect, from source: CGPoint) {
        if bubbleView.frame != frame { bubbleView.setFrameNow(frame) }
        bubble.frame = CGRect(origin: .zero, size: frame.size)
        guard !bubbleShown else { return }
        bubbleShown = true
        bubbleView.refreshTint()
        bubbleView.isHidden = false
        bubbleView.animate(appearing: true, from: source)
    }

    /// Keeps the bubble where it is on screen (local frame) while it animates away and the window moves.
    func placeBubble(frame: CGRect) {
        bubbleView.setFrameNow(frame)
    }

    /// Shrinks back toward the cursor the way it came, then hides.
    func hideBubble(toward source: CGPoint) {
        guard bubbleShown else { return }
        bubbleShown = false
        bubbleView.animate(appearing: false, from: source) { [weak self] in
            guard let self, !self.bubbleShown else { return }
            self.bubbleView.isHidden = true
        }
    }
}

/// Navy glass behind the bubble's text: the system blur of whatever is under it, tinted, with a light top edge.
private final class BubbleGlassView: NSView {
    private let blur = GlassView.make()
    private let tint = CALayer()
    private let edge = CAGradientLayer()
    let contentLayer = CALayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        blur.autoresizingMask = [.width, .height]
        addSubview(blur)
        let top = NSView()
        top.autoresizingMask = [.width, .height]
        top.wantsLayer = true
        top.layer?.addSublayer(tint)
        top.layer?.addSublayer(edge)
        top.layer?.addSublayer(contentLayer)
        addSubview(top)
        edge.colors = [NSColor.clear.cgColor, NSColor.clear.cgColor]
        edge.startPoint = CGPoint(x: 0.5, y: 1)
        edge.endPoint = CGPoint(x: 0.5, y: 0.6)
        refreshTint()
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    /// Moves and resizes the glass and its layers in the same frame, so the tint never lags behind a growing bubble.
    func setFrameNow(_ rect: CGRect) {
        frame = rect
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tint.frame = bounds
        edge.frame = bounds
        contentLayer.frame = bounds
        CATransaction.commit()
    }

    func refreshTint() {
        tint.backgroundColor = GlassView.cgColor(GlassView.tint)
        layer?.borderColor = GlassView.cgColor(.separatorColor)
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        edge.colors = [NSColor.white.withAlphaComponent(isDark ? 0.12 : 0).cgColor, NSColor.clear.cgColor]
        blur.isHidden = DisplayPrefs.shared.solidSurfaces
    }

    /// Scale + fade around the corner closest to `source`, on the shared spring (a fade with Reduce Motion).
    func animate(appearing: Bool, from source: CGPoint, completion: (() -> Void)? = nil) {
        guard let layer else { completion?(); return }
        let anchor = CGPoint(x: source.x <= frame.midX ? 0 : bounds.width, y: source.y <= frame.midY ? 0 : bounds.height)
        var small = CATransform3DMakeTranslation(anchor.x, anchor.y, 0)
        small = CATransform3DScale(small, 0.86, 0.86, 1)
        small = CATransform3DTranslate(small, -anchor.x, -anchor.y, 0)
        let still = DisplayPrefs.shared.reduceMotion
        let from = appearing ? (still ? CATransform3DIdentity : small) : CATransform3DIdentity
        let to = appearing ? CATransform3DIdentity : (still ? CATransform3DIdentity : small)

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        let transform = Motion.caSpring("transform", from: NSValue(caTransform3D: from), to: NSValue(caTransform3D: to))
        let opacity = Motion.caSpring("opacity", from: appearing ? 0 : 1, to: appearing ? 1 : 0, .quick)
        layer.transform = to
        layer.opacity = appearing ? 1 : 0
        layer.add(transform, forKey: "grow")
        layer.add(opacity, forKey: "fade")
        CATransaction.commit()
    }
}
