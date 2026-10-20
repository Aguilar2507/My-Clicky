---
description: "Tasks for 006-cursor-companion"
---

# Tasks: Cursor Companion

**Input**: `specs/006-cursor-companion/` · **Tests**: Core checks required

## Phase 1: Setup

- [X] T001 Add `cursorColor`, `cursorDocked` to `Settings.swift`
- [X] T002 Rename `Companion/Overlay.swift` into `CompanionController.swift`, `CompanionWindow.swift`,
      `BubbleLayer.swift` (split, no behavior change). Run `swift build`

## Phase 2: Foundational

- [X] T003 [P] `MyClickyCore/Logic/ScreenTags.swift` (POINT + DRAW, streaming-safe visible text). Remove Core `PointTag`
- [X] T004 [P] `MyClickyCore/Logic/CompanionMotion.swift` (spring step, offset + edge flip, arc control point)
- [X] T005 [P] `MyClickyCore/Logic/ScreenMapping.swift` (moved from `Screenshot.globalPoint`)
- [X] T006 [P] `MyClickyChecks/CompanionChecks.swift`: all tag shapes, invalid/partial tags, extras capped, spring
      converges, edge flip at each screen edge, mapping round trip

## Phase 3: US1 – follow + states (P1) 🎯

- [X] T007 [US1] `Companion/CompanionLayer.swift` (triangle, glow, idle/listening/thinking/speaking animations)
- [X] T008 [US1] Display-link follow loop in `CompanionController` (start on mouse move, stop when settled). Cross-display handoff
- [X] T009 [US1] Wire states from the talk flow (`Assistant`) and mic level from `SpeechRecognizer`. Hide over the open notch panel

## Phase 4: US2 – bubble (P1)

- [X] T010 [US2] `BubbleLayer` beside the companion, text updated per spoken sentence, 3 s fade, dismissed on push-to-talk

## Phase 5: US3 – pointing flight (P1)

- [X] T011 [US3] Companion flight to a POINT mark (arc, label, 6 s / proximity return). Delete the v0.1 blue arrow code
- [X] T012 [US3] Docked flight: from the notch's right slot and back

## Phase 6: US4 – drawings (P2)

- [X] T013 [US4] `Companion/DrawingLayer.swift` (stroke animation, wobble, 8 s fade, clear on push-to-talk)
- [X] T014 [US4] Prompt + router additions per contracts/screen-tags.md in `Talk/Prompts.swift` and `Core/Logic/Router.swift` (+ checks)

## Phase 7: US5 – text mode (P2)

- [X] T015 [US5] `Companion/TextModeField.swift` opened by the `textMode` action. Return sends through ChatRouter. Esc closes

## Phase 8: US6 – Cursor settings (P2)

- [X] T016 [US6] `Settings/CursorPage.swift` (4 SelectableCards with glowing triangles, Dock cursor toggle). Mark the page available
- [X] T017 [US6] Docked mode: stop following, show in the notch right slot (003 `NotchCollapsedView`)

## Phase 9: Polish

- [X] T018 Apply `showInScreenRecordings` to companion/bubble/drawing/text windows
- [ ] T019 Run quickstart.md and record the results (incl. pointing accuracy)

## Dependencies

Setup → Foundational → US1 → US2 → US3 → (US4 ∥ US5 ∥ US6) → Polish.

## Implementation notes

Implemented 2026-09-25. `swift build` ✓, checks: 6 companion groups (26 checks) pass; 192 total.

- **Found by the checks**: the first spring (step-by-step integration) overshot and went unstable at 30–60 fps.
  `CompanionSpring` now uses the exact critically-damped solution (stable for any frame time), with a softer
  0.25 s response.
- `PointTag` was removed from Core; `ScreenTags` parses POINT and DRAW (the 002 point-tag checks now use it).
- Snapshots: `settings-cursor` matches ref 08 (after two fixes found in snapshots: the glow rendered as a solid
  disc, and the triangle's angle); `companion` (a demo of the layers) shows the triangle, answer bubble, "Export"
  label pill and a hand-drawn circle. The same triangle angle is now used in the notch, the page and the live companion.
- Cross-display flights move straight across instead of fading out/in (research R3 said fade); simpler and still smooth.
- Extra files: `Companion/CompanionDemo.swift` (snapshot scene). `BubbleLayer` and `LabelPillLayer` live in
  `Companion/CompanionLayer.swift`. The listening pulse uses a new mic-level callback in `SpeechRecognizer`.
- **T019 not done**: needs the running app (follow smoothness and CPU, pointing accuracy on real apps, drawings,
  text mode, docking). → **Needs you.**

### Follow-up 2026-09-29: listening waves

Small change (your request): while listening (push-to-talk and dictation), the companion morphs into sound waves in
its color (`WaveformLayer` in `Companion/CompanionLayer.swift`, 9 rounded bars, pattern from your reference image).
The bars follow the mic level and breathe on their own rhythm in silence; they morph back into the cursor when
listening ends. Reduce Motion: a cross-fade and no breathing (bars still follow the level). Snapshot:
`companion-listening`.
