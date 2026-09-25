# Implementation Plan: Spending and Limits

**Branch**: `011-usage-limits` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

Extend `UsageStore` to record cost by model and kind. Add a Core `BudgetPolicy` (allow/warn/block) and
`CreditProjection`. A single `PaidRequestGate` in the app wraps every `ClaudeClient` call. Add the footer ring,
the Spending sheet (Swift Charts bars) and the General → SPENDING section.

## Technical Context

**Language/Version**: Swift 6.4 (Swift 5 mode)

**Primary Dependencies**: SwiftUI, Charts (Apple, macOS 13+)

**Storage**: `usage.json` months gain `byModel`, `byKind` (tolerant, old months decode). Settings: `monthlyBudgetUSD`
(7.0; 0 = off), `budgetTopUps` ({"2026-09": 2.0}), `budgetWarnedMonth` (String), `creditUSD` (Double?),
`creditSince` (Date?)

**Testing**: Checks for BudgetPolicy (thresholds, top-ups, off, month rollover, budget below spend), CreditProjection
(14-day pace, no data), UsageStore aggregation and old-file decode

## Constitution Check

| Principle | Check |
|---|---|
| I | ✅ Strengthens spend visibility and control |
| III | ✅ Local only |
| VI | ✅ Policy/projection pure in Core; one gate in the app |
| VII | ✅ Checks listed |
| VIII | ✅ Footer ring position/size from ref 02 |

## Project Structure

```text
Sources/MyClickyCore/Models/UsageMonth.swift          # + byModel, byKind
Sources/MyClickyCore/Stores/UsageStore.swift          # record(model:kind:usage:), history(months:)
Sources/MyClickyCore/Logic/BudgetPolicy.swift         # decision(spent, budget, topUp, warnedMonth, month) → allow|warn|block
Sources/MyClickyCore/Logic/CreditProjection.swift
Sources/MyClicky/Usage/PaidRequestGate.swift          # check before, record after; notices
Sources/MyClicky/Usage/SpendRing.swift                # footer ring (18 pt)
Sources/MyClicky/Usage/SpendingSheet.swift            # totals, splits, Charts bars, credit form
Sources/MyClicky/Settings/GeneralPage.swift           # + SPENDING section
Sources/MyClickyChecks/UsageChecks.swift
```
