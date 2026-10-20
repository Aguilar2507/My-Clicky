# Feature Specification: Jarvis — a Name Speech Recognition Gets Right

**Feature Branch**: `020-jarvis-voice` · **Created**: 2026-10-01 · **Status**: Draft · **Changes**: spec 018 wake words

**Input**: "Clicky is hard to say and it never detects it: it thinks I'm saying Kiki or Ciki, Cici, etc. The project
can still be named MyClicky, but the agent, I don't want it to recognize itself as that. Let's use Jarvis, but make
sure it recognizes itself like that in every aspect possible: it should recognize the sound, syllables and phonetics
of the word, so even if someone pronounces it badly, since the phonetics or syllables are similar, she knows they are
talking to her. Same for Spanish. And it should recognize if I'm talking in English or Spanish and respond in that
same language, not change it."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - It answers to "Jarvis", however I say it (Priority: P1)

Holding push to talk, I start with "Jarvis…" (or "Hey Jarvis…", "Oye Jarvis…") to talk to the cursor companion, and
"Jarvis agent…" / "Jarvis agente…" to give a task to a Clicky. Said with an English or Spanish accent, or heard by
the recognizer as "Harvis", "Yarvis", "Jarbis", "Jar vis", "Járvis", "Jervis" or "Javis", it still works. Ordinary
sentences that only look similar ("harvest the data", "Harris called", "Charles said") are not taken as the name.

**Why this priority**: The wake word never fired with "Clicky", so the companion/agent split didn't work at all.

**Independent Test**: Say each variant 5 times; check the request reaches Talk or an agent without the name.

**Acceptance Scenarios**:

1. **Given** push to talk, **When** I say "Jarvis, what's this button?", **Then** Talk gets "what's this button?".
2. **Given** push to talk, **When** I say "Oye Yarvis agente, ordena mis descargas", **Then** an agent gets "ordena
   mis descargas" and the agent bot comes out while I'm still talking.
3. **Given** push to talk, **When** I say "harvest the data from this page", **Then** Talk gets the whole sentence.

---

### User Story 2 - The recognizer expects the name (Priority: P1)

Both the English and the Spanish recognizer are told to expect "Jarvis", "Jarvis agent" and "Jarvis agente", so the
name comes out spelled right more often, and my chats show "Jarvis" even when it was heard as a variant.

**Independent Test**: Say "Jarvis agent, …" 10 times: the saved message reads "Jarvis" or the task alone.

---

### User Story 3 - It replies in the language I spoke, and stays in it (Priority: P1)

When I ask in Spanish, the answer is in Spanish and spoken with the Spanish voice from start to end; in English, the
same in English. It doesn't switch because the screen, an earlier message or a short sentence is in the other
language. Typed questions follow the language I typed. Agents answer and announce their result in the language of
the request ("Build Lab terminó. …").

**Independent Test**: Ask the same question in English, then in Spanish, with an English web page on screen: each
answer is entirely in the language asked, with one voice.

**Acceptance Scenarios**:

1. **Given** an English page on screen, **When** I ask "Jarvis, ¿qué dice esta página?", **Then** the answer is in
   Spanish and spoken only by the Spanish voice.
2. **Given** a Spanish request to an agent, **When** it finishes, **Then** the spoken line and summary are in Spanish.

---

### User Story 4 - It calls itself Jarvis (Priority: P2)

The assistant introduces and refers to itself as Jarvis; tips, onboarding and settings tell me to say "Jarvis…" and
"Jarvis agent…". The app is still called MyClicky.

### Edge Cases

- A question that doesn't start with the name still goes to Talk (as before); the name is only needed to tell
  Talk and agents apart.
- "Agent…" alone still gives a task (as before).
- Mixed-language sentence ("Jarvis, open Safari y busca vuelos"): the recognizer's winning language decides, and the
  whole reply stays in it.
- Quick press with nothing said: unchanged ("I didn't catch that").
- The language can't be told (one or two words): the language of my previous request, else the dictation language.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The wake word MUST be "Jarvis" in English and Spanish, after an optional greeting (hey, hi, hello, ok,
  okay, oye, hola, eh, ey, oiga). "Clicky" MUST no longer be a wake word.
- **FR-002**: The name MUST match by sound: letters that sound alike in English or Spanish count as the same (j/h/y/
  soft g, v/b/w, s/z/soft c/x, accents ignored), one sound may differ, and the name split in two words ("jar vis")
  MUST match. The v/b sound MUST be present, and a short list of common words that land close MUST be rejected.
- **FR-003**: "Jarvis agent/agents/agente/agentes" MUST give a task; "agent…" alone still does.
- **FR-004**: Both recognizers MUST be primed with the name and wake phrases; saved transcripts MUST show "Jarvis".
- **FR-005**: Every Talk request MUST tell Claude which language the user used and to reply only in it.
- **FR-006**: Spoken replies MUST use one voice, in the request's language, for the whole answer.
- **FR-007**: Agent tasks MUST be told the request's language; their spoken start/finish lines MUST be in it.
- **FR-008**: The assistant's prompt, tips and copy MUST call it Jarvis; the app name stays MyClicky.

## Success Criteria *(mandatory)*

- **SC-001**: 9 out of 10 "Jarvis" / "Jarvis agent" requests are routed right, in English and in Spanish.
- **SC-002**: 0 false wake words in the check set of ordinary sentences.
- **SC-003**: 10 out of 10 answers are entirely in the language asked, spoken by one voice.

## Cost impact

About 15 extra input tokens per Talk request (the language line, outside the cached system prompt), well under
$0.0001 with Haiku. Wake words and language detection are on-device.

## Deviations from HeyClicky (Principle VIII)

| HeyClicky | MyClicky | Why |
|---|---|---|
| "agent" prefix only | "Jarvis" / "Jarvis agent" wake words matched by sound | Your choice: "Clicky" was never recognized |
| Assistant named after the app | Assistant is Jarvis; the app stays MyClicky | Your choice |

## Assumptions

- Push to talk is unchanged; there's no always-on listening, so the name only routes what you say while holding it.
- English and Spanish are the only two languages (as in specs 007/008).
