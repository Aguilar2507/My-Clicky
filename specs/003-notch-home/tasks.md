---
description: "Tasks for 003-notch-home"
---

# Tasks: Notch Home

**Input**: `specs/003-notch-home/` · **Tests**: Core checks required (Principle VII)

## Phase 1: Setup

- [ ] T001 Create `Sources/MyClicky/Notch/` and `Sources/MyClicky/Home/`
- [ ] T002 Add `showInDock`, `notchOnAllDisplays` to `Sources/MyClickyCore/Models/Settings.swift` (tolerant decode)

## Phase 2: Foundational

- [ ] T003 [P] `Sources/MyClickyCore/Logic/NotchGeometry.swift` per data-model.md
- [ ] T004 [P] `Sources/MyClickyCore/Logic/NotchState.swift` transition function per data-model.md
- [ ] T005 [P] `Sources/MyClickyChecks/NotchChecks.swift`: notch vs pill rects, clamping, every transition row

## Phase 3: US1 – lives in the notch (P1) 🎯

- [ ] T006 [US1] `Notch/NotchShape.swift` (animatable width/height/radius, flared top corners)
- [ ] T007 [US1] `Notch/NotchPanel.swift` (level, collection behavior, canBecomeKey when expanded) per research R2
- [ ] T008 [US1] `Notch/NotchCollapsedView.swift`: badge (reads `AppModel.unreadCount`, 0 for now), right slot (activity/docked/empty)
- [ ] T009 [US1] `Notch/NotchController.swift`: one panel per screen, rebuild on `didChangeScreenParametersNotification`

## Phase 4: US2 – hover to open (P1)

- [ ] T010 [US2] Hover monitor + 150 ms rest + 500 ms grace in `NotchController` driven by `NotchState`
- [ ] T011 [US2] `Notch/NotchContainerView.swift`: grow/shrink animation, top fade, content fade-in, Esc + outside click
- [ ] T012 [US2] `Home/HomeRoot.swift`: placeholder greeting screen using `MascotAvatar` (replaced in 005)
- [ ] T013 [US2] `isBusy` plumbing (text focus/menu/sheet) so the panel doesn't fold while typing

## Phase 5: US3 – pop out / close (P2)

- [ ] T014 [US3] Pop-out and ✕ buttons in `NotchContainerView`
- [ ] T015 [US3] `Notch/PopOutWindowController.swift` (hidden titlebar, autosave frame, min 760×520), single-instance rule

## Phase 6: US4 – displays without a notch (P2)

- [ ] T016 [US4] Pill geometry on non-notch screens. Respect `notchOnAllDisplays`

## Phase 7: US5 – Dock + quit (P3)

- [ ] T017 [US5] `App/DockPolicy.swift`: activation policy from settings, reopen → pop-out window
- [ ] T018 [US5] Right-click menu on the collapsed shape (Open, Settings…, Quit)

## Phase 8: Polish

- [ ] T019 Keep the v0.1 status item until 004 lands (FR-009). It is removed by 004 T018
- [ ] T020 Run quickstart.md and record the results

## Dependencies

Setup → Foundational → US1 → US2 → (US3 ∥ US4 ∥ US5) → Polish.
