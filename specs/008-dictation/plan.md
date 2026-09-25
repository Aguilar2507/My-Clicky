# Implementation Plan: Dictation

**Branch**: `008-dictation` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

A `DictationController` reacts to the `dictate` (hold) and `handsFreeDictation` (double-tap toggle) actions. It
shares a refactored `SpeechRecognizer` that can run one or two on-device recognizers (en + es) on the same audio.
A Core `LanguagePicker` chooses the winning transcript, and `CustomWords` fixes spelling. `TextInserter` checks the
focused element via Accessibility (refusing secure fields), then pastes via a synthesized ⌘V with clipboard save/restore.

## Technical Context

**Language/Version**: Swift 6.4 (Swift 5 mode)

**Primary Dependencies**: Speech (SFSpeechRecognizer on-device, `contextualStrings`), AVFoundation, ApplicationServices
(AXUIElement), CoreGraphics (CGEvent ⌘V), AppKit (NSPasteboard), NaturalLanguage (tie-break)

**Storage**: settings `dictationAutoDetect` (true), `dictationLanguage` ("en"), `spanishLocale` (auto), `customWords` ([])

**Testing**: Checks for LanguagePicker, CustomWords (case/whole-word), SpacingRule, the language → locale mapping

**Performance Goals**: insertion ≤ 1 s after release

## Constitution Check

| Principle | Check |
|---|---|
| I | ✅ Cost none |
| II | ✅ On-device Speech |
| IV | ✅ Transcript never leaves the Mac or chats; clipboard restored |
| V | n/a |
| VI | ✅ Pure choice/fix logic in Core |
| VII | ✅ Checks listed |
| VIII | ✅ Ref 06 (reduced languages, deviation listed) |

## Project Structure

```text
Sources/MyClickyCore/Logic/LanguagePicker.swift     # pick en/es result by confidence + NL tie-break
Sources/MyClickyCore/Logic/CustomWords.swift        # whole-word, case-insensitive respelling
Sources/MyClickyCore/Logic/SpacingRule.swift        # add a leading space? (prev char + text start)
Sources/MyClicky/Voice/SpeechRecognizer.swift       # multi-locale sessions, partials, contextualStrings, finals with confidence
Sources/MyClicky/Dictation/DictationController.swift
Sources/MyClicky/Dictation/TextInserter.swift       # AX focus check, secure field refusal, paste + restore
Sources/MyClicky/Dictation/DictationIndicator.swift # "Dictating…" pill next to the companion (uses BubbleLayer styles)
Sources/MyClicky/Settings/DictationPage.swift
Sources/MyClickyChecks/DictationChecks.swift
```
