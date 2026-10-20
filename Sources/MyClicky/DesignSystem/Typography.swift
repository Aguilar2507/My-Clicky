import SwiftUI
import AppKit
import MyClickyCore

/// Text styles from the shared type scale (spec 014 US4, `MyClickyCore/Design/TypeScale.swift`).
extension TypeStyle {
    var font: Font { .system(size: size, weight: swiftUIWeight) }
    var nsFont: NSFont { .systemFont(ofSize: size, weight: nsWeight) }

    func font(design: Font.Design) -> Font { .system(size: size, weight: swiftUIWeight, design: design) }

    var swiftUIWeight: Font.Weight {
        switch weight {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }

    var nsWeight: NSFont.Weight {
        switch weight {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }
}

private struct TextStyleModifier: ViewModifier {
    let style: TypeStyle
    var design: Font.Design = .default

    func body(content: Content) -> some View {
        content
            .font(style.font(design: design))
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
            .textCase(style.uppercase ? .uppercase : nil)
    }
}

extension View {
    /// Font, tracking, leading and case from the type scale: `.textStyle(.headline)`.
    func textStyle(_ style: TypeStyle, design: Font.Design = .default) -> some View {
        modifier(TextStyleModifier(style: style, design: design))
    }
}

extension Theme {
    /// SF Symbol sizes; icons take the weight of the text beside them.
    enum IconSize {
        static let small: CGFloat = 13
        static let medium: CGFloat = 15
        static let regular: CGFloat = 17
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let hero: CGFloat = 42
    }
}

extension Font {
    /// An SF Symbol at a token size: `.font(.icon(Theme.IconSize.large, .semibold))`.
    static func icon(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight) }
}
