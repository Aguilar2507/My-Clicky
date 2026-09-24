# MyClicky

Your own screen-aware Mac assistant, inspired by [heyclicky](https://www.heyclicky.com/) and the MIT-licensed
[farzaa/clicky](https://github.com/farzaa/clicky).

- **Hold ⌃ Control + ⌥ Option and talk.** It screenshots your screens, asks Claude, answers out loud and flies a
  blue pointer to what you need.
- **Start with "agent…"** ("agent, organize my Downloads folder") to run a background task with Claude Code on your
  Claude subscription. Follow-ups within 15 minutes continue the same task ("agent, yes go ahead").
- **Ask by Typing…** from the menu bar icon if you'd rather type.

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
3. **Grant permissions** when asked: Microphone, Speech Recognition, Screen Recording and Accessibility.
   Screen Recording and Accessibility need you to flip the switch in System Settings, then quit and reopen MyClicky.
   The menu bar icon → Permissions shows what's missing.
4. **Paste your Anthropic API key** when prompted (create it at console.anthropic.com). It's stored in the Keychain.
   **Set a monthly spend limit** in the Console under Billing → Limits.
5. **Better voice (recommended):** System Settings → Accessibility → Spoken Content → System Voice → Manage Voices,
   download a *Premium* or *Enhanced* voice for your language. MyClicky picks it up automatically.

## Settings

Menu bar icon → **Open Settings File** (`~/Library/Application Support/MyClicky/config.json`). Restart the app after editing.

- `speechLocale`: e.g. `"en-US"` or `"es-ES"` (empty = system language)
- `fastModel` / `pointingModel`: which Claude models to use
- `voiceIdentifier`: a specific voice (empty = best installed)
- `agentAllowedTools`: what the agent may do without asking. `Bash` lets it run commands, including AppleScript to control apps.
  The agent is told to ask before anything irreversible (sending, deleting, buying).
- `agentWorkingDirectory`: where the agent puts files (default `~/MyClickyAgent`)

## Notes

- Rebuilding with the default ad-hoc signature makes macOS ask for Screen Recording and Accessibility again. To avoid that,
  create a self-signed "Code Signing" certificate named `MyClicky Dev` in Keychain Access and build with
  `SIGN_IDENTITY="MyClicky Dev" ./build.sh`.
- The menu shows this month's API spend, estimated from each response's token counts at list prices
  (`~/Library/Application Support/MyClicky/usage.json`). Agent tasks aren't included; they run on your Claude plan.
- Prompt caching is enabled, but Haiku 4.5 only caches prompts over ~4,000 tokens, so it mostly helps with longer conversations and Sonnet.
- Personal use only: the agent runs on your own Claude subscription.
