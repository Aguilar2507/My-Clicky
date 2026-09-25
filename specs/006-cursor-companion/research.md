# Research: Cursor Companion

## R1 Smooth follow without burning CPU

- **Decision**: A global + local `.mouseMoved`/`.leftMouseDragged` monitor wakes a display link
  (`window.contentView.displayLink(target:selector:)`, macOS 14). Each frame: critically damped spring toward
  `mouse + offset(18, −26)` (response ~0.12 s), in `CompanionMotion.step(dt:)`. Stop the link when distance < 0.5 pt
  and velocity ~0 (unless a state animation runs).
- **Rationale**: Stays in sync with the display refresh (up to 120 Hz on ProMotion), and uses no CPU when still.
- **Alternatives**: A `Timer` at 60 Hz (drifts, always on); CADisplayLink via CVDisplayLink (deprecated path).

## R2 Companion look

- **Decision**: `CAShapeLayer` with a 22 pt rounded triangle (corner radius 4) pointing right, tilted −20°, fill =
  color, `shadowColor` = color, `shadowRadius` 10, `shadowOpacity` 0.9 (glow). States:
  - **Listening:** scale follows mic RMS (1.0–1.3).
  - **Thinking:** a rotating conic highlight (CAGradientLayer mask) at 1.2 rev/s.
  - **Speaking:** a 0.4 s bounce loop.
- **Rationale**: Matches refs 01/08. All built with GPU-composited layers.

## R3 Pointing flight

- **Decision**: Reuse v0.1's arc (quadratic curve, control point raised by max(60, 0.3 × distance)), 0.5–1.1 s by
  distance. Across displays, fade out on the source and fly from the target display's edge. Label pill in the
  companion color. Return after 6 s, or when the pointer comes within 40 pt of the target.

## R4 Drawing tags

- **Decision**: New grammar in `contracts/screen-tags.md`. `DrawingLayer` animates `strokeEnd` 0→1 (0.5 s) with 3 pt
  round-cap strokes plus a slight hand-drawn wobble (3 jittered control points). Fade after 8 s.
- **Rationale**: Cheap in tokens, and the same coordinate system as POINT (screenshot pixels, top-left origin).

## R5 Streaming-safe tag stripping

- **Decision**: `ScreenTags.visibleText(partial:)` hides any trailing text from an unmatched `[` that could still become
  a tag, so the bubble never flashes `[POI…`. Complete tags are parsed once the stream ends (they're appended at the end).

## R6 Text mode field

- **Decision**: A `NSPanel` (`.nonactivatingPanel` + `becomesKeyOnlyIfNeeded = false`, activating the app briefly) at
  the cursor with a single `NSTextField` styled like the bubble. On Return: close the panel, wait 150 ms, then capture
  screens (MyClicky windows are excluded anyway) and send through ChatRouter.
