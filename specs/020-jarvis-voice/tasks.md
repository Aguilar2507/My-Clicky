---
description: "Tasks for 020-jarvis-voice"
---

# Tasks: Jarvis — a Name Speech Recognition Gets Right

Plan: `WakeWords` (Core) is rewritten around a token scan and a phonetic key (English + Spanish sound classes, edit
distance ≤ 1, v/b required, blocklist), keeping its `parse`/`isAgentCall` API, plus `canonical(_:)` to spell the name
right in transcripts. `SpeechRecognizer` primes both recognizers with the wake phrases, reports the winning language
and checks every session's partial for the agent call. A Core `ReplyLanguage` helper resolves the request language
and writes the one-line instruction; `Assistant` passes it to `ClaudeClient.talkBody` (user turn, outside the cached
system prompt) and locks `SpeechQueue` to it; `AgentSupervisor` adds it to the agent prompt and localizes its spoken
lines. Constitution: I ✅ (~15 tokens/request, documented), II ✅ (on-device), IV ✅, VIII deviations listed ✅.

- [X] T001 [US1] `MyClickyCore/Logic/WakeWords.swift`: phonetic matcher, split-name merge, blocklist, `canonical`
- [X] T002 [US1] `MyClickyChecks/WakeWordChecks.swift`: variants, greetings, agent words, negatives
- [X] T003 [US2] `Voice/SpeechRecognizer.swift`: prime contextual strings; canonical name; language of the result;
  agent call seen in any session's partial
- [X] T004 [US3] `MyClickyCore/Logic/ReplyLanguage.swift` + checks: resolve language, instruction line, spoken lines
- [X] T005 [US3] `Talk/Assistant.swift` + `ClaudeClient.talkBody`: language through Talk; `SpeechQueue` lock
- [X] T006 [US3] `Agents/AgentSupervisor.swift` + `Prompts.agent`: language in the agent prompt and announcements
- [X] T007 [US4] `Talk/Prompts.swift` identity; copy ("Clicky…" → "Jarvis…") in tips, onboarding, settings, bubbles
- [X] T008 Docs: CLAUDE.md voice rule, specs/README.md, CHANGELOG, report
- [X] T009 Try it (you): the variants in both languages, an English page + Spanish question, an agent in Spanish

## Implementation notes

Implemented 2026-10-01. `swift build` ✓, `swift run MyClickyChecks` → 487 passed (77 in `WakeWordChecks`, incl. 9 for
`ReplyLanguage`). Screens with changed copy re-rendered.

- **Sound matching** (`WakeWords`): words are scanned from the start (optional greeting), each turned into a sound
  key (j/h/y/ll/soft g/ch → H, v/b/w → B, s/z/x/soft c → S, c/k/q → K, vowels → A/I/U, repeats collapse). A word is
  the name if its key is within one edit of `HARBIS`, contains the v/b sound (rules out Harris, Charles, Paris) and
  isn't in a small blocklist (harvest…). Two short words run together count ("jar vis"). `canonical` rewrites the
  heard variant to "Jarvis" before the text is routed and saved. Plain "agent…" still works; "Clicky" is gone.
- **Recognizer**: Talk starts both recognizers with `WakeWords.hints` as contextual strings (dictation doesn't get
  them). `lastLanguage` reports the winning language; the agent bot checks every language's partial transcript.
- **Language lock**: `ReplyLanguage.resolve` (heard → guessed from text → previous → dictation language). Talk adds
  `ReplyLanguage.instruction` as a text block in the user turn (the cached system prompt stays identical, ~15 tokens),
  and `SpeechQueue.begin(language:)` uses one voice for the whole answer. Agents get the instruction appended to their
  system prompt; their spoken start/finish lines come from `ReplyLanguage.text` in the request's language ("Build Lab
  terminó."). Notification titles stay in English.
- **Identity**: `Prompts.assistant` says it's Jarvis inside MyClicky and suggests "Jarvis agent…"; "Clickys" are
  "agents" in all user-facing copy (internal type names and the JSON keys in Claude prompts are unchanged). New
  agents without a name are "New agent N".
