---
description: "Tasks for 010-integrations"
---

# Tasks: Integrations

**Input**: `specs/010-integrations/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 With Claude Code installed: verify `claude mcp add/remove/list/get` syntax and outputs, save sample
      outputs to `specs/010-integrations/samples/`, verify the R2 sign-in trigger, and verify each catalog URL. Update research.md
- [ ] T002 Create `Resources/integrations.json` with the verified entries. `build.sh` copies it (+ icons)
- [ ] T003 Add `customIntegrations` to `Settings.swift`

## Phase 2: Foundational

- [ ] T004 [P] `MyClickyCore/Models/Integration.swift`
- [ ] T005 [P] `MyClickyCore/Logic/MCPListParser.swift` (from the saved samples)
- [ ] T006 [P] `MyClickyCore/Logic/IntegrationFilter.swift` + name/URL validation
- [ ] T007 [P] `MyClickyChecks/IntegrationChecks.swift`: catalog decode, list parsing for each status + foreign servers,
      filter, validation
- [ ] T008 `Integrations/ClaudeMCP.swift` (async wrappers with a 20 s timeout) + `IntegrationsModel.swift` (merge catalog + statuses)

## Phase 3: US1 – connect from the catalog (P1) 🎯

- [ ] T009 [US1] `Settings/IntegrationsPage.swift` + `IntegrationRow.swift` per contracts/ui-integrations.md
- [ ] T010 [US1] Connect flow: add → needsAuth → sign-in sheet (R2) → poll → Connected. Cancel path

## Phase 4: US2 – health (P1)

- [ ] T011 [US2] Refresh on page open (spinner). Reconnect, Disconnect, ✕ remove

## Phase 5: US3 – custom connector (P2)

- [ ] T012 [US3] `Settings/CustomConnectorSheet.swift` + validation + add/remove

## Phase 6: US4 – Apps chip (P3)

- [ ] T013 [US4] `Home/Sidebar/AppsChip.swift` (connected icons, opens the page)

## Phase 7: Polish

- [ ] T014 Mark the Integrations page available. Update README/GUIDE
- [ ] T015 Run quickstart.md and record the results

## Dependencies

Setup (T001 first) → Foundational → US1 → US2 → (US3 ∥ US4) → Polish. Requires 009.
