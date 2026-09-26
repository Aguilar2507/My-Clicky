---
description: "Tasks for 012-welcome-tour"
---

# Tasks: Welcome Tour

**Input**: `specs/012-welcome-tour/` · **Tests**: Core checks required

## Phase 1: Setup

- [X] T001 Add `tour` settings (with the upgrade rule: `finished = true` if a key exists and permissions are granted)
- [X] T002 Create `Sources/MyClicky/Onboarding/Steps/`

## Phase 2: Foundational

- [X] T003 [P] `MyClickyCore/Logic/TourFlow.swift`
- [X] T004 [P] `MyClickyCore/Logic/InterviewParser.swift` (+ generic starters)
- [X] T005 [P] `MyClickyChecks/TourChecks.swift`: order/back/skip/resume/replay, apiKey completion rule, parser + dedupe + fallback
- [X] T006 `App/AppEvents.swift` (notchExpanded, talkAnswered, pointed, textModeSent, dictationInserted). Emit from the existing features
- [X] T007 `Onboarding/WelcomeWindowController.swift` + `WelcomeView.swift` (frame, dots, navigation). Show at launch when unfinished

## Phase 3: US1 – setup (P1) 🎯

- [X] T008 [P] [US1] `Steps/IntroStep.swift` (3 animated cards), `Steps/NameStep.swift`
- [X] T009 [US1] `Steps/PermissionsStep.swift` (live polling, Grant buttons, 🌐 key row) + `Onboarding/Relauncher.swift`
- [X] T010 [US1] `Steps/APIKeyStep.swift` (Keychain save, test via PaidRequestGate, budget note)
- [X] T011 [US1] `Steps/ClaudeCodeStep.swift` (locator status, copyable commands, check again, skip)
- [X] T012 [US1] "Finish setup" dot on the notch while unfinished

## Phase 4: US2 – hands-on (P2)

- [X] T013 [US2] `Steps/HandsOnStep.swift` (5 actions observed through AppEvents, practice text box for dictation)

## Phase 5: US3 – interview (P2)

- [X] T014 [US3] `Steps/InterviewStep.swift` (3 questions, voice or typing) → Claude Code or Haiku → InterviewParser → ChatStore
- [X] T015 [US3] `Steps/DoneStep.swift`

## Phase 6: US4 – replay (P3)

- [X] T016 [US4] Show the WELCOME TOUR row in `Settings/GeneralPage.swift`. Replay keeps completion and Clickys

## Phase 7: Polish

- [X] T017 Update README/GUIDE: first-run tour replaces the manual setup steps
- [ ] T018 Run quickstart.md and record the timing and the interview judgment

## Dependencies

Setup → Foundational → US1 → US2 → US3 → US4 → Polish. Requires 002–011.

## Implementation notes

Implemented 2026-09-25. `swift build` ✓, checks: 3 tour groups (23 checks) pass; 377 total.

- The tour opens at launch while `settings.tour.finished` is false. Upgrading users with an API key and all five
  permissions are marked finished (T001 rule); on this Mac the tour will most likely show on first launch, because
  a rebuilt app has to be granted Input Monitoring (new) and often Screen Recording/Accessibility again.
- Steps: animated intro cards (no video), name, live permissions (+ the 🌐 key warning and "Relaunch MyClicky"),
  API key with a real 1-token test (recorded as "interview" spend), Claude Code status with copyable commands,
  hands-on checklist fed by `AppEvents` (notch opened, talk answered, pointed, text mode sent, dictation inserted),
  interview (typed or dictated) → three Clickys via Claude Code first, then Haiku through `PaidRequestGate`, then
  generic starters; done screen.
- Snapshots `welcome-intro`, `welcome-permissions`, `welcome-handson`, `welcome-interview` render as designed.
- "Finish setup": an orange dot on the notch's left wing (when there's no unread badge) and a "Finish setup…" item
  in the notch's right-click menu. Replay lives in Settings → General → Welcome tour.
- File placement: the 8 steps live in `Onboarding/Steps/SetupSteps.swift` (intro, name, permissions, API key,
  Claude Code) and `Onboarding/Steps/TryAndMeetSteps.swift` (hands-on, interview, done); `Relauncher` and
  `WelcomeTour` live in `Onboarding/WelcomeWindowController.swift`.
- Version bumped to 0.3.0 (3); the changelog lists everything from 005–012. The GUIDE's file tree now matches the
  new structure.
- **T018 not done**: timing a fresh install, granting permissions, the relaunch and the interview need you. → **Needs you.**
