---
description: "Tasks for 018-agent-presence"
---

# Tasks: Wake Words, Agent Bot and Task-Done Alerts

Plan: pure `WakeWords` parser in Core (checked) used by `Router`/`ChatRouter`; `Assistant` watches the live
transcript, returns to idle after agent requests, and drives a new `AgentBotPresenter` (small non-activating panel
hosting `LivelyBot`, animated from/to the bottom-left corner, following the pointer) while `CompanionController`
hides its cursor; `TaskAlerts` posts notifications (UserNotifications) and opens the chat on click; announcements
queue instead of dropping. Constitution: I ✅ (no API), II ✅ (on-device), IV ✅ (notifications are local),
new permission justified (FR-007), VIII deviations listed ✅.

- [X] T001 `MyClickyCore/Logic/WakeWords.swift` + `Router.agentTask`/`ChatRouter` use it; checks (`WakeWordChecks`)
- [X] T002 [US2] `Talk/Assistant.swift`: idle after agent requests (FR-005); live-transcript agent detection
- [X] T003 [US2] `Companion/AgentBotPresenter.swift`: panel, enter/follow/exit animations, Reduce Motion
- [X] T004 [US2] `Companion/CompanionController.swift`: hide the cursor while the bot is out
- [X] T005 [US3] `Agents/TaskAlerts.swift`: notification per task end, click opens the chat; permission on first use
- [X] T006 [US3] `AgentSupervisor.finishAnnouncement` → alerts; `Assistant.announce` queues (max 60 s) instead of dropping
- [X] T007 Docs: CLAUDE.md rule (every task end alerts), README, CHANGELOG, report
- [X] T008 Try it (you): "Clicky…", "Clicky Agent…", a task finishing in the background

## Implementation notes

Implemented 2026-09-29. `swift build` ✓, `swift run MyClickyChecks` → 450 passed (24 new in `WakeWordChecks`).
`MyClicky --demo-agent-bot` (developer tool) summons and dismisses the bot and prints its window frames: it starts at
the bottom-left corner, lands beside the pointer in ~0.25 s, and its window is gone after it leaves.

- **Root cause of "I never know when it's done":** after a voice request routed to a Clicky, `Assistant` never left
  `.listening` (only Talk replies reset it). `announce()` waits while listening, so "is on it" and "finished" lines
  never played, and `beginListening()` ignored the next ⌃⌥ press. Fixed by `finishListening()` on agent routes.
- **Announcements** now wait for MyClicky to be idle (listening, thinking or speaking) up to 60 s instead of being
  dropped while it speaks. The bubble falls back to the spoken line when there's no longer text.
- **Notifications** (`UserNotifications`) are asked for the first time a task ends; banners show even while
  MyClicky is in front; clicking one opens the notch on that chat.
- **Wake words** are a pure parser (`WakeWords`) used by `Router.agentTask` and `ChatRouter` (Talk questions lose the
  leading "Clicky"). Plain "click" only counts before "agent", so "click the export button" is untouched.
- **The bot** is a small `.transient` panel that exists only while it's out (no Mission Control side effects),
  hosting the same `LivelyBot` as the home page: it follows the pointer, its eyes go wide while listening, and it nods
  (spring) before flying back. The cursor companion hides via `CompanionController.setAgentBotOut`.
