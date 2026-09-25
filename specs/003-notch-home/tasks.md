---
description: "Tasks for 003-notch-home"
---

# Tasks: Notch Home

**Input**: `specs/003-notch-home/` · **Tests**: Core checks required (Principle VII)

## Phase 1: Setup

- [X] T001 Create `Sources/MyClicky/Notch/` and `Sources/MyClicky/Home/`
- [X] T002 Add `showInDock`, `notchOnAllDisplays` to `Sources/MyClickyCore/Models/Settings.swift` (tolerant decode)

## Phase 2: Foundational

- [X] T003 [P] `Sources/MyClickyCore/Logic/NotchGeometry.swift` per data-model.md
- [X] T004 [P] `Sources/MyClickyCore/Logic/NotchState.swift` transition function per data-model.md
- [X] T005 [P] `Sources/MyClickyChecks/NotchChecks.swift`: notch vs pill rects, clamping, every transition row

## Phase 3: US1 – lives in the notch (P1) 🎯

- [X] T006 [US1] `Notch/NotchShape.swift` (animatable width/height/radius, flared top corners)
- [X] T007 [US1] `Notch/NotchPanel.swift` (level, collection behavior, canBecomeKey when expanded) per research R2
- [X] T008 [US1] `Notch/NotchCollapsedView.swift`: badge (reads `AppModel.unreadCount`, 0 for now), right slot (activity/docked/empty)
- [X] T009 [US1] `Notch/NotchController.swift`: one panel per screen, rebuild on `didChangeScreenParametersNotification`

## Phase 4: US2 – hover to open (P1)

- [X] T010 [US2] Hover monitor + 150 ms rest + 500 ms grace in `NotchController` driven by `NotchState`
- [X] T011 [US2] `Notch/NotchContainerView.swift`: grow/shrink animation, top fade, content fade-in, Esc + outside click
- [X] T012 [US2] `Home/HomeRoot.swift`: placeholder greeting screen using `MascotAvatar` (replaced in 005)
- [X] T013 [US2] `isBusy` plumbing (text focus/menu/sheet) so the panel doesn't fold while typing

## Phase 5: US3 – pop out / close (P2)

- [X] T014 [US3] Pop-out and ✕ buttons in `NotchContainerView`
- [X] T015 [US3] `Notch/PopOutWindowController.swift` (hidden titlebar, autosave frame, min 760×520), single-instance rule

## Phase 6: US4 – displays without a notch (P2)

- [X] T016 [US4] Pill geometry on non-notch screens. Respect `notchOnAllDisplays`

## Phase 7: US5 – Dock + quit (P3)

- [X] T017 [US5] `App/DockPolicy.swift`: activation policy from settings, reopen → pop-out window
- [X] T018 [US5] Right-click menu on the collapsed shape (Open, Settings…, Quit)

## Phase 8: Polish

- [X] T019 Keep the v0.1 status item until 004 lands (FR-009). It is removed by 004 T018
- [ ] T020 Run quickstart.md and record the results

## Dependencies

Setup → Foundational → US1 → US2 → (US3 ∥ US4 ∥ US5) → Polish.

## Implementation notes

Implemented 2026-09-25. `swift build` ✓, checks: Notch geometry (8) + Notch open/close rules (14) pass (92 total).

- Snapshots `notch-collapsed` and `notch-expanded` (`.build/debug/MyClicky --snapshot …`) match refs 01/02: black
  extension with the glossy "1" badge on the left wing; open panel with the top black fade, pop-out + ✕ chrome and
  rounded bottom corners.
- Added helpers not named in the plan: `App/Observe.swift` (`observeChanges`, re-arming Observation tracking),
  `App/Aliases.swift` (SwiftUI also defines `Settings`), `Notch/NotchPanelUI.swift` (per-display view state),
  `Home/HomeChrome.swift`, and `MenuAction` (closure-based menu items) in `NotchController.swift`.
- Right-click on the notch is detected with a global mouse monitor (the collapsed panel ignores the mouse so the
  menu bar keeps working underneath).
- `WindowSharing` (screen-recording exclusion) is wired to every panel now; the setting itself arrives in 004.
- **T020 not done**: the quickstart needs the app running on your Mac (hover timing, 5-minute no-accidental-open test,
  full-screen Spaces, external display, CPU in Activity Monitor). → **Needs you.**
