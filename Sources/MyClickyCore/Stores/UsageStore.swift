import Foundation

/// Running monthly API spend in `usage.json` (same format as v0.1's UsageLog).
/// Agent runs aren't recorded here: they use the Claude subscription, not the API key.
public final class UsageStore: @unchecked Sendable {
    public let paths: AppPaths
    private let lock = NSLock()

    public init(paths: AppPaths = .standard) { self.paths = paths }

    public func record(_ usage: TokenUsage, countsAsQuestion: Bool = true, now: Date = Date()) {
        lock.lock(); defer { lock.unlock() }
        var months = load()
        let key = UsageMonth.key(for: now)
        var month = months[key] ?? UsageMonth()
        if countsAsQuestion { month.questions += 1 }
        month.costUSD += usage.costUSD
        months[key] = month
        try? JSONFile.write(months, to: paths.usage)
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
