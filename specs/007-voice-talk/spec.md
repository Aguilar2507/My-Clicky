# Feature Specification: Voice Talk

**Feature Branch**: `007-voice-talk`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "Talk to it like HeyClicky: hold the key, ask out loud, it answers out loud quickly. Voice and Microphone settings like HeyClicky, but with the free Apple voices."

Reference: `references/heyclicky/04-settings-voice.png`, `05-settings-microphone.png`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fast spoken answers (Priority: P1)

I hold Fn, ask my question, and let go. MyClicky starts answering out loud almost immediately. It speaks the first
sentence while the rest is still being written, and the words appear in the bubble beside my cursor as they're
spoken. Pressing Fn again while it talks cuts it off and starts listening.

**Why this priority**: v0.1 waits for the whole answer before speaking, which feels slow. HeyClicky feels instant.

**Independent Test**: Ask "explain what's on my screen in three sentences". The voice starts within about 2.5 seconds
of letting go, and sentences keep flowing without long pauses.

**Acceptance Scenarios**:

1. **Given** I release Fn after asking, **Then** the first spoken words start within 2.5 s on a normal connection
   (Haiku).
2. **Given** a long answer, **Then** speech continues sentence by sentence with no gap longer than 0.5 s between them.
3. **Given** MyClicky is speaking, **When** I press Fn, **Then** speech stops within 100 ms and listening begins.
4. **Given** I answer in Spanish, **Then** the reply is spoken with a Spanish voice. In English, with an English voice.

---

### User Story 2 - Pick the voice and speed (Priority: P1)

Settings → Voice ("The voice MyClicky answers in, and how fast it talks."):
- **SPEECH SPEED:** chips 0.5x, 0.75x, 1x, 1.25x, 1.5x ("Takes effect on the next spoken reply.").
- **VOICE:** cards for the best voices installed on my Mac, grouped English and Spanish. Each card has an icon, name
  and a short description (like "Premium · US"). Tapping a card plays a short sample and selects it for that language
  ("Tap a voice to hear it. The pick applies to future spoken replies.").
- A "Get more voices" row opens the Mac's voice downloads.

**Independent Test**: Select 1.25x and another English voice. Tap it to hear the sample. The next answer uses both.

**Acceptance Scenarios**:

1. **Given** the Voice page, **Then** up to 10 cards per language are shown, highest quality first, with a check on the
   selected one.
2. **Given** I tap a card, **Then** it speaks "Hi {name}, this is how I sound." in that voice and becomes the selection.
3. **Given** no Premium or Enhanced voice is installed, **Then** a hint explains how to download one ("Get more voices").

---

### User Story 3 - Choose and test the microphone (Priority: P2)

Settings → Microphone ("Which microphone MyClicky listens through."):
- **INPUT DEVICE:** System Default and each connected microphone as radio rows.
- **TEST:** a "Test microphone" button with a row of level bars ("Tap to test selected input"; "Speak normally —
  the bars should move as MyClicky hears you.").

**Independent Test**: Select the MacBook Pro Microphone, click Test microphone, speak, and the bars move.
Unplug a USB mic that was selected, and MyClicky falls back to System Default with a note.

**Acceptance Scenarios**:

1. **Given** a selected device, **Then** push-to-talk and dictation listen through it.
2. **Given** the selected device disappears, **Then** MyClicky uses System Default and the page shows "Disconnected — using System Default".
3. **Given** Test microphone is running, **Then** 16 bars reflect the live level and it stops after 10 s or on a second click.

---

### User Story 4 - Stays quiet when it should (Priority: P2)

MyClicky stays quiet while I'm on a call, sharing my screen or in Do Not Disturb/Focus. It still answers in the
bubble, with a small 🔇 note I can click to hear it anyway.

**Independent Test**: Join a call (the mic is in use by another app), ask a question with Fn, and the answer appears
in the bubble without sound. Click 🔇 and it speaks.

**Acceptance Scenarios**:

1. **Given** another app is using the microphone (a call), **Then** answers aren't spoken aloud.
2. **Given** Focus/Do Not Disturb is on, or screen sharing is detected, **Then** the same.
3. **Given** quiet mode is active, **Then** the notch's right-click menu shows "Quiet mode (automatic)" checked,
   and it can be forced on or off for the next hour.

### Edge Cases

- Fn released after less than 0.3 s → "Hold fn while you talk" hint (baseline behavior).
- The network drops mid-answer → the spoken part stays, the bubble adds "…connection lost", and the partial answer is saved.
- The answer contains a POINT/DRAW tag split across chunks → never spoken (006 streaming-safe parsing).
- Numbers, abbreviations and URLs ("e.g.", "3.5", "v2.1") → not treated as sentence ends.
- The selected voice was deleted from macOS → fall back to the best voice for that language.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Push-to-talk MUST use the Shortcuts binding (default fn, hold).
- **FR-002**: Answers MUST be requested with streaming and spoken sentence by sentence as they arrive.
- **FR-003**: Each sentence MUST be spoken with the selected voice for its language (English or Spanish).
- **FR-004**: The bubble MUST show the words in step with speech (006).
- **FR-005**: The Voice page MUST offer 5 speed chips and a per-language grid of installed Apple voices with preview.
- **FR-006**: The Microphone page MUST list input devices (plus System Default), remember the choice by device, and offer a level test.
- **FR-007**: Quiet mode MUST suppress spoken audio during calls, screen sharing and Focus, as far as macOS lets
  MyClicky detect them, with a manual override.
- **FR-008**: Interrupting (push-to-talk while speaking) MUST stop speech within 100 ms.

### Key Entities

- **Voice choice**: one per language, plus speed.
- **Input device choice**: device identity, or System Default.
- **Quiet state**: automatic reasons (call, sharing, focus) and manual override with expiry.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Median time from releasing Fn to the first spoken word ≤ 2.5 s over 10 Haiku questions (v0.1 baseline
  measured for comparison).
- **SC-002**: 0 tag fragments spoken in 20 pointing/drawing answers.
- **SC-003**: The Voice and Microphone pages match refs 04/05 within 5% (Apple voice names aside).
- **SC-004**: In 5 calls on FaceTime/Zoom/Teams, 0 answers are spoken aloud.

## API Cost Impact

None. Streaming doesn't change token counts. Voices are free and on-device.

## Deviations from HeyClicky

- Apple voices instead of OpenAI voices (Cedar, Marin…), chosen per language because Apple voices speak one language each (II).
- "Get more voices" row added (Apple voices must be downloaded in System Settings).
- The 🔇 click-to-hear note is added so quiet answers aren't lost.

## Assumptions

- Languages are English and Spanish (constitution).
- Screen-sharing detection is best-effort (research.md). The manual override covers misses.
