# UI Contract: Notch

## Collapsed (ref `01-notch-collapsed.png`)

```
 ┌───────────────────────────────────────────┐   ← flush with the top edge, pure black
 │  (1)            [hardware notch]        ▶ │   ← left: unread badge; right: docked companion
 └╮                                         ╭┘   ← rounded bottom corners (radius ≈ 14 pt)
```
- Badge: 22 pt glossy lavender-blue circle, white-outlined, dark number, hidden at 0, "9+" above 9.
- Right slot priority: agent activity indicator > docked companion > empty.

## Expanded (ref `02-app-home.png`)

- 990 × 650 pt, background `#1E1E1E`, a 90 pt black-to-clear fade at the top merging into the notch.
- Top-right: pop-out icon (two overlapping rounded rectangles) and ✕, 20 pt, `#C7C7CC`, 60 pt from the edge.
- Content: `HomeRoot` (features 004/005).

## Right-click menu

`Open MyClicky` · `Settings…` · separator · `Quit MyClicky`
