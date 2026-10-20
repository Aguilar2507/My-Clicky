import Foundation

/// Small facts added to each Talk question (in the user turn, so the cached system prompt stays the same).
public enum TalkContext {
    /// "Local time: Tuesday, 20 October 2026, 15:47 (America/Costa_Rica, UTC-6)." Without it the model read the clock in
    /// the screenshot and guessed other cities' offsets ("16 hours and 46 minutes ahead").
    public static func now(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE, d MMMM yyyy, HH:mm"
        let seconds = timeZone.secondsFromGMT(for: date)
        let hours = seconds / 3600, minutes = abs(seconds % 3600) / 60
        let offset = "UTC" + (seconds >= 0 ? "+" : "-") + "\(abs(hours))" + (minutes > 0 ? String(format: ":%02d", minutes) : "")
        return "Local time: \(formatter.string(from: date)) (\(timeZone.identifier), \(offset))."
    }
}
