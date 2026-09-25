# Data Model: Cursor Companion

## New settings

| Field | Type | Default |
|---|---|---|
| cursorColor | enum `red` \| `blue` \| `yellow` \| `green` | red |
| cursorDocked | Bool | false |

## ScreenMark (Core)

| Case | Fields |
|---|---|
| point | x, y, label, screen |
| circle | x, y, r, screen |
| arrow | x1, y1, x2, y2, screen |
| box | x, y, w, h, screen |
| underline | x1, y, x2, screen |

Coordinates are screenshot pixels (origin top-left) and are clamped to the screenshot size. `screen` is 1-based and
must exist. At most 1 point and 3 drawings per answer (extras are ignored).

## CompanionState (app)

`idle` · `listening(level: Float)` · `thinking` · `speaking` · `pointing(ScreenMark)` · `docked` (visual home = notch).
