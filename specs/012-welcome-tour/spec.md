# Feature Specification: Welcome Tour

**Feature Branch**: `012-welcome-tour`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "The welcome tour like HeyClicky: intro, hands-on tour and an interview. MyClicky makes three new Clickys from my answers; the ones I have stay. I can replay it from Settings."

Reference: `references/heyclicky/03-settings-general.png` (WELCOME TOUR row)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First launch sets everything up (Priority: P1)

The first time I open MyClicky, a welcome window walks me through setup, one step at a time:
1. A short animated intro to what MyClicky does.
2. My name (for greetings).
3. The five permissions, each with a live ✓ once granted, plus the 🌐/fn key setting.
4. My Anthropic API key (tested) and a suggested monthly budget.
5. Claude Code for agents (checked, with instructions if it's missing, or skip).

I can go back, and I can quit and resume where I left off.

**Why this priority**: Without permissions and a key, nothing works. v0.1 left me to find them myself.

**Independent Test**: Delete MyClicky's data folder and relaunch. The welcome window appears. Complete it, and
every check in Settings → General → PERMISSIONS is ✓ and the key works.

**Acceptance Scenarios**:

1. **Given** a permission is granted in System Settings, **Then** its row turns ✓ within 2 s without restarting,
   except where macOS requires a relaunch. Then a "Relaunch MyClicky" button appears and resumes the tour after the relaunch.
2. **Given** I paste an API key, **When** I click Test, **Then** a tiny request confirms it ("Key works") or shows the error.
3. **Given** Claude Code is missing, **Then** the step shows copyable commands and "Check again". "Skip for now" continues.
4. **Given** I quit halfway, **Then** the next launch resumes at the same step.

---

### User Story 2 - Hands-on tour (Priority: P2)

After setup, the tour has me actually try each thing, and ticks each off when I do it:
- hover the notch
- hold fn and ask "what's on my screen?"
- ask "where is the Apple menu?" and watch it point
- double-tap ⌃ and type a question
- hold ⌃fn to dictate into a practice box

I can skip any step.

**Independent Test**: Follow the hands-on steps. Each ticks off automatically when done.

**Acceptance Scenarios**:

1. **Given** a step, **When** I perform its action, **Then** it's detected and ticked within 1 s.
2. **Given** Skip, **Then** it moves on without ticking.

---

### User Story 3 - The interview creates three Clickys (Priority: P2)

Finally, MyClicky asks me three short questions (I can answer by voice or typing):
- "What do you do?"
- "What eats your time each week?"
- "Which apps do you live in?"

From my answers it creates three Clickys with names, colors and purposes tailored to me (like "Signal Radar" or
"Build Lab"). They appear in the sidebar, and the tour ends with "You're all set".

**Independent Test**: Answer the three questions. Three new Clickys appear with sensible names and purposes. Replay
the tour from Settings → General, and three more are added while the old ones stay.

**Acceptance Scenarios**:

1. **Given** my answers, **Then** exactly three Clickys are created with unique names, colors and one-paragraph purposes.
2. **Given** a replay, **Then** existing Clickys are untouched and three new ones are added.
3. **Given** creation fails (no key and no Claude Code), **Then** three generic starter Clickys are created
   (Research Buddy, Build Lab, Inbox Helper) with a note.

---

### User Story 4 - Replay from Settings (Priority: P3)

Settings → General → WELCOME TOUR: "Replay the welcome tour" ("Watch the intro again, then redo the hands-on tour
and the interview. MyClicky makes three new Clickys from your answers; the ones you have stay.") ▶.

**Acceptance Scenarios**:

1. **Given** Replay, **Then** the tour opens at the intro. Setup steps that are already complete show ✓ and can be skipped with one click.

### Edge Cases

- Permissions that macOS only applies after a relaunch (Screen Recording, Input Monitoring) → a guided relaunch that
  resumes the tour.
- The user closes the welcome window → MyClicky still runs. The notch shows a small "Finish setup" dot until the tour is done.
- No microphone → voice steps offer typing instead.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On first launch (or when setup is incomplete), MyClicky MUST show the welcome window with the steps in US1, resumable.
- **FR-002**: Permission and Claude Code statuses MUST update live, with a guided relaunch when needed.
- **FR-003**: The API key step MUST store the key securely and verify it with a minimal request.
- **FR-004**: The hands-on tour MUST detect completion of each action and allow skipping.
- **FR-005**: The interview MUST create three tailored Clickys, preferring the Claude plan (Claude Code) and falling
  back to Haiku, then to generic starters.
- **FR-006**: Replay MUST be available in General and MUST keep existing Clickys.

### Key Entities

- **Tour progress**: current step, completed steps, finished flag.
- **Interview answers**: three short texts (not stored after the Clickys are created, except as the Clickys' purposes).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From a fresh install to the first answered question takes under 10 minutes following the tour.
- **SC-002**: 100% of permissions granted at the end of the tour, when the user accepts all.
- **SC-003**: The interview's three Clickys are judged relevant by the user (subjective check, noted in the quickstart).

## API Cost Impact

- Key test: ~$0.0001 (one tiny Haiku request).
- Hands-on questions: ~$0.01 (one Haiku + one Sonnet pointing answer).
- Interview: $0 via Claude Code. Fallback Haiku ~$0.002 (~600 in, ~400 out).
- **Total per run: < $0.02.**

## Deviations from HeyClicky

- Animated intro cards instead of an intro video (no hosted media).
- API key and Claude Code steps added. There's no account sign-in (III).

## Assumptions

- The welcome window is a normal centered window (not the notch panel), because macOS permission prompts and System
  Settings jumps work better with a regular window.
