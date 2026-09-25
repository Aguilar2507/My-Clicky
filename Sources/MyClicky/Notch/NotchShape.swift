import SwiftUI

/// The black notch extension: flared top corners that melt into the menu bar and rounded bottom corners.
/// Width, height and bottom radius animate, so the same shape grows into the app panel.
struct NotchShape: Shape {
    var width: CGFloat
    var height: CGFloat
    var bottomRadius: CGFloat
    var topFlare: CGFloat = 8
    var offsetX: CGFloat = 0

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(width, height), AnimatablePair(bottomRadius, offsetX)) }
        set {
            width = newValue.first.first
            height = newValue.first.second
            bottomRadius = newValue.second.first
            offsetX = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let w = min(width, rect.width), h = min(height, rect.height)
        let x0 = rect.midX - w / 2 + offsetX, y0 = rect.minY
        let flare = min(topFlare, w / 4, h / 2)
        let r = min(bottomRadius, (w - 2 * flare) / 2, h - flare)
        var p = Path()
        p.move(to: CGPoint(x: x0, y: y0))
        p.addQuadCurve(to: CGPoint(x: x0 + flare, y: y0 + flare), control: CGPoint(x: x0 + flare, y: y0))
        p.addLine(to: CGPoint(x: x0 + flare, y: y0 + h - r))
        p.addQuadCurve(to: CGPoint(x: x0 + flare + r, y: y0 + h), control: CGPoint(x: x0 + flare, y: y0 + h))
        p.addLine(to: CGPoint(x: x0 + w - flare - r, y: y0 + h))
        p.addQuadCurve(to: CGPoint(x: x0 + w - flare, y: y0 + h - r), control: CGPoint(x: x0 + w - flare, y: y0 + h))
        p.addLine(to: CGPoint(x: x0 + w - flare, y: y0 + flare))
        p.addQuadCurve(to: CGPoint(x: x0 + w, y: y0), control: CGPoint(x: x0 + w - flare, y: y0))
        p.closeSubpath()
        return p
    }
}
