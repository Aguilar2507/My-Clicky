---
description: "Tasks for 014-premium-feel"
---

# Tasks: Premium Feel

**Input**: `specs/014-premium-feel/` · **Tests**: Core checks for the motion and type tables and the tour direction
(`PremiumFeelChecks`); visual checks through snapshots and the quickstart. Paths are under `Sources/`.

## Phase 1: Setup

- [X] T001 Save the apple-design skill summary this spec follows in `specs/014-premium-feel/research.md` (done in plan)
  and add spec 014 to the roadmap in `specs/README.md`

## Phase 2: Foundational (blocks every story)

- [X] T002 [P] `MyClickyCore/Design/MotionSpec.swift`: `MotionSpec` table (standard 0.35/1.0, quick 0.2/1.0, bouncy
  0.35/0.8; fade 0.18 s) with the data-model rules "damping ≤ 1 and > 0; response 0.15–0.5; only `bouncy` < 1"
- [X] T003 [P] `MyClickyCore/Design/TypeScale.swift`: the 13 styles from data-model.md (size, weight, tracking, line
  spacing, uppercase), rule "tracking never increases with size"; `TourDirection.between(_:_:)`
- [X] T004 [P] `MyClickyChecks/PremiumFeelChecks.swift` + register in `main.swift`: motion rules, type-scale
  monotonic tracking, tour direction forward/back/same
- [X] T005 `MyClicky/DesignSystem/DisplayPrefs.swift`: `@Observable` mirror of Reduce Motion / Reduce Transparency /
  Increase Contrast, live via `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`; `forceSolid`
- [X] T006 `MyClicky/DesignSystem/Motion.swift`: SwiftUI animations from `MotionSpec`, reduce-motion aware;
  `Motion.withAnimation`; transitions `.materialize`, `.slide(forward:)`, `.grow(from:)`; `CASpringAnimation` factory
- [X] T007 `MyClicky/DesignSystem/Typography.swift`: `.textStyle(_:)` from `TypeScale`; `Theme.IconSize`
- [X] T008 `MyClicky/DesignSystem/Theme.swift`: `Radius`, `Space`, `Shadow` tokens + `.shadowToken(_:)`;
  contrast-aware `cardBorder`, `textSecondary`, `textTertiary`, `hairline`, `trackBorder` (computed, read
  `DisplayPrefs`); snapshot mode sets `DisplayPrefs.forceSolid` in `MyClicky/App/Snapshot.swift`

**Checkpoint**: `swift build`, `swift run MyClickyChecks` pass; nothing looks different yet.

## Phase 3: US1 – instant response (P1) 🎯 MVP

**Goal**: every control reacts on press; lists and cards react on hover.
**Independent test**: quickstart §1.

- [X] T009 [US1] `MyClicky/DesignSystem/Feedback.swift`: `PressableButtonStyle` (`.pressable`, scale 0.97 +
  brightness, `Motion.quick`), `.hoverHighlight(radius:)`, `FeedbackKind` (status/completion/warning/error)
- [X] T010 [US1] `PillButton.swift`: press scale + brightness on `PillButtonStyle` and `CircleIconButtonStyle`
  (replaces the 0.75 opacity); disabled state dims
- [X] T011 [US1] `SelectableCard.swift`: `.pressable`, hover, animated outline and check badge (`Motion.quick`,
  badge scales in)
- [X] T012 [US1] Sidebar and lists → `.pressable` + `.hoverHighlight`: `Home/Sidebar/SidebarView.swift`,
  `ChatRow.swift`, `AppsChip.swift`, `Settings/SettingsSidebar.swift` (selection animates with `Motion.quick`)
- [X] T013 [US1] Remaining `.buttonStyle(.plain)` rows/cards → `.pressable`: `Settings/*Page.swift`,
  `ProfileCard.swift`, `Home/EmptyStateView.swift`, `HomeChrome.swift`, `Conversation/*`, `Usage/SpendingViews.swift`,
  `Onboarding/*`, `Agents/SuggestionScheduler.swift`, `ModalCard.swift` (`SecretField` eye)

## Phase 4: US2 – physical motion (P1)

**Goal**: springs everywhere, interruptible, symmetric paths.
**Independent test**: quickstart §2.

- [X] T014 [US2] `Notch/NotchContainerView.swift`: shape on `Motion.standard`; home content `.grow(from: .top)`
  + opacity in, collapsed shape cross-fades; no fixed-duration easing
