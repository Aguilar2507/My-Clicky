# UI Contract: Settings

## Shell (refs 03–10)

Left column 410 pt, background `#1B1B1B`:
`‹ Back` (pill, `#2A2A2A`) + "Settings" 28 pt bold · profile card (initial circle 56 pt `#3A3A3A`, name 17 pt
semibold, badge e.g. `$0.42 · SEP` in the FREE-badge style) · items: General · `MYCLICKY` Voice, Microphone,
Dictation, Shortcuts, Cursor · `WORK` Agents, Integrations · footer `MyClicky 0.2.0 (2)` 13 pt `#6E6E73`.

Right column: page title 28 pt bold, subtitle 17 pt `#9A9A9F`, then sections (SectionLabel + SettingsCard), max width 1240 px @2x.

## General page

| Section | Row | Control |
|---|---|---|
| BEHAVIOR | Show in Dock / "Turn off to keep MyClicky notch only." | GlossyToggle |
| BEHAVIOR | Show in screen recordings / "Let screen sharing and recording tools capture MyClicky." | GlossyToggle |
| ANTHROPIC | API key / `sk-ant-…ab12` or "Not set" | white pill "Change" |
| PERMISSIONS | Microphone, Speech Recognition, Screen Recording, Accessibility, Input Monitoring | ✓ / "Open" pill |
| VERSION | App version / "You're on version 0.2.0 (2)." | — |
| VERSION | What's new / "Everything that changed in MyClicky." | ↗ opens sheet |
| WELCOME TOUR | Replay the welcome tour / (012 text) | ▶ (hidden until 012) |

## Shortcuts page

Rows exactly as in `07-settings-shortcuts.png` (MyClicky wording). Key caps: `#333333` rounded 8 pt, monospaced
13 pt, e.g. `^ control`, `fn`. "Change" = white pill. Last card: "Reset to defaults" (row button).
Recorder sheet: "Press the new shortcut" + live key caps + "Esc to cancel".
