# How MyClicky works (1.0.0)

The app as it is today, area by area. Each area says what it does, where the code lives, and which specs built it
(`specs/NNN-*`; the full table is in [specs/README.md](../specs/README.md)). Specs are history; this page is the
current picture. Keep it up to date when a feature branch changes an area.

**Code layout:** `Sources/MyClickyCore` holds models, stores and pure logic (Foundation only, covered by
`MyClickyChecks`). `Sources/MyClicky` is the app (AppKit + SwiftUI), and `Sources/MyClickyComputer` is the small MCP
server agents use to click and type. One `@Observable AppModel` owns the state; `AppServices` wires the controllers
together.

## App and window
- **What it does:**
  - A normal Mac window: Dock, ⌘Tab, the menu bar bot icon, or the open-window shortcut (⌥Space by default) to show
    and hide it.
  - The menu bar icon shows a dot for news (unread chats, a running agent, unfinished setup). Right-click it for Open,
    Settings, today's ideas, quiet mode, Stop agents and Quit.
  - Columns stay centered at any window size and in full screen.
  - The logo and name at the top of the sidebar go home.
- **Code:** `App/` (`Main`, `AppDelegate`, `MainWindowController`, `StatusItemController`, `DockPolicy`), `Home/`.
- **Specs:** 019, 017, 004.

## Chats and Talk
- **What it does:**
  - The sidebar lists the pinned **Talk** chat (questions about your screen) and your **agents**.
  - It has search (accents ignored), rename, recolor, delete, and unread dots.
  - Each chat keeps a short written memory, never screenshots.
  - A Talk question sends screenshots of every display, the recent history, the memory and the local time. It uses
    Haiku by default and Sonnet for "where is…" / drawing questions, and streams the answer.
  - Every paid request goes through the spending gate.
- **Code:**
  - `Talk/`: `Assistant` (the request flow), `ClaudeClient`, `Prompts`, `MemoryManager` (memory and `AgentNamer`),
    `ScreenCapture`.
  - `Home/Conversation/`, `Home/Sidebar/`.
  - Core: `Chat`, `Message`, `ChatStore`, `ChatRouter`, `ContextWindow`, `ScreenTags`, `TalkContext`.
- **Specs:** 005, 007.

## Voice
- **What it does:**
  - Hold ⌃⌥ to talk. Your main language listens live (for live text and the wake word). When you let go, every
    language (English and Spanish) reads the whole recording, and the transcript that reads like its own language wins.
  - Answers are spoken sentence by sentence with Apple voices, in the language you spoke.
  - "Jarvis…" talks to the companion; "Jarvis agent…" gives an agent a task. The name is matched by sound.
  - Quiet mode keeps answers silent (bubble only) during calls, screen sharing and Focus, or for an hour from the menu.
- **Code:** `Voice/` (`SpeechRecognizer`, `SpeechQueue`, `QuietMonitor`, `AudioDevices`); Core `WakeWords`,
  `ReplyLanguage`, `Dictation` (`LanguagePicker`), `SentenceSplitter`, `VoiceRanking`.
- **Specs:** 007, 020.

## Cursor companion
- **What it does:**
  - A small glowing triangle follows your pointer. It shows listening (sound waves), thinking and speaking states and a
    bubble with the answer.
  - It flies to point at things with a label, and draws circles, arrows, boxes and underlines.
  - Double-tap ⌃ for a text box beside the cursor.
  - It can be docked (hidden, flies out only to point).
  - The agent bot comes out of the bottom-left corner when you give an agent a task.
- **Code:** `Companion/` (`CompanionController`, `CompanionLayer`, `DrawingLayer`, `TextModeField`,
  `AgentBotPresenter`); Core `CompanionMotion`.
- **Specs:** 006, 018.

## Dictation
- **What it does:**
  - Hold ⌃fn to dictate into any app; double-tap for hands-free (Esc cancels).
  - Text is inserted at the cursor and your clipboard is restored.
  - Password fields are refused before recording. With no text field, the text is copied instead.
  - English/Spanish auto-detect and custom words.
- **Code:** `Dictation/` (`DictationController`, `TextInserter`), sharing `Voice/SpeechRecognizer`.
- **Specs:** 008.

