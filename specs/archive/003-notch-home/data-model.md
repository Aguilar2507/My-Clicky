# Data Model: Notch Home

## New settings (tolerant decode, defaults shown)

| Field | Type | Default |
|---|---|---|
| showInDock | Bool | false |
| notchOnAllDisplays | Bool | true |

The pop-out window frame is saved by AppKit's frame autosave (`MyClickyWindow`), not in settings.

## NotchState (Core, pure)

States: `collapsed`, `hovering(since)`, `expanded`, `poppedOut`.

| From | Event | To |
|---|---|---|
| collapsed | pointerEntered(t) | hovering(t) |
| hovering(t0) | tick(t) where t − t0 ≥ 0.15 s | expanded |
| hovering | pointerExited | collapsed |
| expanded | pointerOutside ≥ 0.5 s and not `isBusy` | collapsed |
| expanded | outsideClick / escape | collapsed |
| expanded | popOut | poppedOut |
| poppedOut | close | collapsed |
| poppedOut | pointerEntered | poppedOut (bring window to front) |

`isBusy` = text field focused, menu open or sheet open.

## NotchGeometry (Core, pure)

Input: screen frame, optional aux top-left/right rects, safe-area top, menu-bar height.
Output: `collapsedRect` (notch width + 2 × 88 pt wings; height = notch height or menu-bar height),
`hoverRect` (collapsedRect), `expandedRect` (990 × 650 centered, top-aligned, clamped to the screen).
