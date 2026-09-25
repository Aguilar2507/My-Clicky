# UI Contract: Agents

## Agents page (ref `09-settings-agents.png`)

- Title "Agents" · subtitle "Where agents work and how much rope they get."
- `WORKSPACE`: "Agent folder" / "Where agents spawn and put the things they make." → trailing "MyClicky default ›"
  (or the folder name). Click → folder picker, plus "Reset to default".
- `AUTONOMY`: three toggle rows with the reference texts ("…Uses more of your Claude plan's usage.";
  "Let Clickys click and type on your Mac without asking first. Off means each turn asks with an Allow card.";
  "Fresh task suggestions every 24 hours, announced through the morning notch.").
- `ANNOUNCEMENTS`: "Speak when a Clicky starts or finishes" / "MyClicky's voice tells you what a Clicky got done." ·
  "Show updates beside the cursor" / "A Clicky's reply streams in a bubble next to your cursor when it finishes."
- Footer caption: "MyClicky always stays quiet while you're on a call, sharing your screen, or in Do Not Disturb.
  Finished work waits in the chat and the notch shows how many Clickys have something new."
- `CLAUDE CODE` (added): status row "Ready · version x.y.z · signed in" ✓, or "Not installed" / "Not signed in" with
  numbered steps (install command, `claude` login) + white pill "Check again".

## In-chat cards

- **Step row**: 14 pt gray, SF Symbol by tool (globe = web, doc = read, pencil = write, terminal = bash, cursorarrow = computer),
  summary text, trailing spinner/✓/✕. Consecutive steps collapse into "7 steps ▸".
- **Allow card**: SettingsCard with the Clicky avatar, "{Name} wants to:" + plain description + monospaced detail
  (command/path). Buttons: primary "Allow", secondary "Always allow for {Name}", text "Deny". Sensitive → red
  "Sensitive" tag and no "Always" button.
- **Keep going card**: "{Name} has used 40 steps on this. Keep going?" · "Keep going" / "Stop here".
- **Stop**: a pill "Stop" in the chat header while running.

## Morning notch

The collapsed notch widens by 220 pt for 10 s: "☀️ 3 ideas for today". Hover shows a list of 3 rows (text + target
avatar) with "Start" pills.
