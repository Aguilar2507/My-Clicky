import AppKit
import QuartzCore

/// Transparent, click-through windows (one per screen) that draw the status bubble and the pointing cursor.
@MainActor
final class OverlayController {
    private var windows: [OverlayWindow] = []
    private var followTimer: Timer?
    private var hideStatusWork: DispatchWorkItem?
    private var hidePointerWork: DispatchWorkItem?

    init() {
        rebuild()
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuild() }
        }
    }

    private func rebuild() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.map { OverlayWindow(screen: $0) }
        windows.forEach { $0.orderFrontRegardless() }
    }

    private func window(containing point: CGPoint) -> OverlayWindow? {
        windows.first { $0.frame.contains(point) } ?? windows.first
    }

    // MARK: Status bubble (follows the mouse)

    /// Shows a bubble next to the cursor. `autoHide` hides it after that many seconds.
    func showStatus(_ text: String, style: OverlayView.BubbleStyle, autoHide: TimeInterval? = nil) {
        hideStatusWork?.cancel()
        let mouse = NSEvent.mouseLocation
        for window in windows {
            if window.frame.contains(mouse) {
                window.overlayView.showBubble(text, style: style, near: window.convertFromGlobal(mouse))
            } else {
                window.overlayView.hideBubble()
            }
        }
        startFollowingMouse()
        if let autoHide {
            let work = DispatchWorkItem { [weak self] in self?.hideStatus() }
            hideStatusWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + autoHide, execute: work)
        }
    }

    func hideStatus() {
        hideStatusWork?.cancel()
        followTimer?.invalidate()
        followTimer = nil
        windows.forEach { $0.overlayView.hideBubble() }
    }

    private func startFollowingMouse() {
        guard followTimer == nil else { return }
        followTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let mouse = NSEvent.mouseLocation
                for window in self.windows where window.frame.contains(mouse) {
                    window.overlayView.moveBubble(near: window.convertFromGlobal(mouse))
                }
            }
        }
    }

    // MARK: Pointer

    /// Flies the blue pointer from the cursor to a global point and labels it.
    func point(at target: CGPoint, label: String, duration: TimeInterval = 10) {
        hidePointerWork?.cancel()
        windows.forEach { $0.overlayView.hidePointer() }
        guard let window = window(containing: target) else { return }
        let mouse = NSEvent.mouseLocation
        let start = window.frame.contains(mouse)
            ? window.convertFromGlobal(mouse)
            : CGPoint(x: window.frame.width / 2, y: window.frame.height / 2)
        window.overlayView.flyPointer(from: start, to: window.convertFromGlobal(target), label: label)

        let work = DispatchWorkItem { [weak self] in self?.hidePointer() }
        hidePointerWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    func hidePointer() {
        hidePointerWork?.cancel()
        windows.forEach { $0.overlayView.hidePointer() }
    }
}

final class OverlayWindow: NSWindow {
    let overlayView: OverlayView

    init(screen: NSScreen) {
        overlayView = OverlayView(frame: CGRect(origin: .zero, size: screen.frame.size))
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
        contentView = overlayView
        setFrame(screen.frame, display: false)
    }

    func convertFromGlobal(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x - frame.minX, y: point.y - frame.minY)
    }
}

final class OverlayView: NSView {
    enum BubbleStyle {
        case listening, thinking, info, agent

        var color: NSColor {
            switch self {
            case .listening: return .systemRed
            case .thinking: return .systemOrange
            case .info: return .systemBlue
            case .agent: return .systemPurple
            }
        }
    }

    private let bubble = CALayer()
    private let bubbleDot = CALayer()
    private let bubbleText = CATextLayer()
    private let pointer = CAShapeLayer()
    private let pointerLabel = CATextLayer()
    private let pointerLabelBackground = CALayer()
    private let font = NSFont.systemFont(ofSize: 13, weight: .medium)
    private let maxBubbleWidth: CGFloat = 380

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        let scale = NSScreen.main?.backingScaleFactor ?? 2

        bubble.backgroundColor = NSColor.black.withAlphaComponent(0.82).cgColor
        bubble.cornerRadius = 12
        bubble.isHidden = true
        bubbleDot.cornerRadius = 5
        bubbleDot.bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
        bubbleText.font = font
        bubbleText.fontSize = font.pointSize
        bubbleText.foregroundColor = NSColor.white.cgColor
        bubbleText.isWrapped = true
        bubbleText.contentsScale = scale
        bubble.addSublayer(bubbleDot)
        bubble.addSublayer(bubbleText)
        layer?.addSublayer(bubble)

