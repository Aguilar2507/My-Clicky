import SwiftUI
import MyClickyCore

/// Apple-style capsule buttons (spec 015). Every kind reacts to the pointer:
/// - `.primary`: accent fill, white text; brightens on hover ("Save", "Continue").
/// - `.secondary` (and `.dark`): light gray fill; darkens on hover ("Change", "Cancel" in forms).
/// - `.destructive`: neutral with red text; fills red on hover ("Delete", "Disconnect", "Deny", "Stop").
/// - `.safe`: neutral; fills green on hover (the "keep"/"yes, go on" side: "Cancel" next to Delete, "Allow").
struct PillButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, dark, destructive, safe }
    var kind: Kind = .secondary
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        PillBody(configuration: configuration, style: self)
    }

    private struct PillBody: View {
        let configuration: Configuration
        let style: PillButtonStyle
        @Environment(\.isEnabled) private var isEnabled
        @StateObject private var hovering = Box(false)

        var body: some View {
            let hover = hovering.value && isEnabled
            configuration.label
                .textStyle(style.compact ? TypeStyle.subheadline.weight(.semibold) : .headline)
                .foregroundStyle(foreground(hover: hover))
                .padding(.horizontal, style.compact ? 14 : 20)
                .padding(.vertical, style.compact ? 6 : 9)
                .background(fill(hover: hover), in: Capsule(style: .continuous))
                .contentShape(Capsule(style: .continuous))
                .pressEffect(configuration.isPressed, brightness: style.kind == .primary ? -0.08 : -0.04)
                .opacity(isEnabled ? 1 : 0.45)
                .onHover { inside in withAnimation(Motion.quick) { hovering.value = inside } }
        }

        private func fill(hover: Bool) -> Color {
            switch style.kind {
            case .primary: hover ? Theme.accent.opacity(0.85) : Theme.accent
            case .secondary, .dark: hover ? Theme.controlHover : Theme.controlDark
            case .destructive: hover ? Theme.red : Theme.controlDark
            case .safe: hover ? Theme.green : Theme.controlDark
            }
        }

        private func foreground(hover: Bool) -> Color {
            switch style.kind {
            case .primary: .white
            case .secondary, .dark: Theme.textPrimary
            case .destructive: hover ? .white : Theme.red
            case .safe: hover ? .white : Theme.textPrimary
            }
        }
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle { PillButtonStyle() }
    static func pill(_ kind: PillButtonStyle.Kind, compact: Bool = false) -> PillButtonStyle {
        PillButtonStyle(kind: kind, compact: compact)
    }
}

/// A capsule with a border and a glossy top highlight. The border is a second fill underneath instead of a stroke:
/// on macOS 27 stroked capsules render small notches at their rounded ends.
struct BorderedCapsule: View {
    var fill: AnyShapeStyle
    var border: Color
    var borderWidth: CGFloat = 1.5
    var highlight: Color = .white.opacity(0.5)

    var body: some View {
        ZStack {
            Capsule(style: .continuous).fill(border)
            Capsule(style: .continuous).fill(fill).padding(borderWidth)
            Capsule(style: .continuous)
                .fill(LinearGradient(colors: [highlight, .clear], startPoint: .top, endPoint: .center))
                .padding(borderWidth + 1.5)
        }
        .allowsHitTesting(false)
    }
}

/// Round "✕" button (remove an integration): gray at rest, red on hover (spec 015).
struct CircleIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        CircleBody(configuration: configuration)
    }

    private struct CircleBody: View {
        let configuration: Configuration
        @StateObject private var hovering = Box(false)

        var body: some View {
            configuration.label
                .font(.icon(Theme.IconSize.small, .bold))
                .foregroundStyle(hovering.value ? .white : Theme.textSecondary)
                .frame(width: 34, height: 34)
                .background(hovering.value ? Theme.red : Theme.controlDark, in: Circle())
                .contentShape(Circle())
                .pressEffect(configuration.isPressed)
                .onHover { inside in withAnimation(Motion.quick) { hovering.value = inside } }
        }
    }
}

/// Key cap label ("^ control", "fn").
struct KeyCap: View {
    let text: String
    var body: some View {
        Text(text)
            .textStyle(TypeStyle.subheadline.weight(.medium), design: .monospaced)
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.keycap, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 1))
            .fixedSize()
    }
}
