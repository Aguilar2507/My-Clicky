---
description: "Tasks for 004-settings-shell"
---

# Tasks: Settings Shell, General and Shortcuts

**Input**: `specs/004-settings-shell/` · **Tests**: Core checks required

## Phase 1: Setup

- [X] T001 Create `Sources/MyClicky/Settings/` and `Sources/MyClicky/Input/`
- [X] T002 Add `profileName`, `showInScreenRecordings`, `shortcuts` to `Settings.swift` (tolerant decode, defaults)
- [X] T003 Add `NSInputMonitoringUsageDescription`-style wording to README/GUIDE (macOS has no plist key for it;
      explain the prompt), and update `Resources/Info.plist` version to 0.2.0 (2)

## Phase 2: Foundational

- [X] T004 [P] `MyClickyCore/Models/Shortcut.swift` (Action, Modifier, KeyChord, Gesture, defaults, conflict check)
- [X] T005 [P] `MyClickyCore/Logic/ShortcutMatcher.swift` per research R3
- [X] T006 [P] `MyClickyCore/Logic/KeyCapLabels.swift`
- [X] T007 [P] `MyClickyChecks/ShortcutChecks.swift`: hold began/ended, cancelled by a key, double-tap timing
      window, hold-vs-double-tap prefix (⌃fn vs ⌃fn⌃fn), combos, conflicts, labels
- [X] T008 `Input/HotkeyTap.swift` (tap creation, re-enable, swallow rules) + `Input/ShortcutCenter.swift` (actions → AppModel)
- [X] T009 Replace the ⌃⌥ monitor in `App/AppDelegate.swift` with `ShortcutCenter`. pushToTalk drives the existing talk flow

**Checkpoint**: hold fn talks. The old ⌃⌥ is gone.

## Phase 3: US1 – settings shell (P1) 🎯

- [X] T010 [US1] `Settings/SettingsPage.swift` (pages, groups, titles, subtitles, symbols, availability)
- [X] T011 [US1] `Settings/SettingsView.swift` + `SettingsSidebar.swift` per contracts/ui-settings.md
- [X] T012 [US1] `Settings/ProfileCard.swift` (initial, name edit sheet, spend badge from UsageStore)
- [X] T013 [US1] Routing in `Home/HomeRoot.swift` (`.home` / `.settings(page)`, Back restores). Right-click "Settings…" opens it

## Phase 4: US2 – General page (P1)

- [X] T014 [US2] `Settings/GeneralPage.swift`: BEHAVIOR toggles (Dock via `DockPolicy`, screen recordings via a
      `WindowSharing` helper applied to all MyClicky windows)
- [X] T015 [US2] ANTHROPIC row: masked key + Change sheet (reuses `Keychain`)
- [X] T016 [US2] PERMISSIONS rows (mic, speech, screen, accessibility, input monitoring) with status + Open buttons
- [X] T017 [US2] VERSION rows + `Settings/WhatsNewSheet.swift`. Create `Resources/CHANGELOG.md`. `build.sh` copies it
- [X] T018 [US2] Remove the v0.1 status item and its menu from `App/AppDelegate.swift` (completes 003 FR-009)

## Phase 5: US3 – Shortcuts page (P1)

- [X] T019 [US3] `Settings/ShortcutsPage.swift`: 4 rows with key caps + Change, Reset to defaults
- [X] T020 [US3] `Settings/ShortcutRecorder.swift`: capture hold/double-tap/combo, Esc cancels, conflict message
- [X] T021 [US3] `Input/FnKeyAdvisor.swift` warning row + Keyboard settings button
- [X] T022 [US3] Permission banner when Accessibility or Input Monitoring is missing

## Phase 6: Polish

- [X] T023 Update `README.md`/`GUIDE.md`: new keys (fn, double ⌃), Settings location, Input Monitoring permission
- [ ] T024 Run quickstart.md and fill in its Notes

