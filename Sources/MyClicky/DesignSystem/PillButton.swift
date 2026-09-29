import SwiftUI

/// Glossy pill buttons: `.primary` (blue-violet glass, "Connect"), `.secondary` (ice white, "Change"), `.dark` ("Disconnect").
struct PillButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, dark }
    var kind: Kind = .secondary
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 17, weight: .semibold))
            .foregroundStyle(kind == .secondary ? Brand.midnight : Theme.textPrimary)
            .padding(.horizontal, compact ? 14 : 22)
            .padding(.vertical, compact ? 6 : 10)
            .background {
                BorderedCapsule(fill: background, border: borderColor,
                                highlight: .white.opacity(kind == .dark ? 0.1 : kind == .primary ? 0.35 : 0.55))
            }
            .shadow(color: kind == .primary ? Brand.electricBlue.opacity(0.45) : .black.opacity(0.35), radius: kind == .primary ? 8 : 3, y: 2)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(Capsule(style: .continuous))
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .primary: AnyShapeStyle(Theme.accentGradient)
        case .secondary: AnyShapeStyle(LinearGradient(colors: [Brand.iceWhite, Color(hex: 0xD3DCF4)], startPoint: .top, endPoint: .bottom))
        case .dark: AnyShapeStyle(Theme.controlDark)
        }
    }

    private var borderColor: Color {
        switch kind {
        case .primary: Theme.accentBorder
        case .secondary: Color(hex: 0xAAB5D6)
        case .dark: Theme.controlDarkBorder
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

/// Round white "✕" button (remove integration).
struct CircleIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Brand.midnight)
            .frame(width: 40, height: 40)
            .background(ZStack { Circle().fill(Color(hex: 0xAAB5D6)); Circle().fill(Brand.iceWhite).padding(1.5) })
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Key cap label ("^ control", "fn").
struct KeyCap: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .monospaced))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.keycap, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .fixedSize()
    }
}
