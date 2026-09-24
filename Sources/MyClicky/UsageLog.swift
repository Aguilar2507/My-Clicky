import Foundation

/// Token counts from one API response, priced at Anthropic's list prices.
struct Usage {
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheWriteTokens: Int
    let cacheReadTokens: Int

    /// USD per million input / output tokens. Cache writes cost 1.25× input, cache reads 0.1×.
    /// Longer prefixes first ("claude-opus-5-5" before "claude-opus-5").
    private static let prices: [(prefix: String, input: Double, output: Double)] = [
        ("claude-haiku-4-5", 1, 5),
        ("claude-sonnet-5", 2, 10),
        ("claude-sonnet-4-6", 3, 15),
        ("claude-opus-5-5", 4, 20),
        ("claude-opus-5", 5, 25),
    ]

    var costUSD: Double {
        let price = Self.prices.first { model.hasPrefix($0.prefix) } ?? (prefix: "", input: 3, output: 15)
        let input = Double(inputTokens) + Double(cacheWriteTokens) * 1.25 + Double(cacheReadTokens) * 0.1
        return (input * price.input + Double(outputTokens) * price.output) / 1_000_000
    }
}

/// Running monthly API spend, kept in ~/Library/Application Support/MyClicky/usage.json.
/// Agent mode isn't counted: it runs on your Claude subscription, not the API key.
enum UsageLog {
    struct Month: Codable {
        var questions = 0
        var costUSD = 0.0

        var formattedCost: String { String(format: costUSD < 1 ? "$%.3f" : "$%.2f", costUSD) }
    }

    static var fileURL: URL { Config.directory.appendingPathComponent("usage.json") }

    static func record(_ usage: Usage) {
        var months = load()
        var month = months[currentMonth] ?? Month()
        month.questions += 1
        month.costUSD += usage.costUSD
        months[currentMonth] = month
        save(months)
    }

    static var thisMonth: Month { load()[currentMonth] ?? Month() }

    private static var currentMonth: String {
        let parts = Calendar.current.dateComponents([.year, .month], from: Date())
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    private static func load() -> [String: Month] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }
        return (try? JSONDecoder().decode([String: Month].self, from: data)) ?? [:]
    }

    private static func save(_ months: [String: Month]) {
        try? FileManager.default.createDirectory(at: Config.directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(months) {
            try? data.write(to: fileURL)
        }
    }
}
