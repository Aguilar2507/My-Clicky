---
description: "Tasks for 008-dictation"
---

# Tasks: Dictation

**Input**: `specs/008-dictation/` · **Tests**: Core checks required

## Phase 1: Setup

- [ ] T001 Add dictation settings to `Settings.swift` + migrate `speechLocale` (+ MigrationChecks)
- [ ] T002 Create `Sources/MyClicky/Dictation/`

## Phase 2: Foundational

- [ ] T003 [P] `MyClickyCore/Logic/LanguagePicker.swift`
- [ ] T004 [P] `MyClickyCore/Logic/CustomWords.swift`
- [ ] T005 [P] `MyClickyCore/Logic/SpacingRule.swift`
- [ ] T006 [P] `MyClickyChecks/DictationChecks.swift`: picker by confidence + tie-break, custom words (whole word, casing,
      accents), spacing cases (after letter, after space, text starting with punctuation), locale mapping
- [ ] T007 Refactor `Voice/SpeechRecognizer.swift` into sessions: locales [1–2], partial callback, contextualStrings,
      final results with confidences. Push-to-talk uses it with the dictation language settings

## Phase 3: US1 – hold to dictate (P1) 🎯

- [ ] T008 [US1] `Dictation/TextInserter.swift` (AX focus + secure check, paste + restore, spacing)
- [ ] T009 [US1] `Dictation/DictationController.swift` for the `dictate` hold action (began → record, ended → pick → words → insert)
- [ ] T010 [US1] `Dictation/DictationIndicator.swift` + companion listening state

## Phase 4: US3 – languages & words page (P1)

- [ ] T011 [US3] `Settings/DictationPage.swift` per contracts/ui-dictation.md (auto-detect, two cards + region menu, WORDS)

## Phase 5: US2 – hands-free (P2)

- [ ] T012 [US2] Hands-free toggle on the `handsFreeDictation` action. Live transcript in the bubble. Esc cancels. 10-min cap

## Phase 6: US4 – safety (P2)

- [ ] T013 [US4] Password refusal + clipboard fallback notices. The offline-model-missing notice with instructions

## Phase 7: Polish

- [ ] T014 Mark the Dictation page available. Update README/GUIDE
- [ ] T015 Run quickstart.md and record the results

## Dependencies

Setup → Foundational → US1 → US3 → (US2 ∥ US4) → Polish.
