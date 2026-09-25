# Implementation Plan: Voice Talk

**Branch**: `007-voice-talk` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

Switch `ClaudeClient` to streaming (SSE over `URLSession.bytes`), parse events with a Core `SSEParser`, cut text
into sentences with a Core `SentenceSplitter`, and feed a `SpeechQueue` (AVSpeechSynthesizer utterance queue, voice
chosen per sentence language via `NLLanguageRecognizer`). The bubble advances on `willSpeakRangeOfSpeechString`.
Add microphone device selection (CoreAudio), a level meter, the Voice and Microphone pages, and a `QuietMonitor`.

## Technical Context

**Language/Version**: Swift 6.4 (Swift 5 mode)

**Primary Dependencies**: Foundation (URLSession bytes), AVFoundation (AVSpeechSynthesizer, AVAudioEngine),
CoreAudio (devices, "running somewhere"), NaturalLanguage (language ID), Speech

**Storage**: settings `speechSpeed` (1.0), `voiceByLanguage` ({"en": id, "es": id}), `microphoneUID` ("" = default),
`quietOverride` (none/on/off + until). Migrates v0.1 `voiceIdentifier` and `speechRate`

**Testing**: Checks for SSEParser (fragmented chunks, pings, errors, stop reasons), SentenceSplitter (EN/ES
abbreviations, decimals, ¿¡, ellipsis, tags), speed→rate map, voice ranking, quiet reasons combination

**Performance Goals**: first audio ≤ 2.5 s median; interrupt ≤ 100 ms

## Constitution Check

| Principle | Check |
|---|---|
| I | ✅ Cost impact none |
| II | ✅ Apple voices, on-device speech and language ID |
| IV | ✅ Audio stays local |
| VI | ✅ Parsers/splitter in Core |
| VII | ✅ Checks listed |
| VIII | ✅ Refs 04/05. Deviations listed |

## Project Structure

```text
Sources/MyClickyCore/Logic/SSEParser.swift            # "event:/data:" lines → MessageStreamEvent
Sources/MyClickyCore/Logic/SentenceSplitter.swift     # incremental; yields complete sentences, keeps the tail
Sources/MyClickyCore/Logic/VoiceRanking.swift         # quality > region match > name; speed → AVSpeech rate table
Sources/MyClickyCore/Logic/QuietPolicy.swift          # reasons + override → isQuiet
Sources/MyClicky/Talk/ClaudeClient.swift              # + stream(…) → AsyncThrowingStream<String> + final Usage
Sources/MyClicky/Talk/Assistant.swift                 # streaming pipeline: text → tags filter → splitter → SpeechQueue
Sources/MyClicky/Voice/SpeechQueue.swift              # replaces Speaker: per-sentence utterances, language → voice, callbacks
Sources/MyClicky/Voice/AudioDevices.swift             # list inputs, UID ↔ AudioDeviceID, change notifications
Sources/MyClicky/Voice/SpeechRecognizer.swift         # + input device selection, level publishing
Sources/MyClicky/Voice/QuietMonitor.swift             # mic in use elsewhere, Focus, screen sharing (best-effort)
Sources/MyClicky/Settings/VoicePage.swift  MicrophonePage.swift  LevelMeter.swift
Sources/MyClickyChecks/VoiceChecks.swift
```