        // A cursor-like arrow; its tip is at the layer's position.
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 7, y: -22))
        path.addLine(to: CGPoint(x: 12, y: -12))
        path.addLine(to: CGPoint(x: 22, y: -7))
        path.closeSubpath()
        pointer.path = path
        pointer.fillColor = NSColor.systemBlue.cgColor
        pointer.strokeColor = NSColor.white.cgColor
        pointer.lineWidth = 2
        pointer.shadowColor = NSColor.black.cgColor
        pointer.shadowOpacity = 0.4
        pointer.shadowRadius = 4
        pointer.shadowOffset = CGSize(width: 0, height: -2)
        pointer.isHidden = true
        layer?.addSublayer(pointer)

        pointerLabelBackground.backgroundColor = NSColor.systemBlue.cgColor
        pointerLabelBackground.cornerRadius = 8
        pointerLabelBackground.isHidden = true
        pointerLabel.font = font
        pointerLabel.fontSize = font.pointSize
        pointerLabel.foregroundColor = NSColor.white.cgColor
        pointerLabel.contentsScale = scale
        pointerLabelBackground.addSublayer(pointerLabel)
        layer?.addSublayer(pointerLabelBackground)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: Bubble

    func showBubble(_ text: String, style: BubbleStyle, near point: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let attributed = NSAttributedString(string: text, attributes: [.font: font])
        let textSize = attributed.boundingRect(with: CGSize(width: maxBubbleWidth, height: 400),
                                               options: [.usesLineFragmentOrigin, .usesFontLeading]).size
        let width = ceil(textSize.width) + 42
        let height = max(30, ceil(textSize.height) + 14)
        bubble.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        bubbleDot.backgroundColor = style.color.cgColor
        bubbleDot.position = CGPoint(x: 16, y: height - 15)
        bubbleText.string = text
        bubbleText.frame = CGRect(x: 28, y: 7, width: ceil(textSize.width) + 4, height: ceil(textSize.height))
        bubble.isHidden = false
        positionBubble(near: point)
        CATransaction.commit()

        bubbleDot.removeAllAnimations()
        if style == .listening || style == .thinking || style == .agent {
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1
            pulse.toValue = 0.25
            pulse.duration = 0.6
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            bubbleDot.add(pulse, forKey: "pulse")
        }
    }

    func moveBubble(near point: CGPoint) {
        guard !bubble.isHidden else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        positionBubble(near: point)
        CATransaction.commit()
    }

    func hideBubble() {
        bubble.isHidden = true
        bubbleDot.removeAllAnimations()
    }

    private func positionBubble(near point: CGPoint) {
        let size = bubble.bounds.size
        // Below-right of the cursor, kept on screen.
        var origin = CGPoint(x: point.x + 18, y: point.y - 22 - size.height)
        origin.x = min(max(8, origin.x), bounds.width - size.width - 8)
        origin.y = min(max(8, origin.y), bounds.height - size.height - 8)
        bubble.frame = CGRect(origin: origin, size: size)
    }

    // MARK: Pointer

    func flyPointer(from start: CGPoint, to end: CGPoint, label: String) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pointer.position = end
        pointer.isHidden = false
        pointerLabelBackground.isHidden = true
        CATransaction.commit()

        // Arc upward between start and end.
        let distance = hypot(end.x - start.x, end.y - start.y)
        let control = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 + max(60, distance * 0.3))
        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)

        let duration = min(1.1, max(0.5, Double(distance) / 1400))
        let flight = CAKeyframeAnimation(keyPath: "position")
        flight.path = path
        flight.duration = duration
        flight.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let grow = CAKeyframeAnimation(keyPath: "transform.scale")
        grow.values = [0.8, 1.35, 1.0]
        grow.duration = duration

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.showPointerLabel(label, at: end)
            self?.bouncePointer()
        }
        pointer.add(flight, forKey: "flight")
        pointer.add(grow, forKey: "grow")
        CATransaction.commit()
    }

    private func showPointerLabel(_ label: String, at point: CGPoint) {
        guard !label.isEmpty, !pointer.isHidden else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let size = NSAttributedString(string: label, attributes: [.font: font]).size()
        let background = CGSize(width: ceil(size.width) + 16, height: ceil(size.height) + 8)
        var origin = CGPoint(x: point.x + 20, y: point.y - 30 - background.height)
        origin.x = min(max(8, origin.x), bounds.width - background.width - 8)
        origin.y = min(max(8, origin.y), bounds.height - background.height - 8)
        pointerLabelBackground.frame = CGRect(origin: origin, size: background)
        pointerLabel.frame = CGRect(x: 8, y: 4, width: ceil(size.width) + 2, height: ceil(size.height))
        pointerLabel.string = label
        pointerLabelBackground.isHidden = false
        CATransaction.commit()
    }

    private func bouncePointer() {
        let bounce = CABasicAnimation(keyPath: "transform.scale")
        bounce.fromValue = 1.0
        bounce.toValue = 1.2
        bounce.duration = 0.45
        bounce.autoreverses = true
        bounce.repeatCount = .infinity
        pointer.add(bounce, forKey: "bounce")
    }

    func hidePointer() {
        pointer.removeAllAnimations()
        pointer.isHidden = true
        pointerLabelBackground.isHidden = true
    }
}
