# Research: Spending and Limits

## R1 One gate for all paid calls

- **Decision**: Every `ClaudeClient` call (streaming answer, summary, naming, welcome interview) goes through
  `PaidRequestGate.run(kind:model:) { … }`. It checks `BudgetPolicy` before sending and records usage after.
- **Rationale**: FR-001/FR-004 can't be forgotten by a new caller. Grep for `ClaudeClient(` in review to confirm.

## R2 Estimating before sending

- **Decision**: No pre-estimate. The gate blocks only once the month's recorded spend reaches the budget. A single
  request can overshoot by at most one request's cost (≈ $0.01).
- **Rationale**: Simple, and the overshoot is negligible.

## R3 Charts

- **Decision**: Swift Charts `BarMark` for 6 months, with the lavender accent. Totals formatted with
  `FormatStyle.Currency(code: "USD")` (3 decimals under $1, matching the v0.1 menu).

## R4 Projection

- **Decision**: remaining = credit − spend since `creditSince`. Pace = spend over the last 14 days ÷ 14 (or ÷ days since
  `creditSince` if fewer). Date = today + remaining ÷ pace. Pace 0 → "No recent spending".
