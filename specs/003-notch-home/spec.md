# Feature Specification: Notch Home

**Feature Branch**: `003-notch-home`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "HeyClicky lives in my Mac's notch, 24/7. When I put my cursor on top of the notch the app opens and I can use it like any AI app: chats, settings, new chat, everything."

Reference: `references/heyclicky/01-notch-collapsed.png`, `02-app-home.png`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - MyClicky lives in the notch (Priority: P1)

MyClicky is always present as a small black extension of the notch. The left side shows a blue numbered badge when
Clickys have something new for me. The right side shows the companion cursor when it's docked there, or a small
activity indicator while an agent is working. With nothing to show, it blends into the notch.

**Why this priority**: It's MyClicky's permanent home and entry point. Nothing else can be reached without it.

**Independent Test**: Launch the app. A black shape the height of the notch, slightly wider, sits flush with the
notch, with rounded bottom corners. Mark a Clicky as having news and a "1" badge appears on the left.

**Acceptance Scenarios**:

1. **Given** the app is running, **When** I look at the top of the built-in display, **Then** a black notch extension
   is visible on every Space and over full-screen apps.
2. **Given** 2 Clickys have unseen results, **Then** the left side shows a glossy blue badge with "2". **Given** 0,
   **Then** there is no badge.
3. **Given** the companion is docked (feature 006), **Then** the right side shows it in its chosen color.
4. **Given** an agent is running, **Then** the right side shows a subtle animated activity indicator.

---

### User Story 2 - Hover to open the app (Priority: P1)

When I move the pointer onto the notch, it smoothly grows downward into the full app (sidebar of chats and the main
area), as if the app pours out of the notch. When I move away, it shrinks back. While I'm typing in it, it stays open.

**Why this priority**: This is how every feature is reached, exactly like HeyClicky.

**Independent Test**: Rest the pointer on the notch: within about a quarter of a second the app grows out of it. Move
the pointer to the middle of the screen: it folds back after a short grace period.

**Acceptance Scenarios**:

1. **Given** the collapsed notch, **When** the pointer rests on it for 150 ms, **Then** it expands to the app panel
   (about 990 × 650 points) attached to the notch, with a black-to-clear fade at the top.
2. **Given** the expanded panel, **When** the pointer stays outside it for 500 ms, **Then** it collapses, unless a text
   field has focus, a sheet or menu is open, or the pointer is on its way back.
3. **Given** the expanded panel, **When** I click outside it or press Esc, **Then** it collapses immediately.
4. **Given** the pointer only brushes the notch while heading to the menu bar, **Then** it doesn't open (the 150 ms rest).
5. **Given** the panel opens, **Then** keystrokes go to it (it accepts keyboard focus) without stealing focus from the
   frontmost app until I click or type in the panel.

---

### User Story 3 - Pop out or close (Priority: P2)

The top-right corner of the app has a "pop out" icon and a close ✕. Pop out turns the panel into a normal window I
can move and resize, which stays open while I work. Close sends it back into the notch.

**Why this priority**: Longer chats need a window that doesn't fold away.

**Independent Test**: Expand, click pop out, and a normal window appears where I last left it. Move the pointer away and
it stays. Click ✕ and it disappears, while the notch is still there.

**Acceptance Scenarios**:

1. **Given** the expanded panel, **When** I click pop out, **Then** the same content moves into a movable, resizable
   window (minimum 760 × 520) that reopens at its last position and size.
2. **Given** the popped-out window, **When** I click ✕, **Then** the window closes and hovering the notch opens the
   panel again.
3. **Given** the popped-out window is open, **When** I hover the notch, **Then** the window comes to the front
   instead of a second copy opening.

---

### User Story 4 - Displays without a notch (Priority: P2)

On my external monitor, MyClicky shows the same black shape as a pill at the top center, and hovering it opens the app
on that display.

**Why this priority**: I use a 2560 × 1440 external display next to the MacBook.

**Independent Test**: With the external display connected, a pill is visible at its top center. Hovering it opens the
panel on that display.

**Acceptance Scenarios**:

1. **Given** a display without a notch, **Then** a pill of the same height as the menu bar appears at its top center.
2. **Given** displays are connected, disconnected or rearranged, **Then** the notch and pills move to the right places
   within 1 second.

---

### User Story 5 - Dock icon on or off, and quitting (Priority: P3)

MyClicky has no Dock icon by default. I can turn one on (setting "Show in Dock", in General, feature 004). Clicking
it opens the popped-out window. Right-clicking the notch gives a small menu with Open, Settings and Quit.

**Independent Test**: Turn on Show in Dock and the icon appears. Click it and the window opens. Turn it off and the icon
disappears. Right-click the notch, choose Quit, and the app quits.

**Acceptance Scenarios**:

1. **Given** Show in Dock is off (default), **Then** there is no Dock icon and no app-switcher entry.
2. **Given** Show in Dock is on, **When** I click the Dock icon, **Then** the popped-out window opens.
3. **Given** a right-click on the notch, **Then** a menu offers Open MyClicky, Settings…, Quit MyClicky.

### Edge Cases

- A full-screen app hides the menu bar → the notch extension stays reachable at the top edge.
- The pointer lives near the top edge (for example over tab bars) → no accidental opens thanks to the rest delay.
  The hover zone is only the notch shape itself.
- The panel is open when the display sleeps or changes → it collapses and rebuilds on the right display.
- Screen recording or sharing → governed by "Show in screen recordings" (feature 004).
- The notch area is covered by another always-on-top utility → MyClicky stays above normal windows but below system alerts.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST show a notch extension on the built-in display and a pill on every other display.
- **FR-002**: The collapsed shape MUST show the unread count (hidden at 0) on the left, and the docked companion or
  agent activity on the right.
- **FR-003**: Resting the pointer on the shape for 150 ms MUST expand it into the app panel with a smooth grow animation (≤ 350 ms).
- **FR-004**: The panel MUST collapse after 500 ms outside it, on an outside click or on Esc, except while text input,
  menus or sheets are active.
- **FR-005**: The panel MUST offer pop out and close in its top-right corner. The pop-out window MUST remember its frame.
- **FR-006**: Only one copy of the app content MUST exist at a time (panel or window).
- **FR-007**: The Dock icon MUST follow the "Show in Dock" setting (default off). A Dock click MUST open the window.
- **FR-008**: Right-clicking the shape MUST open a menu with Open, Settings and Quit.
- **FR-009**: The v0.1 menu bar icon is removed once feature 004 provides the API key setting and Quit. Until then it stays.

### Key Entities

- **Notch state**: collapsed, expanded or popped out, per display.
- **Unread count**: number of Clickys with unseen results (provided by 005/009).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Rest-to-open takes under 0.5 s (150 ms rest plus animation).
- **SC-002**: Zero accidental opens in 5 minutes of normal browsing with tabs near the top edge.
- **SC-003**: Side-by-side with `02-app-home.png`, the panel's size, fade and corner shape match within 5%.
- **SC-004**: The app uses under 1% CPU while collapsed and idle.

## API Cost Impact

None.

## Deviations from HeyClicky

- Right-click menu on the notch (Open, Settings, Quit): HeyClicky's quit path isn't shown in the references. Added so
  the app can always be quit.
- Pill on displays without a notch: HeyClicky's behavior there isn't shown in the references.

## Assumptions

- The built-in display is a MacBook with a notch (confirmed: 16" MacBook Pro, 3456 × 2234).
- The content inside the panel (sidebar, chats, settings) is delivered by features 004 and 005. Until then, the panel
  shows the empty greeting screen.
