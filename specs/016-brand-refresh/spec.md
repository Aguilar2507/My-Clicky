# Feature Specification: Brand Refresh (logo, bot, avatars)

**Feature Branch**: `016-brand-refresh` · **Created**: 2026-09-29 · **Status**: Draft

**Input**: "Update and improve the logo, the bot and the Clicky avatars to feel part of the new look of the app, as they
seem pretty off right now. Improve it in every way, even the motion and the 3D design of the bot. It has to look 100%
professional and even better, more showy."

Follows 015 (Apple look). Replaces 013's neon-on-navy rendering; keeps 013's brand ideas (a cursor with a smile and
"click" dashes; a cursor-shaped bot with ^ ^ eyes and feet) so MyClicky stays recognizable.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - An app icon that belongs next to Apple's (Priority: P1)

The icon is a light macOS squircle tile with a solid, dimensional glass cursor in Apple blue→indigo: specular
highlight, rim light, a soft shadow cast on the tile, smiling eyes and three clean "click" dashes. It reads at 16 px
and looks at home in the Dock next to Apple's apps.

**Acceptance**: the icon at 16, 32, 128 and 1024 px; Dock, Finder and ⌘-Tab show it.

### User Story 2 - A bot that looks rendered, not drawn (Priority: P1)

The bot is shaded like a 3D object: light from the top-left, shading underneath, a glossy highlight, rim light, a
dark glass face plate for its eyes, glossy feet and a soft contact shadow on the floor. It looks good on white (Light
Mode) and on dark (Dark Mode).

### User Story 3 - A bot that feels alive (Priority: P1)

It breathes (squash and stretch), floats with its shadow reacting, blinks naturally (sometimes twice), follows the
pointer with its eyes, hops happily when hovered, and reacts to Clicky's state: listening (eyes wide), thinking
(looking up), speaking (a small mouth moves). Reduce Motion: it stands still, blinks slowly, no hops.

### User Story 4 - Avatars that match (Priority: P2)

Clicky avatars are Apple Contacts-style circles: a gradient of the Clicky's own color with a white glass bot. Talk is
the logo glyph on a blue gradient circle. Each Clicky stays recognizable by color.

### Edge Cases

- Small sizes (26 pt chat bubbles, 16 px icon): details that don't read are dropped (face plate stays, dashes shrink).
- Snapshots can't draw blur: artwork renders use `ImageRenderer` (`app-icon`, `bot`, `bot-dark`).
- The bot's animation runs only while it's on screen.

## Requirements *(mandatory)*

- **FR-001**: Logo, bot and avatars MUST use the same new palette: Apple sky/blue/indigo/purple gradients, no neon glow.
- **FR-002**: All art MUST stay drawn in code (vector), readable in Light and Dark Mode.
- **FR-003**: Motion MUST follow 014 (springs, Reduce Motion) and run only while visible.
- **FR-004**: Avatar colors MUST stay per Clicky (existing `AvatarColor`), no data change.
- **FR-005**: The app icon MUST be regenerated (`scripts/make-icon.sh`).

## Success Criteria *(mandatory)*

- **SC-001**: The icon reads at 16 px (cursor and eyes visible).
- **SC-002**: The user judges the icon, bot and avatars as professional and matching the Apple look.
- **SC-003**: No layout changes on any screen.

## Cost impact

None.

## Deviations from HeyClicky (Principle VIII)

| HeyClicky | MyClicky | Why |
|---|---|---|
| Cloud mascot, static | 3D glass cursor bot that follows the pointer and reacts to Clicky's state | Your design; original branding |
