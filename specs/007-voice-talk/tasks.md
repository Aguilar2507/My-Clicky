---
description: "Tasks for 007-voice-talk"
---

# Tasks: Voice Talk

**Input**: `specs/007-voice-talk/` · **Tests**: Core checks required

## Phase 1: Setup

- [X] T001 Add `speechSpeed`, `voiceByLanguage`, `microphoneUID`, `quietOverride` to `Settings.swift` + migration from
      `voiceIdentifier`/`speechRate` in `SettingsStore` (+ MigrationChecks cases)

## Phase 2: Foundational

- [X] T002 [P] `MyClickyCore/Logic/SSEParser.swift`
- [X] T003 [P] `MyClickyCore/Logic/SentenceSplitter.swift`
- [X] T004 [P] `MyClickyCore/Logic/VoiceRanking.swift` (ranking + speed→rate table)
- [X] T005 [P] `MyClickyCore/Logic/QuietPolicy.swift`
- [X] T006 [P] `MyClickyChecks/VoiceChecks.swift`: SSE fragments split across reads, ping/error, usage totals;
      splitter EN/ES cases incl. "e.g.", "3.5", "v2.1", "¿Qué? ¡Sí!", tag tails; ranking; quiet combos + expiry

## Phase 3: US1 – fast spoken answers (P1) 🎯

- [X] T007 [US1] `Talk/ClaudeClient.swift`: `stream(…)` using SSEParser. Keep non-streaming for summaries/naming
- [X] T008 [US1] `Voice/SpeechQueue.swift` (replaces `Speaker.swift`): enqueue sentences, language → voice, rate from
      speed, `willSpeakRange` → bubble, `stopNow()`
- [X] T009 [US1] `Talk/Assistant.swift` streaming pipeline (visible text via ScreenTags → splitter → queue; tags handled at the end;
      partial answer saved on error; usage recorded)
- [X] T010 [US1] Push-to-talk via the `pushToTalk` action (004). Interrupt stops SpeechQueue + clears bubble/drawings

## Phase 4: US2 – Voice page (P1)

- [X] T011 [US2] `Settings/VoicePage.swift` per contracts/ui-voice-mic.md (speed chips, per-language grids, preview, get more voices)

## Phase 5: US3 – Microphone page (P2)

- [X] T012 [US3] `Voice/AudioDevices.swift` (list, UID mapping, change listener)
- [X] T013 [US3] `SpeechRecognizer.swift`: apply the selected device before start. Publish the level (also to the companion)
- [X] T014 [US3] `Settings/MicrophonePage.swift` + `LevelMeter.swift` (16 bars, 10 s test)

## Phase 6: US4 – quiet mode (P2)

- [X] T015 [US4] `Voice/QuietMonitor.swift` (mic-in-use, Focus attempt, sharing window scan) → QuietPolicy
- [X] T016 [US4] Quiet answers: bubble with a 🔇 button that plays on click. Notch right-click "Quiet mode" override (1 h)

## Phase 7: Polish

- [X] T017 Mark the Voice and Microphone pages available. Update README/GUIDE (fn, voices, quiet mode)
- [ ] T018 Run quickstart.md and fill in the Notes

## Dependencies

Setup → Foundational → US1 → (US2 ∥ US3 ∥ US4) → Polish.

## Implementation notes

Implemented 2026-09-25. `swift build` ✓, checks: 5 voice groups (40 checks) pass; 232 total.

- Streaming: `ClaudeClient.stream` reads SSE lines with `URLSession.bytes`; text goes through
  `ScreenTags.visibleText` (tags never spoken) → `SentenceSplitter` → `SpeechQueue`. The bubble grows as each
  sentence starts. A dropped connection keeps what was said, saves the partial answer with "…connection lost", and
  still records the usage.
- **Found by the checks**: "p. ej." split after "p."; Spanish abbreviations added.
- **Found in the Voice page snapshot**: this Mac has no Premium/Enhanced voices, so plain quality ranking put robotic
  voices (Eddy, Flo, Fred, Grandma) first. Ranking now prefers natural voice families (Siri/Premium > Enhanced >
  compact > super-compact > Eloquence/old synthesis), shows each name once, labels robotic ones, and the page shows
  a "download a Premium voice" hint. Samantha is now the default English voice. A Siri voice ("Voice 4"/Nora) is
  listed by macOS for command-line scripts but not inside the app, so it isn't offered.
- The Microphone page snapshot lists this Mac's real inputs (System Default, MacBook Pro Microphone, Microsoft Teams
  Audio), as in ref 05.
- Quiet answers: the bubble is click-through, so a separate "🔇 Play answer" chip (`QuietPlayChip`) is shown for 12 s.
  Focus detection uses `INFocusStatusCenter` and may be refused for ad-hoc-signed apps; call detection uses "mic in
  use elsewhere"; screen-sharing detection scans for known sharing windows. All best-effort, as the spec says.
- `Speaker.swift` was removed (replaced by `SpeechQueue`). `LevelMeter` and `MicTester` live in `Settings/MicrophonePage.swift`.
- **T018 not done**: needs the running app with your API key (latency stopwatch vs v0.1, interrupting, Spanish voice,
  calls/Focus/sharing detection). → **Needs you.**
