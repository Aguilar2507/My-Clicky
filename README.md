# MyClicky

Your own screen-aware Mac assistant, inspired by [heyclicky](https://www.heyclicky.com/) and the MIT-licensed
[farzaa/clicky](https://github.com/farzaa/clicky).

- **MyClicky lives in your notch.** Rest the pointer on the notch to open the app (chats, settings); move away to close.
- **A companion beside your cursor.** A small glowing triangle follows your pointer. It pulses while listening,
  shimmers while thinking, shows answers in a bubble, **flies to things** to point at them and can **draw** circles,
  arrows and boxes on your screen. Pick its color or dock it in the notch in Settings → Cursor.
- **Hold fn and talk.** It screenshots your screens, asks Claude and answers out loud.
  Double-tap **control** to type a question right next to your cursor. Change the keys in Settings → Shortcuts.
- **Chats, like any AI app.** Your screen questions are saved in the pinned **Talk** chat. Your **Clickys** are named
  helpers (e.g. "Research Buddy"): click **+** or say "agent, …" to create one; "agent, ask Research Buddy to …" sends
  it a new task; follow-ups within 15 minutes continue the last Clicky. Search, rename, recolor and delete from the app.
- MyClicky keeps a short written memory of each chat (never screenshots), so it remembers context cheaply.

| Piece | What it uses | Cost |
|---|---|---|
| Speech-to-text | Apple on-device recognition | free |
| Voice | macOS system voices (picks the best installed one) | free |
| Normal questions | `claude-haiku-4-5` via API key | ~$0.003 each |
| "Where / how do I…" questions | `claude-sonnet-5` via API key (better at pointing) | ~$0.01 each |
| Agent tasks | Claude Code CLI, logged in with your Claude plan | included in your plan |

## Setup

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
3. **Grant permissions** when asked: Microphone, Speech Recognition, Screen Recording, Accessibility and
   **Input Monitoring** (needed so your shortcut keys work in every app). Some need you to flip the switch in System
   Settings, then quit and reopen MyClicky. Settings → General → Permissions shows what's missing.
   Also set System Settings → Keyboard → "Press 🌐 key to" → **Do Nothing**, so fn only talks to MyClicky.
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

- Rebuilding with the default ad-hoc signature makes macOS ask for Screen Recording and Accessibility again. To avoid that,
  create a self-signed "Code Signing" certificate named `MyClicky Dev` in Keychain Access and build with
  `SIGN_IDENTITY="MyClicky Dev" ./build.sh`.
- The Settings profile card shows this month's API spend, estimated from each response's token counts at list prices
  (`~/Library/Application Support/MyClicky/usage.json`). Agent tasks aren't included; they run on your Claude plan.
- Prompt caching is enabled, but Haiku 4.5 only caches prompts over ~4,000 tokens, so it mostly helps with longer conversations and Sonnet.
- Personal use only: the agent runs on your own Claude subscription.
