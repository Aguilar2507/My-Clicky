import Foundation

/// Sidebar times (ref 02): "12:29 PM" today, the weekday within the last week, otherwise "Sep 3".
public enum RelativeTime {
    public static func format(_ date: Date, now: Date = Date(), calendar: Calendar = .current,
                              locale: Locale = .current) -> String {
        var calendar = calendar
        calendar.locale = locale
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar,
                                                   timeZone: calendar.timeZone))
        }
        let startOfToday = calendar.startOfDay(for: now)
        if let weekAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday), date >= weekAgo, date < now {
            return date.formatted(Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).weekday(.wide))
        }
        return date.formatted(Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .month(.abbreviated).day())
    }
}

/// Greeting on the empty screen (ref 02): "Evening, Jose." + the push-to-talk hint.
public enum Greeting {
    public static func salutation(hour: Int) -> String {
        switch hour {
        case 5..<12: "Morning"
        case 12..<18: "Afternoon"
        default: "Evening"
        }
    }

    public static func title(name: String, hour: Int) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "\(salutation(hour: hour))." : "\(salutation(hour: hour)), \(trimmed)."
    }

    public static func hint(for pushToTalk: ShortcutBinding) -> String {
        let keys = KeyCapLabels.holdHint(for: pushToTalk.chord)
        switch pushToTalk.gesture {
        case .hold: return "Hold \(keys) and tell me what to take off your plate."
        case .doubleTap: return "Double-tap \(keys) and tell me what to take off your plate."
        case .press: return "Press \(KeyCapLabels.caps(for: pushToTalk.chord, gesture: .press).joined(separator: " ")) and tell me what to take off your plate."
        }
    }
}
