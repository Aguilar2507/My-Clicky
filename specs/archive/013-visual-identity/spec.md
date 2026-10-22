# Feature Specification: Visual Identity (logo, bot, palette)

**Feature Branch**: `013-visual-identity`

**Created**: 2026-09-26

**Status**: Implemented

**Input**: User description: "I want the app logo to look the most similar to the LOGO.png inspiration I attached. Then,
as in HeyClicky, when you open the app, there's a bot that looks like a cloud. I attached how I want mine to look
(BOT.png). Also the visual guide for you to make all the work even easier."

References (git-ignored, private): `references/myclicky/LOGO.png`, `references/myclicky/BOT.png`,
`references/myclicky/visual-system.png` ("CLICK — Visual System, approved design reference for implementation").

## User Scenarios & Testing *(mandatory)*

### User Story 1 - My own app icon (Priority: P1)

MyClicky has its own icon in Finder, the Dock and ⌘-Tab: a side-facing glass cursor with two smiling eyes and three
neon "click" dashes, on a dark glass tile with a neon rim, like LOGO.png.

**Independent Test**: `./build.sh`, then look at `~/Applications/MyClicky.app` in Finder.

**Acceptance Scenarios**:

1. **Given** the app is built, **Then** Finder shows the glass-cursor icon instead of the generic app icon.
2. **Given** the icon at 16 px, 32 px and 1024 px, **Then** the cursor, eyes and dashes are still readable.

---

### User Story 2 - My own bot inside the app (Priority: P1)

Where HeyClicky shows its cloud mascot, MyClicky shows the bot from BOT.png: a front-facing glass cursor with two curved
smiling eyes and two small glass feet. It stands on the "Hi, how can I help ^_^?" pill on the greeting screen and tops
the welcome tour, blinking every few seconds and floating gently. Clicky chat avatars are small versions of the bot,
each with its own color as a ring. The Talk chat and the sidebar use the app logo.

**Acceptance Scenarios**:

1. **Given** the app opens on the greeting, **Then** the bot stands on the pill with its feet on the pill's edge.
2. **Given** several Clickys, **Then** each avatar is the bot, and their ring colors tell them apart.

---

### User Story 3 - The whole app in my palette (Priority: P2)

The app keeps HeyClicky's layout, but in the visual system's colors: a near-black navy window with a subtle
violet/blue bloom, deep-navy glass cards with thin borders, blue-violet glass buttons and toggles, and ice-white text.

**Acceptance Scenarios**:

1. **Given** any screen (home, conversation, the 8 Settings pages, spending, welcome tour), **Then** no HeyClicky gray
   surface or lavender accent remains.

## Requirements *(mandatory)*

- **FR-001**: The logo and bot MUST follow the visual system's non-negotiable rules: liquid glass with blue-violet
  refraction and warm edge highlights, soft neon rim glow, no flat colors, no hard cartoon outlines, no matte plastic.
- **FR-002**: The artwork MUST be drawn in code (vector), not copied from the PNGs. The PNGs are cut off on the right
  and framed in navy, so they can't be used as-is, and code-drawn art stays sharp at any size and can animate.
- **FR-003**: The palette MUST be the visual system's eight colors: Midnight #080C1C, Deep Navy #11192F,
  Electric Blue #3B82F6, Cyan Glow #47D7FF, Violet #7C5CFF, Magenta #E35BFF, Warm Glass #FFD2B8, Ice White #F7FAFF.
- **FR-004**: All colors MUST come from `Theme`/`Brand` tokens (no scattered hex values for surfaces or accents).
- **FR-005**: The companion cursor, its 4 colors and the notch's black shape are unchanged (not in scope).

## Cost impact

None. No API requests. The bot's animation runs only while the greeting or the tour is on screen.

## Deviations from HeyClicky (Principle VIII)

| HeyClicky | MyClicky | Why |
|---|---|---|
| Cloud blob mascot | Glass cursor bot with feet (BOT.png) | Your design; original branding |
| Gray surfaces, lavender accents | Midnight navy, deep-navy cards, blue-violet glass accents | Your visual system |
| Their app icon | Glass cursor on a glass tile (LOGO.png) | Your design |

The layout, sizes, spacing and behavior stay the same as HeyClicky's.
