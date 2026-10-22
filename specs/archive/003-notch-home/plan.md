# Implementation Plan: Notch Home

**Branch**: `003-notch-home` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

One borderless, non-activating `NSPanel` per display, always sized to the expanded frame and pinned to the top
center (notch or pill). While collapsed it ignores mouse events and draws only the small notch shape. A cheap global
mouse-move monitor detects resting on the shape, then the panel accepts mouse events and SwiftUI animates the shape
growing into the app content (`HomeRoot`). Pop out moves `HomeRoot` into a normal `NSWindow`. The Dock icon is
controlled by the activation policy.

## Technical Context

**Language/Version**: Swift 6.4 (Swift 5 mode)

**Primary Dependencies**: AppKit (NSPanel, NSScreen notch APIs, NSEvent monitors), SwiftUI (shape and content)

**Storage**: `settings.json` gets `showInDock` (false), `popOutFrame` (String, empty), `notchOnAllDisplays` (true)

**Testing**: Checks for `NotchGeometry` math and the `NotchState` transitions (Core). Manual quickstart for visuals

**Target Platform**: macOS 14+; built-in notch display + 2560×1440 external

**Performance Goals**: < 1% CPU idle; open animation ≤ 350 ms at 120 Hz

**Constraints**: must not block clicks on the menu bar outside the shape; must work over full-screen Spaces

**Scale/Scope**: ~8 new files

## Constitution Check

| Principle | Check |
|---|---|
| I | ✅ Cost impact: none |
| II | ✅ AppKit/SwiftUI only |
| III | ✅ |
| IV | ✅ |
| V | ✅ Notch shows agent activity (used by 009 for the stop control) |
| VI | ✅ The state machine is pure logic in Core |
| VII | ✅ Checks for geometry and state machine; quickstart for visuals |
| VIII | ✅ Matches refs 01/02. Deviations listed in the spec |

## Project Structure

```text
Sources/MyClickyCore/Logic/NotchGeometry.swift      # notch rect from aux areas; pill rect; expanded rect (pure CGRect math)
Sources/MyClickyCore/Logic/NotchState.swift         # collapsed/expanded/poppedOut + events → transitions
Sources/MyClicky/Notch/NotchController.swift        # one panel per screen, rebuild on screen change, hover monitor, timers
Sources/MyClicky/Notch/NotchPanel.swift             # NSPanel subclass (borderless, nonactivating, canBecomeKey when expanded)
Sources/MyClicky/Notch/NotchShape.swift             # SwiftUI Shape: flared top corners, rounded bottom, animatable size
Sources/MyClicky/Notch/NotchCollapsedView.swift     # badge (left) + docked companion/activity (right)
Sources/MyClicky/Notch/NotchContainerView.swift     # collapsed ↔ expanded animation host; top fade; pop-out/close buttons
Sources/MyClicky/Notch/PopOutWindowController.swift # normal window hosting HomeRoot; frame autosave
Sources/MyClicky/Home/HomeRoot.swift                # placeholder root (greeting only) until 005
Sources/MyClicky/App/DockPolicy.swift               # activation policy + reopen handling
Sources/MyClickyChecks/NotchChecks.swift
```

**Structure Decision**: new `Notch/` folder. `HomeRoot` is the single content view later features fill.
