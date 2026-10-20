import SwiftUI

/// Three softly pulsing dots shown while an agent works.
struct ActivityDots: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 15)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle().fill(Theme.accent)
                        .frame(width: 5, height: 5)
                        .opacity(0.35 + 0.65 * max(0, sin(t * 4 - Double(i) * 0.7)))
                }
            }
        }
    }
}

/// The MyClicky cursor: a glowing, rounded triangle pointing up-left like a mouse arrow (spec 006).
struct CompanionTriangle: View {
    let color: Color
    var body: some View {
        TriangleShape()
            .fill(color)
            .shadow(color: color.opacity(0.9), radius: 6)
            .rotationEffect(.degrees(10))
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.1))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY - rect.height * 0.1))
        p.closeSubpath()
        return p.strokedPath(StrokeStyle(lineWidth: rect.width * 0.12, lineJoin: .round)).union(p)
    }
}
