---
description: "Tasks for 008-dictation"
---

# Tasks: Dictation

**Input**: `specs/008-dictation/` · **Tests**: Core checks required

## Phase 1: Setup

- [X] T001 Add dictation settings to `Settings.swift` + migrate `speechLocale` (+ MigrationChecks)
- [X] T002 Create `Sources/MyClicky/Dictation/`

## Phase 2: Foundational

- [X] T003 [P] `MyClickyCore/Logic/LanguagePicker.swift`
- [X] T004 [P] `MyClickyCore/Logic/CustomWords.swift`
- [X] T005 [P] `MyClickyCore/Logic/SpacingRule.swift`
- [X] T006 [P] `MyClickyChecks/DictationChecks.swift`: picker by confidence + tie-break, custom words (whole word, casing,
      accents), spacing cases (after letter, after space, text starting with punctuation), locale mapping
- [X] T007 Refactor `Voice/SpeechRecognizer.swift` into sessions: locales [1–2], partial callback, contextualStrings,
      final results with confidences. Push-to-talk uses it with the dictation language settings

## Phase 3: US1 – hold to dictate (P1) 🎯

- [X] T008 [US1] `Dictation/TextInserter.swift` (AX focus + secure check, paste + restore, spacing)
- [X] T009 [US1] `Dictation/DictationController.swift` for the `dictate` hold action (began → record, ended → pick → words → insert)
- [X] T010 [US1] `Dictation/DictationIndicator.swift` + companion listening state

## Phase 4: US3 – languages & words page (P1)

- [X] T011 [US3] `Settings/DictationPage.swift` per contracts/ui-dictation.md (auto-detect, two cards + region menu, WORDS)

## Phase 5: US2 – hands-free (P2)

- [X] T012 [US2] Hands-free toggle on the `handsFreeDictation` action. Live transcript in the bubble. Esc cancels. 10-min cap

## Phase 6: US4 – safety (P2)

- [X] T013 [US4] Password refusal + clipboard fallback notices. The offline-model-missing notice with instructions

## Phase 7: Polish

- [X] T014 Mark the Dictation page available. Update README/GUIDE
- [ ] T015 Run quickstart.md and record the results

## Dependencies

Setup → Foundational → US1 → US3 → (US2 ∥ US4) → Polish.

## Implementation notes

Implemented 2026-09-25. `swift build` ✓, checks: 4 dictation groups (23 checks) pass; 255 total.

- `SpeechRecognizer` was rewritten around "sessions": one on-device recognizer per language on the same microphone
  audio. With auto-detect, English + Spanish run together and `LanguagePicker` keeps the more confident result
  (NaturalLanguage breaks close calls). Push-to-talk and the composer mic use the same language settings (FR-004).
  Custom words are passed as `contextualStrings` and then forced with `CustomWords.apply`.
- Insertion is paste-first (`TextInserter`): Accessibility tells us if the focused element is a password field
  (refused) or editable; text is pasted with a synthesized ⌘V and every clipboard type is restored 0.4 s later
  (unless you copied something new meanwhile). Smart leading space when the app exposes the caret position.
- The "Dictating…" indicator is the companion's bubble (red listening dot) rather than a separate
  `DictationIndicator.swift`; hands-free shows the live transcript there. Esc is caught through the shortcut tap.
- The `Dictation.swift` Core file holds `LanguagePicker`, `CustomWords`, `SpacingRule` and `RecognitionResult`.
- Settings v4 migrates v0.1's `speechLocale` into the dictation language (+ Spanish region). The old
  `Settings.locale` helper was removed.
- Snapshot `settings-dictation` matches ref 06's layout (two language cards instead of 60, as the spec says).
- **T015 not done**: needs the running app (insertion in Notes/Safari/Slack/VS Code/Mail, clipboard restore, password
  refusal, hands-free for 2 minutes, 10-sentence auto-detect test). → **Needs you.**
