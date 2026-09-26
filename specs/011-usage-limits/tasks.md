---
description: "Tasks for 011-usage-limits"
---

# Tasks: Spending and Limits

**Input**: `specs/011-usage-limits/` · **Tests**: Core checks required

## Phase 1: Setup

- [X] T001 Extend `UsageMonth` (byModel, byKind, daily) with tolerant decode. Add budget/credit settings

## Phase 2: Foundational

- [X] T002 [P] `UsageStore.record(model:kind:usage:)` + `history(months:)` + `spend(since:)`
- [X] T003 [P] `MyClickyCore/Logic/BudgetPolicy.swift`
- [X] T004 [P] `MyClickyCore/Logic/CreditProjection.swift`
- [X] T005 [P] `MyClickyChecks/UsageChecks.swift`: v0.1 usage.json still decodes, aggregation, policy thresholds/top-ups/off/
      rollover/budget below spend, projection cases
- [X] T006 `Usage/PaidRequestGate.swift`. Route every ClaudeClient caller through it (Assistant, MemoryManager, ClickyNamer)

## Phase 3: US1 – see spend (P1) 🎯

- [X] T007 [US1] `Usage/SpendRing.swift` in `ProfileFooter`. Same total in `ProfileCard`
- [X] T008 [US1] `Usage/SpendingSheet.swift` (totals, splits, Charts history, disclaimer)

## Phase 4: US2 – budget (P1)

- [X] T009 [US2] General → SPENDING section
- [X] T010 [US2] 80%/100% notices (bubble + speech unless quiet) + "Allow $2 more this month"

## Phase 5: US3 – credit projection (P3)

- [X] T011 [US3] Credit card in SpendingSheet with the projection

## Phase 6: Polish

- [X] T012 Update README cost section (budget, sheet)
- [ ] T013 Run quickstart.md and record the Console comparison

## Dependencies

Setup → Foundational → US1 → US2 → US3 → Polish.

## Implementation notes

Implemented 2026-09-25. `swift build` ✓, checks: 3 spending groups (21 checks) pass; 354 total.

- **Found by the checks**: $5.60 of a $7 budget didn't count as 80% because 7 × 0.8 = 5.6000000000000005 in floating
  point. Thresholds now use a tiny tolerance.
- Every paid call goes through `PaidRequestGate`: answers show the 80%/100% notices; memory summaries and Clicky
  naming are skipped silently when the budget is reached; the welcome interview (012) will use it too. Costs are
  recorded by model, kind and day (`usage.json` stays readable by older versions of the file format).
- The 100% notice's button is a small clickable chip beside the cursor ("Allow $2 more this month"), because the
  bubble itself is click-through.
- Snapshot `spending`: total + questions, budget ring, By model / By kind, 6-month chart (Swift Charts), credit card
  with projection, disclaimer. The home snapshot showed the footer spend text pushing the sidebar sideways once the
  ring was added; it's now "$0.42 · Sep" (like the profile badge) and fits.
- Files: `BudgetPolicy` and `CreditProjection` share `Core/Logic/Budget.swift`; `SpendRing`, `SpendingSheet` and
  `SpendingSection` share `Usage/SpendingViews.swift`.
- **T013 not done**: comparing a week of real spend with console.anthropic.com needs you and real usage. → **Needs you.**
