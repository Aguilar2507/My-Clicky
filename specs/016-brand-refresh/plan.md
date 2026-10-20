# Implementation Plan: Brand Refresh

**Spec**: [spec.md](spec.md) · **Cost**: none · Constitution: I–VII unaffected (no API, data or permissions);
VIII deviations listed in the spec. ✅

## Approach

`DesignSystem/Brand.swift` is rewritten; its public views keep their names so screens don't change:

- **Palette** (`Brand`): sky `#64D2FF`, blue `#0A84FF`, indigo `#5E5CE6`, purple `#BF5AF2`, plus the old 013 colors
  kept for reference. `Brand.bodyGradient` is the shared glass gradient.
- **`GlassSolid`**: renders a shape as a lit 3D glass solid: base gradient (light top-left → deep bottom-right),
  inner core glow, ambient occlusion at the bottom, bounce light, broad soft highlight, sharp specular, rim light
  stroke. Replaces the neon `GlassMaterial`.
- **`AppLogo`**: light squircle tile (white→#E8ECF3, inner highlight, bottom edge, macOS grid 824/1024, drop shadow);
  side-facing cursor `GlassSolid` with a soft blue cast shadow; white "^ ^" eyes; three glossy dashes.
- **`GlassBot`**: body `GlassSolid`, face plate (dark glass rounded rect with its own highlight), eyes (open, closed,
  happy, wide, looking) with a soft glow, optional mouth, blush, glossy feet, contact shadow. Parameters: `blink`,
  `look` (−1…1 x/y), `mood`, `mouth`, `squash`.
- **`LivelyBot`**: `TimelineView` driving breath, float, tilt, pseudo-random blinks, pointer-following eyes (the
  bot's screen frame from a tiny `NSViewRepresentable` probe + `NSEvent.mouseLocation`), a hop on hover (spring) and
  `AppModel.talkState` moods. Reduce Motion: static pose, blink every 8 s.
- **`BotAvatar`/`ChatAvatar`**: gradient circle from the chat color (light top, deeper bottom), white glass bot
  (`GlassBot(style: .white)`), inner hairline; Talk = cursor glyph on the blue→indigo gradient.
- Snapshots: `bot` on light gray, `bot-dark`; `make-icon.sh` regenerates `AppIcon.icns`.
