# Research: Welcome Tour

## R1 Live permission status

- **Decision**: Poll once per second while the Permissions step is visible:
  - Microphone: `AVCaptureDevice.authorizationStatus(for: .audio)`
  - Speech: `SFSpeechRecognizer.authorizationStatus()`
  - Screen Recording: `CGPreflightScreenCaptureAccess()`
  - Accessibility: `AXIsProcessTrusted()`
  - Input Monitoring: `CGPreflightListenEventAccess()`

  Screen Recording and Input Monitoring often only take effect after a relaunch. If the preflight still says no after
  the user flips the switch, show "Relaunch MyClicky".
- **Relaunch**: `open -n` of the app bundle via `Process`, then `NSApp.terminate`. On launch, the tour resumes from `tour.step`.

## R2 Key test

- **Decision**: `max_tokens: 1` Haiku request with the text "hi" through `PaidRequestGate` (kind `interview`). Success
  = HTTP 200. The 401/403 message is shown verbatim.

## R3 Interview generation

- **Decision**: If `ClaudeCodeLocator` reports ready: `claude -p "<prompt>" --output-format json --max-turns 1
  --allowedTools ""` and parse `result`. Else Haiku with the same prompt. The prompt asks for strict JSON:
  three helpers, each with a 1–3 word playful name, a palette color and a purpose paragraph that works as agent
  instructions. Parse with `InterviewParser` and dedupe names against existing Clickys.

## R4 Intro animation

- **Decision**: Three SwiftUI cards (notch → companion → Clickys) with simple matched-geometry transitions and the
  mascot. No video files.
