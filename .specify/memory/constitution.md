# MyClicky Constitution

## Core Principles

### I. Cost First

- The target is that $20 of Anthropic API credit lasts at least 2–3 months of personal daily use.
- `claude-haiku-4-5` MUST be the default model. A pricier model is allowed only for a request type
  that measurably needs it, as `claude-sonnet-5` is used for on-screen pointing, and only through
  explicit routing.
- Every spec MUST include an **API cost impact** note: added or removed tokens per request, which model,
  and the estimated cost per request, or "none".
- Images sent to the API MUST be downscaled (currently to a 1280px long edge). Conversation history
  and memory MUST NOT store or resend old screenshots.
- Background work (agents, daily suggestions) MUST run on the Claude subscription through Claude Code,
  not on the API key.
- API spend MUST stay visible to the user (the spend indicator in the app).

Rationale: the reason this project exists is to be a much cheaper alternative to a $20/month subscription.

### II. Free & On-Device First

- Speech-to-text, dictation, text-to-speech, screen capture and hotkeys MUST use built-in macOS frameworks
  (Speech, AVFoundation, ScreenCaptureKit, AppKit/SwiftUI, CoreGraphics) before any paid or cloud service.
- A paid external service may be added only through its own spec that shows the free option cannot meet
  the need and states the recurring cost. It MUST be off by default.

### III. Personal, Single-User App

- MyClicky is built for one user on their own Mac. There are no accounts, sign-in, plans, servers,
  telemetry, analytics, auto-updates or App Store requirements.
- Where HeyClicky shows account or plan information, MyClicky shows a local profile (name and initial)
  and API spend instead.
- Features MUST NOT add infrastructure (backends, hosted services) to serve other users.

### IV. Privacy by Default

- Secrets (Anthropic API key, integration tokens) MUST be stored only in the macOS Keychain (or the
  `ANTHROPIC_API_KEY` environment variable), never in files, logs or git.
- Microphone audio MUST stay on the Mac (on-device recognition when available).
- Screenshots and transcripts may go only to the Anthropic API or Claude Code, and only when the user
  asks something or starts an agent.
- Chats, memory summaries and settings are stored locally as plain files that MUST NOT contain secrets
  or images.

### V. Agent Safety

- Agents MUST NOT take irreversible or outward-facing actions without an explicit user confirmation.
  This covers sending messages or email, deleting data, purchases, posting online and changing system
  settings. It applies even when "Always allow computer use" is on.
- Computer use (clicking and typing on the user's Mac) MUST ask with an Allow card unless the user has
  turned on "Always allow computer use".
- Agents MUST be stoppable from their chat and from the notch, MUST have a time limit, and work inside the
  agent folder by default.
- Any feature that widens agent permissions MUST spell out the new risk in its spec.

### VI. Native Simplicity

- Swift with AppKit and SwiftUI, built with Swift Package Manager and `build.sh`. No third-party
  dependencies unless a spec justifies them.
- Package layout: `MyClickyCore` (library: models, stores, parsing, pure logic; Foundation only),
  `MyClicky` (the app), `MyClickyChecks` (test runner), plus helper executables that a spec justifies.
- Each file has one clear responsibility. The Anthropic API is called over raw HTTPS (no official Swift SDK).
- Prefer the smallest change that meets the spec. No speculative abstractions.

### VII. Verifiable Changes

- `swift build` MUST succeed with no errors after every change.
- Pure logic in `MyClickyCore` (routing, tag parsing, cost math, settings decoding, stores, shortcut
  matching) MUST have checks in `MyClickyChecks`, run with `swift run MyClickyChecks`, which MUST pass.
  If Xcode is installed later, the checks MAY move to XCTest.
- Behavior that needs the real app (notch, hotkeys, overlays, speech, permissions) MUST be checked by
  building and running it, following the feature's `quickstart.md`. Results MUST be reported honestly.

### VIII. HeyClicky Parity

- Layout, wording, flows and behavior MUST match HeyClicky as shown in `references/heyclicky/`
  (kept out of git), unless another principle forbids it.
- Allowed deviations: anything the other principles forbid (accounts, plans, paid services, cloud
  backends), and original branding. MyClicky uses its own name, logo and mascot art, never HeyClicky's.
- Every spec MUST list its deviations from HeyClicky and the reason for each.

## Technical Constraints

- Platform: macOS 14+ (developed on macOS 27), Apple Silicon. Lives in the MacBook notch, with an
  equivalent top-center pill on displays without a notch. The Dock icon is optional and off by default.
- Permissions: Microphone, Speech Recognition, Screen Recording, Accessibility, Input Monitoring.
  New permissions MUST be justified in a spec and described in `Resources/Info.plist`.
- Data lives in `~/Library/Application Support/MyClicky/` (`settings.json`, `chats/`, `usage.json`).
  New settings MUST have defaults and MUST NOT reset existing values.
- Agents run the Claude Code CLI on the user's Claude subscription, not the API key.
- Languages: English and Spanish.

## Development Workflow

- **Features** (new behavior, new settings, new integrations) go through Spec Kit:
  `/speckit-specify` → (`/speckit-clarify`) → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`
  → `/speckit-converge`. Specs live in `specs/NNN-name/`. The build order is in `specs/README.md`.
- **Small fixes** (bugs, typos, wording, a single constant) are fixed directly with a clear commit message.
  No spec is needed.
- Every plan MUST include a Constitution Check against Principles I–VIII.
- Commits stay focused: one feature or fix per commit.

## Governance

- This constitution overrides ad-hoc habits and earlier vibe-coded conventions. Where code conflicts
  with it, the code is changed or the constitution is amended. Neither is silently ignored.
- Amendments go through `/speckit-constitution` with a version bump: MAJOR for removing or redefining a principle,
  MINOR for a new principle or section, PATCH for wording.
- Runtime guidance for AI assistants lives in `CLAUDE.md` and MUST stay consistent with this document.

**Version**: 2.0.0 | **Ratified**: 2026-09-24 | **Last Amended**: 2026-09-24
