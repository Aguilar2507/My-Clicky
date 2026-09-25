---
description: "Tasks for 002-app-foundation"
---

# Tasks: App Foundation

**Input**: `specs/002-app-foundation/` (plan.md, spec.md, research.md, data-model.md, contracts/storage.md)

**Tests**: Required by Principle VII. Core checks live in `Sources/MyClickyChecks/`.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [ ] T001 Update `Package.swift`: library target `MyClickyCore` (path `Sources/MyClickyCore`), executable `MyClicky`
      depending on it, executable `MyClickyChecks` depending on it
- [ ] T002 Create folders `Sources/MyClickyCore/{Models,Stores,Logic}` and `Sources/MyClicky/{App,DesignSystem,Talk,Voice,Companion,Agents}`
- [ ] T003 Move existing app files into their folders (`git mv`, no code changes): Main/AppDelegate → App;
      Assistant/ClaudeClient/ScreenCapture/Keychain/Prompts → Talk; SpeechRecognizer/Speaker → Voice;
      Overlay → Companion; AgentRunner → Agents. Run `swift build`
- [ ] T004 [P] Create the checks helper `Sources/MyClickyChecks/Check.swift` (groups, expectEqual, expect, summary,
      `exit(1)` on failure) and `Sources/MyClickyChecks/main.swift` calling every group

## Phase 2: Foundational (blocking)

- [ ] T005 [P] `Sources/MyClickyCore/Stores/AppPaths.swift`: support folder, `settings.json`, `chats/`, `usage.json`
      (overridable base folder for checks)
- [ ] T006 [P] `Sources/MyClickyCore/Stores/JSONFile.swift`: tolerant read, atomic write (temp + replace), move to `.damaged`
- [ ] T007 [P] `KeyedDecodingContainer.value(_:default:)` helper in `Sources/MyClickyCore/Models/Decoding.swift`
- [ ] T008 Move the pure logic to Core as `public`: `Router` → `Logic/Router.swift`, `PointTag` → `Logic/PointTag.swift`,
      `Usage` price table → `Logic/Pricing.swift`. The app imports `MyClickyCore`

**Checkpoint**: `swift build` passes and the app still works as v0.1.

## Phase 3: User Story 1 – nothing is lost (P1) 🎯

- [ ] T009 [US1] `Sources/MyClickyCore/Models/Settings.swift` with all fields from data-model.md (tolerant decode)
- [ ] T010 [US1] `Sources/MyClickyCore/Stores/LegacyConfigMigration.swift`: config.json → Settings, backup rename, idempotent
- [ ] T011 [US1] `Sources/MyClickyCore/Stores/SettingsStore.swift`: load (runs migration), `update { }` with 300 ms
      debounced atomic save, `flush()`
- [ ] T012 [US1] `Sources/MyClickyCore/Models/UsageMonth.swift` + `Stores/UsageStore.swift` (moved from `UsageLog.swift`, same file format)
- [ ] T013 [US1] Replace `Config` with `SettingsStore` and `UsageLog` with `UsageStore` in the app. Delete
      `Config.swift` and `UsageLog.swift`
- [ ] T014 [P] [US1] Checks: `MigrationChecks.swift` (all v0.1 keys map, backup created, second run no-op),
      `SettingsChecks.swift` (missing keys default, unknown keys ignored), `UsageStoreChecks.swift`, `PricingChecks.swift`,
      `RouterChecks.swift` (the 12 sentences verified on 2026-09-24), `PointTagChecks.swift`

## Phase 4: User Story 2 – saved safely (P1)

- [ ] T015 [P] [US2] `Sources/MyClickyCore/Models/Chat.swift` and `Message.swift` per data-model.md
- [ ] T016 [US2] `Sources/MyClickyCore/Stores/ChatStore.swift`: load all (set damaged files aside), `talkChat()`
      (create on demand), `save(chat)` (debounced per chat), `delete(id)`
- [ ] T017 [US2] `Sources/MyClicky/App/AppModel.swift`: `@Observable` root holding the stores. Flush on `applicationWillTerminate`
- [ ] T018 [US2] Save each Talk question and answer into the Talk chat (text only, `screensSeen`) in `Talk/Assistant.swift`
- [ ] T019 [P] [US2] `ChatStoreChecks.swift`: round trip, damaged file set aside, others still load, id/filename mismatch

## Phase 5: User Story 3 – one look (P2)

- [ ] T020 [P] [US3] `DesignSystem/Theme.swift`: colors, fonts, radii, spacing from the `specs/README.md` visual table
- [ ] T021 [P] [US3] `DesignSystem/SectionLabel.swift`, `SettingsCard.swift` (rows + dividers)
- [ ] T022 [P] [US3] `DesignSystem/PillButton.swift` (styles: primary lavender, secondary white), `GlossyToggle.swift` (ToggleStyle)
- [ ] T023 [P] [US3] `DesignSystem/SelectableCard.swift` (outline + check badge), `MascotAvatar.swift` (original blob,
      pastel color parameter, `^ ^` eyes, drawn with SwiftUI shapes)
- [ ] T024 [US3] `DesignSystem/DesignGallery.swift` + `--gallery` launch flag in `App/AppDelegate.swift` opening it in a window

## Phase 6: User Story 4 – checks (P2)

- [ ] T025 [US4] Make `swift run MyClickyChecks` print group names, counts and `All N checks passed` / `N failed`. Add a
      "Checks" section to `README.md` and `CLAUDE.md`

## Phase 7: Polish

- [ ] T026 Update `README.md` (settings file name) and `GUIDE.md` (correct project path `~/Desktop/my-clicky`, checks command)
- [ ] T027 Run `specs/002-app-foundation/quickstart.md` end to end and note the results in this file

## Dependencies & Execution Order

Setup → Foundational → US1 → US2 → (US3 ∥ US4) → Polish. US3 does not depend on US1/US2.
[P] tasks touch different files.
