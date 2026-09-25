import Foundation

/// Token counts from one API response, priced at Anthropic's list prices.
public struct TokenUsage: Equatable, Sendable {
    public var model: String
    public var inputTokens: Int
    public var outputTokens: Int
    public var cacheWriteTokens: Int
    public var cacheReadTokens: Int

    public init(model: String, inputTokens: Int = 0, outputTokens: Int = 0,
                cacheWriteTokens: Int = 0, cacheReadTokens: Int = 0) {
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheWriteTokens = cacheWriteTokens
        self.cacheReadTokens = cacheReadTokens
    }

    public var costUSD: Double { Pricing.cost(of: self) }
}

public enum Pricing {
    /// USD per million input / output tokens. Cache writes cost 1.25× input, cache reads 0.1×.
    /// Longer prefixes first ("claude-opus-5-5" before "claude-opus-5").
    public static let table: [(prefix: String, input: Double, output: Double)] = [
        ("claude-haiku-4-5", 1, 5),
        ("claude-sonnet-5", 2, 10),
        ("claude-sonnet-4-6", 3, 15),
        ("claude-opus-5-5", 4, 20),
        ("claude-opus-5", 5, 25),
    ]

    public static func prices(for model: String) -> (input: Double, output: Double) {
        let row = table.first { model.hasPrefix($0.prefix) }
        return (row?.input ?? 3, row?.output ?? 15)
    }

    public static func cost(of usage: TokenUsage) -> Double {
        let price = prices(for: usage.model)
        let input = Double(usage.inputTokens) + Double(usage.cacheWriteTokens) * 1.25 + Double(usage.cacheReadTokens) * 0.1
        return (input * price.input + Double(usage.outputTokens) * price.output) / 1_000_000
    }
}
