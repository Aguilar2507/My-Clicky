# UI Contract: Voice and Microphone pages

## Voice (ref `04-settings-voice.png`)

- Title "Voice" · subtitle "The voice MyClicky answers in, and how fast it talks."
- `SPEECH SPEED`: a card containing 5 chips (`0.5x 0.75x 1x 1.25x 1.5x`). The selected chip is a glossy lavender pill.
  Caption: "Takes effect on the next spoken reply."
- `VOICE — ENGLISH` and `VOICE — SPANISH`: 5-column grid of SelectableCards (230 × 225 px @2x). Each card has an
  SF Symbol icon (color by index: tree/green, waves/blue, dots/gray, cloud/gray, note/purple, heart/pink,
  antenna/blue, leaf/green, sparkles/yellow, bubble/orange, as in the reference), the voice name 17 pt bold, and a
  descriptor 15 pt gray ("Premium · US", "Enhanced · Mexico").
- Caption: "Tap a voice to hear it. The pick applies to future spoken replies."
- Row: "Get more voices" ↗ → `x-apple.systempreferences:com.apple.Accessibility-Settings.extension?SpokenContent`.

## Microphone (ref `05-settings-microphone.png`)

- Title "Microphone" · subtitle "Which microphone MyClicky listens through."
- `INPUT DEVICE`: radio rows (System Default, devices…). The selected row has a lavender check circle.
- `TEST`: white pill "Test microphone" + 16 rounded bars (`#3A3A3A` idle, lavender active). Caption "Tap to test selected input".
- Footer caption: "Speak normally — the bars should move as MyClicky hears you."
