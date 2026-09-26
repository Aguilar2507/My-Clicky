---
description: "Tasks for 005-clickys-chats"
---

# Tasks: Clickys and Chats

**Input**: `specs/005-clickys-chats/` · **Tests**: Core checks required

## Phase 1: Setup

- [X] T001 Create `Sources/MyClicky/Home/Sidebar/` and `Sources/MyClicky/Home/Conversation/`
- [X] T002 Extend `MyClickyCore/Models/Chat.swift` with the data-model.md fields (tolerant decode) + `AvatarColor`

## Phase 2: Foundational

- [X] T003 [P] `MyClickyCore/Logic/ChatRouter.swift` (research R5)
- [X] T004 [P] `MyClickyCore/Logic/ContextWindow.swift`
- [X] T005 [P] `MyClickyCore/Logic/RelativeTime.swift`, `Greeting.swift`
- [X] T006 [P] `MyClickyCore/Logic/SearchIndex.swift`, `NamingParser.swift`
- [X] T007 [P] `MyClickyChecks/ChatChecks.swift`: routing cases (named, continuation, expired, "agenda" ≠ agent),
      windowing at 6/12, time buckets, greetings at 9/15/20 h, folding "canción", naming JSON good/bad/dedupe
- [X] T008 `ChatStore`: unread set/clear, `unreadCount`, rename, recolor, delete file, clear Talk. `AppModel.unreadCount` feeds the notch badge

## Phase 3: US1 – chat list (P1) 🎯

- [X] T009 [US1] `Home/HomeView.swift` two-column layout inside `HomeRoot`
- [X] T010 [P] [US1] `Home/Sidebar/ChatRow.swift` (avatar, name, time, preview, unread dot) per contracts/ui-home.md
- [X] T011 [US1] `Home/Sidebar/SidebarView.swift` (logo, Search + "+", Talk pinned, sorted Clickys)
- [X] T012 [P] [US1] `Home/Sidebar/ProfileFooter.swift` (initial, name, spend text, ⓘ, ⚙ → settings route)
- [X] T013 [P] [US1] `Home/AboutSheet.swift`

## Phase 4: US2 – greeting (P1)

- [X] T014 [US2] `Home/EmptyStateView.swift` (mascot + pill + greeting + key hint from the pushToTalk binding)
- [X] T015 [US2] Pill click toggles listening (reuses the talk flow; the result is routed by ChatRouter)

## Phase 5: US3 – conversation (P1)

- [X] T016 [US3] `Home/Conversation/ChatHeader.swift`, `MessageBubble.swift` (notes line)
- [X] T017 [US3] `Home/Conversation/ConversationView.swift` (paged LazyVStack, scroll to bottom, mark read on appear)
- [X] T018 [US3] `Home/Conversation/Composer.swift` (Return/⇧Return, send, mic dictates into the field via SpeechRecognizer)
- [X] T019 [US3] `Talk/Assistant.swift`: take requests from ChatRouter; Talk uses ContextWindow + summary; write
      user/assistant messages with `via` + `screensSeen`; typed Talk questions capture screens after the panel collapses
- [X] T020 [US3] Clicky messages → existing `Agents/AgentRunner.swift` with the per-chat `agentSessionID`; replies saved to the chat

## Phase 6: US4 – create/rename/delete (P2)

- [X] T021 [US4] "+" → new Clicky draft ("What should this Clicky do?"). On the first message, `Talk/ClickyNamer.swift` names and colors it
- [X] T022 [US4] ⋯ menu: Rename (inline), Change color (palette popover), Delete (confirm) / Clear history (Talk)

## Phase 7: US5 – search (P2)

- [X] T023 [US5] `Home/Sidebar/SearchField.swift` + filtered list with snippets + "No chats match" state

## Phase 8: US6 – memory (P2)

- [X] T024 [US6] `Talk/MemoryManager.swift` (fold after the answer is spoken, per contracts/prompts.md). Record usage in UsageStore

## Phase 9: Polish

- [X] T025 Update README/GUIDE (chats, Talk, Clickys, "agent, ask X to…")
- [ ] T026 Run quickstart.md and record the results

## Dependencies

Setup → Foundational → US1 → US2 → US3 → (US4 ∥ US5 ∥ US6) → Polish.

## Implementation notes

Implemented 2026-09-25. `swift build` ✓, checks: 6 chat groups (37 checks) pass; 166 total.

- Snapshots `home` and `conversation` (seeded with ref-02-like Clickys) match ref 02's sidebar and greeting:
  logo, Search + "+", pinned Talk, pastel avatars, unread dot, relative times, previews, footer (name + spend + ⓘ ⚙),
  mascot over the glossy pill, "Evening, Jose." and the fn hint. Row fonts were reduced after the first snapshot
  showed long names truncating more than HeyClicky's.
- The conversation screen (not in the references) uses the same style: header with ⋯ menu, soft user bubbles,
  Clicky replies beside the avatar, "Voice · Looked at N screens · time" notes, composer with mic and send.
- The composer sends on Return; a new line is ⌥Return (SwiftUI's multi-line field on macOS), not ⇧Return as the
  contract said.
- Typed Talk questions don't collapse the panel first: MyClicky's own windows are always excluded from screenshots.
- `AgentRunner` now takes the Clicky's own session id; one agent runs at a time until 009 (others get a "Waiting"
  note). `MemoryManager` and `ClickyNamer` live together in `Talk/MemoryManager.swift`. Search, footer and About
  live in `Home/Sidebar/SidebarView.swift`; the Apps chip hook is ready for 010.
- **T026 not done**: the quickstart needs the running app and your API key (voice questions, naming a Clicky, the
  "Orion" memory test, unread badge). → **Needs you.**
