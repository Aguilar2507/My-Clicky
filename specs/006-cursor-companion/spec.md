# Feature Specification: Cursor Companion

**Feature Branch**: `006-cursor-companion`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "It has to appear at the side of my cursor, as HeyClicky does."

Reference: `references/heyclicky/08-settings-cursor.png`, `01-notch-collapsed.png` (docked cursor)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A companion that follows my cursor (Priority: P1)

A small glowing triangle (the MyClicky cursor) sits just beside my mouse pointer and follows it smoothly, with a
soft, slightly delayed motion, so it feels alive but never gets in the way. It never blocks clicks. It reacts to
what MyClicky is doing:
- **Idle:** calm.
- **Listening:** pulses with my voice.
- **Thinking:** shimmers.
- **Speaking:** gently bounces.

**Why this priority**: This is HeyClicky's signature. The assistant lives next to my cursor.

**Independent Test**: Move the mouse around both displays. The triangle trails beside the pointer everywhere, over
every app and full-screen Space, and clicks go through it.

**Acceptance Scenarios**:

1. **Given** the companion is undocked, **When** I move the mouse, **Then** it follows at a fixed offset (lower right
   of the pointer) with smooth easing, and settles within 0.3 s after I stop.
2. **Given** I click where the companion is drawn, **Then** the click reaches the app underneath.
3. **Given** I start talking, **Then** it pulses with my voice level. While thinking it shimmers. While speaking it bounces.
4. **Given** the pointer moves to another display, **Then** the companion goes with it.

---

### User Story 2 - Answers appear in a bubble beside the cursor (Priority: P1)

When MyClicky answers, a dark rounded bubble next to the companion shows the words as they're spoken. It fades a
few seconds after the answer ends, or right away if I start a new question.

**Independent Test**: Ask a question. The words appear in the bubble in step with the voice, and the bubble fades
3 s after speaking ends.

**Acceptance Scenarios**:

1. **Given** a spoken answer, **Then** the bubble text grows sentence by sentence with the speech, max 380 pt wide,
   and stays on screen.
2. **Given** the bubble is showing, **When** I press push-to-talk, **Then** it disappears immediately.

---

### User Story 3 - It flies to point at things (Priority: P1)

When the answer involves something on screen ("where is the export button?"), the companion leaves my cursor, flies
in an arc to the item, bounces gently there with a short label, and flies back after a few seconds (or as soon as
I move my mouse onto the item).

**Why this priority**: Pointing is what makes it a screen companion.

**Independent Test**: Ask "where is the Apple menu?". The triangle flies to it, shows the label "Apple menu", and
returns after ~6 s.

**Acceptance Scenarios**:

1. **Given** an answer with a pointing target on another display, **Then** the companion flies there across displays.
2. **Given** the companion is pointing, **When** I move my mouse within 40 pt of the target, **Then** it returns to my cursor.
3. **Given** the companion is docked, **Then** it flies out of the notch to point and back into the notch afterwards.

---

### User Story 4 - It draws on my screen to show the way (Priority: P2)

For answers that are easier to show than say, MyClicky draws on top of my screen in the companion's color: a circle
around a button, an arrow toward something, a box around an area, or an underline. The drawings appear with a
hand-drawn stroke animation and fade after about 8 seconds or when I ask something new.

**Independent Test**: Ask "circle the search field in this window". A circle is drawn around it.

**Acceptance Scenarios**:

1. **Given** an answer with up to 3 drawings, **Then** each draws itself in ≤ 0.6 s in the companion color, on the right display.
2. **Given** drawings are showing, **When** I press push-to-talk or 8 s pass, **Then** they fade out.
3. **Given** a drawing is showing, **Then** clicks go through it.

---

### User Story 5 - Type to it beside my cursor (Priority: P2)

Double-tapping Control (the Text mode shortcut) opens a small text field right next to my cursor: "Ask MyClicky…".
Return sends it (like a spoken question, with my screen), and Esc closes it.

**Independent Test**: Double-tap ⌃, type "what does this error mean?", press Return. The answer is spoken, shown in the
bubble, and saved in Talk.

**Acceptance Scenarios**:

1. **Given** the field opens, **Then** it has focus immediately and doesn't appear in the screenshot sent with the question.
2. **Given** the text starts with "agent", **Then** it's routed to a Clicky (feature 005 rules).

---

### User Story 6 - Choose its color or dock it (Priority: P2)

Settings → Cursor ("The MyClicky cursor that lives on your screen."):
- **COLOR:** four cards (red, the default; blue; yellow; green) with a check on the selected one.
- **VISIBILITY:** "Dock cursor" ("Docking hides the cursor and stops it from following you."). When docked, the
  triangle sits in the notch's right side instead.

**Independent Test**: Pick blue and the companion turns blue at once. Turn on Dock cursor and it slides into the notch.

**Acceptance Scenarios**:

1. **Given** a new color, **Then** the companion, bubble accent, drawings and notch icon use it immediately.
2. **Given** Dock cursor on, **Then** the companion no longer follows the mouse and appears in the notch.

### Edge Cases

- The pointer is at a screen edge → the companion flips to the side with room and never goes off-screen.
- Mouse moving fast → the companion catches up smoothly, without teleporting (except across displays).
- The notch panel is open → the undocked companion hides while the pointer is inside the panel.
- A pointing target is outside all screens (model mistake) → clamp to the nearest edge of that screen, or skip pointing.
- Games or presentations (full-screen) → the companion still follows. The user can dock it.
- Show in screen recordings off → the companion, bubble and drawings are excluded as far as macOS allows (004).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The companion MUST follow the pointer on all displays and Spaces with smooth easing, never intercepting clicks.
- **FR-002**: The companion MUST show distinct idle, listening (voice-reactive), thinking and speaking states.
- **FR-003**: Answers MUST appear in a bubble beside the companion, in sync with speech, fading 3 s after it ends.
- **FR-004**: Pointing answers MUST make the companion fly to the target with a label and return afterwards,
  replacing v0.1's blue arrow.
- **FR-005**: MyClicky MUST support drawn annotations (circle, arrow, box, underline), up to 3 per answer, fading after 8 s.
- **FR-006**: Text mode MUST open a text field beside the cursor that sends a screen question on Return.
- **FR-007**: Settings → Cursor MUST offer 4 colors (default red) and Dock cursor.
- **FR-008**: Docked, the companion MUST appear in the notch and still fly out to point.
- **FR-009**: Drawing and pointing instructions MUST never be spoken or shown as text.

### Key Entities

- **Companion state**: idle, listening(level), thinking, speaking, pointing(target), docked.
- **Screen mark**: a point or a drawing (shape, coordinates, display, label).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The companion trails the pointer at 60+ fps with no visible stutter during normal mouse movement.
- **SC-002**: Idle CPU (companion visible, mouse still) stays under 1%.
- **SC-003**: In 10 "where is…" questions on common apps, the companion lands on the right element at least 8 times.
- **SC-004**: The Cursor page matches `08-settings-cursor.png` within 5%.

## API Cost Impact

The instructions for drawing tags add ~150 tokens to the system prompt, about +$0.00015 per Haiku question and
+$0.0003 per Sonnet question. "Draw/circle/show" wording routes to the pointing model (Sonnet), like "where is".

## Deviations from HeyClicky

- None known. Companion motion and state animations are designed from the references and HeyClicky's public videos.
  They'll be tuned by eye.

## Assumptions

- Colors: red `#F0524A`, blue `#3E7BFA`, yellow `#E9B53A`, green `#3DBE72` (sampled from ref 08).
- Pointing and drawing coordinates come from the model's reading of the screenshot. Accuracy depends on the model.
