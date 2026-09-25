---
description: "Tasks for 005-clickys-chats"
---

# Tasks: Clickys and Chats

**Input**: `specs/005-clickys-chats/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 Create `Sources/MyClicky/Home/Sidebar/` and `Sources/MyClicky/Home/Conversation/`
- [ ] T002 Extend `MyClickyCore/Models/Chat.swift` with the data-model.md fields (tolerant decode) + `AvatarColor`

## Phase 2: Foundational

- [ ] T003 [P] `MyClickyCore/Logic/ChatRouter.swift` (research R5)
- [ ] T004 [P] `MyClickyCore/Logic/ContextWindow.swift`
- [ ] T005 [P] `MyClickyCore/Logic/RelativeTime.swift`, `Greeting.swift`
- [ ] T006 [P] `MyClickyCore/Logic/SearchIndex.swift`, `NamingParser.swift`
- [ ] T007 [P] `MyClickyChecks/ChatChecks.swift`: routing cases (named, continuation, expired, "agenda" ≠ agent),
      windowing at 6/12, time buckets, greetings at 9/15/20 h, folding "canción", naming JSON good/bad/dedupe
- [ ] T008 `ChatStore`: unread set/clear, `unreadCount`, rename, recolor, delete file, clear Talk. `AppModel.unreadCount` feeds the notch badge

## Phase 3: US1 – chat list (P1) 🎯

- [ ] T009 [US1] `Home/HomeView.swift` two-column layout inside `HomeRoot`
- [ ] T010 [P] [US1] `Home/Sidebar/ChatRow.swift` (avatar, name, time, preview, unread dot) per contracts/ui-home.md
- [ ] T011 [US1] `Home/Sidebar/SidebarView.swift` (logo, Search + "+", Talk pinned, sorted Clickys)
- [ ] T012 [P] [US1] `Home/Sidebar/ProfileFooter.swift` (initial, name, spend text, ⓘ, ⚙ → settings route)
- [ ] T013 [P] [US1] `Home/AboutSheet.swift`

## Phase 4: US2 – greeting (P1)

- [ ] T014 [US2] `Home/EmptyStateView.swift` (mascot + pill + greeting + key hint from the pushToTalk binding)
- [ ] T015 [US2] Pill click toggles listening (reuses the talk flow; the result is routed by ChatRouter)

## Phase 5: US3 – conversation (P1)

- [ ] T016 [US3] `Home/Conversation/ChatHeader.swift`, `MessageBubble.swift` (notes line)
- [ ] T017 [US3] `Home/Conversation/ConversationView.swift` (paged LazyVStack, scroll to bottom, mark read on appear)
- [ ] T018 [US3] `Home/Conversation/Composer.swift` (Return/⇧Return, send, mic dictates into the field via SpeechRecognizer)
- [ ] T019 [US3] `Talk/Assistant.swift`: take requests from ChatRouter; Talk uses ContextWindow + summary; write
      user/assistant messages with `via` + `screensSeen`; typed Talk questions capture screens after the panel collapses
- [ ] T020 [US3] Clicky messages → existing `Agents/AgentRunner.swift` with the per-chat `agentSessionID`; replies saved to the chat

## Phase 6: US4 – create/rename/delete (P2)

- [ ] T021 [US4] "+" → new Clicky draft ("What should this Clicky do?"). On the first message, `Talk/ClickyNamer.swift` names and colors it
- [ ] T022 [US4] ⋯ menu: Rename (inline), Change color (palette popover), Delete (confirm) / Clear history (Talk)

## Phase 7: US5 – search (P2)

- [ ] T023 [US5] `Home/Sidebar/SearchField.swift` + filtered list with snippets + "No chats match" state

## Phase 8: US6 – memory (P2)

- [ ] T024 [US6] `Talk/MemoryManager.swift` (fold after the answer is spoken, per contracts/prompts.md). Record usage in UsageStore

## Phase 9: Polish

- [ ] T025 Update README/GUIDE (chats, Talk, Clickys, "agent, ask X to…")
- [ ] T026 Run quickstart.md and record the results

## Dependencies

Setup → Foundational → US1 → US2 → US3 → (US4 ∥ US5 ∥ US6) → Polish.
