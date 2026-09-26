import Foundation

/// One calendar month of API spend, in `usage.json` as `{ "YYYY-MM": UsageMonth }`.
public struct UsageMonth: Codable, Equatable, Sendable {
    public var questions = 0
    public var costUSD = 0.0
    // 011 spending: splits and per-day totals (for the 14-day pace)
    public var byModel: [String: Double] = [:]
    public var byKind: [String: Double] = [:]
    public var daily: [String: Double] = [:]

    public init(questions: Int = 0, costUSD: Double = 0) {
        self.questions = questions
        self.costUSD = costUSD
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        questions = c.value(.questions, default: 0)
        costUSD = c.value(.costUSD, default: 0)
        byModel = c.value(.byModel, default: [:])
        byKind = c.value(.byKind, default: [:])
        daily = c.value(.daily, default: [:])
    }

    /// What a paid request was for.
    public enum Kind: String, CaseIterable, Sendable { case answer, memory, naming, interview }

    public static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    public var formattedCost: String { UsageMonth.format(costUSD) }

    public static func format(_ usd: Double) -> String {
        String(format: usd < 1 ? "$%.3f" : "$%.2f", usd)
    }

    public static func key(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }
}
