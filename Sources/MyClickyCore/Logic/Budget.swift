import Foundation

/// The monthly budget (spec 011 US2): warn once at 80%, pause paid requests at 100% until next month or a top-up.
public enum BudgetPolicy {
    public enum Decision: Equatable, Sendable {
        case allow
        case warn(percent: Int)
        case block(resetsOn: Date)
    }

    public static let warnFraction = 0.8
    public static let topUpStep = 2.0

    /// - budget 0 means "no budget". `warnedMonth` is the month ("YYYY-MM") already warned.
    public static func decision(spent: Double, budget: Double, topUp: Double, warnedMonth: String, month: String,
                                now: Date = Date(), calendar: Calendar = .current) -> Decision {
        guard budget > 0 else { return .allow }
        let limit = budget + topUp
        if spent + 1e-9 >= limit {
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            return .block(resetsOn: calendar.date(byAdding: .month, value: 1, to: start) ?? now)
        }
        if spent + 1e-9 >= limit * warnFraction && warnedMonth != month { // tolerance: 7 × 0.8 = 5.6000000000000005
            return .warn(percent: Int((spent / limit * 100).rounded(.down)))
        }
        return .allow
    }

    /// 0…1 for the spend ring (0 when there's no budget).
    public static func fraction(spent: Double, budget: Double, topUp: Double) -> Double {
        guard budget > 0 else { return 0 }
        return min(1, spent / (budget + topUp))
    }
}

/// "How long will my credit last?" (spec 011 US3).
public struct CreditProjection: Equatable, Sendable {
    public let remaining: Double
    /// Average daily spend over the last 14 days (or since the credit was bought, if more recent).
    public let pacePerDay: Double
    /// nil when there's no recent spending.
    public let runsOutOn: Date?

    public init(credit: Double, since: Date, daily: [String: Double], now: Date = Date(), calendar: Calendar = .current) {
        let sinceKey = UsageMonth.dayKey(for: since, calendar: calendar)
        let spentSince = daily.filter { $0.key >= sinceKey }.values.reduce(0, +)
        remaining = max(0, credit - spentSince)
        let today = calendar.startOfDay(for: now)
        let windowStart = max(calendar.date(byAdding: .day, value: -13, to: today) ?? today, calendar.startOfDay(for: since))
        let days = max(1, (calendar.dateComponents([.day], from: windowStart, to: today).day ?? 0) + 1)
        let startKey = UsageMonth.dayKey(for: windowStart, calendar: calendar)
        let recent = daily.filter { $0.key >= startKey }.values.reduce(0, +)
        pacePerDay = recent / Double(days)
        if pacePerDay > 0 {
            runsOutOn = calendar.date(byAdding: .day, value: Int((remaining / pacePerDay).rounded(.down)), to: today)
        } else {
            runsOutOn = nil
        }
    }
}
