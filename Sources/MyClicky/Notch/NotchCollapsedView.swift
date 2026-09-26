import SwiftUI

/// Collapsed notch contents (ref 01): unread badge on the left wing, agent activity / docked companion on the right.
struct NotchCollapsedView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                if model.unreadCount > 0 { UnreadBadge(count: model.unreadCount) }
            }
            .frame(width: 88)
            Spacer(minLength: 0)
            ZStack {
                if model.isAgentRunning {
                    ActivityDots()
                } else if let docked = model.dockedCompanionColor {
                    CompanionTriangle(color: docked).frame(width: 20, height: 20)
                }
            }
            .frame(width: 88)
        }
        .padding(.top, 2)
    }
}

/// Glossy lavender badge with a white outline and a dark number ("9+" above 9).
struct UnreadBadge: View {
    let count: Int
    var body: some View {
        ZStack {
            Circle().fill(.white)
            Circle().fill(Theme.lavenderGradient).padding(2)
            Circle().fill(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .center)).padding(3)
            Text(count > 9 ? "9+" : "\(count)")
                .font(.system(size: count > 9 ? 9 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x1C2A5E))
        }
        .frame(width: 22, height: 22)
        .shadow(color: Theme.lavender.opacity(0.6), radius: 3)
    }
}

/// Three softly pulsing dots shown while an agent works.
struct ActivityDots: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 15)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle().fill(Theme.lavender)
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
