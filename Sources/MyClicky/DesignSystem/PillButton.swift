import SwiftUI

/// Glossy pill buttons: `.primary` (lavender, "Connect"), `.secondary` (white, "Change"), `.dark` ("Disconnect").
struct PillButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, dark }
    var kind: Kind = .secondary
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 17, weight: .semibold))
            .foregroundStyle(kind == .dark ? Color.white : Color.black.opacity(0.85))
            .padding(.horizontal, compact ? 14 : 22)
            .padding(.vertical, compact ? 6 : 10)
            .background {
                BorderedCapsule(fill: background, border: borderColor,
                                highlight: .white.opacity(kind == .dark ? 0.12 : 0.55))
            }
            .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(Capsule(style: .continuous))
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .primary: AnyShapeStyle(Theme.lavenderGradient)
        case .secondary: AnyShapeStyle(LinearGradient(colors: [.white, Color(hex: 0xDADADF)], startPoint: .top, endPoint: .bottom))
        case .dark: AnyShapeStyle(Color(hex: 0x2F2F33))
        }
    }

    private var borderColor: Color {
        switch kind {
        case .primary: Color(hex: 0x5C74D6)
        case .secondary: Color(hex: 0xBDBDC4)
        case .dark: Color(hex: 0x4A4A50)
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
            .foregroundStyle(.black.opacity(0.8))
            .frame(width: 40, height: 40)
            .background(ZStack { Circle().fill(Color(hex: 0xBDBDC4)); Circle().fill(.white).padding(1.5) })
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
