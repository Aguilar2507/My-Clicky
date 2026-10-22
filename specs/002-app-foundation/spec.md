# Feature Specification: App Foundation

**Feature Branch**: `002-app-foundation`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "Before building the HeyClicky-style app, reorganize the project so settings and chats are saved safely, the app has one consistent look, and there are automatic checks."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Nothing I already have is lost (Priority: P1)

After updating to the reorganized app, everything that worked in v0.1 still works: my API key, my settings
(language, voice, models, agent folder) and this month's spend are all still there.

**Why this priority**: A reorganization that loses data or breaks features is worse than none.

**Independent Test**: Install the new build over v0.1, open it, and ask a question by voice. The answer comes
back as before, the spend total is unchanged, and the old settings are still in effect.

**Acceptance Scenarios**:

1. **Given** a v0.1 settings file, **When** the new app starts for the first time, **Then** every value is carried
   into the new settings file, and the old file is kept as a backup.
2. **Given** a saved API key, **When** the new app starts, **Then** it is used without asking again.
3. **Given** this month's spend recorded by v0.1, **When** the new app starts, **Then** the same total is shown.
4. **Given** the baseline behaviors (push-to-talk, pointing, agent, typed questions), **When** used, **Then** they
   behave as described in `specs/archive/001-baseline/spec.md`.

---

### User Story 2 - My settings and chats are saved safely (Priority: P1)

Whatever I change or say is saved immediately. It survives quitting, crashes and restarts, and one damaged file
never wipes out everything else.

**Why this priority**: Chats and settings are the backbone of every later feature.

**Independent Test**: Change a setting, force-quit the app, reopen it, and the change is still there. Damage
one saved chat file by hand and reopen: the other chats still load, and the damaged file is set aside, not deleted.

**Acceptance Scenarios**:

1. **Given** any settings change, **When** the app is force-quit within 1 second, **Then** the change is kept.
2. **Given** a damaged or unreadable chat file, **When** the app loads chats, **Then** the file is renamed
   `*.damaged`, the others load, and nothing is deleted.
3. **Given** a settings file missing some values, **When** loaded, **Then** those values use defaults and the rest are kept.

---

### User Story 3 - One consistent look (Priority: P2)

Every screen uses the same dark look as HeyClicky: cards, section labels, glossy blue buttons, toggles and
selectable cards, so the app feels like one product.

**Why this priority**: All later screens reuse these pieces. Getting them right once avoids mismatched screens.

**Independent Test**: Open the design gallery (a hidden developer screen). Every control appears in its normal,
hover, selected and disabled states, matching the reference screenshots side by side.

**Acceptance Scenarios**:

1. **Given** the design gallery, **When** compared with `references/heyclicky/03-settings-general.png`, **Then** the
   card, section label, toggle and white button look the same (colors, corner radius, spacing within 2 points).

---

### User Story 4 - Automatic checks before I try anything (Priority: P2)

A single command checks the app's core logic (routing, cost math, saving and loading, parsing) and says clearly
whether everything passed.

**Why this priority**: Beginners can't easily tell whether a change broke something. This gives a yes/no answer.

**Independent Test**: Run the checks command and see "All N checks passed". Break a rule on purpose and see it fail
with a readable message.

**Acceptance Scenarios**:

1. **Given** the project, **When** the checks command runs, **Then** it prints each group, the number passed,
   and ends with a clear pass/fail line and exit status.

### Edge Cases

- The app support folder is missing or read-only → the app still starts with defaults and says it cannot save.
- Two quick changes in a row → the last one wins and the file is never half-written.
- A v0.1 settings file with unknown extra keys → they are ignored, not an error.
- The disk is full → the save fails without corrupting the existing file.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST migrate v0.1 settings to the new settings file once, keeping a backup of the old file.
- **FR-002**: Settings MUST be saved within 1 second of any change, by replacing the file in one step so it is never half-written.
- **FR-003**: Missing or unknown settings values MUST NOT reset other values (defaults fill the gaps).
- **FR-004**: Each chat MUST be stored in its own file so that one damaged chat cannot affect others.
- **FR-005**: Damaged files MUST be set aside with a `.damaged` suffix, never deleted.
- **FR-006**: The app MUST provide shared visual building blocks matching the roadmap's visual language table.
- **FR-007**: A checks command MUST test the core logic and report pass/fail with a non-zero exit status on failure.
- **FR-008**: All v0.1 behaviors in the baseline spec MUST keep working.
- **FR-009**: Saved files MUST NOT contain secrets or images (Principle IV).

### Key Entities

- **Settings**: every user preference. Grows as features are added; each value has a default.
- **Chat**: one conversation (the pinned Talk chat or a Clicky), with its messages and memory summary.
- **Message**: who said it, the text, when, and optional extras (for example "looked at 2 screens").
- **Usage month**: spend and question count per calendar month.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of v0.1 settings values survive the upgrade, checked against a copy of the old file.
- **SC-002**: A force-quit right after a change never loses the change (10 of 10 tries).
- **SC-003**: The checks command runs in under 30 seconds and covers every pure-logic area listed in Principle VII.
- **SC-004**: Reference and design gallery match within 2 points for the shared controls.

## API Cost Impact

None. No new requests, and prompts are unchanged.

## Deviations from HeyClicky

None visible. This feature is groundwork.

## Assumptions

- Chats are few (under a few hundred), so one file per chat is fast enough. No database is needed.
- The design gallery is a developer screen, opened with a launch flag, not shown in the normal app.
