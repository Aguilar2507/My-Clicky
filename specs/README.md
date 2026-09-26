# MyClicky Specs: Roadmap

MyClicky's goal is to feel exactly like HeyClicky (Principle VIII) while running on your own Anthropic
API key, with the free Apple voices and your Claude subscription for agents. Reference screenshots
live in `references/heyclicky/` (git-ignored):

| File | Shows |
|---|---|
| `01-notch-collapsed.png` | Collapsed notch: unread badge on the left, docked cursor on the right |
| `02-app-home.png` | Opened app: sidebar of Clickys, search, +, Apps chip, profile footer, greeting |
| `03`–`10-settings-*.png` | Settings pages: General, Voice, Microphone, Dictation, Shortcuts, Cursor, Agents, Integrations |

## Build order

Each feature has `spec.md` → `plan.md` (+ `research.md`, `data-model.md`, `contracts/`, `quickstart.md`) → `tasks.md`.
Build them in this order; each one depends on those above it.

**Implementation status (2026-09-25):** 207/221 tasks done, 377 checks passing; see
[docs/IMPLEMENTATION-REPORT.md](../docs/IMPLEMENTATION-REPORT.md). The open tasks are the manual quickstart runs and
the Claude Code verifications.

| # | Feature | Depends on | What you get |
|---|---|---|---|
| 001 | [baseline](001-baseline/spec.md) | — | What v0.1 does (history; partly replaced by the features below) |
| 002 | [app-foundation](002-app-foundation/spec.md) | 001 | Code reorganized, settings and chats saved safely, shared look, checks runner |
| 003 | [notch-home](003-notch-home/spec.md) | 002 | MyClicky lives in the notch; hover opens the app; pop out; Dock toggle |
| 004 | [settings-shell](004-settings-shell/spec.md) | 003 | Settings with Back, profile card, sidebar; General and Shortcuts pages; rebindable keys |
| 005 | [clickys-chats](005-clickys-chats/spec.md) | 004 | Chat list (pinned Talk + Clickys), search, new chat, conversation view, memory, greeting |
| 006 | [cursor-companion](006-cursor-companion/spec.md) | 005 | Glowing triangle companion, colors, dock, bubble, flying pointer, drawing, text mode |
| 007 | [voice-talk](007-voice-talk/spec.md) | 006 | Fn push-to-talk, streaming spoken answers, voice picker, speed, microphone page |
| 008 | [dictation](008-dictation/spec.md) | 007 | Hold ⌃+Fn to type by voice anywhere, hands-free mode, English/Spanish, custom words |
| 009 | [agents](009-agents/spec.md) | 005, 007 | Clickys run tasks with Claude Code, live progress, Allow cards, computer use, suggestions |
| 010 | [integrations](010-integrations/spec.md) | 009 | Connector catalog (GitHub, Notion, Linear…) and custom connectors for agents |
| 011 | [usage-limits](011-usage-limits/spec.md) | 005 | Monthly spend ring, monthly cap, warnings |
| 012 | [welcome-tour](012-welcome-tour/spec.md) | all | First-run setup, hands-on tour, interview that creates three Clickys |

## Shared architecture (all plans follow this)

```text
Package.swift
Sources/
├── MyClickyCore/        # library, Foundation only: models, stores, parsers, pure logic (checked)
│   ├── Models/          # Settings, Chat, Message, Clicky, UsageMonth, Shortcut, Integration…
│   ├── Stores/          # SettingsStore, ChatStore, UsageStore (atomic JSON files)
│   └── Logic/           # Router, ScreenTags, Pricing, SSE + stream-json parsers, ShortcutMatcher…
├── MyClicky/            # the app (AppKit + SwiftUI)
│   ├── App/             # Main, AppDelegate, AppModel (@Observable root), Permissions
│   ├── DesignSystem/    # Theme tokens and reusable controls (see below)
│   ├── Notch/  Home/  Settings/  Input/  Companion/  Talk/  Voice/
│   └── Dictation/  Agents/  Integrations/  Usage/  Onboarding/
├── MyClickyChecks/      # `swift run MyClickyChecks`: checks for MyClickyCore (no Xcode needed)
└── MyClickyComputer/    # (009) small MCP server that clicks/types for agents and asks for approval
```

- **UI:** SwiftUI views hosted in AppKit panels and windows. Overlays (companion, drawings) use Core Animation.
- **State:** one `@Observable AppModel` owns the stores and services. Views read from it.
- **Data:** `~/Library/Application Support/MyClicky/`: `settings.json`, `chats/<id>.json`, `usage.json`.
  Atomic writes, and a missing key means "use the default".
- **Talk (screen questions):** Anthropic Messages API with streaming, Haiku by default, Sonnet for pointing.
- **Agents:** Claude Code CLI (`claude -p … --output-format stream-json`) on the Claude subscription.
- **Speech:** Apple on-device recognition in, Apple voices out.
- **Global keys:** a CGEvent tap. Needs the Accessibility and Input Monitoring permissions.

## Visual language (taken from the screenshots)

| Token | Value |
|---|---|
| Window background | `#1E1E1E`; sidebar `#1B1B1B`; a black-to-clear fade at the top where the panel meets the notch |
| Card | fill `#2A2A2A`, 1 pt border `#3A3A3A`, corner radius 16, rows split by 1 pt `#3A3A3A` lines |
| Text | primary `#FFFFFF` (titles 28 pt bold, rows 17 pt semibold); secondary `#9A9A9F` 15 pt |
| Section label | 12 pt semibold, uppercase, letter-spaced, `#8E8E93` (e.g. `BEHAVIOR`) |
| Primary button | glossy lavender-blue pill (gradient `#C9D6FF`→`#7D97F2`, top highlight, dark text) |
| Secondary button | white glossy pill with dark text ("Change", "Check for updates") |
| Toggle | on: lavender-blue gradient track with a black knob; off: gray track with a light knob |
| Selected card | white/lavender 2 pt outline plus a round check badge in the top-right corner |
| Sidebar item | 17 pt with SF Symbol; selected = `#333333` rounded fill |
| Window chrome | top-right "pop out" and "close" icons, no traffic lights |
| Mascot | original MyClicky blob (pastel, happy `^ ^` eyes). Not HeyClicky's artwork |

## Deviations from HeyClicky (Principle VIII)

| HeyClicky | MyClicky | Why |
|---|---|---|
| Account email, FREE/Pro plan | Local name + API spend this month | III: no accounts or plans |
| OpenAI voices (Cedar, Marin…) | Best installed Apple voices | II, and your choice: free voices only |
| Check for updates, community links | Version + local "What's new" | III: no auto-updates, no community |
| 60+ dictation languages | English + Spanish + auto-detect between them | Your choice |
| Intro video in the welcome tour | Animated intro cards | No hosted media |
| Agent message quotas | Step limit + "Keep going?" card; Claude subscription limits apply | III/I |
| Their logo and blob mascot | Original MyClicky logo and blob | Original branding |
| No API key setting | API key row in General | Needed for your own key |
