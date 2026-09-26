import Foundation

/// Running monthly API spend in `usage.json` (same format as v0.1's UsageLog).
/// Agent runs aren't recorded here: they use the Claude subscription, not the API key.
public final class UsageStore: @unchecked Sendable {
    public let paths: AppPaths
    private let lock = NSLock()

    public init(paths: AppPaths = .standard) { self.paths = paths }

    public func record(_ usage: TokenUsage, countsAsQuestion: Bool = true, now: Date = Date()) {
        record(usage, kind: countsAsQuestion ? .answer : .memory, countsAsQuestion: countsAsQuestion, now: now)
    }

    /// Records a paid request's cost by model, kind and day (spec 011).
    public func record(_ usage: TokenUsage, kind: UsageMonth.Kind, countsAsQuestion: Bool? = nil, now: Date = Date()) {
        lock.lock(); defer { lock.unlock() }
        var months = load()
        let key = UsageMonth.key(for: now)
        var month = months[key] ?? UsageMonth()
        let cost = usage.costUSD
        if countsAsQuestion ?? (kind == .answer) { month.questions += 1 }
        month.costUSD += cost
        month.byModel[usage.model, default: 0] += cost
        month.byKind[kind.rawValue, default: 0] += cost
        month.daily[UsageMonth.dayKey(for: now), default: 0] += cost
        months[key] = month
        try? JSONFile.write(months, to: paths.usage)
    }

    /// The last `count` months, oldest first (missing months are zero).
    public func history(months count: Int, until date: Date = Date(), calendar: Calendar = .current) -> [(key: String, month: UsageMonth)] {
        lock.lock(); defer { lock.unlock() }
        let all = load()
        return (0..<count).reversed().compactMap { back in
            guard let d = calendar.date(byAdding: .month, value: -back, to: date) else { return nil }
            let key = UsageMonth.key(for: d, calendar: calendar)
            return (key, all[key] ?? UsageMonth())
        }
    }

    /// Spend per day (all months), for pace and credit projections.
    public func dailySpend() -> [String: Double] {
        lock.lock(); defer { lock.unlock() }
        return load().values.reduce(into: [:]) { result, month in month.daily.forEach { result[$0.key, default: 0] += $0.value } }
    }

    public func month(containing date: Date = Date()) -> UsageMonth {
        lock.lock(); defer { lock.unlock() }
        return load()[UsageMonth.key(for: date)] ?? UsageMonth()
    }

    public func allMonths() -> [String: UsageMonth] {
        lock.lock(); defer { lock.unlock() }
        return load()
    }

    private func load() -> [String: UsageMonth] {
        guard let data = JSONFile.read(paths.usage) else { return [:] }
        return (try? JSONFile.decoder.decode([String: UsageMonth].self, from: data)) ?? [:]
    }
}
