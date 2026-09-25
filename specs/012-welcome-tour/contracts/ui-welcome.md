# UI Contract: Welcome window

- Window 720 × 560, `#1E1E1E`, no traffic lights except close, centered. The mascot at the top of each step.
- Footer: progress dots (8) · "Back" (text) · "Skip" (text, where allowed) · primary pill "Continue".
- **Permissions**: SettingsCard rows (icon, name, why, ✓ or white pill "Grant"). A warning row for the 🌐 key
  setting with "Open Keyboard Settings". "Relaunch MyClicky" primary pill when needed.
- **API key**: secure field + "Test" pill + result line (green "Key works" / red error) + "Monthly budget: $7 (change
  later in Settings)" + link to console.anthropic.com.
- **Claude Code**: status line + copyable commands (monospaced cards with Copy) + "Check again" + "Skip for now".
- **Hands-on**: checklist of 5 actions with live ticks and a hint for each.
- **Interview**: one question at a time, big text, with a mic button (dictation into the field) and a text field.
  "Creating your Clickys…" with three avatar placeholders that pop in.
- **Done**: "You're all set, {name}." + three tips (hover the notch, hold fn, start with "agent").
