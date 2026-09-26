import AppKit
import QuartzCore

/// The MyClicky cursor: a glowing, rounded triangle (ref 08) with state animations (spec 006 research R2).
final class CompanionLayer: CALayer {
    enum Look: Equatable { case idle, listening, thinking, speaking, pointing }

    static let size: CGFloat = 22
    private let shape = CAShapeLayer()
    private let shine = CAShapeLayer()
    private(set) var look: Look = .idle

    override init() {
        super.init()
        bounds = CGRect(x: 0, y: 0, width: Self.size, height: Self.size)
        let path = Self.trianglePath(size: Self.size)
        shape.path = path
        shape.frame = bounds
        shape.shadowRadius = 10
        shape.shadowOpacity = 0.9
        shape.shadowOffset = .zero
        shine.path = path
        shine.frame = bounds
        shine.fillColor = NSColor.white.withAlphaComponent(0.55).cgColor
        shine.opacity = 0
        addSublayer(shape)
        addSublayer(shine)
        setAffineTransform(CGAffineTransform(rotationAngle: -10 * .pi / 180)) // points right, tilted slightly down (ref 08)
    }

    override init(layer: Any) { super.init(layer: layer) }
    required init?(coder: NSCoder) { fatalError("not used") }

    func setColor(_ color: NSColor) {
        shape.fillColor = color.cgColor
        shape.shadowColor = color.cgColor
    }

    /// Right-pointing triangle with rounded corners, centered in a square of `size`.
    static func trianglePath(size s: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let a = CGPoint(x: s * 0.16, y: s * 0.10), b = CGPoint(x: s * 0.94, y: s * 0.5), c = CGPoint(x: s * 0.16, y: s * 0.90)
        let r = s * 0.14
        path.move(to: CGPoint(x: (a.x + c.x) / 2, y: (a.y + c.y) / 2))
        path.addArc(tangent1End: a, tangent2End: b, radius: r)
        path.addArc(tangent1End: b, tangent2End: c, radius: r)
        path.addArc(tangent1End: c, tangent2End: a, radius: r)
        path.closeSubpath()
        return path
    }

    func setLook(_ look: Look) {
        guard look != self.look else { return }
        self.look = look
        shape.removeAllAnimations()
        shine.removeAllAnimations()
        shine.opacity = 0
        shape.transform = CATransform3DIdentity
        switch look {
        case .idle, .pointing, .listening:
            break // listening: scale follows the mic level (setLevel)
        case .thinking:
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0
            pulse.toValue = 0.8
            pulse.duration = 0.45
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            shine.add(pulse, forKey: "shimmer")
        case .speaking:
            let bounce = CAKeyframeAnimation(keyPath: "transform.scale")
            bounce.values = [1.0, 1.18, 1.0]
            bounce.keyTimes = [0, 0.5, 1]
            bounce.duration = 0.4
            bounce.repeatCount = .infinity
            shape.add(bounce, forKey: "speaking")
        }
    }

    /// Listening: grow with the voice (1.0–1.3×).
    func setLevel(_ level: Float) {
        guard look == .listening else { return }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.08)
        let scale = 1 + 0.3 * CGFloat(level)
        shape.transform = CATransform3DMakeScale(scale, scale, 1)
        CATransaction.commit()
    }

    /// A short attention bounce when arriving at a pointing target.
    func bounce() {
        let bounce = CAKeyframeAnimation(keyPath: "transform.scale")
        bounce.values = [1.0, 1.35, 1.0, 1.2, 1.0]
        bounce.duration = 0.7
        shape.add(bounce, forKey: "arrive")
    }
}

/// Dark rounded bubble with a status dot and wrapped text, shown beside the companion (spec 006 US2).
final class BubbleLayer: CALayer {
    enum Style { case info, listening, thinking, agent, quiet }

    static let maxWidth: CGFloat = 380
    private let dot = CALayer()
    private let text = CATextLayer()
    private let font = NSFont.systemFont(ofSize: 13, weight: .medium)

    override init() {
        super.init()
        backgroundColor = NSColor.black.withAlphaComponent(0.85).cgColor
        cornerRadius = 12
        borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        borderWidth = 1
        dot.cornerRadius = 4
        dot.bounds = CGRect(x: 0, y: 0, width: 8, height: 8)
        text.font = font
        text.fontSize = font.pointSize
        text.foregroundColor = NSColor.white.cgColor
        text.isWrapped = true
        text.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        addSublayer(dot)
        addSublayer(text)
    }

    override init(layer: Any) { super.init(layer: layer) }
    required init?(coder: NSCoder) { fatalError("not used") }

    /// Sets the text and resizes; returns the new size.
    @discardableResult
    func set(_ string: String, style: Style, accent: NSColor) -> CGSize {
        let size = NSAttributedString(string: string, attributes: [.font: font])
            .boundingRect(with: CGSize(width: Self.maxWidth, height: 600), options: [.usesLineFragmentOrigin, .usesFontLeading]).size
        let width = ceil(size.width) + 40, height = max(30, ceil(size.height) + 14)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bounds = CGRect(x: 0, y: 0, width: width, height: height)
        dot.backgroundColor = color(for: style, accent: accent).cgColor
        dot.position = CGPoint(x: 15, y: height - 15)
        text.string = string
        text.frame = CGRect(x: 26, y: 7, width: ceil(size.width) + 4, height: ceil(size.height))
        CATransaction.commit()
        return bounds.size
    }

    private func color(for style: Style, accent: NSColor) -> NSColor {
        switch style {
        case .info: accent
        case .listening: .systemRed
        case .thinking: .systemOrange
        case .agent: .systemPurple
        case .quiet: .systemGray
        }
    }
}

/// Label pill shown at a pointing target, in the companion's color.
final class LabelPillLayer: CALayer {
    private let text = CATextLayer()
    private let font = NSFont.systemFont(ofSize: 13, weight: .semibold)

    override init() {
        super.init()
        cornerRadius = 9
        text.font = font
        text.fontSize = font.pointSize
        text.foregroundColor = NSColor.white.cgColor
        text.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        addSublayer(text)
    }

    override init(layer: Any) { super.init(layer: layer) }
    required init?(coder: NSCoder) { fatalError("not used") }

    func set(_ string: String, color: NSColor, near point: CGPoint, within bounds: CGRect) {
        let size = NSAttributedString(string: string, attributes: [.font: font]).size()
        let box = CGSize(width: ceil(size.width) + 18, height: ceil(size.height) + 8)
        var origin = CGPoint(x: point.x + 18, y: point.y - 30 - box.height)
        origin.x = min(max(8, origin.x), bounds.width - box.width - 8)
        origin.y = min(max(8, origin.y), bounds.height - box.height - 8)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundColor = color.cgColor
        frame = CGRect(origin: origin, size: box)
        text.frame = CGRect(x: 9, y: 4, width: ceil(size.width) + 2, height: ceil(size.height))
        text.string = string
        isHidden = string.isEmpty
        CATransaction.commit()
    }
}
