# MyClicky

Your own screen-aware Mac assistant, inspired by [heyclicky](https://www.heyclicky.com/) and the MIT-licensed
[farzaa/clicky](https://github.com/farzaa/clicky).

- **MyClicky lives in your notch.** Rest the pointer on the notch to open the app (chats, settings); move away to close.
- **A companion beside your cursor.** A small glowing triangle follows your pointer. It pulses while listening,
  shimmers while thinking, shows answers in a bubble, **flies to things** to point at them and can **draw** circles,
  arrows and boxes on your screen. Pick its color or dock it in the notch in Settings → Cursor.
- **Hold control + option and talk.** It screenshots your screens, asks Claude and starts answering out loud within a couple of
  seconds, sentence by sentence as the answer arrives. Pick the voice (English and Spanish), speed and microphone in
  Settings → Voice / Microphone. It stays quiet during calls, screen sharing and Focus (answers show in the bubble
  with a ▶ Play chip); right-click the notch → Quiet mode to force it for an hour.
  Double-tap **control** to type a question right next to your cursor. Change the keys in Settings → Shortcuts.
- **Dictation anywhere.** Hold **⌃ control + fn**, speak, release: your words are typed where your text cursor is,
  in any app (on-device, never saved or sent). Double-tap **⌃ fn** for hands-free dictation (double-tap again to insert,
  Esc to cancel). English, Spanish or auto-detect, plus your own words, in Settings → Dictation.
- **Chats, like any AI app.** Your screen questions are saved in the pinned **Talk** chat. Your **Clickys** are named
  helpers (e.g. "Research Buddy"): click **+** or say "agent, …" to create one; "agent, ask Research Buddy to …" sends
  it a new task; follow-ups within 15 minutes continue the last Clicky. Search, rename, recolor and delete from the app.
- **Clickys do real work.** Each Clicky runs its tasks with Claude Code on your Claude plan, shows its steps live in
  its chat, asks with an **Allow card** before running commands, editing outside its folder, using your apps or
  clicking/typing on your Mac (sending, deleting, buying and posting always need your OK), and tells you when it's
  done (voice + bubble + blue dot + notch badge). Up to 3 run at once; stop them from the chat or the notch.
  Settings → Agents has the folder, autonomy, announcements and the Claude Code status. Once a day it can suggest tasks.
- **Integrations.** Settings → Integrations connects GitHub, Notion, Linear, Jira & Confluence, Asana or Sentry (or any
  custom connector) for your Clickys. Sign-in happens in your browser through Claude Code, which keeps the tokens;
  every action in a connected app still asks with an Allow card. The sidebar's **Apps** chip shows what's connected.
- MyClicky keeps a short written memory of each chat (never screenshots), so it remembers context cheaply.

| Piece | What it uses | Cost |
|---|---|---|
| Speech-to-text | Apple on-device recognition | free |
| Voice | macOS system voices, one per language (Settings → Voice) | free |
| Normal questions | `claude-haiku-4-5` via API key | ~$0.003 each |
| "Where / how do I…" questions | `claude-sonnet-5` via API key (better at pointing) | ~$0.01 each |
| Agent tasks (Clickys) and daily suggestions | Claude Code CLI, logged in with your Claude plan | included in your plan |

**Your budget.** MyClicky shows this month's spend beside your name (the ring fills toward your monthly budget).
The default budget is **$7/month**, so $20 of credit lasts about 3 months. At 80% it tells you once; at 100% it pauses
paid requests until the next month (agents keep working: they use your Claude plan) and offers "Allow $2 more this
month". Change or turn off the budget in Settings → General → Spending. Tap the spend to see the Spending sheet (by
model, by kind, last 6 months, and how long your credit will last).

## Setup

The first launch opens a **welcome tour** that does all of this with you (permissions with live ✓, API key test,
Claude Code check, a hands-on practice, and an interview that creates your first three Clickys). Replay it from
Settings → General. By hand:

1. **Install Claude Code** (for agent mode) and log in once:
   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```
   ```bash
   claude
   ```
   Choose to log in with your Claude subscription (not an API key).
2. **Build and install the app:**
   ```bash
   ./build.sh
   ```
   ```bash
   open ~/Applications/MyClicky.app
   ```
3. **Grant permissions** when asked: Microphone, Speech Recognition, Screen Recording, Device Control and Data Access (Accessibility before macOS 27) and
   **Input Monitoring** (needed so your shortcut keys work in every app). Some need you to flip the switch in System
   Settings, then quit and reopen MyClicky. Settings → General → Permissions shows what's missing.
   Also set System Settings → Keyboard → "Press 🌐 key to" → **Do Nothing**, so control + fn dictation doesn't also open the emoji picker.
4. **Paste your Anthropic API key** in Settings → General → API key (create it at console.anthropic.com). It's stored in the Keychain.
   **Set a monthly spend limit** in the Console under Billing → Limits.
5. **Better voice (recommended):** System Settings → Accessibility → Spoken Content → System Voice → Manage Voices,
   download a *Premium* or *Enhanced* voice for your language. MyClicky picks it up automatically.

## Settings

Open the notch → ⚙ (or right-click the notch → Settings…). Settings apply immediately. They're stored in
`~/Library/Application Support/MyClicky/settings.json` (v0.1's `config.json` was migrated automatically and kept as
`config.v1.backup.json`). Advanced values below can be edited in that file.

- `speechLocale`: e.g. `"en-US"` or `"es-ES"` (empty = system language)
- `fastModel` / `pointingModel`: which Claude models to use
- `voiceIdentifier`: a specific voice (empty = best installed)
- `agentAllowedTools`: what the agent may do without asking. `Bash` lets it run commands, including AppleScript to control apps.
  The agent is told to ask before anything irreversible (sending, deleting, buying).
- `agentWorkingDirectory`: where the agent puts files (default `~/MyClickyAgent`)

## Checks

`swift run MyClickyChecks` runs the automatic checks for MyClicky's core logic (routing, pricing, saving and loading).
It ends with `All N checks passed`, or lists each failure and exits with status 1. XCTest isn't used because it doesn't
build with Command Line Tools alone.

Developer tools: `MyClicky --gallery` opens the design gallery; `.build/debug/MyClicky --snapshot <screen> <file.png>`
renders a screen to an image (run with an unknown name to list screens).

## Notes

- `build.sh` signs with the self-signed `MyClicky Dev` certificate in your login keychain (set up 2026-09-26), so
  macOS keeps MyClicky's permissions across rebuilds. Without that certificate it falls back to an ad-hoc signature,
  and each rebuild quietly revokes Device Control and Data Access and Input Monitoring.
- The Settings profile card shows this month's API spend, estimated from each response's token counts at list prices
  (`~/Library/Application Support/MyClicky/usage.json`). Agent tasks aren't included; they run on your Claude plan.
- Prompt caching is enabled, but Haiku 4.5 only caches prompts over ~4,000 tokens, so it mostly helps with longer conversations and Sonnet.
- Personal use only: the agent runs on your own Claude subscription.
