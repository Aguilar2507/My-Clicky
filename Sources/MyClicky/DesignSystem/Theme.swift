import SwiftUI

/// Visual tokens: HeyClicky's layout (specs/README.md → Visual language) in MyClicky's own palette (spec 013,
/// `references/myclicky/visual-system.png`): near-black navy, glass panels with thin borders, blue-violet accents.
enum Theme {
    // Surfaces
    static let windowBackground = Brand.midnight
    static let sidebarBackground = Color(hex: 0x0A0F22)
    static let card = Brand.deepNavy
    static let cardBorder = Color(hex: 0x232D4D)
    static let selectedItem = Color(hex: 0x1A2342)
    static let rowSelected = Color(hex: 0x151D38)
    static let keycap = Color(hex: 0x1A2342)
    static let userBubble = Color(hex: 0x1F2C66)
    static let modal = Color(hex: 0x0F1630)
    static let hairline = Color(hex: 0x1C2442)
    /// Off toggles, empty meter bars, inactive dots.
    static let track = Color(hex: 0x28325A)
    static let trackBorder = Color(hex: 0x36416B)
    static let controlDark = Color(hex: 0x1B2442)
    static let controlDarkBorder = Color(hex: 0x2E3A63)

    // Text
    static let textPrimary = Brand.iceWhite
    static let textSecondary = Color(hex: 0x98A2C0)
    static let textTertiary = Color(hex: 0x646E8E)
    static let previewText = Color(hex: 0xA9B2CC)
    static let sectionLabel = Color(hex: 0x8A94B4)
    static let icon = Color(hex: 0xC3CAE2)

    // Accents
    static let accentTop = Color(hex: 0x5AB0FF)
    static let accentBottom = Color(hex: 0x6A4DFF)
    static let accent = Color(hex: 0x7F9CFF)
    static let accentBorder = Color(hex: 0xA9C2FF)
    static let unreadBlue = Brand.electricBlue
    static let green = Color(hex: 0x34C759)
    static let orange = Color(hex: 0xF5A623)
    static let red = Color(hex: 0xFF5F57)

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accentTop, Brand.electricBlue, accentBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Near-black navy with a soft violet/blue bloom (visual system: BACKGROUND).
    static var bloomBackground: some View {
        ZStack {
            windowBackground
            RadialGradient(colors: [Brand.violet.opacity(0.16), .clear], center: UnitPoint(x: 0.75, y: 0.1),
                           startRadius: 0, endRadius: 520)
            RadialGradient(colors: [Brand.electricBlue.opacity(0.1), .clear], center: UnitPoint(x: 0.2, y: 0.95),
                           startRadius: 0, endRadius: 460)
        }
    }

    // Type
    static let pageTitle = Font.system(size: 28, weight: .bold)
    static let pageSubtitle = Font.system(size: 17)
    static let rowTitle = Font.system(size: 17, weight: .semibold)
    static let rowSubtitle = Font.system(size: 15)
    static let sectionFont = Font.system(size: 12, weight: .semibold)

    // Shape
    static let cardRadius: CGFloat = 16
    static let rowPadding = EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
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
