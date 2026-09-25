import SwiftUI

/// Visual tokens taken from the HeyClicky reference screenshots (specs/README.md → Visual language).
enum Theme {
    // Surfaces
    static let windowBackground = Color(hex: 0x1E1E1E)
    static let sidebarBackground = Color(hex: 0x1B1B1B)
    static let card = Color(hex: 0x2A2A2A)
    static let cardBorder = Color(hex: 0x3A3A3A)
    static let selectedItem = Color(hex: 0x333333)
    static let keycap = Color(hex: 0x333333)
    static let userBubble = Color(hex: 0x2E3550)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0x9A9A9F)
    static let textTertiary = Color(hex: 0x6E6E73)
    static let sectionLabel = Color(hex: 0x8E8E93)
    static let icon = Color(hex: 0xC7C7CC)

    // Accents
    static let lavenderTop = Color(hex: 0xC9D6FF)
    static let lavenderBottom = Color(hex: 0x7D97F2)
    static let lavender = Color(hex: 0xA3B6F8)
    static let unreadBlue = Color(hex: 0x3B82F6)
    static let green = Color(hex: 0x34C759)
    static let orange = Color(hex: 0xF5A623)
    static let red = Color(hex: 0xFF5F57)

    static var lavenderGradient: LinearGradient {
        LinearGradient(colors: [lavenderTop, lavenderBottom], startPoint: .top, endPoint: .bottom)
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

/// Local view state. SwiftUI's `@State` is a compiler macro on the macOS 27 SDK and its plugin isn't part of the
/// Command Line Tools, so views keep local state in `@StateObject private var x = Box(value)` instead.
final class Box<Value>: ObservableObject {
    @Published var value: Value
    init(_ value: Value) { self.value = value }
}
