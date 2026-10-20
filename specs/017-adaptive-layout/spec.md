# Feature Specification: Adaptive Layout and Home Header

**Feature Branch**: `017-adaptive-layout` · **Created**: 2026-09-29 · **Status**: Draft

**Input**: "I attached a screenshot of how it looks full screen. The app and everything in it needs to be adaptive,
so it's even better and user friendly. Also, at the top left corner, above the search bar, there's a blank space doing
nothing. Maybe put the logo, the name of the app or the bot there, so it doesn't look empty, and when I click it, it
brings me to the home page."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Looks right at any size (Priority: P1)

In the pop-out window at any size and in full screen, content sits where the eye expects it: Settings pages are a
centered column of comfortable width (not stuck to the left with an empty half screen), conversations are a centered
readable column, grids reflow to the space, and the empty space reserved for the window buttons disappears in full
screen (where macOS hides them).

**Acceptance**: full screen on a 16" display, Settings → General: the cards are centered with even margins; a long
conversation: messages and the composer share one centered column; Settings → Voice: the voice grid fills the column.

### User Story 2 - A home header (Priority: P1)

The top of the sidebar shows MyClicky's logo and name. Clicking it goes to the home greeting from anywhere (a chat,
Settings). It's there in the notch, the window and full screen.

**Acceptance**: open a Clicky's chat, click the header: the greeting shows. Open Settings → Voice, click it: the
greeting shows.

## Requirements *(mandatory)*

- **FR-001**: Settings content MUST be centered with a maximum width (720 pt) and equal side margins.
- **FR-002**: Conversation messages and the composer MUST share a centered column (max 820 pt).
- **FR-003**: The window-buttons row MUST collapse when the window is in full screen.
- **FR-004**: The sidebar header (logo + "MyClicky") MUST go home: close Settings and deselect the chat.
- **FR-005**: The notch panel keeps its fixed size; nothing there moves except the new header.

## Success Criteria *(mandatory)*

- **SC-001**: In full screen no page leaves more than 60% of its width empty on one side.
- **SC-002**: The header takes you home in one click from every screen.

## Cost impact

None.

## Deviations from HeyClicky (Principle VIII)

| HeyClicky | MyClicky | Why |
|---|---|---|
| Sidebar starts with the search field | Logo + name header that goes home | Your choice |
