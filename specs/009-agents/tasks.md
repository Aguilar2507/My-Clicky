---
description: "Tasks for 009-agents"
---

# Tasks: Agents

**Input**: `specs/009-agents/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 Install Claude Code, sign in, run `claude --help` and one `-p … --output-format stream-json --verbose`
      dry run. Save a sample stream to `specs/009-agents/samples/stream.jsonl` (no secrets). Update research.md if flags differ
- [X] T002 Add the `MyClickyComputer` executable target (depends on MyClickyCore) to `Package.swift`. `build.sh` copies it into `Contents/MacOS`
- [X] T003 Add the data-model.md settings and Chat/Message fields (tolerant decode)

## Phase 2: Foundational

- [X] T004 [P] `MyClickyCore/Logic/AgentEventParser.swift` (from the saved sample)
- [X] T005 [P] `MyClickyCore/Logic/MCPProtocol.swift` (initialize, tools/list, tools/call, framing)
- [X] T006 [P] `MyClickyCore/Logic/PermissionDescriber.swift` (+ sensitive-command guard)
- [X] T007 [P] `MyClickyCore/Logic/RunQueue.swift`, `SuggestionParser.swift`, `Models/AgentRun.swift`, `ApprovalRequest.swift`, `Suggestion.swift`
- [X] T008 [P] `MyClickyChecks/AgentChecks.swift`: the sample stream parses, unknown events, partial lines,
      JSON-RPC round trips, descriptions + sensitive tags, queue limit/FIFO, step cap, suggestions JSON
- [X] T009 `Agents/ClaudeCodeLocator.swift` (moved from `AgentRunner.findClaude` + version + signed-in check)

## Phase 3: US1 – runs with live progress (P1) 🎯

- [X] T010 [US1] `Agents/AgentSupervisor.swift`: spawn per research R1, stream → chat messages (steps/text/result),
      session save/resume, per-Clicky folder, 30-min limit, watchdog, stop (SIGINT → SIGTERM), queue of 3
- [X] T011 [US1] `Home/Conversation/AgentStepRow.swift` + collapsed steps. "Stop" pill in `ChatHeader`. Working indicator in `ChatRow`
- [X] T012 [US1] Notch: activity indicator while any run is active. Right-click "Stop agents ▸" submenu
- [X] T013 [US1] Delete `Agents/AgentRunner.swift`. Route 005's Clicky messages to AgentSupervisor

## Phase 4: US2 – Allow cards (P1)

- [X] T014 [US2] `MyClickyComputer/main.swift`: MCP server with the `approve` tool forwarding to `agent.sock`
- [X] T015 [US2] `Agents/AgentBridgeServer.swift` (NWListener unix socket, 0600, chat validation)
- [X] T016 [US2] `Home/Conversation/AllowCard.swift` + a cursor bubble variant when the chat isn't visible. 10-min timeout. Per-Clicky rules
- [X] T017 [US2] Write `mcp.json` per run. Pass `--permission-prompt-tool`/`--allowedTools` safe list

## Phase 5: US4 – Agents page (P2)

- [X] T018 [US4] `Settings/AgentsPage.swift` per contracts/ui-agents.md incl. the CLAUDE CODE section
- [X] T019 [US4] Step cap 40/150 + `KeepGoingCard.swift` (resume with "Please continue.")

## Phase 6: US3 – computer use (P2)

- [X] T020 [US3] Computer tools in `MyClickyComputer` (screenshot/click/type/key/scroll/move → socket)
- [X] T021 [US3] `Agents/ComputerActions.swift`: perform via CGEvent/SCK with companion fly-to feedback. Pause on user input.
      Once-per-instruction approval unless `alwaysAllowComputerUse`

## Phase 7: US5 – announcements (P2)

- [X] T022 [US5] `Agents/Announcer.swift` (start/finish speech, finish bubble streaming, unread + badge, quiet-aware)

## Phase 8: US6 – suggestions (P3)

- [X] T023 [US6] `Agents/SuggestionScheduler.swift` (07:00 + activity trigger, 20 h spacing, Claude Code call)
- [X] T024 [US6] `Notch/MorningNotchView.swift` + Start → route to a Clicky (existing or new). Developer "Run suggestions now"

## Phase 9: Polish

- [X] T025 Mark the Agents page available. Update README/GUIDE (agents, Allow cards, computer use, Claude Code setup)
- [ ] T026 Run quickstart.md and record the results

## Dependencies

Setup (T001 first) → Foundational → US1 → US2 → US4 → (US3 ∥ US5) → US6 → Polish.

## Implementation notes

Implemented 2026-09-25. `swift build` ✓, checks: 7 agent groups (57 checks) pass; 312 total — including a **real
end-to-end bridge check**: `MyClickyChecks` starts the socket server, runs the `MyClickyComputer` binary like Claude
Code would, sends an MCP `tools/call`, and gets the answer back through the socket (socket mode 0600 verified).

- **T001 not done** — Claude Code isn't installed on this Mac, and signing in needs you in a browser. The stream
  parser is built and checked against `specs/009-agents/samples/stream.documented.jsonl` (hand-written from the
  documented format). The flag names, `Edit(./**)` rules and the signed-in check (`~/.claude.json` →
  `oauthAccount`) are unverified until you install it. → **Needs you** (then re-run a real task and save its stream).
- Snapshots: `settings-agents` matches ref 09 (+ the CLAUDE CODE section); `agent-chat` shows grouped steps
  ("4 steps ▸"), an Allow card with Allow / Always allow / Deny, and a Keep going card; `morning` shows the ideas panel.
- The socket server lives in Core (`BridgeSocketServer`, POSIX) instead of `Agents/AgentBridgeServer.swift` with
  NWListener, so it can be checked (research R3b). Announcements are `Assistant.announce` + the supervisor's
  `finishAnnouncement` (no separate `Announcer.swift`); the Allow chip beside the cursor is `ApprovalChip`
  (in `AgentSupervisor.swift`). Agent cards live in `Home/Conversation/AgentCards.swift`.
- `AgentRun` and `ApprovalRequest` (T007) aren't separate model files: a run is `AgentSupervisor.Run` (in memory),
  and an approval is a chat `Message` with `kind: .approval`, so it's saved and visible in the chat.
- **Deviation**: the morning ideas appear in a panel just under the notch for 15 s (and in the notch's right-click
  menu → "Today's ideas") instead of the collapsed notch itself widening.
- Computer use: the companion flies to each spot before a click; your own mouse/keyboard input during a run makes
  the next action ask "keep using your Mac?". Screenshots for agents are captured fresh and never stored in chats.
- **T026 not done**: the quickstart needs Claude Code + your Claude plan. → **Needs you.**
