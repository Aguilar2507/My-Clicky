# Research: Settings Shell

## R1 Global keys incl. fn

- **Decision**: `CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
  eventsOfInterest: flagsChanged | keyDown | keyUp)`. fn = `CGEventFlags.maskSecondaryFn`. The callback returns the
  event unchanged, except it swallows the flagsChanged event for a modifier-only binding's own press/release, and only
  when that binding just fired.
- **Rationale**: `NSEvent` global monitors can't swallow events, and they don't report some fn transitions reliably.
  A default (active) tap needs Accessibility. Listening to key events in other apps also needs Input Monitoring
  (`CGPreflightListenEventAccess` / `CGRequestListenEventAccess`).
- **Resilience**: On `.tapDisabledByTimeout` / `.tapDisabledByUserInput`, re-enable with `CGEvent.tapEnable`.
- **As built (2026-09-25)**: flagsChanged events are never swallowed, only key-down events of `press` combos.
  Swallowing modifier changes risks stuck modifiers in other apps, and the fn/🌐 system action can't be blocked this way anyway (R2).

## R2 The 🌐/fn system action

- **Decision**: Read `AppleFnUsageType` from the `com.apple.HIToolbox` preferences domain with
  `CFPreferencesCopyAppValue`. 0 = Do Nothing, 1 = Change Input Source, 2 = Show Emoji & Symbols, 3 = Start Dictation.
  If it isn't 0 and fn is bound, show a warning with a button that opens
  `x-apple.systempreferences:com.apple.Keyboard-Settings.extension`.
- **Rationale**: macOS handles the globe key below the event tap, so swallowing the event can't reliably stop
  the emoji picker. Asking the user to set "Do Nothing" is what HeyClicky-like apps do.

## R3 Hold vs double-tap vs combos

- **Decision**: Pure matcher state machine:
  - *Hold binding* (modifiers only): `began` when exactly those modifiers go down with no other modifier and no
    key pressed since; `ended` on the first release. Cancelled (no `ended` send, `cancelled` instead) if a regular key
    is pressed while held.
  - *Double-tap binding*: down-up-down within 0.35 s, with each tap under 0.3 s held and no keys in between →
    `triggered` (or `began` for hands-free, stopped by the next double-tap).
  - *Combo binding* (modifiers + key): `triggered` on keyDown.
  - A hold binding that is a prefix of a double-tap binding (Dictate ⌃fn vs Hands-free ⌃fn⌃fn) waits for release:
    a short press (< 0.3 s) is a tap, and a long press is a hold.
- **Rationale**: Covers every gesture in `07-settings-shortcuts.png`. Time is injected, so checks are deterministic.

## R4 Excluding MyClicky from screen recordings

- **Decision**: When the setting is off, set `window.sharingType = .none` on every MyClicky window (notch panels,
  pop-out, companion, bubbles, drawings).
- **Risk**: Recent macOS versions may ignore `sharingType` for some ScreenCaptureKit-based recorders. The quickstart
  verifies with QuickTime and one video-call app, and the result is documented honestly on the page.
  MyClicky's own screenshots always exclude MyClicky (via `SCContentFilter`), regardless of this setting.

## R5 Changelog

- **Decision**: `Resources/CHANGELOG.md`, maintained by hand per feature, copied into `Contents/Resources/` by
  `build.sh`, rendered with `AttributedString(markdown:)`.
