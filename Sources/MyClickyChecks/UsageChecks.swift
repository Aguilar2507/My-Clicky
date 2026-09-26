import Foundation
import MyClickyCore

/// Checks for spec 011 (spending and limits).
enum UsageChecks {
    static func run() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let sep10 = cal.date(from: DateComponents(year: 2026, month: 9, day: 10, hour: 12))!

        Check.group("Usage store: splits and history") {
            let paths = AppPaths(base: Check.tempPaths())
            try JSONFile.write(#"{"2026-08":{"questions":3,"costUSD":0.5}}"#.data(using: .utf8)!, to: paths.usage)
            let store = UsageStore(paths: paths)
            store.record(TokenUsage(model: "claude-haiku-4-5", inputTokens: 1_000_000), kind: .answer, now: sep10)
            store.record(TokenUsage(model: "claude-sonnet-5", inputTokens: 1_000_000), kind: .answer, now: sep10)
            store.record(TokenUsage(model: "claude-haiku-4-5", outputTokens: 100_000), kind: .memory, now: sep10)
            let month = store.month(containing: sep10)
            Check.equal(month.questions, 2, "memory doesn't count as a question")
            Check.near(month.costUSD, 3.5)
            Check.near(month.byModel["claude-sonnet-5"] ?? 0, 2)
            Check.near(month.byKind["memory"] ?? 0, 0.5)
            Check.near(month.byModel.values.reduce(0, +), month.costUSD, tolerance: 1e-9, "splits add up")
            Check.near(month.daily["2026-09-10"] ?? 0, 3.5)
            let history = store.history(months: 6, until: sep10, calendar: cal)
            Check.equal(history.map(\.key), ["2026-04", "2026-05", "2026-06", "2026-07", "2026-08", "2026-09"])
            Check.near(history[4].month.costUSD, 0.5, tolerance: 1e-9, "old v0.1 month still reads")
        }

        Check.group("Budget policy") {
            let d = { (spent: Double, budget: Double, topUp: Double, warned: String) in
                BudgetPolicy.decision(spent: spent, budget: budget, topUp: topUp, warnedMonth: warned, month: "2026-09",
                                      now: sep10, calendar: cal)
            }
            Check.equal(d(1, 7, 0, ""), .allow)
            Check.equal(d(5.6, 7, 0, ""), .warn(percent: 80), "warn at 80%")
            Check.equal(d(6, 7, 0, "2026-09"), .allow, "warn only once a month")
            let resets = cal.date(from: DateComponents(year: 2026, month: 10, day: 1))!
            Check.equal(d(7, 7, 0, "2026-09"), .block(resetsOn: resets), "block at 100% until Oct 1")
            Check.equal(d(7, 7, 2, "2026-09"), .allow, "top-up lifts the limit")
            Check.equal(d(100, 0, 0, ""), .allow, "no budget")
            Check.equal(d(3, 2, 0, ""), .block(resetsOn: resets), "budget lowered below spend blocks at once")
            Check.near(BudgetPolicy.fraction(spent: 3.5, budget: 7, topUp: 0), 0.5)
            Check.near(BudgetPolicy.fraction(spent: 9, budget: 7, topUp: 0), 1)
        }

        Check.group("Credit projection") {
            let bought = cal.date(from: DateComponents(year: 2026, month: 9, day: 1))!
            var daily: [String: Double] = [:]
            for day in 1...10 { daily[String(format: "2026-09-%02d", day)] = 0.11 }
            daily["2026-08-20"] = 5 // before the credit: ignored
            let p = CreditProjection(credit: 20, since: bought, daily: daily, now: sep10, calendar: cal)
            Check.near(p.remaining, 18.9, tolerance: 1e-9)
            Check.near(p.pacePerDay, 0.11, tolerance: 1e-9)
            Check.equal(p.runsOutOn, cal.date(byAdding: .day, value: 171, to: cal.startOfDay(for: sep10)), "18.9 / 0.11 = 171 days")
            let quiet = CreditProjection(credit: 20, since: bought, daily: [:], now: sep10, calendar: cal)
            Check.equal(quiet.runsOutOn, nil, "no spending → no date")
        }
    }
}