- [X] T015 [US2] `ModalCard.swift`: `.materialize` card over an animated dim; all 10 `ModalCard` call sites present
  it inside `Motion.withAnimation` (ProfileCard, GeneralPage ×2, IntegrationsPage ×2, ShortcutsPage, SidebarView,
  ConversationView ×2, SpendingViews)
- [X] T016 [US2] `Onboarding/WelcomeView.swift`: step keyed by `.id`, `.slide(forward:)` by `TourDirection`, changes
  inside `Motion.withAnimation`; progress dots animate
- [X] T017 [US2] `Onboarding/Steps/SetupSteps.swift`: intro carousel symmetric (in from trailing, out to leading),
  `Motion.standard`, dot capsules animate width
- [X] T018 [US2] `GlossyToggle.swift`: knob on `Motion.bouncy`; `Settings/MicrophonePage.swift` meter on `Motion.quick`
- [X] T019 [US2] `Companion/CompanionController.swift` + `CompanionWindow.swift`: bubble grows from the cursor
  corner with a `CASpringAnimation` (fade only with Reduce Motion) and shrinks back the same way

## Phase 5: US3 – glass and depth (P2)

**Goal**: navy glass floating surfaces, heavier sidebar, edge fades.
**Independent test**: quickstart §3.

- [X] T020 [US3] `MyClicky/DesignSystem/Materials.swift`: `GlassSurface` (`NSVisualEffectView` `.hudWindow`,
  behind-window, dark) + navy tint + top-edge highlight + shadow; `.glass(.floating | .structural, radius:)`; solid
  when `reduceTransparency || forceSolid`; `.scrollEdgeFade()`
- [X] T021 [US3] `CompanionWindow.swift`/`CompanionLayer.swift`: overlay layers move into full-size host views;
  bubble hosted in an `NSVisualEffectView` that follows its frame; text on glass stays ≥ 4.5:1
- [X] T022 [US3] `Companion/TextModeField.swift`: glass background (effect view + tint + highlight border), rounded
  16, spring-in (fade with Reduce Motion)
- [X] T023 [US3] `ModalCard.swift`: glass card (`.ultraThinMaterial` + navy tint), large shadow token
- [X] T024 [US3] `Notch/NotchContainerView.swift`: panel fill → floating glass under the bloom (solid fallback)
- [X] T025 [US3] `Home/Sidebar/SidebarView.swift`, `Settings/SettingsSidebar.swift`: structural weight; replace the
  sidebar hairline, `ChatRow` bottom rules and the `ChatHeader` `Divider()` with `.scrollEdgeFade()`; apply the fade to
  Settings pages, conversation and tour scroll views

## Phase 6: US4 – type scale (P2)

**Goal**: every text style from the scale.
**Independent test**: quickstart §4; `grep` finds no `.font(.system(size:` on text outside `DesignSystem/`.

- [X] T026 [US4] Design system text: `SettingsCard.swift` (`SectionLabel` → `.label`, `PageHeader`, `SettingsRow`),
  `PillButton.swift`, `ModalCard.swift`, `SelectableCard.swift`, `KeyCap`; `Theme` fonts become aliases of the scale
- [X] T027 [P] [US4] Home: `Sidebar/*`, `Conversation/*`, `EmptyStateView.swift`, `HomeChrome.swift`,
  `Notch/NotchCollapsedView.swift` (icons → `Theme.IconSize`)
- [X] T028 [P] [US4] Settings: `AgentsPage`, `DictationPage`, `GeneralPage`, `IntegrationsPage`, `MicrophonePage`,
  `ProfileCard`, `SettingsSidebar`, `ShortcutsPage`, `VoicePage`
- [X] T029 [P] [US4] Tour, spending, suggestions: `Onboarding/*`, `Usage/SpendingViews.swift`,
  `Agents/SuggestionScheduler.swift`, `DesignGallery.swift`; companion `BubbleLayer`/`LabelPillLayer`/text field fonts
  match `footnote`/`callout` with tracking

## Phase 7: US5 – accessibility (P2)

**Goal**: live Reduce Motion / Transparency / Increase Contrast.
**Independent test**: quickstart §5.

- [X] T030 [US5] `Brand.swift` `LivelyBot`: no float and a blink every 8 s with Reduce Motion
- [X] T031 [US5] Companion `CompanionLayer` state loops (thinking shimmer, speaking bounce) → gentle opacity only with
  Reduce Motion; bubble/text field solid with Reduce Transparency
