import AppKit
import QuartzCore
import MyClickyCore

/// Hand-drawn-looking annotations (circle, arrow, box, underline) in the companion's color (spec 006 US4).
enum DrawingLayer {
    /// A stroke layer that draws itself in 0.5 s. `point`/`length` convert screenshot pixels → layer coordinates.
    static func make(_ mark: ScreenMark, color: NSColor, point: (Double, Double) -> CGPoint,
                     length: (Double) -> CGFloat) -> CAShapeLayer? {
        let path = CGMutablePath()
        switch mark {
        case .circle(let x, let y, let r, _):
            let c = point(x, y), radius = length(r)
            // Slightly uneven ellipse that overshoots its start, like a pen circle.
            let steps = 48
            for i in 0...(steps + 4) {
                let t = Double(i) / Double(steps) * 2 * .pi - .pi / 2
                let wobble = 1 + 0.04 * sin(3 * t + 0.7)
                let p = CGPoint(x: c.x + radius * 1.08 * wobble * cos(t), y: c.y + radius * 0.94 * wobble * sin(t))
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
        case .arrow(let x1, let y1, let x2, let y2, _):
            let a = point(x1, y1), b = point(x2, y2)
            let mid = CGPoint(x: (a.x + b.x) / 2 + 6, y: (a.y + b.y) / 2 + 6)
            path.move(to: a)
            path.addQuadCurve(to: b, control: mid)
            let angle = atan2(b.y - mid.y, b.x - mid.x), head: CGFloat = 16
            path.move(to: CGPoint(x: b.x - head * cos(angle - 0.45), y: b.y - head * sin(angle - 0.45)))
            path.addLine(to: b)
            path.addLine(to: CGPoint(x: b.x - head * cos(angle + 0.45), y: b.y - head * sin(angle + 0.45)))
        case .box(let x, let y, let w, let h, _):
            let p0 = point(x, y), p1 = point(x + w, y + h)
            let rect = CGRect(x: min(p0.x, p1.x), y: min(p0.y, p1.y), width: abs(p1.x - p0.x), height: abs(p1.y - p0.y))
            path.addPath(CGPath(roundedRect: rect.insetBy(dx: -4, dy: -4), cornerWidth: 8, cornerHeight: 8, transform: nil))
        case .underline(let x1, let y, let x2, _):
            let a = point(x1, y), b = point(x2, y)
            path.move(to: CGPoint(x: a.x, y: a.y - 4))
            path.addQuadCurve(to: CGPoint(x: b.x, y: b.y - 4), control: CGPoint(x: (a.x + b.x) / 2, y: a.y - 8))
        case .point:
            return nil
        }
        let layer = CAShapeLayer()
        layer.path = path
        layer.strokeColor = color.cgColor
        layer.fillColor = nil
        layer.lineWidth = 3.5
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.shadowColor = color.cgColor
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.7
        layer.shadowOffset = .zero
        let draw = CABasicAnimation(keyPath: "strokeEnd")
        draw.fromValue = 0
        draw.toValue = 1
        draw.duration = 0.5
        draw.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(draw, forKey: "draw")
        return layer
    }
}
