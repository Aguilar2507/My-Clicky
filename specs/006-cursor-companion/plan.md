# Implementation Plan: Cursor Companion

**Branch**: `006-cursor-companion` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

Evolve v0.1's `OverlayController` (one transparent, click-through window per display) into a `CompanionController`
with three Core Animation layers per window: companion triangle, bubble and drawings. A display-link loop (running
only while something moves) springs the companion toward `mouse + offset`. A Core `ScreenTags` parser replaces
`PointTag` and handles `[POINT…]` and `[DRAW…]` tags, including while streaming. A `TextModeField` panel opens at
the cursor on the textMode shortcut. Settings → Cursor page is added.

## Technical Context

**Language/Version**: Swift 6.4 (Swift 5 mode)

**Primary Dependencies**: AppKit, QuartzCore (CAShapeLayer, CAKeyframeAnimation), `NSView.displayLink` (macOS 14)

**Storage**: settings `cursorColor` (red), `cursorDocked` (false)

**Testing**: Checks for ScreenTags (complete/partial/streaming/invalid), spring step math, edge flipping, screenshot→global coordinates

**Performance Goals**: 60–120 fps follow, < 1% CPU idle (display link stopped when settled)

**Constraints**: `ignoresMouseEvents = true` on all overlay windows; excluded from MyClicky's own screenshots

## Constitution Check

| Principle | Check |
|---|---|
| I | ✅ +150 prompt tokens documented |
| II | ✅ Native drawing |
| IV | ✅ Nothing stored |
| VI | ✅ Tag parsing and motion math in Core |
| VII | ✅ Checks listed |
| VIII | ✅ Ref 08 page. Docked cursor as in ref 01 |

## Project Structure

```text
Sources/MyClickyCore/Logic/ScreenTags.swift          # POINT + DRAW grammar (contracts/screen-tags.md), streaming-safe stripping
Sources/MyClickyCore/Logic/CompanionMotion.swift     # spring step, offset/edge flip, arc path control points
Sources/MyClickyCore/Logic/ScreenMapping.swift       # screenshot pixels → global points (from v0.1 Screenshot.globalPoint)
Sources/MyClicky/Companion/CompanionController.swift # replaces OverlayController: windows per screen, state, display link
Sources/MyClicky/Companion/CompanionWindow.swift     # transparent click-through window (from OverlayWindow)
Sources/MyClicky/Companion/CompanionLayer.swift      # glowing rounded triangle + state animations
Sources/MyClicky/Companion/BubbleLayer.swift         # streaming text bubble (from OverlayView bubble)
Sources/MyClicky/Companion/DrawingLayer.swift        # circle/arrow/box/underline stroke animations
Sources/MyClicky/Companion/TextModeField.swift       # small key panel at the cursor
Sources/MyClicky/Settings/CursorPage.swift
Sources/MyClicky/Talk/Prompts.swift                  # + DRAW instructions
Sources/MyClickyChecks/CompanionChecks.swift
```
