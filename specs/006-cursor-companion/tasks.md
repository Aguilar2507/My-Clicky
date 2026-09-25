---
description: "Tasks for 006-cursor-companion"
---

# Tasks: Cursor Companion

**Input**: `specs/006-cursor-companion/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 Add `cursorColor`, `cursorDocked` to `Settings.swift`
- [ ] T002 Rename `Companion/Overlay.swift` into `CompanionController.swift`, `CompanionWindow.swift`,
      `BubbleLayer.swift` (split, no behavior change). Run `swift build`

## Phase 2: Foundational

- [ ] T003 [P] `MyClickyCore/Logic/ScreenTags.swift` (POINT + DRAW, streaming-safe visible text). Remove Core `PointTag`
- [ ] T004 [P] `MyClickyCore/Logic/CompanionMotion.swift` (spring step, offset + edge flip, arc control point)
- [ ] T005 [P] `MyClickyCore/Logic/ScreenMapping.swift` (moved from `Screenshot.globalPoint`)
- [ ] T006 [P] `MyClickyChecks/CompanionChecks.swift`: all tag shapes, invalid/partial tags, extras capped, spring
      converges, edge flip at each screen edge, mapping round trip

## Phase 3: US1 – follow + states (P1) 🎯

- [ ] T007 [US1] `Companion/CompanionLayer.swift` (triangle, glow, idle/listening/thinking/speaking animations)
- [ ] T008 [US1] Display-link follow loop in `CompanionController` (start on mouse move, stop when settled). Cross-display handoff
- [ ] T009 [US1] Wire states from the talk flow (`Assistant`) and mic level from `SpeechRecognizer`. Hide over the open notch panel

## Phase 4: US2 – bubble (P1)

- [ ] T010 [US2] `BubbleLayer` beside the companion, text updated per spoken sentence, 3 s fade, dismissed on push-to-talk

## Phase 5: US3 – pointing flight (P1)

- [ ] T011 [US3] Companion flight to a POINT mark (arc, label, 6 s / proximity return). Delete the v0.1 blue arrow code
- [ ] T012 [US3] Docked flight: from the notch's right slot and back

## Phase 6: US4 – drawings (P2)

- [ ] T013 [US4] `Companion/DrawingLayer.swift` (stroke animation, wobble, 8 s fade, clear on push-to-talk)
- [ ] T014 [US4] Prompt + router additions per contracts/screen-tags.md in `Talk/Prompts.swift` and `Core/Logic/Router.swift` (+ checks)

## Phase 7: US5 – text mode (P2)

- [ ] T015 [US5] `Companion/TextModeField.swift` opened by the `textMode` action. Return sends through ChatRouter. Esc closes

## Phase 8: US6 – Cursor settings (P2)

- [ ] T016 [US6] `Settings/CursorPage.swift` (4 SelectableCards with glowing triangles, Dock cursor toggle). Mark the page available
- [ ] T017 [US6] Docked mode: stop following, show in the notch right slot (003 `NotchCollapsedView`)

## Phase 9: Polish

- [ ] T018 Apply `showInScreenRecordings` to companion/bubble/drawing/text windows
- [ ] T019 Run quickstart.md and record the results (incl. pointing accuracy)

## Dependencies

Setup → Foundational → US1 → US2 → US3 → (US4 ∥ US5 ∥ US6) → Polish.
