---
description: "Tasks for 004-settings-shell"
---

# Tasks: Settings Shell, General and Shortcuts

**Input**: `specs/004-settings-shell/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 Create `Sources/MyClicky/Settings/` and `Sources/MyClicky/Input/`
- [ ] T002 Add `profileName`, `showInScreenRecordings`, `shortcuts` to `Settings.swift` (tolerant decode, defaults)
- [ ] T003 Add `NSInputMonitoringUsageDescription`-style wording to README/GUIDE (macOS has no plist key for it;
      explain the prompt), and update `Resources/Info.plist` version to 0.2.0 (2)

## Phase 2: Foundational

- [ ] T004 [P] `MyClickyCore/Models/Shortcut.swift` (Action, Modifier, KeyChord, Gesture, defaults, conflict check)
- [ ] T005 [P] `MyClickyCore/Logic/ShortcutMatcher.swift` per research R3
- [ ] T006 [P] `MyClickyCore/Logic/KeyCapLabels.swift`
- [ ] T007 [P] `MyClickyChecks/ShortcutChecks.swift`: hold began/ended, cancelled by a key, double-tap timing
      window, hold-vs-double-tap prefix (⌃fn vs ⌃fn⌃fn), combos, conflicts, labels
- [ ] T008 `Input/HotkeyTap.swift` (tap creation, re-enable, swallow rules) + `Input/ShortcutCenter.swift` (actions → AppModel)
- [ ] T009 Replace the ⌃⌥ monitor in `App/AppDelegate.swift` with `ShortcutCenter`. pushToTalk drives the existing talk flow

**Checkpoint**: hold fn talks. The old ⌃⌥ is gone.

## Phase 3: US1 – settings shell (P1) 🎯

- [ ] T010 [US1] `Settings/SettingsPage.swift` (pages, groups, titles, subtitles, symbols, availability)
- [ ] T011 [US1] `Settings/SettingsView.swift` + `SettingsSidebar.swift` per contracts/ui-settings.md
- [ ] T012 [US1] `Settings/ProfileCard.swift` (initial, name edit sheet, spend badge from UsageStore)
- [ ] T013 [US1] Routing in `Home/HomeRoot.swift` (`.home` / `.settings(page)`, Back restores). Right-click "Settings…" opens it

## Phase 4: US2 – General page (P1)

- [ ] T014 [US2] `Settings/GeneralPage.swift`: BEHAVIOR toggles (Dock via `DockPolicy`, screen recordings via a
      `WindowSharing` helper applied to all MyClicky windows)
- [ ] T015 [US2] ANTHROPIC row: masked key + Change sheet (reuses `Keychain`)
- [ ] T016 [US2] PERMISSIONS rows (mic, speech, screen, accessibility, input monitoring) with status + Open buttons
- [ ] T017 [US2] VERSION rows + `Settings/WhatsNewSheet.swift`. Create `Resources/CHANGELOG.md`. `build.sh` copies it
- [ ] T018 [US2] Remove the v0.1 status item and its menu from `App/AppDelegate.swift` (completes 003 FR-009)

## Phase 5: US3 – Shortcuts page (P1)

- [ ] T019 [US3] `Settings/ShortcutsPage.swift`: 4 rows with key caps + Change, Reset to defaults
- [ ] T020 [US3] `Settings/ShortcutRecorder.swift`: capture hold/double-tap/combo, Esc cancels, conflict message
- [ ] T021 [US3] `Input/FnKeyAdvisor.swift` warning row + Keyboard settings button
- [ ] T022 [US3] Permission banner when Accessibility or Input Monitoring is missing

## Phase 6: Polish

- [ ] T023 Update `README.md`/`GUIDE.md`: new keys (fn, double ⌃), Settings location, Input Monitoring permission
- [ ] T024 Run quickstart.md and fill in its Notes

## Dependencies

Setup → Foundational → US1 → (US2 ∥ US3) → Polish. T018 must come after T015–T016 (nothing is lost when the menu goes).
