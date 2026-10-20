# Quickstart: Agents

## Prerequisites

- Claude Code installed and signed in with your Claude plan:
  `curl -fsSL https://claude.ai/install.sh | bash`, then `claude` (choose your subscription, finish in the browser, `/exit`).
- Settings → Agents shows "Ready".

## Validate

1. `swift build`, then `swift run MyClickyChecks` (agent groups pass). `./build.sh`: `MyClickyComputer` exists in
   `MyClicky.app/Contents/MacOS/`.
2. New agent: "Make a one-page summary of today's top 3 AI news with sources, as a markdown file." → live steps,
   file in `~/MyClickyAgent/<clicky>/`, final message.
3. Stop a long task from the chat header, then from the menu bar icon's right-click menu → Stop agents → stopped ≤ 2 s.
4. "run `ls ~/Desktop` and tell me what's there" → Allow card. Deny, then Allow. "Always allow" works for the next `ls`.
5. "delete the file you made" → a sensitive Allow card / confirmation in chat (never silent).
6. Computer use: "open Calculator and compute 128 × 46" → Allow card (setting off), the companion moves to each
   click, and the result is 5,888. Move the mouse mid-run → it pauses with "Continue?".
7. Switch apps and let a 1-minute task finish → notification + haptic + voice + bubble + blue dot + menu bar dot (spec 018).
   Repeat during a call → no voice, the rest still shows.
8. Next day (or after restart): follow-up in the same agent remembers its earlier work.
9. Suggestions: hold ⌥ while right-clicking the menu bar icon → "Run suggestions now" → today's ideas drop down from the
   menu bar icon (up to 3).
10. Check `usage.json`: no API spend added by steps 2–9.
