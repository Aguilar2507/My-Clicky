import SwiftUI
import MyClickyCore

/// Visual tokens (spec 015): Apple's look. Every color follows the Mac's Light/Dark appearance and Increase Contrast,
/// the accent is the system accent, text uses the system label colors. HeyClicky's layout stays (specs/README.md →
/// Visual language); the logo, bot and avatars keep MyClicky's brand art (`Brand`, spec 013).
enum Theme {
    // Surfaces
    /// Grouped background behind cards (Settings pages, the tour footer).
    static let windowBackground = dynamic(light: 0xF5F5F7, dark: 0x1C1C1E)
    /// Main reading surface (home, conversations, welcome tour).
    static let contentBackground = dynamic(light: 0xFFFFFF, dark: 0x1E1E20)
    static let sidebarBackground = dynamic(light: 0xEFEFF2, dark: 0x252528)
    static let card = dynamic(light: 0xFFFFFF, dark: 0x2C2C2E)
    static let modal = dynamic(light: 0xFFFFFF, dark: 0x2C2C2E)
    static var cardBorder: Color { overlay(light: 0.09, dark: 0.1, contrast: 0.3) }
    static var hairline: Color { overlay(light: 0.08, dark: 0.09, contrast: 0.3) }
    static let selectedItem = overlayColor(light: 0.07, dark: 0.1)
    static let rowSelected = overlayColor(light: 0.06, dark: 0.09)
    static let keycap = overlayColor(light: 0.05, dark: 0.1)
    static var userBubble: Color { accent }
    /// Off tracks, empty meter bars, inactive dots.
    static let track = overlayColor(light: 0.12, dark: 0.18)
    static var trackBorder: Color { cardBorder }
    /// Secondary buttons and chips.
    static let controlDark = overlayColor(light: 0.06, dark: 0.11)
    static let controlHover = overlayColor(light: 0.11, dark: 0.17)
    static var controlDarkBorder: Color { overlay(light: 0.0, dark: 0.0, contrast: 0.3) }

    // Text (system label colors: black / gray / light gray in Light Mode)
    static let textPrimary = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)
    static let previewText = Color(nsColor: .secondaryLabelColor)
    static let sectionLabel = Color(nsColor: .secondaryLabelColor)
    static let icon = Color(nsColor: .secondaryLabelColor)

    // Accents (the accent you chose in System Settings)
    static var accent: Color { .accentColor }
    static var accentFill: Color { .accentColor }
    static var accentBorder: Color { .accentColor }
    static var unreadBlue: Color { .accentColor }
    static let green = Color(nsColor: .systemGreen)
    static let orange = Color(nsColor: .systemOrange)
    static let red = Color(nsColor: .systemRed)

    /// Plain surfaces: Apple's apps don't use blooms. Kept as views so screens can layer them.
    static var contentSurface: some View { contentBackground }
    static var sidebarSurface: some View { sidebarBackground }

    /// A color with a light and a dark value, resolved by the view's appearance.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(Color(hex: isDark ? dark : light))
        })
    }

    /// Black (Light Mode) or white (Dark Mode) at a low opacity: fills and lines that sit on any surface.
    static func overlayColor(light: Double, dark: Double) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark ? NSColor.white.withAlphaComponent(dark) : NSColor.black.withAlphaComponent(light)
        })
    }

    private static func overlay(light: Double, dark: Double, contrast: Double) -> Color {
        DisplayPrefs.shared.increaseContrast ? overlayColor(light: contrast, dark: contrast) : overlayColor(light: light, dark: dark)
    }

    // Type: `DesignSystem/Typography.swift` (`.textStyle(_:)`, spec 014).

    // Shape
    static let cardRadius: CGFloat = Radius.lg
    static let rowPadding = EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)

    /// Readable column widths for big windows and full screen (spec 017).
    enum Layout {
        static let settingsColumn: CGFloat = 720
        static let conversationColumn: CGFloat = 820
    }

    /// Continuous-corner radii.
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 22
    }

    /// 4-pt spacing grid.
    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    /// Bigger surfaces read as thicker: deeper, softer shadows (skill §12).
    enum Shadow {
        case small, medium, large

        var radius: CGFloat { switch self { case .small: 3; case .medium: 12; case .large: 30 } }
        var y: CGFloat { switch self { case .small: 1; case .medium: 5; case .large: 12 } }
        var opacity: Double { switch self { case .small: 0.1; case .medium: 0.14; case .large: 0.22 } }
    }

}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

extension Color {
    func lighter(_ amount: Double) -> Color {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .gray
        return Color(.sRGB, red: min(1, ns.redComponent + amount), green: min(1, ns.greenComponent + amount),
                     blue: min(1, ns.blueComponent + amount), opacity: ns.alphaComponent)
    }
}

/// Local view state. SwiftUI's `@State` is a compiler macro on the macOS 27 SDK and its plugin isn't part of the
/// Command Line Tools, so views keep local state in `@StateObject private var x = Box(value)` instead.
final class Box<Value>: ObservableObject {
    @Published var value: Value
    init(_ value: Value) { self.value = value }
}

extension View {
    func shadowToken(_ shadow: Theme.Shadow, color: Color = .black) -> some View {
        self.shadow(color: color.opacity(shadow.opacity), radius: shadow.radius, y: shadow.y)
    }
}
