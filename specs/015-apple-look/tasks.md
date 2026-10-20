---
description: "Tasks for 015-apple-look"
---

# Tasks: Apple Look

**Input**: `specs/015-apple-look/` · **Tests**: Core checks unchanged; snapshots (Light Mode); quickstart in both
appearances. Paths under `Sources/MyClicky/`.

## Phase 1: Foundational

- [X] T001 `DesignSystem/Theme.swift`: appearance-aware tokens (backgrounds, label colors, separators, system accent,
  system green/orange/red), `contentBackground`, `accentFill`; remove bloom
- [X] T002 Remove forced dark: `HomeRoot`, `WelcomeView`, `WelcomeWindowController`, `PopOutWindowController`,
  `SuggestionScheduler`, `DesignGallery`, `Materials.GlassView`; snapshots render Light Mode (`App/Snapshot.swift`)

## Phase 2: US1 – light & dark app (P1) 🎯 MVP

- [X] T003 [US1] Surfaces: `HomeView`, `SettingsView`, `WelcomeView` backgrounds; remove `TopFade`; sidebar surface
- [X] T004 [US1] `SettingsCard`, `SelectableCard`, `CheckBadge`, `ModalCard`, `KeyCap`, `FieldBackground`,
  `SecretField`, hover highlight: both appearances
- [X] T005 [US1] Literal white/black sweep: `AgentsPage`, `AgentCards`, `VoicePage`, `EmptyStateView`,
  `SuggestionScheduler`, `MessageBubble` (user bubble accent + white), `ChatAvatar`

## Phase 3: US2 – interactive buttons (P1)

- [X] T006 [US2] `PillButton.swift`: flat Apple capsules with hover; kinds `.primary`, `.secondary`, `.destructive`
  (red on hover), `.safe` (green on hover); `.dark` = `.secondary`; `CircleIconButtonStyle` red on hover
- [X] T007 [US2] Apply: delete/clear confirmation (Delete → destructive, Cancel → safe), Disconnect, Allow (safe) /
  Deny (destructive), Keep going (safe) / Stop here (destructive), header Stop (destructive)

## Phase 4: US3 – window buttons (P1)

- [X] T008 [US3] `DesignSystem/WindowControls.swift`: `WindowControls` environment, `TrafficLights` (hover glyphs),
  `WindowControlsRow`
- [X] T009 [US3] Sidebars: row replaces the Home logo; row above Back in Settings; `HomeChrome` icons removed
- [X] T010 [US3] `PopOutWindowController`: real buttons, miniaturizable, full screen, `show(fullScreen:)`;
  `NotchController`/`NotchContainerView`: notch actions (red/yellow collapse, green full screen)

## Phase 5: US4 – native details (P2)

- [X] T011 [US4] `GlossyToggle.swift` → native switch + haptic
- [X] T012 [US4] Companion bubble, text box, agent chip: popover material, system appearance, label colors
- [X] T013 [US4] Greeting pill flat accent; welcome footer; progress dots

## Phase 6: Polish

- [X] T014 `swift build`, `swift run MyClickyChecks`, re-render `docs/screens/`, check both appearances
- [X] T015 Docs: `specs/README.md` (visual language, deviations, roadmap), `CHANGELOG.md`, `IMPLEMENTATION-REPORT.md`,
  `CLAUDE.md`
- [X] T016 Manual quickstart in the installed app (you)

## Dependencies

T001–T002 first. US1–US4 then in order (they share components). Polish last.

## Implementation notes

Implemented 2026-09-29. `swift build` ✓ (no warnings), `swift run MyClickyChecks` → 426 passed, 22 screens re-rendered
in Light Mode plus 3 Dark Mode renders (`*-dark.png`).

- **Switch:** the AppKit switch draws gray in inactive windows, and the notch panel is never the active window, so
  `.glossy` is a SwiftUI switch drawn like the macOS one (accent track, white knob). `controlActiveState` is set to
  `.key` for the home and the tour so other native controls keep their accent too.
- **Surfaces are solid**, not blurred: white content, `#EFEFF2` sidebar, `#F5F5F7` grouped background (dark
  equivalents in Dark Mode). This also removes 014's unverified notch blur (a native blur inside the rounded, scaling
  notch clip). The bubble, text box and agent chip use the `.popover` material, like macOS popovers.
- **Core Animation colors** (bubble text/border) don't follow Light/Dark on their own; they're resolved for the current
  appearance each time the bubble is set (`GlassView.cgColor`).
- **Kept dark on purpose:** the collapsed notch and the morning ideas card that hangs from it (Dynamic Island style).
- **Buttons:** `.pill(.destructive)` = red text, red fill on hover; `.pill(.safe)` = neutral, green fill on hover.
  Applied to delete/clear, Disconnect, the ✕ remove button, Allow/Deny, Keep going/Stop here, and Stop.
- **Window buttons:** `WindowControlsRow` at the top of both sidebars. Pop-out window: real buttons, miniaturizable,
  `.fullScreenPrimary`. Notch: custom dots with hover glyphs; green calls `popOutNow(fullScreen: true)`.
