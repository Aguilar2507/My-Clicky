import Foundation

/// UTC ISO-8601 dates with exact milliseconds ("2026-09-25T23:41:35.829Z").
/// Milliseconds are handled as integers so saving, loading and saving again gives identical text.
public enum ISODate {
    private static let plain = Date.ISO8601FormatStyle(timeZone: TimeZone(identifier: "UTC")!)

    public static func string(from date: Date) -> String {
        let totalMs = Int64((date.timeIntervalSince1970 * 1000).rounded())
        let seconds = totalMs >= 0 ? totalMs / 1000 : (totalMs - 999) / 1000
        let ms = totalMs - seconds * 1000
        let whole = Date(timeIntervalSince1970: TimeInterval(seconds)).formatted(plain) // "…T23:41:35Z"
        return String(whole.dropLast()) + String(format: ".%03lldZ", ms)
    }

    public static func date(from text: String) -> Date? {
        guard text.hasSuffix("Z") else { return try? Date(text, strategy: .iso8601) }
        var base = String(text.dropLast())
        var ms: Int64 = 0
        if let dot = base.lastIndex(of: ".") {
            let digits = String(base[base.index(after: dot)...].prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
            guard let value = Int64(digits) else { return nil }
            ms = value
            base = String(base[..<dot])
        }
        guard let whole = try? Date(base + "Z", strategy: plain) else { return nil }
        let seconds = Int64(whole.timeIntervalSince1970.rounded())
        return Date(timeIntervalSince1970: TimeInterval(seconds * 1000 + ms) / 1000)
    }
}
