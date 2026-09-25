---
description: "Tasks for 009-agents"
---

# Tasks: Agents

**Input**: `specs/009-agents/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 Install Claude Code, sign in, run `claude --help` and one `-p … --output-format stream-json --verbose`
      dry run. Save a sample stream to `specs/009-agents/samples/stream.jsonl` (no secrets). Update research.md if flags differ
- [ ] T002 Add the `MyClickyComputer` executable target (depends on MyClickyCore) to `Package.swift`. `build.sh` copies it into `Contents/MacOS`
- [ ] T003 Add the data-model.md settings and Chat/Message fields (tolerant decode)

## Phase 2: Foundational

- [ ] T004 [P] `MyClickyCore/Logic/AgentEventParser.swift` (from the saved sample)
- [ ] T005 [P] `MyClickyCore/Logic/MCPProtocol.swift` (initialize, tools/list, tools/call, framing)
- [ ] T006 [P] `MyClickyCore/Logic/PermissionDescriber.swift` (+ sensitive-command guard)
- [ ] T007 [P] `MyClickyCore/Logic/RunQueue.swift`, `SuggestionParser.swift`, `Models/AgentRun.swift`, `ApprovalRequest.swift`, `Suggestion.swift`
- [ ] T008 [P] `MyClickyChecks/AgentChecks.swift`: the sample stream parses, unknown events, partial lines,
      JSON-RPC round trips, descriptions + sensitive tags, queue limit/FIFO, step cap, suggestions JSON
- [ ] T009 `Agents/ClaudeCodeLocator.swift` (moved from `AgentRunner.findClaude` + version + signed-in check)

## Phase 3: US1 – runs with live progress (P1) 🎯

- [ ] T010 [US1] `Agents/AgentSupervisor.swift`: spawn per research R1, stream → chat messages (steps/text/result),
      session save/resume, per-Clicky folder, 30-min limit, watchdog, stop (SIGINT → SIGTERM), queue of 3
- [ ] T011 [US1] `Home/Conversation/AgentStepRow.swift` + collapsed steps. "Stop" pill in `ChatHeader`. Working indicator in `ChatRow`
- [ ] T012 [US1] Notch: activity indicator while any run is active. Right-click "Stop agents ▸" submenu
- [ ] T013 [US1] Delete `Agents/AgentRunner.swift`. Route 005's Clicky messages to AgentSupervisor

## Phase 4: US2 – Allow cards (P1)

- [ ] T014 [US2] `MyClickyComputer/main.swift`: MCP server with the `approve` tool forwarding to `agent.sock`
- [ ] T015 [US2] `Agents/AgentBridgeServer.swift` (NWListener unix socket, 0600, chat validation)
- [ ] T016 [US2] `Home/Conversation/AllowCard.swift` + a cursor bubble variant when the chat isn't visible. 10-min timeout. Per-Clicky rules
- [ ] T017 [US2] Write `mcp.json` per run. Pass `--permission-prompt-tool`/`--allowedTools` safe list

## Phase 5: US4 – Agents page (P2)

- [ ] T018 [US4] `Settings/AgentsPage.swift` per contracts/ui-agents.md incl. the CLAUDE CODE section
- [ ] T019 [US4] Step cap 40/150 + `KeepGoingCard.swift` (resume with "Please continue.")

## Phase 6: US3 – computer use (P2)

- [ ] T020 [US3] Computer tools in `MyClickyComputer` (screenshot/click/type/key/scroll/move → socket)
- [ ] T021 [US3] `Agents/ComputerActions.swift`: perform via CGEvent/SCK with companion fly-to feedback. Pause on user input.
      Once-per-instruction approval unless `alwaysAllowComputerUse`

## Phase 7: US5 – announcements (P2)

- [ ] T022 [US5] `Agents/Announcer.swift` (start/finish speech, finish bubble streaming, unread + badge, quiet-aware)

## Phase 8: US6 – suggestions (P3)

- [ ] T023 [US6] `Agents/SuggestionScheduler.swift` (07:00 + activity trigger, 20 h spacing, Claude Code call)
- [ ] T024 [US6] `Notch/MorningNotchView.swift` + Start → route to a Clicky (existing or new). Developer "Run suggestions now"

## Phase 9: Polish

- [ ] T025 Mark the Agents page available. Update README/GUIDE (agents, Allow cards, computer use, Claude Code setup)
- [ ] T026 Run quickstart.md and record the results

## Dependencies

Setup (T001 first) → Foundational → US1 → US2 → US4 → (US3 ∥ US5) → US6 → Polish.
