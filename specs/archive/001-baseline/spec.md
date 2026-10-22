# Feature Specification: MyClicky Baseline (current behavior)

**Feature Branch**: `main` (baseline; documents existing behavior, no code changes)

**Created**: 2026-09-24

**Status**: Accepted (describes version 0.1.0 as built). Partly superseded by 002–012; see `specs/README.md`.
The ⌃⌥ shortcut, blue arrow, menu bar icon and single agent session are replaced there.

**Input**: User description: "Document what MyClicky does today so future features have a written starting point."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ask about the screen by voice (Priority: P1)

The user holds a two-key shortcut, asks a question out loud and lets go. The assistant looks at what is on
every screen at that moment and answers out loud in 1–3 short sentences, in the language the user spoke.
A small status bubble next to the mouse shows "Listening…", then the question, then the answer.

**Why this priority**: This is the core of the product; everything else builds on it.

**Independent Test**: With permissions granted and an API key set, hold the shortcut, ask "what app am I in?",
release, and hear a correct spoken answer.

**Acceptance Scenarios**:

1. **Given** the app is running with all permissions and an API key, **When** the user holds the shortcut, speaks and
   releases, **Then** the spoken question is transcribed on the Mac and the answer is spoken aloud and shown in the bubble.
2. **Given** a previous question in the same session, **When** the user asks a follow-up ("and what about the other one?"),
   **Then** the answer takes the last 10 question/answer pairs into account.
3. **Given** the assistant is speaking, **When** the user presses the shortcut again, **Then** speech stops immediately
   and a new question starts.
4. **Given** the user releases the shortcut in under 0.3 seconds or says nothing, **Then** no request is sent and a
   short hint is shown ("Hold ⌃⌥ while you talk" / "I didn't catch that").

---

### User Story 2 - Get pointed at the thing on screen (Priority: P1)

The user asks where something is or how to do something ("where is the export button?"). The assistant answers
and a blue arrow flies from the cursor to the item on the right screen, with a short label, and bounces there
for about 10 seconds.

**Why this priority**: Pointing is what makes this a screen assistant rather than a chatbot.

**Independent Test**: Open an app with a visible button, ask "where is the [button]?", and see the arrow land on it.

**Acceptance Scenarios**:

1. **Given** a "where / how do I / show me / dónde / cómo hago…" question, **When** it is answered, **Then** the
   more capable (pricier) model is used and the arrow points at the named on-screen element if it is visible.
2. **Given** the element is hidden (e.g. inside a closed menu), **Then** the assistant points at the first thing to
   click and says what comes next.
3. **Given** a general question, **Then** the cheap default model is used and no arrow is shown unless the answer
   benefits from one.
4. **Given** several displays, **Then** the arrow appears on the display that contains the element.

---

### User Story 3 - Hand off a task to the background agent (Priority: P2)

The user starts a request with "agent" ("agent, organize my Downloads folder"). The assistant confirms it is on it,
runs the task in the background, and speaks a short summary when finished. Follow-ups within 15 minutes continue
the same task ("agent, yes go ahead").

**Why this priority**: Adds "do it for me", but depends on a separately installed and logged-in tool.

**Independent Test**: Say "agent, create a text file called hello with the word hi in it" and hear "Agent done…";
the file exists in the agent's working folder.

**Acceptance Scenarios**:

1. **Given** the agent tool is installed and logged in, **When** a request starts with "agent" or "agente" as a whole
   word, **Then** the task runs in the background and the result is spoken when done, without talking over the user.
2. **Given** a task would send, delete, buy, post or change system settings, **Then** the agent stops and asks
   in its final message instead of acting.
3. **Given** an agent task is running, **When** another agent request arrives, **Then** the user is told to wait or stop
   it from the menu.
4. **Given** the agent tool is not installed, **Then** the user hears a message explaining how to install it.

---

### User Story 4 - Type instead of talk (Priority: P3)

From the menu bar icon the user chooses "Ask by Typing…", types a question, and gets the same spoken answer and
pointing, with the typing dialog removed before the screenshot is taken.

**Independent Test**: Menu → Ask by Typing… → "where is the Wi-Fi icon?" → spoken answer + arrow.

**Acceptance Scenarios**:

1. **Given** the typing dialog, **When** the user submits text, **Then** it follows the same path as a spoken question
   (including "agent…" routing).

---

### User Story 5 - Set up, see status and control costs (Priority: P2)

The user sets the API key once, grants permissions, adjusts settings in a file, and can see this month's API spend
from the menu.

**Independent Test**: Open the menu and see permission ✓/✗ marks, agent status, and "API this month: $… · N questions".

