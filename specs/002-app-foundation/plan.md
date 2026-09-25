# Implementation Plan: App Foundation

**Branch**: `002-app-foundation` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-app-foundation/spec.md`

## Summary

Split the package into `MyClickyCore` (pure logic and storage), `MyClicky` (app) and `MyClickyChecks`
(test runner), and group app files by feature. Replace `config.json` with a versioned `settings.json`
behind a `SettingsStore`, with a one-time migration. Add a `ChatStore` (one JSON file per chat) and move
`UsageLog` into a Core `UsageStore` plus `Pricing`. Add the shared SwiftUI design system and a developer
design gallery. Behavior stays identical to the baseline.

## Technical Context

**Language/Version**: Swift 6.4 toolchain, Swift 5 language mode (as today), `swift-tools-version:5.10`

**Primary Dependencies**: Apple frameworks only: Foundation (Core); AppKit, SwiftUI, Observation (app)

**Storage**: JSON files in `~/Library/Application Support/MyClicky/`, written atomically

**Testing**: `MyClickyChecks` executable (`swift run MyClickyChecks`). XCTest and Swift Testing don't build with
Command Line Tools only (see research.md R1)

**Target Platform**: macOS 14+ (developed on macOS 27), Apple Silicon

**Project Type**: desktop app (menu-bar/notch agent)

**Performance Goals**: load settings + 200 chats in < 200 ms at launch; save < 20 ms

**Constraints**: no third-party packages; no behavior change for v0.1 features

**Scale/Scope**: ~25 source files moved/split, ~10 new Core files, ~8 design system components

## Constitution Check

| Principle | Check |
|---|---|
| I Cost First | ✅ No API changes. Cost impact: none |
| II Free & On-Device | ✅ Apple frameworks only |
| III Personal | ✅ Local files only |
| IV Privacy | ✅ Stores never hold the API key or images. The key stays in Keychain |
| V Agent Safety | ✅ Agent code only moves |
| VI Native Simplicity | ✅ Creates the Core/App/Checks layout the constitution requires |
| VII Verifiable | ✅ Adds the checks runner, with checks for every Core file |
| VIII Parity | ✅ Design tokens copied from the reference screenshots |

Post-design re-check: passes, no violations.

## Project Structure

### Documentation (this feature)

```text
specs/002-app-foundation/
├── plan.md  research.md  data-model.md  quickstart.md  tasks.md
└── contracts/storage.md     # on-disk file formats + migration rules
```

### Source Code (repository root)

```text
Package.swift                         # 3 targets: MyClickyCore (library), MyClicky, MyClickyChecks
Sources/MyClickyCore/
├── Models/  Settings.swift  Chat.swift  Message.swift  UsageMonth.swift
├── Stores/  AppPaths.swift  JSONFile.swift  SettingsStore.swift  ChatStore.swift  UsageStore.swift
│            LegacyConfigMigration.swift
└── Logic/   Router.swift  PointTag.swift  Pricing.swift
Sources/MyClicky/
├── App/            Main.swift  AppDelegate.swift  AppModel.swift  Permissions.swift
├── DesignSystem/   Theme.swift  SectionLabel.swift  SettingsCard.swift  PillButton.swift
│                   GlossyToggle.swift  SelectableCard.swift  MascotAvatar.swift  DesignGallery.swift
├── Talk/           Assistant.swift  ClaudeClient.swift  ScreenCapture.swift  Keychain.swift  Prompts.swift
├── Voice/          SpeechRecognizer.swift  Speaker.swift
├── Companion/      Overlay.swift
└── Agents/         AgentRunner.swift
Sources/MyClickyChecks/
├── main.swift  Check.swift
└── RouterChecks.swift  PointTagChecks.swift  PricingChecks.swift  SettingsChecks.swift  ChatStoreChecks.swift
    UsageStoreChecks.swift  MigrationChecks.swift
```

**Structure Decision**: the shared architecture in `specs/README.md`. Features 003–012 add folders under
`Sources/MyClicky/` and files under `Sources/MyClickyCore/`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Homemade checks runner instead of XCTest | CLT-only machine can't build XCTest/Swift Testing | Installing Xcode (~15 GB) just for tests; documented as an optional later switch |
