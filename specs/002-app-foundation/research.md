# Research: App Foundation

## R1 Test framework without Xcode

- **Decision**: `MyClickyChecks` executable target with a ~60-line `Check` helper (`check(_:_:)`, `expectEqual`,
  grouped output, exit code 1 on failure). It depends on `MyClickyCore`.
- **Rationale**: Tried 2026-09-24 on this Mac (CLT only, Swift 6.4, macOS 27). `import XCTest` fails with "unable
  to resolve module dependency: 'XCTest'", and Swift Testing fails with "plugin for module 'TestingMacros' not found".
- **Alternatives**: Install Xcode (works, but ~15 GB; allowed later by Principle VII). Test through the app
  (slow, not automatable).

## R2 Library + executable split

- **Decision**: Put pure logic in a `MyClickyCore` library with no AppKit imports. The app and the checks runner depend on it.
- **Rationale**: The checks runner can't import an executable target's internals without `@testable` (XCTest
  only). A library also forces clean boundaries.
- **Alternatives**: Duplicate the logic in checks (drifts); `@testable import` of the executable (no XCTest).

## R3 Storage format

- **Decision**: Codable JSON, one file per chat (`chats/<uuid>.json`), `settings.json` with `"version": 2`,
  `usage.json` unchanged in shape. Write to a temp file in the same folder, then use `FileManager.replaceItemAt`
  (atomic). Saves are debounced 300 ms on a background queue; pending saves are flushed on quit.
- **Rationale**: Human-readable, easy to back up, easy to check. A debounce well under 1 s meets FR-002.
- **Alternatives**: SwiftData/Core Data (more machinery and harder to inspect); a single `chats.json` (one damaged file loses everything).

## R4 Tolerant decoding

- **Decision**: Every Core model decodes each key with `decodeIfPresent ?? default` (the pattern already used in
  `Config.swift`), via a small `KeyedDecodingContainer.value(_:default:)` helper to keep it short.
- **Rationale**: FR-003. Adding settings in later features must never reset the user's values.

## R5 Legacy migration

- **Decision**: On launch, if `settings.json` is missing and `config.json` exists, map its keys into `Settings`, save
  it, and rename `config.json` → `config.v1.backup.json`.
- **Rationale**: FR-001, runs once, and the backup allows a manual rollback.

## R6 State management

- **Decision**: `@Observable final class AppModel` (Observation, macOS 14) owns the stores and services. SwiftUI views
  read it through `@Environment(AppModel.self)`.
- **Rationale**: Native, no Combine boilerplate, and it works with AppKit-hosted SwiftUI (`NSHostingView`).

## R7 Design system

- **Decision**: SwiftUI components with values from the roadmap's visual language table (`Theme` enum of colors,
  fonts, radii and spacing). The glossy pill uses a `LinearGradient` fill, a white top highlight overlay and a soft
  shadow. The toggle is a custom `ToggleStyle`. `DesignGallery` opens with `--gallery`.
- **Rationale**: HeyClicky's controls are custom, not stock AppKit. One source of truth keeps them identical everywhere.
