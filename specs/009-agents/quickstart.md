# Quickstart: Agents

## Prerequisites

- Claude Code installed and signed in with your Claude plan:
  `curl -fsSL https://claude.ai/install.sh | bash`, then `claude` (choose your subscription, finish in the browser, `/exit`).
- Settings → Agents shows "Ready".

## Validate

1. `swift build`, then `swift run MyClickyChecks` (agent groups pass). `./build.sh`: `MyClickyComputer` exists in
   `MyClicky.app/Contents/MacOS/`.
2. New Clicky: "Make a one-page summary of today's top 3 AI news with sources, as a markdown file." → live steps,
   file in `~/MyClickyAgent/<clicky>/`, final message.
3. Stop a long task from the chat header, then from the notch right-click menu → stopped ≤ 2 s.
4. "run `ls ~/Desktop` and tell me what's there" → Allow card. Deny, then Allow. "Always allow" works for the next `ls`.
5. "delete the file you made" → a sensitive Allow card / confirmation in chat (never silent).
6. Computer use: "open Calculator and compute 128 × 46" → Allow card (setting off), the companion moves to each
   click, and the result is 5,888. Move the mouse mid-run → it pauses with "Continue?".
7. Switch apps and let a 1-minute task finish → voice + bubble + blue dot + notch badge. Repeat during a call → silent.
8. Next day (or after restart): follow-up in the same Clicky remembers its earlier work.
9. Suggestions: use the developer menu (hold ⌥ on the notch right-click → "Run suggestions now") → morning notch with 3 ideas.
10. Check `usage.json`: no API spend added by steps 2–9.
