---
description: "Tasks for 010-integrations"
---

# Tasks: Integrations

**Input**: `specs/010-integrations/` · **Tests**: Core checks required

## Phase 1: Setup

- [X] T001 With Claude Code installed: verify `claude mcp add/remove/list/get` syntax and outputs, save sample
      outputs to `specs/010-integrations/samples/`, verify the R2 sign-in trigger, and verify each catalog URL. Update research.md
- [X] T002 Create `Resources/integrations.json` with the verified entries. `build.sh` copies it (+ icons)
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
- [X] T015 Run quickstart.md and record the results

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
- `ClaudeMCP.swift` (T008) was folded into `Integrations/IntegrationsModel.swift` (the `claude mcp` wrappers + a
  process runner with a timeout). `IntegrationRow`, `SignInCard` and `CustomConnectorSheet` live in `Settings/IntegrationsPage.swift`.
- The Apps chip always shows (with "Apps +") and opens the Integrations page; connected icons appear on it.
- **T015 not done**: needs Claude Code and your accounts (GitHub/Notion/Linear sign-ins). → **Needs you.**

### Verification 2026-10-20

- **T001 done** with Claude Code 2.1.283. `claude mcp add --transport http -s user`, `list`, `get` and `remove` work as
  `Integration.addArguments` and `disconnect` use them (`samples/mcp-roundtrip.real.txt`). The real `claude mcp list`
  output (`samples/mcp-list.real.txt`) differed from the documented sample:
  - the status marks are `✔` and `!`
  - claude.ai connectors have spaces in their names and no `(HTTP)` suffix
  - the header ends with `…`
  **Fixed:** `MCPListParser` dropped names with spaces, so claude.ai connectors never showed as "Managed in Claude
  Code"; it also trims `✔ ✘ ! ⏸` now. Checked against the real sample.
- **Sign-in (R2):** Claude Code now has `claude mcp login <server>`. Connect opens Terminal running that command, and the
  browser sign-in starts straight away (no more typing `/mcp` and choosing the server). It still needs a terminal:
  without one it stops with "stdin isn't a terminal".
- **T002 done:** all six catalog addresses answer with 401 + an OAuth challenge (made-up paths on the same hosts
  return 404). Atlassian and Asana moved from the old SSE endpoints to their current HTTP ones:
  `https://mcp.atlassian.com/v1/mcp` and `https://mcp.asana.com/v2/mcp`. `build.sh` copies the file into the app.

### Foundation pass 2026-10-22

- **T015 done** by an automated end-to-end run of the installed app (scripts/e2e/). GitHub connected with your own OAuth app (GitHub doesn't allow dynamic client registration; fixed), listed PRs, reconnect after a revoke, Apps chip icon; custom connector bad/good/remove; claude.ai connectors listed; Disconnect tested on Sentry. Asana moved back to an address that allows sign-in. Evidence: checklist E.
