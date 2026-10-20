# Feature Specification: Apple Look (light & dark, system colors, window controls)

**Feature Branch**: `015-apple-look`

**Created**: 2026-09-29

**Status**: Draft

**Input**: User description: "I want Clicky to feel and be exactly as an Apple app, with UX/UI design, colors, animations,
etc. Change the color to white, titles to be black, text to be like gray, buttons to be interactive, so if I click
delete, when I put the cursor over yes, it's red, over no, it's green. Also add the option to extend Clicky to full
screen, to minimize it or to close it, the three buttons that all apps have at the top left corner, the red, yellow
and green ones. Let's make it an even better app in every aspect visible."

Clarified 2026-09-29: follow the Mac's appearance (light and dark, like Apple's apps); accent = Apple system blue (your
System Settings accent); traffic lights on both the pop-out window (real ones) and the notch panel (same look).

Builds on 014 (motion, feedback, type scale, accessibility), which stays. Replaces 013's midnight-navy palette for the
app's surfaces and controls; 013's logo, bot and Clicky avatars stay as the brand art.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A light, Apple-style app that follows my Mac (Priority: P1)

In Light Mode, Clicky is white and light gray like Apple's apps: black titles, gray secondary text, a light sidebar,
white grouped cards with hairline separators, blue for selection and primary actions. In Dark Mode it turns into the
matching dark version automatically. The accent follows the color I chose in System Settings.

**Independent Test**: Open Clicky in Light Mode, then switch System Settings → Appearance to Dark: every screen
(home, conversation, the 8 Settings pages, spending, welcome tour, bubble, text box) follows without a restart.

**Acceptance Scenarios**:

1. **Given** Light Mode, **Then** backgrounds are white/light gray, titles black, secondary text gray, and no navy
   surface remains.
2. **Given** Dark Mode, **Then** the same screens use Apple's dark colors with readable text.
3. **Given** the accent is set to purple in System Settings, **Then** Clicky's selection, switches and primary
   buttons are purple.

---

### User Story 2 - Buttons that tell me what they'll do (Priority: P1)

Every button reacts to the pointer. In a confirmation ("Delete Signal Radar?"), the destructive choice turns red when
I hover it and the safe choice turns green. The same goes for Disconnect, Deny, Stop and removing an integration (red)
and Cancel, Allow and Keep going (green). Primary buttons are blue and brighten on hover; secondary buttons are light
gray and darken on hover.

**Independent Test**: Open a chat's ⋯ menu → Delete…, hover Delete (red) and Cancel (green).

**Acceptance Scenarios**:

1. **Given** the delete confirmation, **When** the pointer is over Delete, **Then** it fills red with white text;
   **When** over Cancel, **Then** it fills green with white text; at rest both are neutral.
2. **Given** any primary or secondary button, **When** hovered, **Then** its fill changes; **When** pressed, **Then**
   it reacts as in 014.

---

### User Story 3 - The three window buttons (Priority: P1)

Like every Mac app, Clicky has red, yellow and green buttons at its top-left corner. In the pop-out window they are
the real macOS buttons: close, minimize to the Dock, and full screen. In the notch panel they look and behave the
same way: red closes the panel, yellow tucks it back into the notch, green opens Clicky as a full-screen window.
Hovering them shows ×, − and the full-screen arrows.

**Independent Test**: Hover the notch, click green: Clicky opens full screen. Exit full screen, click yellow: it goes to
the Dock. Reopen from the Dock, click red: the window closes.

**Acceptance Scenarios**:

1. **Given** the notch panel, **Then** three colored buttons sit at its top-left; hovering shows their symbols.
2. **Given** the pop-out window, **Then** the standard close, minimize and full-screen buttons work.
3. **Given** the notch panel, **When** I click green, **Then** Clicky opens as a window in full screen.

---

### User Story 4 - Native-feeling details everywhere (Priority: P2)

Switches are real macOS switches. Messages I send are blue bubbles with white text. The companion bubble, text box
and morning ideas look like macOS popovers in both appearances. No leftover glows, gradients or black fades.

**Independent Test**: Walk quickstart.md screen by screen in both appearances.

**Acceptance Scenarios**:

1. **Given** Settings, **Then** switches are the system switch in the accent color.
2. **Given** a conversation, **Then** my messages are accent-colored bubbles with white text.

### Edge Cases

- Increase Contrast / Reduce Transparency (014) keep working in both appearances.
- The collapsed notch stays black (it's the hardware notch).
- Full screen from the notch while a window is already open: that window goes full screen.
- Snapshot renders use Light Mode (plus the art renders).

## Requirements *(mandatory)*

- **FR-001**: All surfaces, text and controls MUST use appearance-aware colors from `Theme`, following the Mac's
  Light/Dark setting live.
- **FR-002**: The accent MUST be the system accent color.
- **FR-003**: Titles MUST use the primary label color (black in Light Mode), body/secondary text the secondary label
  color (gray), hints the tertiary label color.
- **FR-004**: Buttons MUST have hover states. Destructive choices MUST fill red on hover, safe choices green, both
  neutral at rest.
- **FR-005**: The pop-out window MUST show working close, minimize and full-screen buttons; the notch panel MUST show
  equivalent buttons (close panel, back to notch, open full screen).
- **FR-006**: Switches MUST be the native macOS switch (with 014's haptic).
- **FR-007**: The logo, bot, Clicky avatars, companion cursor colors and the collapsed notch MUST NOT change.
- **FR-008**: Layout and wording MUST stay the same except for the window-controls row (which replaces the sidebar
  logo in Home and adds a row above Back in Settings) and the removed top-right pop-out/close icons.

## Success Criteria *(mandatory)*

- **SC-001**: No hard-coded navy or white/black text remains outside the brand art (checked by search).
- **SC-002**: Every screen is readable (WCAG AA) in both appearances.
- **SC-003**: The three window buttons work in both the notch panel and the window, 10 out of 10 tries.
- **SC-004**: The user says Clicky looks and feels like an Apple app.

## Cost impact

None. No API requests.

## Deviations from HeyClicky (Principle VIII)

| HeyClicky | MyClicky | Why |
|---|---|---|
| Dark UI only | Light and dark, following the Mac | Your choice: an Apple app |
| Top-right pop-out and close icons, no traffic lights | Red/yellow/green at top-left (real ones in the window) | Your choice: standard Mac window controls |
| Lavender (013: blue-violet glass) accents | System accent color | Your choice |

## Assumptions

- "Apple look" = system colors, system switch, flat accent-filled buttons in capsule shape (macOS 26), SF type (014).
- Green on hover means "safe/keep" and red means "destructive"; plain form Cancel buttons (Save/Cancel) stay neutral.
