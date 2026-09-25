# Feature Specification: Clickys and Chats

**Feature Branch**: `005-clickys-chats`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "When I open it, it shows the chats I have and everything, settings, create a new chat, as all the AIs work. Screen questions go to a pinned Talk chat; 'agent…' requests create or continue named Clickys."

Reference: `references/heyclicky/02-app-home.png`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See all my chats at a glance (Priority: P1)

The app's left side shows the MyClicky logo, a Search field with a "+" button, and my chats:
- **Talk** is pinned first. It holds all my screen questions.
- Below it are my **Clickys**, the named helpers (like "Research Buddy"), newest activity first.

Each row shows a round pastel avatar, the name in bold, the time of the last message ("12:29 PM", "Tuesday") and a
one-line preview. A blue dot on the left marks a chat with something new. At the bottom: an "Apps +" chip (feature
010), then my initial, my name, this month's spend, an ⓘ button and a ⚙ button.

**Why this priority**: This is the app. It's the first thing I see when I hover the notch.

**Independent Test**: With a few chats saved, open the notch. The list matches the reference layout, sorted by
latest activity, with Talk on top.

**Acceptance Scenarios**:

1. **Given** chats exist, **When** the app opens, **Then** Talk is first and the rest are sorted by last activity.
2. **Given** a message arrived today at 12:29, **Then** its row shows "12:29 PM". Within the last week, the weekday.
   Older, a short date.
3. **Given** a chat got a new reply while I wasn't looking at it, **Then** it shows a blue dot, and the notch badge counts it.
4. **Given** I open a chat, **Then** its dot disappears and the badge count drops.

---

### User Story 2 - The greeting screen (Priority: P1)

With no chat open, the main area shows the MyClicky mascot peeking over a glossy blue pill that says
"🎤 Hi, how can I help ^_^?". Below it: "Evening, Jose." (morning, afternoon or evening depending on the time) and
"Hold Fn and tell me what to take off your plate." (using my actual push-to-talk key). Clicking the pill starts
listening, and clicking again sends.

**Independent Test**: Open the app in the evening with no chat selected, and the screen matches the reference.
Click the pill, speak, click again, and the request is answered in Talk (or becomes a Clicky if it starts with "agent").

**Acceptance Scenarios**:

1. **Given** it's 8 pm, **Then** the greeting reads "Evening, {name}.". At 9 am "Morning", at 3 pm "Afternoon".
2. **Given** push-to-talk is set to ⌥ option, **Then** the hint reads "Hold ⌥ Option and tell me…".

---

### User Story 3 - Read and continue a conversation (Priority: P1)

Clicking a chat opens it on the right:
- **Header:** its avatar, name and a short status.
- **Messages:** mine on the right in soft bubbles, the Clicky's on the left. Small notes like "Looked at 2 screens"
  or "Voice" appear under messages.
- **Composer:** a message field with a mic button at the bottom.

Typing in **Talk** asks about my screen, exactly like a spoken question. Typing in a **Clicky** gives that Clicky its
next instruction.

**Why this priority**: Chats are only useful if I can read them back and continue them.

**Independent Test**: Ask two questions by voice, open Talk, and see both questions and answers. Type a follow-up
and get an answer that uses the earlier context.

**Acceptance Scenarios**:

1. **Given** Talk is open, **When** I type a question and press Return, **Then** the app looks at my screens and the
   answer appears (and is spoken, per feature 007).
2. **Given** a Clicky is open, **When** I type an instruction, **Then** it goes to that Clicky's agent (feature 009).
3. **Given** a long chat, **Then** it opens scrolled to the newest message, and older messages load as I scroll up.
4. **Given** the mic button in the composer, **When** I click it and speak, **Then** my words are typed into the
   field (not sent) until I press Return.

---

### User Story 4 - Create, rename and delete Clickys (Priority: P2)

"+" starts a new Clicky: an empty chat asking "What should this Clicky do?". After my first message it gets a
fitting two-word name (like "Research Buddy") and a pastel color. Saying "agent, …" by voice also creates a new
Clicky, unless I'm continuing one from the last 15 minutes or I say its name ("agent, ask Research Buddy to…").
From a chat's ⋯ menu I can rename it, change its color or delete it (with confirmation). Talk can't be deleted,
only cleared.

**Independent Test**: Click +, type "keep an eye on new AI architect jobs", and a new Clicky appears named something
like "Role Scout". Rename it, delete it, and it's gone after confirming.

**Acceptance Scenarios**:

1. **Given** a new Clicky, **When** my first message is sent, **Then** it gets a 1–3 word name and a color within 2 seconds.
2. **Given** "agent, ask Research Buddy to add sources", **Then** the request goes to the existing "Research Buddy".
3. **Given** Delete, **When** confirmed, **Then** the chat and its saved file are removed. Cancel keeps it.

