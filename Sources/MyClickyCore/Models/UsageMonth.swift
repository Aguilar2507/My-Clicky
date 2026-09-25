import Foundation

/// One calendar month of API spend, in `usage.json` as `{ "YYYY-MM": UsageMonth }`.
public struct UsageMonth: Codable, Equatable, Sendable {
    public var questions = 0
    public var costUSD = 0.0

    public init(questions: Int = 0, costUSD: Double = 0) {
        self.questions = questions
        self.costUSD = costUSD
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        questions = c.value(.questions, default: 0)
        costUSD = c.value(.costUSD, default: 0)
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
