# Implementation Plan: Visual Identity

**Spec**: `spec.md` · **Cost**: none

## Approach

- `DesignSystem/Brand.swift` (new): the 8 palette colors, and the artwork as SwiftUI views:
  - `GlassMaterial`: paints any shape as liquid glass. It stacks a blurred angular neon glow, a radial deep-blue body,
    a violet/magenta edge tint, a light top, a thick blurred inner rim band (angular: white top, violet/magenta left,
    blue bottom, warm bottom-right, cyan right), an optional inner edge, and a crisp rim.
  - `GlassBot` (BOT.png), `LivelyBot` (blink every 4.2 s and a gentle float, via TimelineView), `BotAvatar`.
  - `AppLogo` (LOGO.png) on the macOS icon grid (tile = 80.5% of the canvas), `SparkleDashes`, `GlowingEye`,
    `RoundedPolygon`.
- Shapes and positions are measured from the reference PNGs, then tuned by rendering side-by-side comparisons.
- `Theme.swift`: surfaces, text and accents move to the palette. New tokens (`track`, `hairline`, `rowSelected`,
  `modal`, `controlDark`, `previewText`, `accentBorder`, `bloomBackground`) replace ~30 scattered hex values.
  `lavender*` is renamed to `accent*`.
- App icon: `--snapshot app-icon` renders `AppLogo` at 1024 px with `ImageRenderer` (the layer render used for screens
  drops blur). `scripts/make-icon.sh` builds `Resources/AppIcon.icns` (16–1024 px) with `sips` + `iconutil`.
  `build.sh` copies it, and `Info.plist` sets `CFBundleIconFile`.

## Files

New: `DesignSystem/Brand.swift`, `scripts/make-icon.sh`, `Resources/AppIcon.icns`.
Changed: `Theme.swift`, `PillButton.swift`, `GlossyToggle.swift`, `SelectableCard.swift`, `ModalCard.swift`,
`EmptyStateView.swift`, `ChatAvatar.swift`, `SidebarView.swift`, `ChatRow.swift`, `WelcomeView.swift`, `SetupSteps.swift`,
`NotchCollapsedView.swift` (badge), `ProfileCard.swift`, `MicrophonePage.swift`, `VoicePage.swift`, `SpendingViews.swift`,
`HomeView.swift`, `SettingsView.swift`, `DesignGallery.swift`, `Snapshot.swift`, `Info.plist`, `build.sh`.
Removed: `DesignSystem/MascotAvatar.swift` (the old pastel blob).
