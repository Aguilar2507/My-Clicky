# Feature Specification: Agents (Clickys at work)

**Feature Branch**: `009-agents`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "Agents like HeyClicky: Clickys that do tasks for me in the background, click and type on my Mac when allowed, tell me when they finish, and suggest tasks. Runs on my Claude subscription."

Reference: `references/heyclicky/09-settings-agents.png`, `02-app-home.png`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A Clicky works on my task and shows its progress (Priority: P1)

When I give a Clicky an instruction (typed in its chat, or "agent, …" by voice), it starts working in the
background. Its chat shows live progress:
- short steps like "Searching the web", "Reading report.pdf" and "Writing summary.md", which I can expand
- its messages as they come
- a final answer

Its sidebar row and the notch show that it's working. I can stop it at any time from its chat, or from the notch.
Each Clicky remembers its previous work, so later instructions continue where it left off, and it keeps its files
in its own folder.

**Why this priority**: "Runs agents to do tasks for you" is half of HeyClicky's value.

**Independent Test**: In a new Clicky, type "Make a one-page summary of today's top 3 AI news with sources, as a
markdown file". Steps appear live, a file is created in that Clicky's folder, and the final message says where it is.

**Acceptance Scenarios**:

1. **Given** an instruction, **Then** the first progress step appears within 5 s, and the Clicky's row shows a working indicator.
2. **Given** a running Clicky, **When** I press Stop (in its chat, or in the notch right-click menu under Stop agents), **Then** it stops within 2 s
   and the chat says "Stopped".
3. **Given** a finished Clicky, **When** I send a follow-up the next day, **Then** it continues with full memory of its earlier work.
4. **Given** 30 minutes pass on one instruction, **Then** it's stopped automatically with a note.
5. **Given** three Clickys are already running, **When** I start a fourth, **Then** it's queued with "Waiting for another Clicky to finish".

---

### User Story 2 - It asks before doing sensitive things (Priority: P1)

When a Clicky wants to do something that needs my permission (run a command, change files outside its folder, click
or type on my Mac), an **Allow card** appears in its chat, and beside my cursor if I'm not looking at the chat. The
card says what it wants to do in plain words, with **Allow**, **Always allow for this Clicky** and **Deny**. Sending,
deleting, buying, posting and changing system settings are always confirmed in the chat, whatever the settings.

**Why this priority**: Constitution Principle V. I must stay in control.

**Independent Test**: Ask a Clicky to "run `ls ~/Desktop` and tell me what's there". An Allow card appears. Deny →
the Clicky explains it couldn't. Repeat and Allow → it lists the files.

**Acceptance Scenarios**:

