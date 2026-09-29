---
description: "Tasks for 013-visual-identity"
---

# Tasks: Visual Identity

**Input**: `specs/013-visual-identity/` · **Tests**: visual (snapshots compared with the references); Core checks unchanged

## Phase 1: Setup

- [X] T001 Save the references in `references/myclicky/` (LOGO.png, BOT.png, visual-system.png; git-ignored)
- [X] T002 `Brand.swift`: palette tokens

## Phase 2: US1 – app icon (P1)

- [X] T003 [US1] `GlassMaterial`, `RoundedPolygon`, `GlowingEye`, `SparkleDashes`, `AppLogo`
- [X] T004 [US1] Artwork snapshots with `ImageRenderer` (`app-icon`, `bot`); compare side by side with LOGO.png
- [X] T005 [US1] `scripts/make-icon.sh` → `Resources/AppIcon.icns`; `build.sh` + `Info.plist` (`CFBundleIconFile`)

## Phase 3: US2 – bot (P1)

- [X] T006 [US2] `GlassBot` compared with BOT.png; `LivelyBot` (blink + float)
- [X] T007 [US2] Greeting: the bot standing on the pill (replaces the blob and paws)
- [X] T008 [US2] Welcome tour header, `BotAvatar` for Clickys, `AppLogo` for Talk, the sidebar and About
- [X] T009 [US2] Remove the old blob mascot (`MascotAvatar.swift`)

## Phase 4: US3 – palette (P2)

- [X] T010 [US3] `Theme` tokens in the palette; `lavender*` → `accent*`; bloom background on the home, settings and tour
- [X] T011 [US3] Controls: pill buttons, toggle, check badge, selectable card, unread badge, modal
- [X] T012 [US3] Replace the scattered gray hex values with tokens
- [X] T013 [US3] Re-render every screen in `docs/screens/` (+ `app-icon.png`, `bot.png`)

## Phase 5: Polish

- [X] T014 Update specs/README (roadmap, visual language, deviations), CLAUDE.md, CHANGELOG, report
- [ ] T015 Build, install and look at it for real (icon in Finder/Dock, the bot's glow and blink, every screen)

## Implementation notes

Implemented 2026-09-26. `swift build` ✓, `./build.sh --no-install` ✓ (bundle contains `AppIcon.icns`),
`swift run MyClickyChecks` → 386 passed.

- **Why not use the PNGs directly:** both are cut off on the right (the logo's tile and the bot's third dash) and have a
  navy frame, so an icon made from them would have a sliced edge. The artwork is drawn in code, measured from the PNGs
  and tuned over 4 rounds of side-by-side renders (`docs/screens/app-icon.png`, `docs/screens/bot.png`).
- **Snapshots vs. the real app:** the screen snapshots use a layer render that can't draw blur, so there the bot's glow
  looks harder and its floor glow shows as a solid oval. The real app (and the `app-icon`/`bot` renders, which use
  `ImageRenderer`) draws them soft. T015 checks this on screen.
- Clicky avatars keep their per-chat colors (`AvatarColor.blobHex`) as the ring, so no data changes were needed.
- Primary buttons, the toggle's on track, check badges and the unread badge now use white text or knobs on the
  blue-violet glass (they had dark text on lavender). The secondary button stays light: ice-white glass with navy text.
- Not changed (FR-005): the companion cursor and its 4 colors, the notch's black shape, the Voice page's per-voice
  icon colors, and the integration letter tiles.
- **T015 not done**: seeing the installed icon and the live glow needs you. → **Needs you.**
