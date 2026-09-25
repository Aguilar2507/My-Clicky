# UI Contract: Dictation page (ref `06-settings-dictation.png`)

- Title "Dictation" · subtitle "Languages and the words MyClicky should spell right."
- `LANGUAGE` card:
  - Row: "Auto-detect language" / "MyClicky figures out the language as you speak." + GlossyToggle.
  - Divider, then two SelectableCards side by side: "English / English" and "Spanish / Español" (with a small region
    menu, e.g. "México ▾"). When auto-detect is on, the cards show both as included (lavender outline on both) and
    the selected one is the fallback (check badge).
- `WORDS` card:
  - Caption "Names and terms MyClicky should always spell your way."
  - Token field of words (chips `#333333` rounded with ✕) + "Add word" text field. Return adds.
- Indicator while dictating: pill beside the companion, `#1E1E1E` 90%, red dot + "Dictating…" (hold) or
  "Hands-free · ⌃fn ⌃fn to stop" (hands-free).