**Acceptance Scenarios**:

1. **Given** no API key, **When** the app launches, **Then** it asks for the key and stores it securely.
2. **Given** a missing permission, **Then** the Permissions submenu shows ✗ and opens the matching System Settings page.
3. **Given** questions have been answered this month, **Then** the menu shows the estimated spend and count for the month.
4. **Given** an older settings file that lacks a newer setting, **Then** the user's values are kept and the new
   setting gets its default.
5. **Given** "Start Fresh Conversation", **Then** question history and the agent's follow-up session are cleared.

### Edge Cases

- Screen Recording permission missing → the question is still answered, with a note that no screenshot was available.
- No API key → the assistant says to set it from the menu; nothing is sent.
- API error or timeout (60 s) → "Sorry, something went wrong" plus the error message is spoken.
- The model refuses → "Sorry, I can't help with that one."
- The user interrupts during "thinking" → the pending answer is discarded (it is still counted in spend).
- Speech recognition unavailable for the chosen language → an error bubble is shown for 4 seconds.
- Displays added or removed → overlays are rebuilt for the new screen layout.
- Words that merely contain a trigger ("appointment", "agenda") do not trigger pointing or agent mode.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Holding Control+Option (and no other modifiers) MUST start listening; releasing MUST end it.
- **FR-002**: Speech MUST be transcribed on the device when the device supports it; audio MUST NOT be uploaded.
- **FR-003**: Each question MUST include a fresh, downscaled image of every display, with the display under the
  mouse listed first and marked.
- **FR-004**: Answers MUST be short, spoken-style text in the user's language, read aloud with the best installed voice.
- **FR-005**: Questions whose wording asks where something is or how to do something on screen MUST use the pointing
  model; all others MUST use the default low-cost model.
- **FR-006**: When the answer includes a pointing target, the app MUST animate an arrow to that location on the
  correct display and label it; the pointing marker MUST never be spoken.
- **FR-007**: The app MUST keep up to 10 previous question/answer pairs as text only (no old images).
- **FR-008**: Requests starting with "agent"/"agente" (optionally "hey/ok/okay/clicky agent") as a whole word MUST
  run as background agent tasks, continuing the previous task if it ran within 15 minutes.
- **FR-009**: The agent MUST run on the user's Claude subscription login, never on the API key.
- **FR-010**: The menu MUST offer Ask by Typing, Stop Speaking (while speaking), Stop Agent (while running),
  Start Fresh Conversation, Permissions, Set/Change API Key, Open Settings File, agent status, monthly spend and Quit.
- **FR-011**: The menu bar icon MUST reflect state: idle, listening, thinking, speaking, agent running.
- **FR-012**: The API key MUST be stored in the system keychain (or read from the environment).
- **FR-013**: Settings (models, speech language, voice, speech rate, history length, agent tool path, agent folder,
  agent allowed tools) MUST be user-editable in a settings file and survive app upgrades.
- **FR-014**: Every answered question MUST add its estimated cost to a monthly local total.

### Key Entities

- **Question/Answer turn**: the user's text and the spoken answer; kept in memory, last 10 only.
- **Screenshot**: one per display; image, pixel size, display position, whether the mouse is on it.
- **Pointing target**: x/y in screenshot pixels, a short label, a display number.
- **Settings**: the user-editable values listed in FR-013.
- **Monthly usage**: per calendar month, number of questions and estimated spend in USD.
- **Agent session**: an identifier and last-run time, used for 15-minute follow-ups.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: $20 of API credit covers at least 2–3 months of personal daily use (spend visible in the menu).
- **SC-002**: A typical general question costs under half a US cent; a pointing question under 1.5 cents.
- **SC-003**: The user hears the start of an answer within about 5 seconds of releasing the shortcut on a normal connection.
- **SC-004**: For a visible target, the arrow lands on the right element in most attempts during normal use.
- **SC-005**: Setup, from first launch to the first answered question, takes under 10 minutes following the guide.

## Assumptions

- A single user on their own Mac (macOS 14+), with an internet connection for answers.
- The user has an Anthropic API key with a spend limit set in the Console.
- Agent mode additionally requires the Claude Code CLI installed and logged in with a Claude subscription;
  without it, everything except agent mode works.
- Costs are estimated from list prices and may differ slightly from the Anthropic bill.
- Known gaps, to be addressed as future specs or fixes: answers are spoken only after the full reply arrives
  (no streaming); the agent may run any shell command it chooses (guarded only by its instructions) and has no time
  limit; settings changes need an app restart.
