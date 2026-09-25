---
description: "Tasks for 011-usage-limits"
---

# Tasks: Spending and Limits

**Input**: `specs/011-usage-limits/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 Extend `UsageMonth` (byModel, byKind, daily) with tolerant decode. Add budget/credit settings

## Phase 2: Foundational

- [ ] T002 [P] `UsageStore.record(model:kind:usage:)` + `history(months:)` + `spend(since:)`
- [ ] T003 [P] `MyClickyCore/Logic/BudgetPolicy.swift`
- [ ] T004 [P] `MyClickyCore/Logic/CreditProjection.swift`
- [ ] T005 [P] `MyClickyChecks/UsageChecks.swift`: v0.1 usage.json still decodes, aggregation, policy thresholds/top-ups/off/
      rollover/budget below spend, projection cases
- [ ] T006 `Usage/PaidRequestGate.swift`. Route every ClaudeClient caller through it (Assistant, MemoryManager, ClickyNamer)

## Phase 3: US1 – see spend (P1) 🎯

- [ ] T007 [US1] `Usage/SpendRing.swift` in `ProfileFooter`. Same total in `ProfileCard`
- [ ] T008 [US1] `Usage/SpendingSheet.swift` (totals, splits, Charts history, disclaimer)

## Phase 4: US2 – budget (P1)

- [ ] T009 [US2] General → SPENDING section
- [ ] T010 [US2] 80%/100% notices (bubble + speech unless quiet) + "Allow $2 more this month"

## Phase 5: US3 – credit projection (P3)

- [ ] T011 [US3] Credit card in SpendingSheet with the projection

## Phase 6: Polish

- [ ] T012 Update README cost section (budget, sheet)
- [ ] T013 Run quickstart.md and record the Console comparison

## Dependencies

Setup → Foundational → US1 → US2 → US3 → Polish.
