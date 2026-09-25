import SwiftUI

/// MyClicky's own mascot: a soft round blob with happy "^ ^" eyes (original art, not HeyClicky's).
struct MascotBlob: View {
    var color: Color
    var glow = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                BlobShape()
                    .fill(LinearGradient(colors: [color.lighter(0.12), color], startPoint: .top, endPoint: .bottom))
                    .shadow(color: glow ? color.opacity(0.7) : .clear, radius: w * 0.12)
                HappyEye().stroke(.white, style: StrokeStyle(lineWidth: max(1.5, w * 0.06), lineCap: .round, lineJoin: .round))
                    .frame(width: w * 0.2, height: h * 0.1)
                    .offset(x: -w * 0.16, y: h * 0.05)
                HappyEye().stroke(.white, style: StrokeStyle(lineWidth: max(1.5, w * 0.06), lineCap: .round, lineJoin: .round))
                    .frame(width: w * 0.2, height: h * 0.1)
                    .offset(x: w * 0.16, y: h * 0.05)
            }
        }
    }
}

/// Chat avatar: blob on a lighter round ring (sidebar rows).
struct MascotAvatar: View {
    var blob: Color
    var ring: Color
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            Circle().fill(ring)
            MascotBlob(color: blob).frame(width: size * 0.78, height: size * 0.62).offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// A puffy cloud-like outline built from overlapping circles.
struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        let bumps: [(CGFloat, CGFloat, CGFloat)] = [ // center x, center y, radius (as fractions)
            (0.30, 0.40, 0.30), (0.52, 0.30, 0.32), (0.72, 0.42, 0.28),
            (0.25, 0.62, 0.26), (0.50, 0.62, 0.34), (0.76, 0.64, 0.24),
        ]
        for (x, y, r) in bumps {
            let radius = r * min(w, h * 1.3)
            path.addEllipse(in: CGRect(x: rect.minX + x * w - radius, y: rect.minY + y * h - radius * 0.85,
                                       width: radius * 2, height: radius * 1.7))
        }
        return path
    }
}

/// "^" shaped eye.
struct HappyEye: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.9))
        return path
    }
}

extension Color {
    func lighter(_ amount: Double) -> Color {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .gray
        return Color(.sRGB, red: min(1, ns.redComponent + amount), green: min(1, ns.greenComponent + amount),
                     blue: min(1, ns.blueComponent + amount), opacity: ns.alphaComponent)
    }
}
