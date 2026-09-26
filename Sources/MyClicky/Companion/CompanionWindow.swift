import AppKit

/// Transparent, click-through window covering one display. Holds the companion, bubble, label and drawings layers.
final class CompanionWindow: NSWindow {
    let overlay: CompanionOverlayView

    init(screen: NSScreen) {
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
}

/// The layer stack of one companion window.
final class CompanionOverlayView: NSView {
    let drawings = CALayer()
    let companion = CompanionLayer()
    let bubble = BubbleLayer()
    let label = LabelPillLayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        for sub in [drawings, bubble, label, companion] as [CALayer] {
            sub.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
            layer?.addSublayer(sub)
        }
        drawings.frame = bounds
        companion.isHidden = true
        bubble.isHidden = true
        label.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError("not used") }
}
