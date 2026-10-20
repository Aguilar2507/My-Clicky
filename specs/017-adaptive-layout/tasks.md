---
description: "Tasks for 017-adaptive-layout"
---

# Tasks: Adaptive Layout and Home Header

Plan: `AppModel.goHome()` + `isWindowFullScreen` (set by `PopOutWindowController`'s full-screen delegate calls);
`WindowControlsRow` owns its padding and collapses in full screen; new `SidebarBrand`; centered max-width columns in
`SettingsView` and `ConversationView`/`Composer`; adaptive voice grid; wide snapshots. Constitution: no API, data or
permission change ✅.

- [X] T001 `App/AppModel.swift`: `goHome()`, `isWindowFullScreen`
- [X] T002 `Notch/PopOutWindowController.swift`: track full screen
- [X] T003 [US1] `DesignSystem/WindowControls.swift`: row padding inside, collapses in full screen
- [X] T004 [US2] `DesignSystem/WindowControls.swift`: `SidebarBrand` (logo + name, goes home); both sidebars
- [X] T005 [US1] `Settings/SettingsView.swift`: centered 720 pt column
- [X] T006 [US1] `Home/Conversation/*`: centered 820 pt column for messages and composer; header's old chrome padding
- [X] T007 [US1] `Settings/VoicePage.swift`: adaptive grid
- [X] T008 Snapshots at full-screen size (`*-wide`), checks, docs
- [X] T009 Try full screen and the header (you)

## Implementation notes

Implemented 2026-09-29. `swift build` ✓, 426 checks pass, screens re-rendered plus `home-wide`, `conversation-wide`,
`settings-general-wide`, `settings-voice-wide` (1728×1080, window mode in full screen).

- **Header instead of an extra row:** the Settings sidebar is 209 pt wide and nearly full, so the logo shares the
  window-buttons row (like macOS 26 apps put the title after the buttons). Notch: dots + logo (+ name in Home). Window:
  the row keeps room for macOS's buttons, measured from the real buttons (`windowButtonsFrame`), and lines up with
  their center. Full screen: no buttons, so the logo and name start at the edge.
- **Home** = `AppModel.goHome()`: closes Settings and the Spending sheet and deselects the chat (the greeting).
- **Columns:** `Theme.Layout.settingsColumn` 720, `conversationColumn` 820; the chat header, messages and composer
  share the column. The chat header lost the 150 pt it still reserved for 015's removed top-right icons.
- The notch panel keeps its fixed size (HeyClicky parity); the welcome window stays 720×600 (a setup window).
