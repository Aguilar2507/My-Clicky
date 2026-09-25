---
description: "Tasks for 007-voice-talk"
---

# Tasks: Voice Talk

**Input**: `specs/007-voice-talk/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 Add `speechSpeed`, `voiceByLanguage`, `microphoneUID`, `quietOverride` to `Settings.swift` + migration from
      `voiceIdentifier`/`speechRate` in `SettingsStore` (+ MigrationChecks cases)

## Phase 2: Foundational

- [ ] T002 [P] `MyClickyCore/Logic/SSEParser.swift`
- [ ] T003 [P] `MyClickyCore/Logic/SentenceSplitter.swift`
- [ ] T004 [P] `MyClickyCore/Logic/VoiceRanking.swift` (ranking + speed→rate table)
- [ ] T005 [P] `MyClickyCore/Logic/QuietPolicy.swift`
- [ ] T006 [P] `MyClickyChecks/VoiceChecks.swift`: SSE fragments split across reads, ping/error, usage totals;
      splitter EN/ES cases incl. "e.g.", "3.5", "v2.1", "¿Qué? ¡Sí!", tag tails; ranking; quiet combos + expiry

## Phase 3: US1 – fast spoken answers (P1) 🎯

- [ ] T007 [US1] `Talk/ClaudeClient.swift`: `stream(…)` using SSEParser. Keep non-streaming for summaries/naming
- [ ] T008 [US1] `Voice/SpeechQueue.swift` (replaces `Speaker.swift`): enqueue sentences, language → voice, rate from
      speed, `willSpeakRange` → bubble, `stopNow()`
- [ ] T009 [US1] `Talk/Assistant.swift` streaming pipeline (visible text via ScreenTags → splitter → queue; tags handled at the end;
      partial answer saved on error; usage recorded)
- [ ] T010 [US1] Push-to-talk via the `pushToTalk` action (004). Interrupt stops SpeechQueue + clears bubble/drawings

## Phase 4: US2 – Voice page (P1)

- [ ] T011 [US2] `Settings/VoicePage.swift` per contracts/ui-voice-mic.md (speed chips, per-language grids, preview, get more voices)

## Phase 5: US3 – Microphone page (P2)

- [ ] T012 [US3] `Voice/AudioDevices.swift` (list, UID mapping, change listener)
- [ ] T013 [US3] `SpeechRecognizer.swift`: apply the selected device before start. Publish the level (also to the companion)
- [ ] T014 [US3] `Settings/MicrophonePage.swift` + `LevelMeter.swift` (16 bars, 10 s test)

## Phase 6: US4 – quiet mode (P2)

- [ ] T015 [US4] `Voice/QuietMonitor.swift` (mic-in-use, Focus attempt, sharing window scan) → QuietPolicy
- [ ] T016 [US4] Quiet answers: bubble with a 🔇 button that plays on click. Notch right-click "Quiet mode" override (1 h)

## Phase 7: Polish

- [ ] T017 Mark the Voice and Microphone pages available. Update README/GUIDE (fn, voices, quiet mode)
- [ ] T018 Run quickstart.md and fill in the Notes

## Dependencies

Setup → Foundational → US1 → (US2 ∥ US3 ∥ US4) → Polish.
