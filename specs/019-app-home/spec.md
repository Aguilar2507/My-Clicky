# Feature Specification: App Home Without the Notch

**Feature Branch**: `019-app-home` · **Created**: 2026-10-01 · **Status**: Draft · **Supersedes**: spec 003 (notch home)

**Input**: "Even if Clicky being in my notch is cool, for me it's not: every time I open an app or go through my pages
it opens and it's annoying; the real notch doesn't disappear, so in terms of design and UX it brings problems; and
it's not viable when you're working on multiple things or projects, because when you open it you can't see what is
behind." Chosen direction: a regular window as home, a menu bar icon and a global shortcut; remove the notch entirely.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Nothing opens by accident (Priority: P1)

I move my pointer anywhere, including along the top edge of the screen and across the notch, while switching apps and
tabs. MyClicky never opens unless I ask for it.

**Why this priority**: The accidental opening is the main complaint; removing it is the core of the feature.

**Independent Test**: Sweep the pointer across the top edge and the notch 20 times while using other apps: nothing
appears.

**Acceptance Scenarios**:

1. **Given** MyClicky is running, **When** the pointer rests on or crosses the notch, **Then** nothing opens or changes.
2. **Given** MyClicky is running, **When** I click in other apps, **Then** MyClicky's window does not come forward.

---

### User Story 2 - MyClicky is a normal window (Priority: P1)

MyClicky's home (chats, Clickys, settings, spending) is a regular Mac window: it has its own place in the Dock and
⌘Tab, the real red/yellow/green buttons, can be moved, resized, minimized and put in full screen, and remembers where
I left it. Other windows can sit beside or on top of it, so I can see my work while it's open.

**Why this priority**: It replaces the notch panel as the only place to use the app.

**Independent Test**: Open MyClicky from the Dock, resize it beside another app, quit and reopen: same place and size.

**Acceptance Scenarios**:

1. **Given** MyClicky is running, **When** I click its Dock icon or pick it in ⌘Tab, **Then** its window comes forward.
2. **Given** the window is open, **When** I click another app, **Then** that app comes forward over MyClicky as usual.
3. **Given** I moved and resized the window, **When** I relaunch MyClicky, **Then** it opens at the same place and size.

---

### User Story 3 - Open it from the menu bar (Priority: P2)

