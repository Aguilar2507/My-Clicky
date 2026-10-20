# Implementation Plan: Apple Look

**Branch**: `015-apple-look` | **Date**: 2026-09-29 | **Spec**: [spec.md](spec.md) | **Cost**: none

## Summary

Swap the navy palette for appearance-aware system colors in `Theme` (so every screen follows through the tokens it
already uses), flatten the components to Apple's style with hover states and red/green confirmation buttons, use the
native switch, and add window controls: real traffic lights on the pop-out window and a matching row in the notch.

## Technical Context

**Language/Version**: Swift 6 (SwiftPM, Swift 5 mode) · **Dependencies**: SwiftUI, AppKit
**Storage**: none · **Testing**: `swift run MyClickyChecks` (unchanged logic), snapshots in Light Mode, quickstart
**Constraints**: no `@State` (`Box`); `BorderedCapsule` for capsule borders; tokens only; snapshots can't draw blur

## Constitution Check

| Principle | Result |
|---|---|
| I Cost, II Free, III Single user, IV Privacy, V Agent safety | ✅ No API, data or permission changes |
| VI Native simplicity | ✅ More native: system colors, system switch, real window buttons |
| VII Verifiable | ✅ Snapshots re-rendered; quickstart covers both appearances and the window buttons |
| VIII HeyClicky parity | ✅ Deviations listed in the spec (appearance, window controls, accent) |

## Approach

1. **Theme** (`DesignSystem/Theme.swift`): dynamic colors via `NSColor(name:dynamicProvider:)` or system `NSColor`s:
   window/content/sidebar/card/modal backgrounds, `labelColor` family for text, `separatorColor` for borders, system
   accent, system green/orange/red. `bloomBackground` → `contentBackground` (no bloom); `accentGradient` → `accentFill`.
   Increase Contrast comes from the system colors themselves.
2. **Components**: `PillButtonStyle` flat capsules with hover (`.primary`, `.secondary`, `.destructive`, `.safe`);
   `CircleIconButtonStyle` destructive hover; `GlossyToggleStyle` → native `.switch` + haptic; `SelectableCard`,
   `SettingsCard`, `ModalCard`, `KeyCap`, hover highlight adapt to both appearances.
3. **Window controls**: `WindowControls` environment value (`.notch(actions)` / `.window`), `TrafficLights` view,
   `WindowControlsRow` at the top of both sidebars. `PopOutWindowController`: miniaturizable, real buttons visible,
   full-screen capable, `show(fullScreen:)`. `NotchController`: red/yellow collapse, green pops out full screen.
   `HomeChrome`'s top-right icons are removed.
4. **Appearance**: remove every forced `.dark`/`darkAqua`; AppKit surfaces (bubble, text box, agent chip) use
   `.popover` material with the system appearance and label colors resolved on show.
5. **Sweep**: white/black literals → tokens; user bubbles accent + white; black top fades removed; greeting pill flat
   accent.
6. **Snapshots**: Light Mode.

## Structure

`Sources/MyClicky/DesignSystem/` (Theme, PillButton, GlossyToggle, SelectableCard, SettingsCard, ModalCard, Materials,
Feedback, new `WindowControls.swift`), `Notch/`, `Home/`, `Settings/`, `Onboarding/`, `Companion/`, `Agents/`,
`App/Snapshot.swift`.
