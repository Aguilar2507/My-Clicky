import Foundation

/// One type scale for the whole app (spec 014, apple-design skill §15): each style is a size, weight, tracking and
/// line spacing chosen as a set. SF already applies optical sizes; tracking here is the extra, size-specific
/// adjustment on top: tighter as text grows, wider for small uppercase labels.
public struct TypeStyle: Equatable, Sendable {
    public enum Weight: String, Sendable { case regular, medium, semibold, bold }

    public let name: String
    public let size: Double
    public let weight: Weight
    public let tracking: Double
    public let lineSpacing: Double
    public let uppercase: Bool

    init(_ name: String, _ size: Double, _ weight: Weight, tracking: Double, lineSpacing: Double, uppercase: Bool = false) {
        self.name = name
        self.size = size
        self.weight = weight
        self.tracking = tracking
        self.lineSpacing = lineSpacing
        self.uppercase = uppercase
    }

    public static let display = TypeStyle("display", 34, .bold, tracking: -0.6, lineSpacing: 0)
    public static let largeTitle = TypeStyle("largeTitle", 28, .bold, tracking: -0.5, lineSpacing: 0)
    public static let title1 = TypeStyle("title1", 26, .bold, tracking: -0.5, lineSpacing: 0)
    public static let title2 = TypeStyle("title2", 22, .semibold, tracking: -0.3, lineSpacing: 0)
    public static let title3 = TypeStyle("title3", 20, .semibold, tracking: -0.3, lineSpacing: 0)
    public static let headline = TypeStyle("headline", 17, .semibold, tracking: -0.1, lineSpacing: 1)
    public static let body = TypeStyle("body", 17, .regular, tracking: -0.1, lineSpacing: 2)
    public static let callout = TypeStyle("callout", 15, .regular, tracking: 0, lineSpacing: 2)
    public static let subheadline = TypeStyle("subheadline", 14, .regular, tracking: 0, lineSpacing: 1)
    public static let footnote = TypeStyle("footnote", 13, .regular, tracking: 0, lineSpacing: 1)
    public static let caption = TypeStyle("caption", 12, .regular, tracking: 0, lineSpacing: 1)
    public static let caption2 = TypeStyle("caption2", 11, .regular, tracking: 0.1, lineSpacing: 0)
    public static let label = TypeStyle("label", 12, .semibold, tracking: 1.2, lineSpacing: 0, uppercase: true)

    public static let all = [display, largeTitle, title1, title2, title3, headline, body, callout, subheadline,
                             footnote, caption, caption2, label]

    /// Same style, different weight (emphasis through weight, not size).
    public func weight(_ weight: Weight) -> TypeStyle {
        TypeStyle(name, size, weight, tracking: tracking, lineSpacing: lineSpacing, uppercase: uppercase)
    }
}
