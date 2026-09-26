import CoreGraphics

/// Motion math for the cursor companion (spec 006, research R1/R3). AppKit coordinates (y up).
public struct CompanionSpring: Equatable, Sendable {
    public var position: CGPoint
    public var velocity = CGVector.zero
    /// Roughly how long it takes to catch up (seconds); larger = softer, more "alive" trailing.
    public var response: Double = 0.25

    public init(position: CGPoint) { self.position = position }

    /// Critically damped spring step toward `target`, using the exact solution so any frame time is stable
    /// (no overshoot, no teleporting after a hitch).
    public mutating func step(toward target: CGPoint, dt: Double) {
        let dt = min(max(dt, 0), 0.25)
        let omega = 2 * Double.pi / response
        let decay = exp(-omega * dt)
        func axis(_ x: Double, _ v: Double, _ t: Double) -> (Double, Double) {
            let c1 = x - t
            let c2 = v + omega * c1
            return (t + (c1 + c2 * dt) * decay, (c2 - omega * (c1 + c2 * dt)) * decay)
        }
        let (nx, nvx) = axis(position.x, velocity.dx, target.x)
        let (ny, nvy) = axis(position.y, velocity.dy, target.y)
        position = CGPoint(x: nx, y: ny)
        velocity = CGVector(dx: nvx, dy: nvy)
    }

    public func isSettled(at target: CGPoint) -> Bool {
        hypot(target.x - position.x, target.y - position.y) < 0.5 && hypot(velocity.dx, velocity.dy) < 5
    }
}

public enum CompanionLayout {
    public static let offset = CGVector(dx: 18, dy: -26)

    /// Where the companion (of `size`) sits for a mouse position: lower-right of the pointer, flipped at screen edges.
    public static func anchor(mouse: CGPoint, screen: CGRect, size: CGSize) -> CGPoint {
        var x = mouse.x + offset.dx + size.width / 2
        var y = mouse.y + offset.dy - size.height / 2
        if x + size.width / 2 > screen.maxX { x = mouse.x - offset.dx - size.width / 2 }
        if y - size.height / 2 < screen.minY { y = mouse.y - offset.dy + size.height / 2 }
        x = min(max(x, screen.minX + size.width / 2), screen.maxX - size.width / 2)
        y = min(max(y, screen.minY + size.height / 2), screen.maxY - size.height / 2)
        return CGPoint(x: x, y: y)
    }

    /// Bubble origin (bottom-left) next to the companion, kept on screen.
    public static func bubbleOrigin(companion: CGPoint, bubble: CGSize, screen: CGRect, margin: CGFloat = 8) -> CGPoint {
        var origin = CGPoint(x: companion.x + 16, y: companion.y - 12 - bubble.height)
        if origin.x + bubble.width > screen.maxX - margin { origin.x = companion.x - 16 - bubble.width }
        if origin.y < screen.minY + margin { origin.y = companion.y + 16 }
        origin.x = min(max(origin.x, screen.minX + margin), screen.maxX - margin - bubble.width)
        origin.y = min(max(origin.y, screen.minY + margin), screen.maxY - margin - bubble.height)
        return origin
    }

    /// Control point for the pointing flight: an arc raised above the straight line.
    public static func arcControl(from start: CGPoint, to end: CGPoint) -> CGPoint {
        let distance = hypot(end.x - start.x, end.y - start.y)
        return CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 + max(60, distance * 0.3))
    }

    /// Flight duration by distance (0.5–1.1 s).
    public static func flightDuration(from start: CGPoint, to end: CGPoint) -> Double {
        min(1.1, max(0.5, Double(hypot(end.x - start.x, end.y - start.y)) / 1400))
    }
}

/// Screenshot pixels (origin top-left) → AppKit global points (origin bottom-left), clamped to the screenshot.
public enum ScreenMapping {
    public static func globalPoint(x: Double, y: Double, pixelWidth: Int, pixelHeight: Int, screenFrame: CGRect) -> CGPoint {
        let px = min(max(x, 0), Double(pixelWidth))
        let py = min(max(y, 0), Double(pixelHeight))
        return CGPoint(x: screenFrame.minX + px * screenFrame.width / Double(pixelWidth),
                       y: screenFrame.maxY - py * screenFrame.height / Double(pixelHeight))
    }

    /// Pixels → points length (for radii and widths).
    public static func length(_ pixels: Double, pixelWidth: Int, screenFrame: CGRect) -> CGFloat {
        CGFloat(pixels) * screenFrame.width / CGFloat(pixelWidth)
    }
}
