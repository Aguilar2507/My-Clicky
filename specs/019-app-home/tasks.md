---
description: "Tasks for 019-app-home"
---

# Tasks: App Home Without the Notch

Plan: the pop-out window becomes the app's only home (`MainWindowController`, with `toggle()`); a new
`StatusItemController` owns the menu bar icon (bot template image, dot badge, click toggles, right-click menu moved
from `NotchController`); a new `ShortcutAction.openApp` (⌥Space, press) toggles the window; the notch code, geometry,
state, checks and setting are deleted; the docked companion and the morning ideas card anchor to the status item.
Constitution: I ✅ (no API), II ✅, III ✅, IV ✅ (no new data), VI ✅ (less code: notch tracking and hover timers go),
VII ✅ (checks + snapshots), VIII deviations listed ✅.

- [X] T001 [US2] `App/MainWindowController.swift` (from `Notch/PopOutWindowController.swift`): `show`, `toggle`, `hide`
- [X] T002 [US2] `showInDock` default on; Dock reopen shows the window; General page subtitle; drop "notch on all displays"
- [X] T003 [US3] `App/StatusItemController.swift`: bot template icon, dot badge (unread / agent running), click toggles,
  right-click menu (items moved from `NotchController.rightClick`)
- [X] T004 [US4] `ShortcutAction.openApp` (⌥Space press) + defaults + migration for saved settings; `AppDelegate` handles it
- [X] T005 [US1] Delete `Notch/` panel code, `NotchGeometry`, `NotchState`, `NotchChecks`; `isNotchOpen` → window;
  `WindowControls.notch` removed; `AppServices` holds the window/status item
- [X] T006 [US5] Docked companion and morning ideas card anchored to the menu bar icon
- [X] T007 [US5] Copy: onboarding, hints (`AppEvent`), Agents page, comments
- [X] T008 Snapshots use the window size; notch screens removed; re-render `docs/screens/`
- [X] T009 Docs: CLAUDE.md, specs/README.md, CHANGELOG, implementation report
- [X] T010 Try it (you): sweep the top edge, menu bar icon, ⌥Space, Dock on/off, a task finishing

## Implementation notes

Implemented 2026-10-01. `swift build` ✓, `swift run MyClickyChecks` → 434 passed (6 new: ⌥Space matching, shortcut
backfill, Dock migration; the 22 notch checks were removed with the notch). Screens re-rendered; `notch-*` removed,
`menubar-icon` added.

- **Window** (`App/MainWindowController.swift`, was `Notch/PopOutWindowController.swift`): `show`/`hide`/`toggle`.
  Hiding gives focus back to the app that was in front before the shortcut or icon; in full screen it minimizes. A
  frame saved on a disconnected display falls back to the center. Opens at launch when you start the app yourself,
  not when macOS starts it at login.
- **Menu bar icon** (`App/StatusItemController.swift`): `MenuBarBot` (body + visor cut out + "^ ^" eyes) rendered
  once as a template image; the dot shows for unread Clickys, a running agent, or unfinished setup (it replaces the
  notch's unread badge, activity dots and orange setup dot). `anchorRect` is where the morning ideas card and the
  docked companion's flights start.
- **Shortcut**: `ShortcutAction.openApp`, ⌥Space press (swallowed). Saved settings without it get it through
  `ShortcutBinding.normalized`; the Shortcuts page has a new "Window" section.
- **Settings v6**: `notchOnAllDisplays` removed (unknown keys are ignored by `TolerantDecoder`); `showInDock` default
  on, and turned on once for existing users.
- **Removed**: `Notch/` (controller, panel, shape, collapsed view), `NotchGeometry`, `NotchState`, `NotchChecks`,
  `WindowControls.notch` and the drawn traffic lights, `AppModel.isNotchOpen`/`dockedCompanionColor`. Kept views
  that other screens use (`ActivityDots`, `CompanionTriangle`) in `DesignSystem/Indicators.swift`.
- `AppEvent.notchExpanded` → `.appOpened` (raw value kept), emitted whenever the window shows.
