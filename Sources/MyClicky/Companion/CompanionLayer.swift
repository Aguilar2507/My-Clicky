import AppKit
import QuartzCore
import MyClickyCore

/// The MyClicky cursor: a glowing, rounded triangle (ref 08) with state animations (spec 006 research R2).
final class CompanionLayer: CALayer {
    enum Look: Equatable { case idle, listening, thinking, speaking, pointing }

    static let size: CGFloat = 22
    private let shape = CAShapeLayer()
    private let shine = CAShapeLayer()
    /// While listening the cursor turns into sound waves that move with your voice.
    private let waves = WaveformLayer()
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
        waves.position = CGPoint(x: bounds.midX, y: bounds.midY)
        waves.setAffineTransform(CGAffineTransform(rotationAngle: 10 * .pi / 180)) // upright despite the cursor's tilt
        waves.opacity = 0
        addSublayer(waves)
        setAffineTransform(CGAffineTransform(rotationAngle: -10 * .pi / 180)) // points right, tilted slightly down (ref 08)
    }

    override init(layer: Any) { super.init(layer: layer) }
    required init?(coder: NSCoder) { fatalError("not used") }

    func setColor(_ color: NSColor) {
        shape.fillColor = color.cgColor
        shape.shadowColor = color.cgColor
        waves.setColor(color)
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
        let wasListening = self.look == .listening
        self.look = look
        if look == .listening { showWaves(true) } else if wasListening { showWaves(false) }
        shape.removeAllAnimations()
        shine.removeAllAnimations()
        shine.opacity = 0
        if look != .listening { shape.transform = CATransform3DIdentity }
        switch look {
        case .idle, .pointing, .listening:
            break // listening: scale follows the mic level (setLevel)
        case .speaking where DisplayPrefs.shared.reduceMotion:
            // Reduce Motion: a gentle glow instead of a bounce (spec 014 US5).
            let glow = CABasicAnimation(keyPath: "opacity")
            glow.fromValue = 0
            glow.toValue = 0.35
            glow.duration = 0.8
            glow.autoreverses = true
            glow.repeatCount = .infinity
            shine.add(glow, forKey: "speaking")
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

    /// Listening: the sound waves follow the microphone level.
    func setLevel(_ level: Float) {
        guard look == .listening else { return }
        waves.setLevel(CGFloat(level))
    }

    /// The cursor morphs into sound waves while listening, and back when it stops (a cross-fade with Reduce Motion).
    private func showWaves(_ on: Bool) {
        let still = DisplayPrefs.shared.reduceMotion
        CATransaction.begin()
        CATransaction.setAnimationDuration(still ? MotionSpec.fadeDuration : 0.22)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        shape.opacity = on ? 0 : 1
        shape.transform = on && !still ? CATransform3DMakeScale(0.5, 0.5, 1) : CATransform3DIdentity
        waves.opacity = on ? 1 : 0
        waves.transform = CATransform3DConcat(on || still ? CATransform3DIdentity : CATransform3DMakeScale(0.5, 0.5, 1),
                                              CATransform3DMakeRotation(10 * .pi / 180, 0, 0, 1))
        CATransaction.commit()
        if on { waves.startBreathing(still: still) } else { waves.stopBreathing() }
    }

    /// A short attention bounce when arriving at a pointing target.
    func bounce() {
        guard !DisplayPrefs.shared.reduceMotion else { return }
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
    private let font = TypeStyle.footnote.weight(.medium).nsFont

    /// Transparent: the navy glass behind it is `BubbleGlassView` (spec 014).
    override init() {
        super.init()
        dot.cornerRadius = 4
        dot.bounds = CGRect(x: 0, y: 0, width: 8, height: 8)
        text.font = font
        text.fontSize = font.pointSize
        text.foregroundColor = GlassView.cgColor(.labelColor)
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
        text.foregroundColor = GlassView.cgColor(.labelColor) // follows Light/Dark (spec 015)
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
    private let font = TypeStyle.footnote.weight(.semibold).nsFont

    override init() {
        super.init()
        cornerRadius = 9
        cornerCurve = .continuous
        shadowOpacity = 0.3
        shadowRadius = 6
        shadowOffset = CGSize(width: 0, height: -2)
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

/// Sound waves for the listening cursor (spec 006, look from your reference): nine rounded bars, tallest in the
/// middle, in the cursor's color with its glow. Heights follow the microphone level; a gentle breathing keeps them
/// moving while you pause, so you can always tell MyClicky is listening.
final class WaveformLayer: CALayer {
    /// Resting heights, from the reference image (fractions of the full height).
    private static let pattern: [CGFloat] = [0.38, 0.24, 0.58, 0.92, 0.58, 0.76, 0.38, 0.54, 0.18]
    static let size = CGSize(width: 34, height: 28)
    private let barWidth: CGFloat = 2.7
    private var bars: [CALayer] = []
    private var level: CGFloat = 0

    override init() {
        super.init()
        bounds = CGRect(origin: .zero, size: Self.size)
        shadowRadius = 6
        shadowOpacity = 0.8
        shadowOffset = .zero
        let gap = (Self.size.width - barWidth * CGFloat(Self.pattern.count)) / CGFloat(Self.pattern.count - 1)
        for i in Self.pattern.indices {
            let bar = CALayer()
            bar.cornerRadius = barWidth / 2
            bar.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bar.position = CGPoint(x: barWidth / 2 + CGFloat(i) * (barWidth + gap), y: Self.size.height / 2)
            addSublayer(bar)
            bars.append(bar)
        }
        layout(level: 0, animated: false)
    }

    override init(layer: Any) { super.init(layer: layer) }
    required init?(coder: NSCoder) { fatalError("not used") }

    func setColor(_ color: NSColor) {
        bars.forEach { $0.backgroundColor = color.cgColor }
        shadowColor = color.cgColor
    }

    /// 0…1 from the microphone.
    func setLevel(_ level: CGFloat) {
        self.level = self.level * 0.4 + min(1, max(0, level)) * 0.6 // a little smoothing
        layout(level: self.level, animated: true)
    }

    /// Quiet: 45 % of the pattern. Loud: the full pattern, with the smaller bars catching up.
    private func layout(level: CGFloat, animated: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        CATransaction.setAnimationDuration(0.09)
        for (bar, base) in zip(bars, Self.pattern) {
            let height = max(barWidth, Self.size.height * base * (0.45 + 0.55 * level) * (1 + (1 - base) * level * 0.5))
            bar.bounds = CGRect(x: 0, y: 0, width: barWidth, height: min(Self.size.height, height))
        }
        CATransaction.commit()
    }

    /// Each bar breathes on its own rhythm, so the waves look alive even in silence.
    func startBreathing(still: Bool) {
        guard !still else { return }
        for (i, bar) in bars.enumerated() {
            let breathe = CABasicAnimation(keyPath: "transform.scale.y")
            breathe.fromValue = 0.72
            breathe.toValue = 1.0
            breathe.duration = 0.42 + Double(i % 4) * 0.07
            breathe.autoreverses = true
            breathe.repeatCount = .infinity
            breathe.timeOffset = Double(i) * 0.11
            breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            bar.add(breathe, forKey: "breathe")
        }
    }

    func stopBreathing() {
        bars.forEach { $0.removeAnimation(forKey: "breathe") }
        level = 0
        layout(level: 0, animated: false)
    }
}