A small bot icon lives in the menu bar. Clicking it shows or hides the window; right-clicking (or ⌃-clicking) shows
the menu that used to be on the notch: Open MyClicky, Finish setup… (until the tour is done), Settings…, agent items
(today's ideas, stop agents), quiet mode, Quit. When a Clicky has something new or an agent is working, the icon
shows a small dot.

**Why this priority**: Always-reachable entry point, also when the Dock icon is hidden.

**Independent Test**: Click the icon: window toggles; right-click: menu with the items above; finish an agent task:
dot appears until the chat is read.

**Acceptance Scenarios**:

1. **Given** the window is hidden, **When** I click the menu bar icon, **Then** the window appears and becomes active.
2. **Given** the window is active, **When** I click the menu bar icon, **Then** the window hides.
3. **Given** an agent finished and I haven't read it, **Then** the menu bar icon shows a dot; **When** I open that
   chat, **Then** the dot goes away.

---

### User Story 4 - Open it with a shortcut (Priority: P2)

From any app I press ⌥Space ("Open MyClicky") to show the window; pressing it again while MyClicky is active hides it.
I can change or turn off the shortcut in Settings → Shortcuts.

**Why this priority**: Fastest way in without touching the mouse.

**Independent Test**: In another app press ⌥Space twice: window shows, then hides. Rebind it: the new keys work and
⌥Space no longer does.

**Acceptance Scenarios**:

1. **Given** another app is active, **When** I press the shortcut, **Then** MyClicky's window appears and is active.
2. **Given** MyClicky's window is active, **When** I press the shortcut, **Then** the window hides and the previous
   app is active again.

---

### User Story 5 - What hung off the notch moves to the menu bar icon (Priority: P3)

The morning "ideas for today" card drops below the menu bar icon, and the docked cursor companion (Settings →
Cursor → dock) flies out from and back to the menu bar icon, instead of the notch. Onboarding and hints no longer mention the notch.

**Independent Test**: Trigger today's ideas: the card drops below the menu bar icon. Turn docking on and ask where something is:
the companion flies from the icon and back.

**Acceptance Scenarios**:

1. **Given** suggestions are ready, **When** they're announced, **Then** the card appears under the menu bar icon.
2. **Given** a new install, **When** I go through the welcome tour, **Then** it explains the menu bar icon and the
   shortcut, never the notch.

### Edge Cases

- "Show in Dock" turned off: no Dock or ⌘Tab entry; the menu bar icon and shortcut still open the window.
- The menu bar is full or the icon is hidden by the system (crowded menu bar): the shortcut and Dock still work.
- The window was on a display that's been disconnected: it opens on the main display.
- The shortcut is already used by another app: the setting shows the conflict like other shortcuts do; the user can
  rebind it.
- Full screen: the window works like any full-screen app; the shortcut brings its Space forward.
- A notification "task finished" is clicked: the window opens on that chat.
- Mac without a notch or external display only: identical behavior (nothing depended on the notch).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: MyClicky MUST NOT open, expand or show anything in response to pointer movement or hover.
- **FR-002**: The notch home MUST be removed: no notch panel, collapsed shape, notch badge or "show on all displays"
  setting.
- **FR-003**: MyClicky's home MUST be a standard window: movable, resizable, minimizable, full-screen capable, with the
  system window buttons, remembering its size and position between launches.
- **FR-004**: MyClicky MUST show in the Dock and ⌘Tab by default; "Show in Dock" (Settings → General) MUST still allow
  hiding it.
- **FR-005**: A menu bar icon MUST always be present. Click toggles the window; right-click/⌃-click shows the menu with
  Open MyClicky, Finish setup… (until done), Settings…, agent items, quiet mode items and Quit.
- **FR-006**: The menu bar icon MUST show a dot while any Clicky has unread news or an agent task is running.
- **FR-007**: A new shortcut "Open MyClicky" (default ⌥Space, single press) MUST toggle the window from any app and be
  editable in Settings → Shortcuts. Existing users MUST get it added without losing their other shortcuts.
- **FR-008**: The morning ideas card and the docked cursor companion MUST be placed relative to the menu bar icon.
- **FR-009**: Every task end MUST still alert (spec 018 rule): notification, haptic, spoken line + bubble, and the menu
  bar dot in place of the notch badge. Clicking the notification opens that chat in the window.
- **FR-010**: All user-facing copy (onboarding, hints, settings subtitles) MUST describe the window, menu bar icon and
  shortcut instead of the notch.

### Key Entities

- **Open MyClicky shortcut**: a new shortcut binding (action, key chord, press gesture), stored with the others.
- **Settings**: "notch on all displays" removed; "Show in Dock" default becomes on.

## Success Criteria *(mandatory)*

- **SC-001**: 0 accidental openings in 20 sweeps of the pointer across the top edge and notch.
- **SC-002**: The window can be opened in one action from any app (shortcut, menu bar icon or Dock) in under 1 s.
- **SC-003**: The window's size and position are restored on 10 out of 10 relaunches.
- **SC-004**: 100% of finished agent tasks show the menu bar dot until read, in addition to the notification.
- **SC-005**: No screen, hint or onboarding step mentions the notch.

## Cost impact

None. No API calls are added or removed.

## Deviations from HeyClicky (Principle VIII)

| HeyClicky | MyClicky | Why |
|---|---|---|
| Lives in the notch, opens on hover | Regular window + menu bar icon + ⌥Space shortcut; no notch | Your choice: hover opened it by accident, the physical notch cut the panel, and it hid your work |
| Notch badge for news | Dot on the menu bar icon | Follows from removing the notch |
| Morning ideas hang from the notch | They drop below the menu bar icon | Follows from removing the notch |

## Assumptions

- ⌥Space is free on this Mac (Spotlight uses ⌘Space; Raycast/Alfred users can rebind).
- The window keeps today's layout (sidebar + content) and default size; only where it lives changes.
- The shortcut uses the existing global shortcut listener, so it needs the same Accessibility/Input Monitoring
  permissions already granted for push-to-talk.
- Specs 003 (notch home) and the notch parts of 006/009/018 are superseded where they conflict with this spec.
