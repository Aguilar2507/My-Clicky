# Data Model: Spending and Limits

## UsageMonth (usage.json, per "YYYY-MM")

| Field | Type | Default |
|---|---|---|
| questions | Int | 0 |
| costUSD | Double | 0 |
| byModel | [String: Double] | {} |
| byKind | [String: Double] | {} (keys: `answer`, `memory`, `naming`, `interview`) |
| daily | [String: Double] | {} ("YYYY-MM-DD" → cost; for the 14-day pace) |

## New settings

| Field | Type | Default |
|---|---|---|
| monthlyBudgetUSD | Double | 7.0 (0 = off) |
| budgetTopUps | [String: Double] | {} |
| budgetWarnedMonth | String | "" |
| creditUSD | Double? | nil |
| creditSince | Date? | nil |

## BudgetDecision (Core)

`allow` · `warn(percent)` (once per month, at ≥ 80%) · `block(resetsOn: Date)`
Effective budget = monthlyBudgetUSD + budgetTopUps[month].
