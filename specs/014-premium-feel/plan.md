# Implementation Plan: Premium Feel

**Branch**: `014-premium-feel` | **Date**: 2026-09-29 | **Spec**: [spec.md](spec.md) | **Cost**: none

## Summary

Apply the apple-design skill to MyClicky without moving anything: a shared **motion** set (critically damped springs,
one bouncy spring for toggles, reduce-motion cross-fades), **press and hover feedback** on every control, **navy
glass materials** for floating surfaces, one **type scale** with size-specific tracking, live **accessibility**
adaptation (Reduce Motion, Reduce Transparency, Increase Contrast), and restrained **haptics**. Almost everything lands
in `DesignSystem/`, so screens pick it up through the components they already use; the rest is a mechanical sweep of
font calls and animations.

## Technical Context

**Language/Version**: Swift 6 (SwiftPM, Command Line Tools only)
**Primary Dependencies**: SwiftUI, AppKit (`NSVisualEffectView`, `NSHapticFeedbackManager`, `NSWorkspace`
accessibility options), Core Animation (`CASpringAnimation` for the companion bubble)
**Storage**: `settings.json`, one new field `hapticFeedback` (default `true`, filled in by `TolerantDecoder`)
**Testing**: `swift run MyClickyChecks` (pure logic: motion parameters, type scale table, direction of tour steps);
`--snapshot` renders; manual quickstart in the running app
**Target Platform**: macOS 14+ (developed on macOS 27), Apple Silicon
**Project Type**: desktop app (notch panel, companion overlay, windows)
**Performance Goals**: 60/120 fps motion; no new idle timers; blur only on visible floating surfaces
**Constraints**: no `@State` (use `Box`); stroked capsules → `BorderedCapsule`; colors only from `Theme`/`Brand`;
snapshots can't draw live blur → solid fallback; layout and wording unchanged (Principle VIII)
**Scale/Scope**: ~140 font calls, 9 animation sites, ~40 `.buttonStyle(.plain)` rows/cards, 4 floating surfaces

## Constitution Check

| Principle | Check | Result |
|---|---|---|
| I. Cost First | No API requests. No new background work: loops run only while their view is on screen. | ✅ |
| II. Free & On-Device First | Only system frameworks. No libraries, fonts or assets downloaded. | ✅ |
| III. Personal, Single-User | No accounts. One local preference. | ✅ |
| IV. Privacy by Default | No data leaves the Mac. Glass surfaces keep honoring "Show in screen recordings". | ✅ |
| V. Agent Safety | Allow cards unchanged; press feedback never auto-fires actions (release still commits). | ✅ |
| VI. Native Simplicity | Native springs, materials and accessibility flags instead of custom physics. Gesture physics (momentum, rubber-banding) left out: nothing in the app is dragged. | ✅ |
| VII. Verifiable Changes | New checks for motion/type tables; snapshots re-rendered; quickstart covers the three accessibility modes. | ✅ |
| VIII. HeyClicky Parity | Layout, sizes and wording unchanged; deviations listed in the spec (motion/material/type polish, haptics). | ✅ |

Post-design re-check: unchanged, all ✅. The new `hapticFeedback` setting has a default and resets nothing.

## Approach

1. **Tokens (`DesignSystem/`)**
   - `Motion.swift`: `Motion.standard` (response 0.35, damping 1.0), `.quick` (0.2, 1.0), `.bouncy` (0.35, 0.8),
     `.fade` (0.18 s ease-out, reduce-motion only). `Motion.animation(_:)` swaps any motion for `.fade` when Reduce
     Motion is on. Transitions: `.materialize` (scale 0.96 + blur 6 + opacity), `.slide(forward:)` (push along x),
     `.growFrom(anchor)`; each degrades to opacity with Reduce Motion.
   - `DisplayPrefs.swift`: `@Observable` singleton mirroring `NSWorkspace` `accessibilityDisplayShouldReduceMotion /
     …ReduceTransparency / …IncreaseContrast`, refreshed on `accessibilityDisplayOptionsDidChangeNotification`, plus
     `forceSolid` for snapshots. Observation tracks reads, so `Theme` tokens that read it update views live.
   - `Typography.swift`: `TextStyle` (largeTitle 28, title1 26, title2 22, title3 20, headline 17 semibold, body 17,
     callout 15, subheadline 14, footnote 13, caption 12, caption2 11, label 12 semibold uppercase) with tracking and
     line spacing; `.textStyle(_:)` modifier. Icon sizes as `Theme.IconSize`.
   - `Materials.swift`: `GlassSurface` (behind-window `NSVisualEffectView`, dark, + navy tint + top-edge highlight +
     shadow token), `.glass(_ weight:)` modifier; solid navy when Reduce Transparency or `forceSolid`.
     `.scrollEdgeFade()` mask. Shadow tokens `Theme.Shadow.small/medium/large`, radii `Theme.Radius`, spacing
     `Theme.Space` (4-pt grid).
   - `Feedback.swift`: press modifier (scale 0.97 + brightness, `Motion.quick`), `PressableButtonStyle` for
     cards/rows that use `.plain` today, `.hoverHighlight()`, `FeedbackKind` (status/completion/warning/error:
     color + SF Symbol), `Haptics.tap()` gated by the setting.
2. **Components**: `PillButtonStyle`, `CircleIconButtonStyle`, `GlossyToggleStyle` (bouncy knob + haptic),
   `SelectableCard` (animated outline/badge, hover), `SettingsCard`/`SettingsRow`/`SectionLabel`/`PageHeader`
   (type scale, contrast-aware borders), `ModalCard` (glass + materialize + dim), `KeyCap`, `SecretField`.
3. **Surfaces**: notch panel (glass under the bloom, content transitions on `Motion`), companion bubble
   (`NSVisualEffectView` host sized to the bubble, grow-from-cursor `CASpringAnimation`), text-mode field (glass +
   materialize), sidebar (heavier material), headers (edge fade instead of dividers).
4. **Sweep**: every `.font(.system(size:))` on text → `.textStyle`; every animation → `Motion`; row/card buttons →
   `.pressable`; `.onHover` highlights on lists.
5. **Tour**: step changes slide in the direction of travel (`TourFlow` order decides), intro carousel symmetric.
6. **Haptics**: push-to-talk begin/end, toggles, agent finished; Settings → General → Behavior switch.
7. **Bot**: `LivelyBot` stops floating and blinks every 8 s with Reduce Motion.

## Project Structure

### Documentation (this feature)

```text
specs/014-premium-feel/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/design-system.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code

```text
Sources/MyClicky/DesignSystem/   Motion, DisplayPrefs, Typography, Materials, Feedback (new); components updated
Sources/MyClicky/Notch/          NotchContainerView (glass, motion)
Sources/MyClicky/Companion/      CompanionLayer, CompanionWindow, TextModeField (glass, spring entrance)
Sources/MyClicky/**/             font + animation + button-style sweep
Sources/MyClickyCore/Models/     Settings.hapticFeedback; MotionSpec/TypeScale tables (checkable)
Sources/MyClickyChecks/          PremiumFeelChecks
```

**Structure Decision**: same single-package layout. Pure tables that can be checked (motion parameters, type scale,
step direction) live in `MyClickyCore`; SwiftUI/AppKit bits stay in `MyClicky`.

## Complexity Tracking

None. No principle is bent.
