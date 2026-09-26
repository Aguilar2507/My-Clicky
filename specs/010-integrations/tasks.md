---
description: "Tasks for 010-integrations"
---

# Tasks: Integrations

**Input**: `specs/010-integrations/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 With Claude Code installed: verify `claude mcp add/remove/list/get` syntax and outputs, save sample
      outputs to `specs/010-integrations/samples/`, verify the R2 sign-in trigger, and verify each catalog URL. Update research.md
- [ ] T002 Create `Resources/integrations.json` with the verified entries. `build.sh` copies it (+ icons)
- [X] T003 Add `customIntegrations` to `Settings.swift`

## Phase 2: Foundational

- [X] T004 [P] `MyClickyCore/Models/Integration.swift`
- [X] T005 [P] `MyClickyCore/Logic/MCPListParser.swift` (from the saved samples)
- [X] T006 [P] `MyClickyCore/Logic/IntegrationFilter.swift` + name/URL validation
- [X] T007 [P] `MyClickyChecks/IntegrationChecks.swift`: catalog decode, list parsing for each status + foreign servers,
      filter, validation
- [X] T008 `Integrations/ClaudeMCP.swift` (async wrappers with a 20 s timeout) + `IntegrationsModel.swift` (merge catalog + statuses)

## Phase 3: US1 – connect from the catalog (P1) 🎯

- [X] T009 [US1] `Settings/IntegrationsPage.swift` + `IntegrationRow.swift` per contracts/ui-integrations.md
- [X] T010 [US1] Connect flow: add → needsAuth → sign-in sheet (R2) → poll → Connected. Cancel path

## Phase 4: US2 – health (P1)

- [X] T011 [US2] Refresh on page open (spinner). Reconnect, Disconnect, ✕ remove

## Phase 5: US3 – custom connector (P2)

- [X] T012 [US3] `Settings/CustomConnectorSheet.swift` + validation + add/remove

## Phase 6: US4 – Apps chip (P3)

- [X] T013 [US4] `Home/Sidebar/AppsChip.swift` (connected icons, opens the page)

## Phase 7: Polish

- [X] T014 Mark the Integrations page available. Update README/GUIDE
- [ ] T015 Run quickstart.md and record the results

## Dependencies

Setup (T001 first) → Foundational → US1 → US2 → (US3 ∥ US4) → Polish. Requires 009.

## Implementation notes

Implemented 2026-09-25. `swift build` ✓, checks: 3 integration groups (21 checks) pass; 333 total.

- **T001 not done** (needs Claude Code installed): the `claude mcp add/remove/list` syntax, the sign-in trigger and
  the catalog URLs are unverified. The list parser is checked against
  `specs/010-integrations/samples/mcp-list.documented.txt` (hand-written). → **Needs you.**
- **T002 partly done**: `Resources/integrations.json` exists (GitHub, Notion, Linear, Jira & Confluence, Asana,
  Sentry) and `build.sh` bundles it, but the entries are the research candidates, not yet *verified* (that's T001).
  Left unchecked on purpose.
- Sign-in (research R2): Connect runs `claude mcp add … -s user`; if it needs authentication, MyClicky opens a
  Terminal script (`connect-<id>.command`) that starts Claude Code with step-by-step instructions (`/mcp` →
  Authenticate), and polls `claude mcp list` every 3 s for up to 5 minutes.
- Snapshot `settings-integrations` matches ref 10 (connected with green/orange status, Reconnect + ✕, Available with
  Connect). Brand logos aren't bundled: rows use letter tiles (a small deviation, avoids shipping trademarks).
- The Apps chip always shows (with "Apps +") and opens the Integrations page; connected icons appear on it.
- **T015 not done**: needs Claude Code and your accounts (GitHub/Notion/Linear sign-ins). → **Needs you.**
