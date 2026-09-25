---
description: "Tasks for 012-welcome-tour"
---

# Tasks: Welcome Tour

**Input**: `specs/012-welcome-tour/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 Add `tour` settings (with the upgrade rule: `finished = true` if a key exists and permissions are granted)
- [ ] T002 Create `Sources/MyClicky/Onboarding/Steps/`

## Phase 2: Foundational

- [ ] T003 [P] `MyClickyCore/Logic/TourFlow.swift`
- [ ] T004 [P] `MyClickyCore/Logic/InterviewParser.swift` (+ generic starters)
- [ ] T005 [P] `MyClickyChecks/TourChecks.swift`: order/back/skip/resume/replay, apiKey completion rule, parser + dedupe + fallback
- [ ] T006 `App/AppEvents.swift` (notchExpanded, talkAnswered, pointed, textModeSent, dictationInserted). Emit from the existing features
- [ ] T007 `Onboarding/WelcomeWindowController.swift` + `WelcomeView.swift` (frame, dots, navigation). Show at launch when unfinished

## Phase 3: US1 – setup (P1) 🎯

- [ ] T008 [P] [US1] `Steps/IntroStep.swift` (3 animated cards), `Steps/NameStep.swift`
- [ ] T009 [US1] `Steps/PermissionsStep.swift` (live polling, Grant buttons, 🌐 key row) + `Onboarding/Relauncher.swift`
- [ ] T010 [US1] `Steps/APIKeyStep.swift` (Keychain save, test via PaidRequestGate, budget note)
- [ ] T011 [US1] `Steps/ClaudeCodeStep.swift` (locator status, copyable commands, check again, skip)
- [ ] T012 [US1] "Finish setup" dot on the notch while unfinished

## Phase 4: US2 – hands-on (P2)

- [ ] T013 [US2] `Steps/HandsOnStep.swift` (5 actions observed through AppEvents, practice text box for dictation)

## Phase 5: US3 – interview (P2)

- [ ] T014 [US3] `Steps/InterviewStep.swift` (3 questions, voice or typing) → Claude Code or Haiku → InterviewParser → ChatStore
- [ ] T015 [US3] `Steps/DoneStep.swift`

## Phase 6: US4 – replay (P3)

- [ ] T016 [US4] Show the WELCOME TOUR row in `Settings/GeneralPage.swift`. Replay keeps completion and Clickys

## Phase 7: Polish

- [ ] T017 Update README/GUIDE: first-run tour replaces the manual setup steps
- [ ] T018 Run quickstart.md and record the timing and the interview judgment

## Dependencies

Setup → Foundational → US1 → US2 → US3 → US4 → Polish. Requires 002–011.
