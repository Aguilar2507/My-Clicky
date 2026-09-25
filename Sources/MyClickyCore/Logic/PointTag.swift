import Foundation

/// Extracts the optional `[POINT:x,y:label:screen N]` tag from a reply.
public struct PointTag: Equatable {
    public let x: Double
    public let y: Double
    public let label: String
    public let screen: Int

    public static let regex = try! NSRegularExpression(
        pattern: #"\[POINT:\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*(?::\s*([^\]]*?))?\s*(?::\s*screen\s*(\d+))?\s*\]"#,
        options: [.caseInsensitive])

    /// Returns the spoken text (tag removed) and the tag, if any.
    public init(x: Double, y: Double, label: String, screen: Int) {
        self.x = x
        self.y = y
        self.label = label
        self.screen = screen
    }

    public static func parse(_ reply: String) -> (spoken: String, point: PointTag?) {
        let range = NSRange(reply.startIndex..., in: reply)
        guard let match = regex.firstMatch(in: reply, range: range) else { return (reply, nil) }
        func group(_ i: Int) -> String? {
            Range(match.range(at: i), in: reply).map { String(reply[$0]) }
        }
        let spoken = regex.stringByReplacingMatches(in: reply, range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let point = PointTag(
            x: Double(group(1) ?? "") ?? 0,
            y: Double(group(2) ?? "") ?? 0,
            label: group(3)?.trimmingCharacters(in: .whitespaces) ?? "",
            screen: Int(group(4) ?? "") ?? 1)
        return (spoken, point)
    }
}