## Agents
- **What it does:**
  - Agents run tasks with Claude Code (`claude -p … --output-format stream-json`) on your Claude plan, each in its own
    folder under `~/MyClickyAgent/`.
  - Live steps show in the chat.
  - **Allow cards** appear for commands, edits outside the folder, connected apps and computer use (Allow / Always
    allow / Deny; sensitive actions always ask).
  - Computer use goes through `MyClickyComputer`, and pauses with "keep using your Mac?" when you touch the mouse.
  - Up to 3 agents run at once.
  - New agents are named from their first instruction.
  - Daily ideas appear under the menu bar icon.
  - **Every task end tells you:** a notification, a trackpad tap, the unread and menu bar dots, a spoken line and a
    bubble (rule in `CLAUDE.md`).
- **Code:** `Agents/` (`AgentSupervisor`, `ComputerActions`, `SuggestionScheduler`, `TaskAlerts`,
  `ClaudeCodeLocator`); Core `AgentEvents`, `PermissionDescriber`, `BridgeSocketServer`, `MCPProtocol`.
- **Specs:** 009, 018.

## Integrations
- **What it does:**
  - A catalog (GitHub, Notion, Linear, Jira & Confluence, Asana, Sentry) and custom connectors, added to Claude Code
    (`claude mcp add`).
  - Sign-in runs `claude mcp login` in a small Terminal window. GitHub uses your own OAuth app.
  - MyClicky stores no secrets.
- **Code:** `Integrations/IntegrationsModel`, `Settings/IntegrationsPage`, `Resources/integrations.json`; Core
  `Integration` (`MCPListParser`).
- **Specs:** 010.

## Spending
- **What it does:**
  - Every paid request is counted (by model, kind and day) at official prices.
  - A monthly budget ($7 by default) with a notice at 80%; at 100% requests pause until "Allow $2 more".
  - A footer ring and a Spending sheet; agents (Claude plan) aren't counted.
- **Code:** `Usage/` (`PaidRequestGate`, `SpendingViews`); Core `Pricing`, `Budget`, `UsageMonth`, `UsageStore`.
- **Specs:** 011.

## Settings and shortcuts
- **What it does:**
  - Pages: General, Voice, Microphone, Dictation, Shortcuts, Cursor, Agents, Integrations.
  - Every shortcut can be rebound, and conflicts are refused.
  - Settings live in `~/Library/Application Support/MyClicky/settings.json` (atomic writes; unknown or missing keys
    are tolerated). The API key is in the Keychain.
- **Code:** `Settings/`, `Input/` (`HotkeyTap`, `ShortcutCenter`); Core `Settings`, `SettingsStore`,
  `ShortcutMatcher`, `KeyCapLabels`.
- **Specs:** 004.

## Welcome tour
- **What it does:**
  - On first launch: intro, name, permissions with live ✓, API key test, Claude Code check, hands-on practice, and an
    interview that creates three agents.
  - Replay it from Settings → General. People who already have a key and all permissions skip it.
- **Code:** `Onboarding/`; Core `TourFlow`.
- **Specs:** 012.

## Look and design system
- **What it does:**
  - Light/Dark following the Mac, with system colors and accent.
  - Springs only, glass surfaces and one type scale.
  - Respects Reduce Motion / Transparency / Increase Contrast.
  - The 3D glass icon and the lively bot are drawn in code.
- **Code:** `DesignSystem/` (`Theme`, `Brand`, `Motion`, `Materials`, `Typography`, `Feedback`, `DisplayPrefs`);
  Core `Design/`.
- **Rules:** see `CLAUDE.md` → Build, check and run.
- **Specs:** 014, 015, 016.

## Diagnostics and testing
- **Checks:** `swift run MyClickyChecks`, the logic checks for `MyClickyCore`.
- **Events log:** `/usr/bin/log show --predicate 'subsystem == "com.myclicky.app"'`. The `events` category records what
  happened, never what was said.
- **End-to-end:** `scripts/e2e/` drives the installed app (keys, Accessibility, `say` into the mic, screenshots
  through `MyClicky --screenshot`, `--hold-mic` to fake a call).
  [docs/FOUNDATION-CHECKLIST.md](FOUNDATION-CHECKLIST.md) is the full pass for 1.0.0.
- **Screens:** `.build/debug/MyClicky --snapshot <screen> <out.png>` renders `docs/screens/`.
- **Status and history:** [docs/IMPLEMENTATION-REPORT.md](IMPLEMENTATION-REPORT.md) and `Resources/CHANGELOG.md`.
