# Feature Specification: Premium Feel (motion, materials, type, accessibility)

**Feature Branch**: `014-premium-feel`

**Created**: 2026-09-29

**Status**: Draft

**Input**: User description: "I want to change everything related on how it looks, so it feels even more premium. I want
you to implement this repository skill: https://github.com/emilkowalski/skills/blob/main/skills/apple-design/SKILL.md"

The skill distills Apple's WWDC design talks (*Designing Fluid Interfaces*, *The Details of UI Typography*, *Designing
Audio-Haptic Experiences*, *Principles of Great Design*) for the web. This spec translates it to MyClicky, a native Mac
app. Layout, wording and flows stay HeyClicky's (Principle VIII); colors and art stay spec 013's. What changes is how
the app **feels**: how it responds, moves, layers, reads and adapts.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Everything answers my touch instantly (Priority: P1)

Every button, card, sidebar row, chip and toggle reacts the moment I press it, before I let go: it sinks slightly and
brightens or dims. Things I can point at light up softly when the pointer is over them. Nothing waits for a timer to
show that my input landed.

**Why this priority**: Response is the foundation of the skill ("the moment lag appears, directness falls off a
cliff"). It touches every screen and is the most noticeable single change.

**Independent Test**: Open Home and Settings, press and hold any button, card or row without releasing: it visibly
reacts while held. Move the pointer over sidebar rows and cards: they highlight.

**Acceptance Scenarios**:

1. **Given** any pill button, **When** I press and hold it, **Then** it scales down slightly and changes brightness
   within one frame, and returns smoothly when released or when I drag off it.
2. **Given** a selectable card (voice, cursor color, language), **When** I press it, **Then** it shows press feedback,
   and the selection outline and check badge animate in instead of popping.
3. **Given** a sidebar row or chat row, **When** the pointer hovers over it, **Then** it shows a subtle highlight that
   is distinct from the selected state.

---

### User Story 2 - Motion that feels physical and never gets in my way (Priority: P1)

The notch panel grows out of the notch and shrinks back into it. Modal cards arrive as glass materializing (scale plus
blur clearing), and leave the same way. Welcome tour steps slide in from the right when I go forward and back out to
the right when I go back. The companion bubble grows out of the cursor. If I change my mind mid-animation (move the
pointer back out of the notch, press Back during a step change), the motion reverses from where it is, with no jump
and no waiting.

**Why this priority**: Interruptibility and spatial consistency are what the skill calls "the single most important
principle". The notch is the app's front door.

**Independent Test**: Hover the notch and move away halfway through the expansion: it reverses smoothly from its
current size. Open and close a modal card and walk the welcome tour forward and back.

**Acceptance Scenarios**:

1. **Given** the notch is expanding, **When** the pointer leaves before it finishes, **Then** it collapses from its
   current size without first finishing the expansion.
2. **Given** a modal card (rename, custom connector, top-up), **When** it opens and closes, **Then** it enters and
   leaves along the same path, and the background dims while it's open.
3. **Given** the welcome tour, **When** I go forward, **Then** the new step enters from the trailing edge; **When** I
   go back, **Then** the current step leaves toward the trailing edge.
4. **Given** any animation in the app, **Then** it settles without a bounce unless it follows a physical gesture or a
   toggle flip.

---

### User Story 3 - Glass that looks real and reads clearly (Priority: P2)

Floating surfaces (the notch panel, companion bubble, text-mode field, modal cards) look like tinted navy glass: the
content behind shows through, blurred, with a bright top edge catching the light and a shadow that grows with the
surface's size. The sidebar is a darker, heavier layer than the content. Where content scrolls under a header, it fades
out instead of meeting a hard line. Text on glass stays crisp and readable.

**Why this priority**: Materials and depth are the most visible "premium" signal, but they build on US1/US2 and on
palette work already done in 013.

**Independent Test**: Put a colorful window behind the text-mode field and the companion bubble: the color shows
through, blurred and tinted navy. Scroll a long Settings page and a long chat: the top edge fades.

**Acceptance Scenarios**:

1. **Given** the companion bubble over a bright web page, **Then** it shows a blurred, navy-tinted view of the page and
   its text passes WCAG AA contrast (4.5:1).
2. **Given** a scrolling list under a header, **Then** there is a soft fade where they meet and no 1 pt divider.
3. **Given** two translucent surfaces, **Then** a light one is never placed directly on another light one.

---

### User Story 4 - Typography with a real hierarchy (Priority: P2)

Titles are tight and confident, body text is comfortable, small uppercase labels are open and legible. The same kind
of text looks the same everywhere, because every screen draws from one type scale where each size has its own weight,
letter spacing and line height.

**Why this priority**: Consistent type is a large part of craft, but it is invisible until the rest moves well.

**Independent Test**: Compare the page titles, row titles, captions and section labels across Home, Settings,
Spending and the welcome tour: each kind has one size, weight and spacing.

**Acceptance Scenarios**:

1. **Given** any screen, **Then** every text style comes from the shared type scale (no one-off sizes).
2. **Given** a large title, **Then** its letters are tracked tighter than body text; **Given** an uppercase section
   label, **Then** it is tracked wider than body text.

---

### User Story 5 - It respects how I set up my Mac (Priority: P2)

If I turn on Reduce Motion, slides, scales and bounces become short cross-fades, and the bot stops floating and
blinks less. If I turn on Reduce Transparency, glass becomes solid navy. If I turn on Increase Contrast, borders get
stronger and gray text gets brighter. Changes apply without restarting.

**Why this priority**: The skill treats accessibility as part of the design, not an add-on (Flexibility principle).
The app currently ignores all three settings.

**Independent Test**: Toggle each of System Settings → Accessibility → Display → Reduce motion / Reduce transparency /
Increase contrast while MyClicky is open, and repeat the US2 and US3 checks.

**Acceptance Scenarios**:

1. **Given** Reduce Motion is on, **When** the notch expands or a tour step changes, **Then** content cross-fades in
   place, with no slide, scale or overshoot.
2. **Given** Reduce Transparency is on, **Then** every glass surface is an opaque navy fill with its border.
3. **Given** Increase Contrast is on, **Then** card borders and secondary text are visibly stronger, and all text
   passes WCAG AA against its background.

---

### User Story 6 - A gentle tap for moments that matter (Priority: P3)

On a Force Touch trackpad, MyClicky gives a light haptic tap when push-to-talk starts listening, when it stops, when a
toggle flips and when an agent finishes, on the same frame as the visual change. It never taps on hover or scrolling.
I can turn it off in Settings → General.

**Why this priority**: Pleasant, but the skill's "utility" rule says feedback must earn its place; it's the least
essential part.

**Independent Test**: With the setting on, hold push-to-talk and flip a toggle: feel one tap each. Turn the setting
off: no taps.

**Acceptance Scenarios**:

1. **Given** haptics are on, **When** push-to-talk starts, **Then** one tap is felt as the listening state appears.
2. **Given** haptics are off, **Then** no haptic fires anywhere in the app.

### Edge Cases

- A pointer that presses a control, drags off it and releases: the press feedback reverts and the action does not fire.
- A new animation starts while one is running (fast hover in/out of the notch, rapid Back/Next): the new motion starts
  from the current on-screen state, never from the end state.
- Reduce Motion and Reduce Transparency both on: cross-fades over solid surfaces.
- Screen snapshots (`--snapshot`) can't render live blur: snapshot mode uses the solid fallback so the renders stay
  deterministic.
- Displays without a notch (top-center pill): the panel grows out of the pill the same way.
- Macs without a Force Touch trackpad (mouse, external keyboard only): haptics silently do nothing.
- The bot's float and blink loops never run slower than one cycle every 5 seconds without Reduce Motion, and stop
  floating with it (the skill warns against slow ~0.2 Hz oscillations).

## Requirements *(mandatory)*

### Functional Requirements

**Response and feedback**

- **FR-001**: Every pressable control (pill buttons, icon buttons, cards, rows, chips, toggles) MUST show press feedback
  while pressed (slight scale-down plus a brightness change), starting on press, not on release.
- **FR-002**: Pointer-driven controls in lists and grids (sidebar rows, chat rows, settings sidebar items, selectable
  cards, integration cards) MUST show a hover state distinct from their selected state.
- **FR-003**: Status messages MUST use one of four consistent styles: status, completion, warning, error.

**Motion**

- **FR-004**: The app MUST use one shared set of named motions: a default (no overshoot), a quick one for small
  controls, and a bouncy one reserved for toggles and gesture-driven motion. No screen defines its own timing.
- **FR-005**: Animations MUST be interruptible: a new change starts from the current on-screen state, and input is never
  blocked while something animates.
- **FR-006**: Surfaces MUST enter and leave along the same path and from their source: the notch panel from the notch,
  the companion bubble from the cursor, tour steps along the horizontal axis in the direction of travel, and modal
  cards scaling in place while their blur clears.
- **FR-007**: Selection changes (check badges, selected outlines, sidebar selection) MUST animate rather than switch
  instantly.

**Materials and depth**

- **FR-008**: The notch panel, companion bubble, text-mode field and modal cards MUST be translucent navy-tinted
  material with a bright top edge; the sidebar MUST read as a darker, heavier layer than the content.
- **FR-009**: Shadows MUST scale with surface size (small chips light, panels and modals deep) from shared tokens.
- **FR-010**: Scrolling content MUST fade out under headers instead of meeting a 1 pt divider.
- **FR-011**: Text on translucent surfaces MUST stay at or above WCAG AA contrast.

**Typography and craft**

- **FR-012**: All text MUST come from one type scale (display, title, headline, body, callout, subheadline, caption,
  label), each style defining size, weight, tracking and line spacing: negative tracking for large text, near zero for
  body, positive for small uppercase labels.
- **FR-013**: Spacing, corner radii and shadows MUST come from shared tokens on a 4 pt grid, with continuous corners.
- **FR-014**: The system font MUST be used; icons MUST use consistent weights matched to the text beside them.

**Accessibility**

- **FR-015**: With Reduce Motion on, slides, scales, overshoot and the bot's float MUST be replaced by short
  cross-fades or no motion; the bot blinks at most every 8 seconds.
- **FR-016**: With Reduce Transparency on, all translucent surfaces MUST become opaque navy.
- **FR-017**: With Increase Contrast on, borders and secondary text MUST be stronger.
- **FR-018**: All three MUST take effect live, without restarting the app.

**Haptics**

- **FR-019**: A light haptic MUST fire, on the same frame as the visual, when push-to-talk starts, when it ends, when a
  toggle flips and when an agent finishes, and nowhere else.
- **FR-020**: A "Haptic feedback" switch MUST exist in Settings → General, on by default. Adding it MUST NOT reset any
  existing setting.

**Scope guard**

- **FR-021**: Layout, wording, flows, the spec 013 palette, logo and bot art MUST NOT change. The companion cursor's
  colors and the notch's black shape MUST NOT change.

### Key Entities

- **Motion vocabulary**: the named motions (default, quick, bouncy, cross-fade) that every screen uses.
- **Type scale**: named text styles, each a size, weight, tracking and line spacing.
- **Surface tokens**: material weights (structural, floating), shadow depths, corner radii, spacing steps.
- **Haptic feedback setting**: one on/off preference, default on.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of pressable controls show visible feedback while held (checked screen by screen on Home,
  Conversation, all 8 Settings pages, Spending and the welcome tour).
- **SC-002**: Zero fixed-duration ease animations remain; every animation comes from the shared motion set.
- **SC-003**: Zero one-off font sizes remain outside the type scale.
- **SC-004**: Reversing the notch mid-expansion shows no visible jump in 10 out of 10 tries.
- **SC-005**: With each of Reduce Motion, Reduce Transparency and Increase Contrast on, every screen follows the setting,
  with no restart.
- **SC-006**: All text passes WCAG AA contrast on every surface, including glass over a white background.
- **SC-007**: Screen renders in `docs/screens/` keep the same layout as before (same positions and sizes of elements),
  so HeyClicky parity is preserved.
- **SC-008**: The user judges the app as feeling more premium than 0.3.0 after using it for a day.

## Cost impact

None. No API requests. All motion runs only while something changes on screen; no new idle loops are added.

## Deviations from HeyClicky (Principle VIII)

| HeyClicky | MyClicky | Why |
|---|---|---|
| Its own motion, materials and type details | Apple-style springs, navy glass materials, a tracked type scale | Your choice: a more premium feel (apple-design skill) |
| No haptics | Light haptic on push-to-talk, toggles and agent finish, can be turned off | Your choice; follows the skill's audio-haptic rules |

The layout, wording, sizes and flows stay the same as HeyClicky's.

## Assumptions

- The skill's web techniques map to native ones: pointer-down feedback → pressed state, CSS springs → native spring
  animations, `backdrop-filter` → macOS materials, `prefers-*` media queries → the macOS accessibility settings.
- Drag-driven gestures (rubber-banding, momentum projection, velocity handoff) have no current use in MyClicky, which
  has no draggable sheets or carousels; they are out of scope until a feature needs them.
- No new sounds are added (MyClicky already speaks; extra sounds would break the skill's utility rule).
- Type sizes stay close to today's so HeyClicky's layout doesn't shift; the change is in weight, tracking and leading.
- Haptics depend on a Force Touch trackpad; there is no fallback for mice.