- [X] T032 [US5] Verify every transition in `Motion.swift` degrades to opacity; Increase Contrast tokens reach cards,
  rows, fields, sidebar selection and toggles off-track

## Phase 8: US6 – haptics (P3)

**Goal**: a tap at meaningful moments, off-able.
**Independent test**: quickstart §6.

- [X] T033 [US6] `MyClickyCore/Models/Settings.swift`: `hapticFeedback = true` in a `// 014 premium feel` block
  (no version bump; TolerantDecoder fills older files); check in `PremiumFeelChecks` that an old file decodes to `true`
- [X] T034 [US6] `Feedback.swift` `Haptics.tap(_:)` (`.levelChange` / `.generic`, `.now`), gated by the setting
- [X] T035 [US6] Fire it: `Talk/Assistant.swift` (listening begins/ends), `GlossyToggle.swift` (flip),
  `Agents/AgentSupervisor.swift` (agent finished); nowhere else
- [X] T036 [US6] `Settings/GeneralPage.swift` → Behavior: "Haptic feedback" row with a glossy toggle

## Phase 9: Polish

- [X] T037 Replace hard-coded radii/shadows in design-system components with `Theme.Radius`/`Theme.Shadow`
- [X] T038 `swift build`, `swift run MyClickyChecks`; re-render `docs/screens/` and compare layouts with the old renders
- [X] T039 Docs: `specs/README.md` (visual language: motion, materials, type, accessibility), `Resources/CHANGELOG.md`,
  `docs/IMPLEMENTATION-REPORT.md`, `CLAUDE.md` rule "motion/type/surfaces come from DesignSystem tokens"
- [X] T040 Manual quickstart §1–§6 in the running app (needs you: haptics and accessibility toggles)

## Dependencies

- Phase 2 blocks everything. US1 and US2 are independent of each other; US3 builds on `ModalCard`/notch changes from
  US2 (same files, do US2 first). US4 is independent (only fonts). US5 verifies US2/US3. US6 is independent.
- Parallel: T002–T004; T027–T029 (different folders).

## Implementation strategy

MVP = Phase 2 + US1 (the whole app responds instantly). Then US2 → US3 → US4 → US5 → US6, building and checking after
each phase.

## Implementation notes

Implemented 2026-09-29. `swift build` ✓, `swift run MyClickyChecks` → 426 passed (40 new in `PremiumFeelChecks`),
24 screens re-rendered (21 changed; icon, bot and collapsed notch are identical).

- **Files:** new `DesignSystem/{DisplayPrefs,Motion,Typography,Materials,Feedback}.swift`,
  `MyClickyCore/Design/{MotionSpec,TypeScale}.swift`, `MyClickyChecks/PremiumFeelChecks.swift`. The companion overlay
  (`CompanionWindow.swift`) now hosts each layer in its own view so the bubble can sit on real glass.
- **Modal cards:** SwiftUI only runs the transition of the inserted view, so `ModalCard` has one animatable
  transition that passes its progress down (the dim fades, the card materializes). `.modalOverlay(trigger)` replaces
  `.overlay` at all 8 presenting sites, so no button action had to change.
- **Direction-aware slides** (tour steps, intro cards): a leaving view keeps the transition it was last drawn with,
  so Back/Continue set the direction first and change the step on the next run-loop turn.
- **Type sweep:** 104 text calls → `.textStyle`, 26 icon calls → `.font(.icon(...))`. Sizes that had no style moved by
  1–2 pt (10→11, 16→17, 18/19→20, 21→22); snapshots show no layout shift. Three glyphs sized relative to their shape
  stay as they are: the notch badge count, profile initials, integration letter.
- **Kept on purpose:** chat-row separators (HeyClicky's list layout), the menu `Divider()`, the on-screen drawing
  strokes' ease-out (they draw a path, not a UI transition), page paddings (HeyClicky's measured layout).
- **Snapshots** use the solid fallback (`DisplayPrefs.forceSolid`): renders can't draw live blur, so the glass,
  press, hover and motion can only be judged in the running app (T040).
- **Fixes after the first try (2026-09-29):** hover highlights were drawn behind filled controls (profile card, Apps
  chip, +, Back, voice cards) and never showed, so they're an overlay now. Full-width rows no longer shrink when pressed
  (`.pressableRow`: brighten only), since 3 % of a 640 pt row is a 19 pt jump. Tour steps were clipped to their own
  height, which cut off button glows; the window edge clips the slide instead. The bubble's navy tint resized a frame
  after the bubble, so a growing bubble flashed an untinted strip; it's resized in the same frame now.
