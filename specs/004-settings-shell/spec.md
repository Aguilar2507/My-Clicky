# Feature Specification: Settings Shell, General and Shortcuts

**Feature Branch**: `004-settings-shell`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "Settings like HeyClicky: Back button, profile card, sidebar with General, Voice, Microphone, Dictation, Shortcuts, Cursor, Agents, Integrations, and the version at the bottom."

Reference: `references/heyclicky/03-settings-general.png`, `07-settings-shortcuts.png`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open settings inside the app (Priority: P1)

From the gear in the app (or the notch's right-click menu) I open Settings. It replaces the app content in the same
panel. On the left: "‹ Back" and the "Settings" title, my profile card (initial, name, this month's spend badge),
then General, a MYCLICKY group (Voice, Microphone, Dictation, Shortcuts, Cursor), a WORK group (Agents, Integrations),
and "MyClicky 0.2.0 (2)" at the bottom. The selected page shows on the right.

**Why this priority**: Every later feature puts its options here.

**Independent Test**: Open Settings, click through each available page, then press Back and return to the chats.

**Acceptance Scenarios**:

1. **Given** the app is open, **When** I click the gear, **Then** Settings appears in place, with General selected.
2. **Given** Settings, **When** I click Back, **Then** I return to where I was.
3. **Given** a page belongs to a feature not built yet, **Then** its sidebar item is hidden (never a broken page).
4. **Given** the profile card, **When** I click it, **Then** I can edit the name used in greetings.

---

### User Story 2 - General page (Priority: P1)

The General page ("How MyClicky behaves on your Mac.") has:
- **BEHAVIOR:** Show in Dock ("Turn off to keep MyClicky notch only.") and Show in screen recordings ("Let screen
  sharing and recording tools capture MyClicky.").
- **ANTHROPIC:** the API key, shown masked with a Change button.
- **PERMISSIONS:** ✓/✗ for each permission, with an Open button.
- **VERSION:** "You're on version 0.2.0 (2)." and What's new.
- **WELCOME TOUR:** Replay, once feature 012 exists.

**Why this priority**: It replaces the v0.1 menu (API key, permissions, quit), so the old menu bar icon can go.

**Independent Test**: Toggle Show in Dock: the icon appears and disappears. Change the API key: the next question
uses it. Revoke Screen Recording: the row shows ✗ and Open goes to the right System Settings page.

**Acceptance Scenarios**:

1. **Given** Show in screen recordings is off, **When** I record the screen with another app, **Then** MyClicky's
   windows (notch, panel, companion, bubbles) are left out as far as macOS allows.
2. **Given** the API key row, **When** I click Change and paste a key, **Then** it is stored securely and shown masked (`sk-ant-…ab12`).
3. **Given** What's new, **When** clicked, **Then** a sheet lists changes by version, read from the app's own changelog.
4. **Given** this feature ships, **Then** the old menu bar icon no longer appears.

---

### User Story 3 - Shortcuts page with rebindable keys (Priority: P1)

The Shortcuts page ("The keys that summon MyClicky.") lists:
- **TALK TO MYCLICKY:** Push to talk (default `fn`, "Hold to talk to MyClicky. Release to send.") and Text mode
  (default `⌃ control ⌃ control`, "Press to type to MyClicky instead of talking.").
- **DICTATION:** Dictate (default `⌃ control` `fn`, "Hold and speak. Release to insert what you said at your cursor.")
  and Hands-free dictation (default `⌃ control` `fn` `⌃ control` `fn`, "Dictate without holding a key down. Press to
  start, press again to stop.").

Each row shows its keys as key caps and has a Change button. There is also "Reset to defaults".

**Why this priority**: HeyClicky's keys (Fn, double Control) replace v0.1's ⌃⌥, and all voice features rely on this.

**Independent Test**: Change Push to talk to `⌥ option`, hold Option, and listening starts. Reset to defaults, and Fn works again.

**Acceptance Scenarios**:

1. **Given** I click Change, **When** I press a new shortcut (a held key or combination, a double-tap, or a combination
   with a regular key), **Then** it is shown as key caps and works immediately. Esc cancels.
2. **Given** a new shortcut that's already used by another action, **Then** it's rejected with "Already used for Text mode".
3. **Given** Fn is used and macOS is set to open the emoji picker or dictation on the 🌐 key, **Then** the page
   shows a warning with a button that opens the right Keyboard setting.
4. **Given** Reset to defaults, **Then** all four shortcuts return to the defaults above.

### Edge Cases

- Input Monitoring or Accessibility is missing → shortcuts can't work. The page shows a banner with the button to grant them.
- A double-tap that's too slow (more than 0.35 s apart) → not treated as a double-tap.
- Holding Control for push-to-talk-style actions while using ⌃-shortcuts in other apps → combinations with regular keys
  (like ⌃C) never trigger MyClicky holds.
- The key already has a system meaning (for example ⌘Space) → allowed, with the warning "May conflict with Spotlight".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Settings MUST open in the same panel or window, with Back returning to the previous screen.
- **FR-002**: The sidebar MUST match the reference layout and wording, with MyClicky naming and pages hidden until built.
- **FR-003**: The profile card MUST show my initial, my name (editable, defaults to my macOS first name) and this
  month's API spend as its badge.
- **FR-004**: General MUST provide Show in Dock, Show in screen recordings, API key, permissions status, version,
  What's new, and Replay welcome tour (when available).
- **FR-005**: Shortcuts MUST offer the four actions with the defaults above, key-cap display, Change, conflict
  detection and Reset to defaults.
- **FR-006**: Shortcuts MUST support: holding one or more modifiers (including fn), double-tapping them, and
  modifier + key combinations.
- **FR-007**: Shortcuts MUST work in any app, and MUST NOT fire when the modifiers are part of a regular key combination.
- **FR-008**: The v0.1 menu bar icon and menu MUST be removed. Everything it offered is available in the app.
- **FR-009**: All settings changes MUST apply immediately (no restart).

### Key Entities

- **Shortcut binding**: an action, a key combination and a gesture (hold or double-tap).
- **Profile**: name and initial.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Side-by-side with `03-settings-general.png` and `07-settings-shortcuts.png`, layout and spacing match
  within 5% (MyClicky wording aside).
- **SC-002**: A held shortcut starts its action within 100 ms of the key press.
- **SC-003**: 0 false triggers while typing normal text with ⌃ and fn combinations for 5 minutes.
- **SC-004**: Every v0.1 menu action can be reached in 2 clicks or fewer from the notch.

## API Cost Impact

None.

## Deviations from HeyClicky

- Profile card shows my name and API spend instead of an email and FREE plan (III).
- Added ANTHROPIC (API key) and PERMISSIONS sections. Removed Updates (Check for updates) and COMMUNITY (III).
- What's new is a local sheet, not a web page.

## Assumptions

- The Voice, Microphone, Dictation, Cursor, Agents and Integrations pages are specified in 007, 007, 008, 006, 009 and 010.
- The Text mode and Dictation actions do nothing until 006 and 008 are built. The bindings still save.
