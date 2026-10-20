---
description: "Tasks for 016-brand-refresh"
---

# Tasks: Brand Refresh

- [X] T001 `DesignSystem/Brand.swift`: new palette + `GlassSolid` 3D glass renderer
- [X] T002 [US1] `AppLogo`: light squircle tile, glass cursor, eyes, dashes, shadows; `scripts/make-icon.sh`
- [X] T003 [US2] `GlassBot`: 3D body, face plate, eyes (moods), mouth, blush, feet, contact shadow, white style
- [X] T004 [US3] `LivelyBot`: breath, float, tilt, blinks, pointer-following eyes, hover hop, talk-state moods,
  Reduce Motion
- [X] T005 [US4] `BotAvatar`, `ChatAvatar` (Talk glyph), About logo
- [X] T006 Snapshots (`bot`, `bot-dark`, `app-icon`), compare renders at small sizes; re-render screens
- [X] T007 Docs: README visual language, CHANGELOG, report, 013 note
- [X] T008 Look at it installed (you)

## Implementation notes

Implemented 2026-09-29. `swift build` ✓, 426 checks pass, `AppIcon.icns` regenerated, screens re-rendered; new art
renders `app-icon`, `bot`, `bot-dark`, `avatars`.

- **Rendering:** `GlassSolid` stacks a lit gradient, a glowing core, ambient occlusion, form shading, an inner
  thickness edge, a light band on the lit edge, a violet rim light on the shadow side, bounce light, a broad highlight
  and a crisp specular. The old neon `GlassMaterial`/`GlowingEye` are gone.
- **One character:** the logo's cursor wears the bot's visor, so the icon, the bot and the Talk avatar match.
- **Performance** (measured with the new `MyClicky --bench-bot`, release build, % of one core while the bot is on
  screen): first version (a 60/30 fps `TimelineView` re-describing the whole bot) 10.6–12.4%; now 6.1%. What changed:
  the glass body and the dashes are rendered once (`.drawingGroup()`, padded so the head isn't clipped) and only moved;
  `GlassSolid` is `Equatable`; blinks, glances and hops are timer-driven events (`BotDriver`); float, breath, sway and
  the talking mouth are repeating animations SwiftUI interpolates without rebuilding the bot; the contact shadow is a
  gradient instead of a blur. Zero cost when the greeting isn't on screen (the notch collapsed removes it).
- **Pointer-following eyes** read the bot's screen position through a 1-view probe and `NSEvent.mouseLocation` 12×/s,
  and only animate when the target moves; no event monitors.
- The icon at 16 px shows a blue cursor with a dark face spot; the eyes appear from 32 px.
