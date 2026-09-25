# UI Contract: Home (ref `02-app-home.png`)

## Sidebar (270 pt, `#1B1B1B`)

- Top: MyClicky logo (original mark), 32 pt, white, 24 pt from the top-left.
- Search field: `#2A2A2A` rounded 12, magnifier + "Search", 17 pt; "+" square button 30 pt, same fill, to its right.
- Row (58 pt): unread dot 8 pt `#3B82F6` at x = 8 · avatar 42 pt (ring + blob + `^ ^`) · name 17 pt bold white ·
  time 15 pt `#9A9A9F`, right-aligned · preview 16 pt `#B0B0B5`, one line, truncated · 1 pt `#333333` divider
  inset from the text.
- Talk row: logo avatar, name "Talk", always first.
- Bottom: "Apps +" chip (connected integration icons + "Apps" + "+"), `#2A2A2A` capsule, only once 010 exists ·
  1 pt divider · footer: initial circle 40 pt `#3A3A3A` · name (17 pt semibold) · "$0.42 this month" 14 pt gray
  + spend ring 18 pt (011) · ⓘ · ⚙ icons 22 pt `#C7C7CC`.

## Empty state

- Mascot blob (coral/peach, ~260 × 190 pt, soft glow) with two paws over the pill.
- Pill 440 × 88 pt glossy lavender-blue: 🎤 + "Hi, how can I help ^_^?" 24 pt semibold dark text.
- "Evening, Jose." 34 pt bold white · "Hold Fn and tell me what to take off your plate." 20 pt `#9A9A9F`.

## Conversation

- Header 64 pt: avatar 32 · name 20 pt bold · status 14 pt gray ("Questions about your screen" for Talk) · ⋯ menu
  (Rename, Change color, Delete / Clear history).
- User bubble: right-aligned, `#2E3550` fill, 16 pt corner radius, max 70% width. Assistant: left, avatar 24 pt, plain
  text on the background. Note line under messages: 12 pt gray ("Voice · Looked at 2 screens").
- Composer: `#2A2A2A` rounded 18, placeholder "Message {name}…", mic button (tap to dictate into the field), send
  arrow (lavender when enabled). Return sends, ⇧Return adds a new line.
