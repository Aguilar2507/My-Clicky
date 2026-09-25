# Research: Dictation

## R1 Inserting text in any app

- **Decision**: Paste-first. Save all `NSPasteboard.general` items (every type), write the transcript as `.string`,
  post ⌘V (virtual key 9 with `.maskCommand`) to `.cghidEventTap`, then restore the saved items after 400 ms.
  Before pasting, read `kAXFocusedUIElementAttribute` from the system-wide AX element. Refuse if its role/subrole is
  `AXSecureTextField`. If there's no focused editable element, leave the transcript on the clipboard (FR-007).
- **Rationale**: Setting `kAXSelectedTextAttribute` works in native apps but silently fails in many Electron/web
  apps. Pasting works nearly everywhere and is what popular dictation tools do.
- **Risk**: Clipboard managers may record the transient paste. Accepted.

## R2 Auto-detecting English vs Spanish

- **Decision**: With auto-detect on, run two `SFSpeechRecognitionTask`s (en-US and the Spanish locale) fed by the
  same tap buffers. At the end, `LanguagePicker` compares the mean segment confidence of each final result. If the
  gap is < 0.1, use `NLLanguageRecognizer` on each text as a tie-break.
- **Rationale**: `SFSpeechRecognizer` has no built-in language ID. Two on-device models on Apple Silicon are cheap.
- **Alternatives**: Newer SpeechAnalyzer APIs. Check availability on macOS 27 during implementation, and switch if
  they offer language detection with equal privacy.

## R3 Custom words

- **Decision**: Pass words as `contextualStrings` (boosts recognition). Afterwards, replace case-insensitive
  whole-word matches with the exact spelling (`CustomWords.apply`).

## R4 Hands-free length

- **Decision**: On-device recognition has no 1-minute server limit. Cap hands-free at 10 minutes (FR in US2),
  restarting the task every 5 minutes with overlap if needed. Verify during implementation.

## R5 Leading space

- **Decision**: Best-effort: if AX exposes `kAXValueAttribute` + `kAXSelectedTextRangeAttribute`, read the character
  before the caret. If it's a letter, digit or punctuation (not whitespace), and the transcript doesn't start with
  punctuation, prefix a space.
