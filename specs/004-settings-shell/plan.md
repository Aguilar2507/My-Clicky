# Implementation Plan: Settings Shell, General and Shortcuts

**Branch**: `004-settings-shell` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

`HomeRoot` gains a route (`.home` / `.settings(page)`). `SettingsView` is a two-column SwiftUI layout built from
the 002 design system. Pages register themselves in a `SettingsPage` enum with an `isAvailable` flag. A new
**input engine** replaces the ⌃⌥ `NSEvent` monitor: a CGEvent tap feeds a pure `ShortcutMatcher` (Core) that
emits `began/ended/triggered` per action. The v0.1 status item is removed.

## Technical Context

**Language/Version**: Swift 6.4 (Swift 5 mode)

**Primary Dependencies**: SwiftUI, AppKit, CoreGraphics (CGEvent tap), ApplicationServices (AX trust), Security (Keychain)

**Storage**: settings: `profileName`, `showInScreenRecordings` (true), `shortcuts` ([Binding]). The key stays in Keychain

**Testing**: `ShortcutMatcher` and binding encode/decode checks. Manual quickstart for UI and permissions

**Performance Goals**: hold detection < 100 ms; the tap callback does < 1 ms of work (it forwards to the main actor)

**Constraints**: the tap must be re-enabled if macOS disables it (timeout/user input); never swallow regular typing

## Constitution Check

| Principle | Check |
|---|---|
| I | ✅ Cost impact: none. Spend badge reads UsageStore |
| II | ✅ Apple APIs only |
| III | ✅ Local profile, no account |
| IV | ✅ API key only in Keychain; masked display |
| V | n/a |
| VI | ✅ Matcher is pure Core logic |
| VII | ✅ Matcher checks cover hold, double-tap, combos, conflicts |
| VIII | ✅ Layout/wording from refs 03 and 07. Deviations listed |

New permission: **Input Monitoring** (listening to keyboard events in other apps). Justified by FR-007 and
described in Info.plist. The General page shows its status.

## Project Structure

```text
Sources/MyClickyCore/Models/Shortcut.swift          # Action enum, KeyChord (modifiers + optional keyCode), Gesture (hold/doubleTap), defaults
Sources/MyClickyCore/Logic/ShortcutMatcher.swift    # input events → action events (pure, time-injected)
Sources/MyClickyCore/Logic/KeyCapLabels.swift       # chord → ["⌃ control", "fn"] labels
Sources/MyClicky/Input/HotkeyTap.swift              # CGEvent tap (flagsChanged, keyDown, keyUp), re-enable on timeout
Sources/MyClicky/Input/ShortcutCenter.swift         # owns tap + matcher; publishes actions to AppModel
Sources/MyClicky/Input/FnKeyAdvisor.swift           # reads AppleFnUsageType; opens Keyboard settings
Sources/MyClicky/Settings/SettingsView.swift        # two-column shell, Back, footer version
Sources/MyClicky/Settings/SettingsSidebar.swift     # profile card + grouped items
Sources/MyClicky/Settings/ProfileCard.swift         # initial, name, spend badge, edit sheet
Sources/MyClicky/Settings/SettingsPage.swift        # enum of pages + availability
Sources/MyClicky/Settings/GeneralPage.swift
Sources/MyClicky/Settings/ShortcutsPage.swift
Sources/MyClicky/Settings/ShortcutRecorder.swift    # "Press new shortcut…" capture sheet
Sources/MyClicky/Settings/WhatsNewSheet.swift       # renders bundled CHANGELOG.md
Sources/MyClicky/Home/HomeRoot.swift                # + routing
Resources/CHANGELOG.md                              # copied into the app by build.sh
```