1. **Given** a request needing permission, **Then** an Allow card appears within 1 s and the Clicky waits (up to 10 minutes, then it's denied).
2. **Given** "Always allow for this Clicky", **Then** the same kind of action isn't asked again for that Clicky.
3. **Given** the Clicky would email, delete, purchase, post or change settings, **Then** it stops and asks in its message before doing it.

---

### User Story 3 - Clickys can use my Mac (Priority: P2)

Clickys can look at my screen and click, type, press keys and scroll, to do things in apps that have no other way
in. While they do, the MyClicky companion visibly moves to where it clicks, so I can watch. If "Always allow
computer use" is off, each instruction that needs it asks first with an Allow card.

**Independent Test**: Ask "open Calculator and compute 128 × 46". The companion moves to Calculator's buttons and
clicks them, and the Clicky reports 5,888.

**Acceptance Scenarios**:

1. **Given** computer use is allowed, **Then** each click, keystroke or scroll is shown by the companion moving and pulsing at that spot.
2. **Given** "Always allow computer use" is off, **Then** the first computer action of each instruction asks with an Allow card.
3. **Given** I move the mouse or press Esc during computer use, **Then** it pauses and asks "Continue?".

---

### User Story 4 - The Agents settings page (Priority: P2)

Settings → Agents ("Where agents work and how much rope they get."):
- **WORKSPACE:** Agent folder ("Where agents spawn and put the things they make.", "MyClicky default ›").
- **AUTONOMY:**
  - Auto-approve extra usage ("Let long tasks keep running without asking each time. Uses more of your Claude plan's usage.")
  - Always allow computer use ("Let Clickys click and type on your Mac without asking first. Off means each turn asks with an Allow card.")
  - Suggest agent tasks ("Fresh task suggestions every 24 hours, announced through the morning notch.")
- **ANNOUNCEMENTS:**
  - Speak when a Clicky starts or finishes ("MyClicky's voice tells you what a Clicky got done.")
  - Show updates beside the cursor ("A Clicky's reply streams in a bubble next to your cursor when it finishes.")
- A footer note about staying quiet.
- A **CLAUDE CODE** section: installed and signed-in status, with help if it isn't.

**Independent Test**: Toggle each option and see its effect (US1–US6). Change the agent folder and new Clickys work there.

**Acceptance Scenarios**:

1. **Given** Auto-approve extra usage is off (default), **When** a task reaches 40 steps, **Then** it pauses with a
   "Keep going?" card. **Given** it's on, it continues up to 150 steps.
2. **Given** Claude Code isn't installed or signed in, **Then** the page says so with step-by-step instructions and a
   "Check again" button, and Clickys explain the same when asked to work.

---

### User Story 5 - It tells me when work starts and finishes (Priority: P2)

When a Clicky starts, MyClicky says "{Name} is on it." When it finishes, it says "{Name} finished." plus a one-line
summary, and the final reply streams into a bubble beside my cursor. The chat gets a blue dot, and the notch badge
counts it. While I'm on a call, sharing my screen or in Focus, it stays quiet and the work waits in the chat.

**Independent Test**: Start a 1-minute task, then switch to another app. When it finishes: voice + bubble + blue dot + notch badge.

**Acceptance Scenarios**:

1. **Given** announcements are on and I'm not in quiet mode, **Then** start and finish are spoken (≤ 1 sentence each).
2. **Given** quiet mode (007), **Then** nothing is spoken or shown beside the cursor, and only the dot and badge update.

---

### User Story 6 - Morning suggestions (Priority: P3)

Once a day, the first time I use my Mac after 7 am, the notch briefly widens with "☀️ 3 ideas for today". Hovering
shows three suggested tasks based on my recent chats (for example "Draft the weekly update from Build Lab's notes").
Clicking one starts it in the right Clicky, or in a new Clicky.

**Independent Test**: Set the suggestion time to now (developer option), and the morning notch appears with 3 ideas.
Start one and it runs.

**Acceptance Scenarios**:

1. **Given** Suggest agent tasks is on, **Then** suggestions are prepared at most once per 24 h, using my Claude plan, not the API key.
2. **Given** I ignore them, **Then** they disappear at the end of the day.

### Edge Cases

- Claude Code updates and changes its output format → unknown events are ignored, and the final result is still shown.
- The Mac sleeps mid-task → the task continues or fails on wake. The chat shows the outcome, never a stuck spinner
  (a watchdog marks runs with no events for 5 minutes as stalled).
- The Claude plan's usage limit is reached → the Clicky shows Claude Code's message ("Usage limit reached, resets at …").
- The agent folder is deleted → recreated on the next run.
- Two Allow cards at once from different Clickys → both shown, each labeled with its Clicky.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each Clicky MUST run its instructions with Claude Code on the user's Claude subscription, with its own
  resumable session and its own folder inside the agent folder.
- **FR-002**: Progress (steps, messages, final answer) MUST stream into the Clicky's chat and be saved.
- **FR-003**: Runs MUST be stoppable from the chat and the notch, time-limited (30 min), and limited to 3 at once (others queue).
- **FR-004**: Actions needing permission MUST show an Allow card (Allow / Always for this Clicky / Deny), with a
  10-minute timeout that denies.
- **FR-005**: Irreversible or outward-facing actions MUST always be confirmed in the chat (Principle V).
- **FR-006**: Clickys MUST be able to take screenshots, click, type, press keys and scroll through MyClicky, showing
  each action with the companion. They MUST ask once per instruction unless "Always allow computer use" is on.
- **FR-007**: The Agents page MUST provide the options in US4 with the reference wording (MyClicky-named), plus Claude Code status.
- **FR-008**: Without auto-approve, runs MUST pause at 40 steps with "Keep going?". With it, the cap is 150 steps.
- **FR-009**: Start and finish MUST be announced (voice and bubble) per the settings, and suppressed in quiet mode.
- **FR-010**: Finished work MUST mark the chat unread and update the notch badge (005/003).
- **FR-011**: Daily suggestions MUST run at most once per 24 h, via Claude Code, and appear in the morning notch.

### Key Entities

- **Agent run**: which Clicky, instruction, status (queued, running, waiting for approval, paused, finished, stopped,
  failed), steps, start and end times.
- **Approval request**: which Clicky, what action in plain words, decision.
- **Clicky permissions**: actions always allowed for that Clicky.
- **Suggestion**: text, target Clicky (optional), date.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 5 sample tasks (research note, file organization in its folder, calculator via computer use, web
  lookup, follow-up next day) complete successfully, with visible progress.
- **SC-002**: 0 sensitive actions happen without an Allow card or chat confirmation across the sample tasks.
- **SC-003**: Stop takes effect within 2 s in 5 of 5 tries.
- **SC-004**: The Agents page matches ref 09 within 5% (MyClicky wording, plus the Claude Code section).
- **SC-005**: No API-key spend is recorded for any agent run or suggestion.

## API Cost Impact

None on the API key. Agents and suggestions use the Claude subscription through Claude Code (Principle I). They
consume the plan's usage limits instead.

## Deviations from HeyClicky

- Usage is governed by the Claude plan's limits and a step cap, not HeyClicky's agent message quotas (III).
- Added a CLAUDE CODE status section (needed for the subscription setup).
- Bash commands ask via Allow cards by default (v0.1 allowed them silently). This is stricter than before (V).

## Assumptions

- Claude Code is installed and signed in with a Claude plan (the welcome tour, 012, guides this). It is not installed
  on this Mac yet (checked 2026-09-24).
- Claude Code's `-p` streaming output and permission-prompt features behave as documented. Plan research verifies
  them once it's installed.