---

### User Story 5 - Search (Priority: P2)

Typing in Search filters the list to chats whose name or messages match, showing the matching words in the preview.
Accents and capital letters don't matter ("cancion" finds "canción").

**Independent Test**: Search "spacex" and only the chat that mentioned SpaceX remains, with the matching line shown.

**Acceptance Scenarios**:

1. **Given** a search term, **Then** results update as I type (within 150 ms for 200 chats).
2. **Given** no results, **Then** the list shows "No chats match "…"".

---

### User Story 6 - It remembers context (Priority: P2)

Each chat keeps a short written summary of older messages, so MyClicky remembers what we talked about without
sending the whole history every time. Screenshots are never kept.

**Independent Test**: In Talk, say "my project is called Orion", ask 15 other questions, then ask "what's my project
called?" The answer is "Orion".

**Acceptance Scenarios**:

1. **Given** a chat longer than 12 exchanges, **Then** the oldest ones are folded into its summary, and the summary is
   sent with new questions instead of those messages.
2. **Given** any saved chat file, **Then** it contains no images.

### Edge Cases

- No API key → typing in Talk shows an inline "Set your API key in Settings" message with a button.
- A Clicky naming request fails (or there's no API key) → it's named "New Clicky N" with the next free number.
- 500+ messages in one chat → it still opens in under 300 ms (older pages load on scroll).
- A chat file is damaged → it's hidden from the list (002 sets it aside), and a one-time note appears in Settings.
- Two Clickys get the same generated name → the second gets " 2".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The sidebar MUST show: logo, Search, +, the pinned Talk chat, then Clickys by last activity, the Apps chip
  (when 010 exists), and the profile footer (initial, name, spend, ⓘ, ⚙).
- **FR-002**: Rows MUST show avatar, name, relative time, one-line preview and an unread dot.
- **FR-003**: The unread count MUST drive the notch badge (003).
- **FR-004**: The empty state MUST show the mascot, pill, time-of-day greeting with my name, and a hint with the real
  push-to-talk key.
- **FR-005**: Opening a chat MUST show its messages with a composer. Typing in Talk asks a screen question. Typing
  in a Clicky instructs its agent.
- **FR-006**: "+" MUST create a Clicky that is auto-named and colored after the first message.
- **FR-007**: Voice/typed requests starting with "agent" MUST go to: a Clicky named in the request, else the Clicky
  used in the last 15 minutes, else a new Clicky.
- **FR-008**: Chats MUST support rename, change color and delete (confirmed). Talk supports Clear instead of delete.
- **FR-009**: Search MUST match names and message text, ignoring case and accents.
- **FR-010**: Each chat MUST keep a text summary of messages older than the last 12 exchanges. Requests MUST send
  the summary plus the last 6 exchanges, never images.
- **FR-011**: The ⓘ button MUST show an About sheet (logo, version, What's new).

### Key Entities

- **Chat**: Talk or Clicky; name, color, unread, summary, messages.
- **Clicky**: a Chat with a purpose (its instructions) and, from 009, an agent session.
- **Message**: text, author, time, notes (voice/typed, screens seen).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Side-by-side with `02-app-home.png`, the sidebar and greeting match within 5% (MyClicky branding aside).
- **SC-002**: The app shows the chat list within 200 ms of the notch opening, with 200 chats.
- **SC-003**: The "Orion" memory test passes (User Story 6).
- **SC-004**: Talk questions cost no more than before this feature, on average over 20 questions (checked with the spend line).

## API Cost Impact

- **Talk requests**: history changes from the last 10 exchanges to summary (~150 tokens) + last 6 exchanges. That's
  neutral to slightly cheaper (about −200 input tokens on long chats).
- **Summaries**: one Haiku call per 12 exchanges (~1,500 in, ~200 out) ≈ $0.0025. For Talk at ~20 questions a day,
  that's about $0.004 a day.
- **Clicky naming**: one Haiku call per new Clicky (~120 in, ~20 out) ≈ $0.0002.

## Deviations from HeyClicky

- Pinned **Talk** chat for screen questions (your choice). HeyClicky's handling of talk history isn't shown in the references.
- Profile footer shows name and spend instead of email and plan (III).
- The conversation screen isn't in the references. It's designed in the same style (cards, lavender accents).

## Assumptions

- Chat count stays in the hundreds, not thousands.
- Clicky avatars use the original MyClicky blob in 8 pastel color pairs.
- Agent execution inside Clickys is completed in 009. Until then, Clicky messages use the v0.1 agent runner.
