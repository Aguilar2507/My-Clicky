# Research: Voice Talk

## R1 Streaming the Messages API

- **Decision**: Add `"stream": true` to the request and read `URLSession.shared.bytes(for:)` line by line. Handle
  `message_start` (input usage), `content_block_delta` with `text_delta`, `message_delta` (stop_reason, output
  usage), `message_stop`, `ping`, `error`. The final usage is recorded in UsageStore as before.
- **Rationale**: The raw HTTPS approach stays (no Swift SDK). The event names and shape follow the Anthropic
  streaming docs. Verify against the live docs during implementation (claude-api skill).

## R2 Sentence splitting

- **Decision**: Incremental splitter. A sentence ends at `.`, `!`, `?`, `…` or `\n` followed by whitespace, unless the
  token before it is a known abbreviation (EN: e.g., i.e., Mr., Dr., vs., etc.; ES: Sr., Sra., Dr., p. ej., etc.) or
  it's a decimal/version number. The first chunk is flushed early at a comma if > 60 chars, to start speaking sooner.
- **Rationale**: Low latency without chopping mid-thought.

## R3 Voice per language

- **Decision**: `NLLanguageRecognizer.dominantLanguage` per sentence (constrained to en/es, with the previous sentence's
  language as the default for sentences shorter than 20 chars). Voice = `voiceByLanguage[lang]`, else the best-ranked
  installed voice for that language (VoiceRanking: premium > enhanced > default, then region match).
- **Rationale**: Apple voices speak a single language. Mixed-language answers would sound wrong otherwise.

## R4 Speed mapping

- **Decision**: AVSpeechUtterance rate table: 0.5x → 0.38, 0.75x → 0.45, 1x → 0.52, 1.25x → 0.57, 1.5x → 0.62. Tune by ear
  in the quickstart.
- **Rationale**: Perceived speed isn't linear in the rate value. 0.52 matches v0.1's default.

## R5 Microphone device

- **Decision**: List devices with `kAudioHardwarePropertyDevices` + an input-streams check. Store by `kAudioDevicePropertyDeviceUID`.
  Apply with `AudioUnitSetProperty(inputNode.audioUnit, kAudioOutputUnitProperty_CurrentDevice, …)` before
  `engine.start()`. Listen for device list changes and fall back to the default.
- **Level**: RMS of each tap buffer → dB → 0…1 → 16 bars (also feeds the companion's listening pulse).

## R6 Quiet mode detection (best-effort)

- **Calls**: `kAudioDevicePropertyDeviceIsRunningSomewhere` on the default input device while MyClicky isn't recording
  → another app uses the mic.
- **Focus/DND**: Try `INFocusStatusCenter` (requires authorization, and may need an entitlement unavailable to
  ad-hoc-signed apps). If unavailable, it's treated as unknown. Verify on macOS 27 during implementation and record the result.
- **Screen sharing**: `CGWindowListCopyWindowInfo` scan for known sharing UI (Zoom share toolbar, Teams sharing bar,
  Google Meet "is sharing" window, macOS screen-sharing indicator owner). A list is kept in `QuietMonitor` and extended
  over time.
- **Rationale**: There's no single public API for these. Honest best-effort plus the manual override (FR-007).