## Dependencies

Setup → Foundational → US1 → (US2 ∥ US3) → Polish. T018 must come after T015–T016 (nothing is lost when the menu goes).

## Implementation notes

Implemented 2026-09-25. `swift build` ✓, checks: 7 shortcut/settings groups (37 checks) pass; 129 total.

- Snapshots `settings-general` and `settings-shortcuts` match refs 03/07 (MyClicky wording; API key + Permissions
  sections instead of Updates/Community, as the spec lists). A row-wrapping bug (key caps and "Change" breaking
  onto two lines) was found in the snapshot and fixed (`SettingsRow` trailing controls are fixed-size).
- **Real finding on this Mac**: the Shortcuts page shows the fn warning because "Press 🌐 key to" is currently
  "Show Emoji & Symbols". Set it to "Do Nothing" before using fn push-to-talk.
- Modifier events are never swallowed (only `press` combo keys), so other apps never get stuck modifiers. This is a
  simplification of research R1 and is noted there.
- Forms (API key, name, shortcut recorder, What's new) are in-panel `ModalCard`s instead of sheets (sheets are
  unreliable in a non-activating panel).
- Double-tap Control opens the v0.1 "Ask MyClicky" box until 006 adds the field beside the cursor.
- File placement: the recorder UI (`ShortcutRecorderView`) lives in `Settings/ShortcutsPage.swift`, and
  `WhatsNewSheet` + `APIKeyEditor` live in `Settings/GeneralPage.swift`.
- Extra helpers: `App/AppServices.swift` (route + services), `App/Permissions.swift`, `DesignSystem/ModalCard.swift`,
  `Settings/SettingsView.swift`.
- **T024 not done**: needs the running app (grant Input Monitoring, hold fn, rebind keys, 5-minute typing test,
  screen-recording exclusion test on macOS 27). → **Needs you.**

**Bug found at first real use (2026-09-26):** ⌘C/⌘V/⌘X/⌘A/⌘Z did nothing in any text box. Mac apps get these from the
Edit menu, and MyClicky has no menu bar; also the notch panel is non-activating, so a menu wouldn't receive them. Fixed
with `App/EditShortcuts.swift` (a local key monitor that sends cut/copy/paste/selectAll/undo/redo to the focused text
box). The API key boxes (General → API key, tour step) now use `SecretField`: eye button to show/hide, plus Paste.
New snapshot: `welcome-apikey`.

**"⌃⌥ does nothing" (2026-09-26):** the shortcut setting was right (⌃⌥ hold, settings v5). The cause was permissions: the
new `App/Log.swift` diagnostic log showed `accessibility=false inputMonitoring=false` at launch. Every rebuild with the
ad-hoc signature makes macOS stop trusting the app, even though System Settings still shows MyClicky switched on. Fix:
remove MyClicky from Accessibility and Input Monitoring (−), add it back, reopen. Lasting fix: build with a self-signed
certificate (`SIGN_IDENTITY="MyClicky Dev" ./build.sh`, README). The log also records every shortcut event:
`/usr/bin/log show --last 10m --predicate 'subsystem == "com.myclicky.app"'` (in zsh, plain `log` is a shell builtin).
macOS 27 renamed Privacy & Security → **Accessibility** to **Device Control and Data Access** (Spanish: "Control de
dispositivos y acceso a datos"); Input Monitoring and Screen Recording keep their names. `Permission.accessibilityName`
shows the right name per macOS version; README/GUIDE updated.
**Stable signature (2026-09-26):** created a self-signed code-signing certificate "MyClicky Dev" (RSA 2048, 10 years,
codeSigning only) in the login keychain, trusted for code signing, with codesign allowed to use its key. `build.sh`
picks it automatically (falls back to ad-hoc) and prints which one it used. Designated requirement is now
`identifier "com.myclicky.app" and certificate leaf = H"d406…e16f"`, the same on every build, so permissions persist.
