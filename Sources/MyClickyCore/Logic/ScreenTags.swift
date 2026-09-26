import Foundation

/// Something MyClicky shows on screen: a point to fly to, or a drawing (spec 006, contracts/screen-tags.md).
/// Coordinates are screenshot pixels (origin top-left); `screen` is 1-based.
public enum ScreenMark: Equatable, Sendable {
    case point(x: Double, y: Double, label: String, screen: Int)
    case circle(x: Double, y: Double, r: Double, screen: Int)
    case arrow(x1: Double, y1: Double, x2: Double, y2: Double, screen: Int)
    case box(x: Double, y: Double, w: Double, h: Double, screen: Int)
    case underline(x1: Double, y: Double, x2: Double, screen: Int)

    public var screen: Int {
        switch self {
        case .point(_, _, _, let s), .circle(_, _, _, let s), .arrow(_, _, _, _, let s), .box(_, _, _, _, let s),
             .underline(_, _, _, let s): s
        }
    }
}

/// Parses `[POINT:…]` and `[DRAW:…]` tags from replies and hides them from spoken/shown text.
public enum ScreenTags {
    public static let maxDrawings = 3

    private static let pointRegex = try! NSRegularExpression(
        pattern: #"\[POINT:\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*(?::\s*([^\]]*?))?\s*(?::\s*screen\s*(\d+))?\s*\]"#,
        options: [.caseInsensitive])
    private static let drawRegex = try! NSRegularExpression(
        pattern: #"\[DRAW:\s*(circle|arrow|box|underline)\s*:\s*([-\d.,\s]+?)\s*(?::\s*screen\s*(\d+))?\s*\]"#,
        options: [.caseInsensitive])
    private static let anyTag = try! NSRegularExpression(pattern: #"\[(?:POINT|DRAW):[^\]]*\]"#, options: [.caseInsensitive])

    public struct Parsed: Equatable, Sendable {
        public var text: String
        public var point: ScreenMark?
        public var drawings: [ScreenMark]
    }

    public static func parse(_ reply: String) -> Parsed {
        let range = NSRange(reply.startIndex..., in: reply)
        func group(_ match: NSTextCheckingResult, _ i: Int) -> String? {
            Range(match.range(at: i), in: reply).map { String(reply[$0]) }
        }
        var point: ScreenMark?
        if let m = pointRegex.firstMatch(in: reply, range: range),
           let x = group(m, 1).flatMap(Double.init), let y = group(m, 2).flatMap(Double.init) {
            point = .point(x: x, y: y, label: group(m, 3)?.trimmingCharacters(in: .whitespaces) ?? "",
                           screen: group(m, 4).flatMap(Int.init) ?? 1)
        }
        var drawings: [ScreenMark] = []
        for m in drawRegex.matches(in: reply, range: range) where drawings.count < maxDrawings {
            guard let kind = group(m, 1)?.lowercased(), let raw = group(m, 2) else { continue }
            let n = raw.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            let screen = group(m, 3).flatMap(Int.init) ?? 1
            switch (kind, n.count) {
            case ("circle", 3): drawings.append(.circle(x: n[0], y: n[1], r: n[2], screen: screen))
            case ("arrow", 4): drawings.append(.arrow(x1: n[0], y1: n[1], x2: n[2], y2: n[3], screen: screen))
            case ("box", 4): drawings.append(.box(x: n[0], y: n[1], w: n[2], h: n[3], screen: screen))
            case ("underline", 3): drawings.append(.underline(x1: n[0], y: n[1], x2: n[2], screen: screen))
            default: continue // wrong number of values: dropped
            }
        }
        return Parsed(text: stripTags(reply), point: point, drawings: drawings)
    }

    /// Text safe to show or speak while a reply is still streaming: complete tags removed, and a trailing
    /// fragment that could still become a tag ("[POI", "[DRAW:circle:12") hidden.
    public static func visibleText(partial: String) -> String {
        var text = stripTags(partial, trim: false)
        if let open = text.lastIndex(of: "["), !text[open...].contains("]") {
            let tail = text[text.index(after: open)...].uppercased()
            let couldBeTag = ["POINT:", "DRAW:"].contains { $0.hasPrefix(tail) || tail.hasPrefix($0) }
            if couldBeTag { text = String(text[..<open]) }
        }
        return text
    }

    static func stripTags(_ text: String, trim: Bool = true) -> String {
        let stripped = anyTag.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        return trim ? stripped.trimmingCharacters(in: .whitespacesAndNewlines) : stripped
    }
}
