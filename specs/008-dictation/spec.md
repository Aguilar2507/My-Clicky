# Feature Specification: Dictation

**Feature Branch**: `008-dictation`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "Dictation like HeyClicky: hold a key, speak, and the text is typed where my cursor is, in any app. Hands-free mode. Only the languages I need (English and Spanish)."

Reference: `references/heyclicky/06-settings-dictation.png`, `07-settings-shortcuts.png`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Hold, speak, release, and it's typed (Priority: P1)

In any app, with the text cursor in a field, I hold ⌃ control + fn, speak, and let go. What I said appears at my
cursor with punctuation, as if I had typed it. While I'm holding the keys, a small "Dictating…" indicator appears
beside the companion.

**Why this priority**: This is the core of dictation, and it's useful all day in every app.

**Independent Test**: In Notes, hold ⌃fn, say "Hello team, the meeting moved to Thursday.", release, and the
sentence appears at the cursor within a second.

**Acceptance Scenarios**:

1. **Given** a focused text field in Notes, Safari, Slack, VS Code or Mail, **When** I dictate, **Then** the text is
   inserted at the cursor in each of them.
2. **Given** the insertion point follows a letter, **Then** a space is added before the dictated text when needed.
3. **Given** dictation finishes, **Then** my clipboard contents are exactly what they were before.
4. **Given** I say nothing, **Then** nothing is inserted.

---

### User Story 2 - Hands-free dictation (Priority: P2)

Double-tapping ⌃fn starts dictation without holding anything. I can speak for as long as I want, and the words
appear live in the bubble. Double-tapping ⌃fn again stops it and inserts everything at my cursor. Esc cancels
without inserting.

**Independent Test**: Double-tap ⌃fn, dictate a 3-paragraph email over 2 minutes, double-tap again, and all of it
is inserted.

**Acceptance Scenarios**:

1. **Given** hands-free is running, **Then** a live transcript shows in the bubble and the companion pulses.
2. **Given** 10 minutes pass, **Then** it stops automatically and inserts what it has, with a notice.
3. **Given** Esc while hands-free, **Then** it stops and nothing is inserted.

---

### User Story 3 - English, Spanish or automatic (Priority: P1)

Settings → Dictation ("Languages and the words MyClicky should spell right."):
- **LANGUAGE:** "Auto-detect language" ("MyClicky figures out the language as you speak.") plus two language cards,
  English (English) and Spanish (Español).
- **WORDS:** my own words (names, product names, jargon) that should always be spelled the way I write them.

The same language setting is used when I talk to MyClicky with push-to-talk.

**Why this priority**: I speak both languages. Wrong-language transcripts are useless.

**Independent Test**: Auto-detect on: dictate one sentence in English and one in Spanish (separately). Both are
transcribed in the right language. Add "Anthropic" to Words: saying it is spelled "Anthropic".

**Acceptance Scenarios**:

1. **Given** auto-detect is on, **When** I speak Spanish, **Then** the transcript is Spanish (with accents), and
   English when I speak English.
2. **Given** auto-detect is off and Spanish is selected, **Then** everything is transcribed as Spanish.
3. **Given** a word in WORDS, **Then** it's recognized more reliably and inserted with my exact spelling and capitalization.

---

### User Story 4 - Safe and predictable (Priority: P2)

Dictation never types into password fields. If no text field is focused, the text is copied to the clipboard and
the bubble says "Copied — no text field was focused".

**Acceptance Scenarios**:

1. **Given** a password field is focused, **Then** dictation doesn't start, and the bubble says "Can't dictate into password fields".
2. **Given** no text field is focused, **Then** the transcript is left on the clipboard with a notice.

### Edge Cases

- Push-to-talk (fn) and Dictate (⌃fn) overlap → Dictate wins when ⌃ is held, per the shortcut matcher (004).
- The frontmost app changes during dictation → insert into whatever is focused at release.
- Speech recognition unavailable offline for a language (model not downloaded) → notice with instructions to
  download it in System Settings → Keyboard → Dictation.
- A very long hands-free transcript (> 5,000 characters) → inserted in one go.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Holding the Dictate shortcut (default ⌃fn) MUST record, and releasing MUST insert the transcript at the text cursor.
- **FR-002**: The Hands-free shortcut (default double-tap ⌃fn) MUST toggle continuous dictation with a live transcript, Esc to cancel.
- **FR-003**: Transcription MUST be on-device and support English and Spanish, with optional auto-detection.
- **FR-004**: The language settings MUST also apply to push-to-talk speech.
- **FR-005**: A custom word list MUST improve recognition and force exact spelling.
- **FR-006**: Insertion MUST work in native and web/Electron apps and MUST restore the clipboard.
- **FR-007**: Dictation MUST refuse password fields, and MUST fall back to the clipboard when no field is focused.
- **FR-008**: Dictation text MUST NOT be sent anywhere or saved in chats.

### Key Entities

- **Dictation languages**: auto-detect on/off, selected language, Spanish region.
- **Custom words**: a list of exact spellings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Insertion succeeds in 5 of 5 target apps (Notes, Safari, Slack, VS Code, Mail).
- **SC-002**: Text appears ≤ 1 s after release for a 10-second utterance.
- **SC-003**: Auto-detect picks the right language in ≥ 9 of 10 test sentences (5 English, 5 Spanish).
- **SC-004**: The clipboard is unchanged after 10 dictations.
- **SC-005**: The Dictation page matches ref 06 within 5% (language count aside).

## API Cost Impact

None. Dictation is fully on-device.

## Deviations from HeyClicky

- Only English and Spanish cards, without the language search field (your choice, constitution).
- WORDS section layout isn't visible in the reference (it's below the fold). It's designed in the same card style.

## Assumptions

- Spanish region defaults to the Mac's region if it's a Spanish-speaking one, otherwise Mexico (es-MX). It can be
  changed with a small region picker on the Spanish card.
