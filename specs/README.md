# MyClicky Specs: Roadmap

MyClicky's goal is to feel exactly like HeyClicky (Principle VIII) while running on your own Anthropic
API key, with the free Apple voices and your Claude subscription for agents. Reference screenshots
live in `references/heyclicky/` (git-ignored):

| File | Shows |
|---|---|
| `01-notch-collapsed.png` | Collapsed notch: unread badge on the left, docked cursor on the right |
| `02-app-home.png` | Opened app: sidebar of Clickys, search, +, Apps chip, profile footer, greeting |
| `03`–`10-settings-*.png` | Settings pages: General, Voice, Microphone, Dictation, Shortcuts, Cursor, Agents, Integrations |

MyClicky's own design (spec 013) lives in `references/myclicky/` (git-ignored): `LOGO.png` (app icon), `BOT.png`
(in-app bot) and `visual-system.png` (palette and rules). **Layout follows HeyClicky; colors and art follow these.**

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
| 007 | [voice-talk](007-voice-talk/spec.md) | 006 | ⌃⌥ push-to-talk (was fn), streaming spoken answers, voice picker, speed, microphone page |
| 008 | [dictation](008-dictation/spec.md) | 007 | Hold ⌃+Fn to type by voice anywhere, hands-free mode, English/Spanish, custom words |
| 009 | [agents](009-agents/spec.md) | 005, 007 | Clickys run tasks with Claude Code, live progress, Allow cards, computer use, suggestions |
| 010 | [integrations](010-integrations/spec.md) | 009 | Connector catalog (GitHub, Notion, Linear…) and custom connectors for agents |
| 011 | [usage-limits](011-usage-limits/spec.md) | 005 | Monthly spend ring, monthly cap, warnings |
| 012 | [welcome-tour](012-welcome-tour/spec.md) | all | First-run setup, hands-on tour, interview that creates three Clickys |
| 013 | [visual-identity](013-visual-identity/spec.md) | 012 | Glass-cursor app icon, glass bot, midnight-navy palette |

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

## Visual language (HeyClicky's layout, MyClicky's palette: spec 013)

| Token | Value |
|---|---|
| Palette | Midnight `#080C1C`, Deep Navy `#11192F`, Electric Blue `#3B82F6`, Cyan Glow `#47D7FF`, Violet `#7C5CFF`, Magenta `#E35BFF`, Warm Glass `#FFD2B8`, Ice White `#F7FAFF` |
| Window background | Midnight with a subtle violet/blue bloom; sidebar `#0A0F22`; a black-to-clear fade at the top where the panel meets the notch |
| Card | fill Deep Navy, 1 pt border `#232D4D`, corner radius 16, rows split by 1 pt lines |
| Text | primary Ice White (titles 28 pt bold, rows 17 pt semibold); secondary `#98A2C0` 15 pt |
| Section label | 12 pt semibold, uppercase, letter-spaced, `#8A94B4` (e.g. `BEHAVIOR`) |
| Primary button | blue-violet glass pill (gradient `#5AB0FF`→Electric Blue→`#6A4DFF`, thin light border, blue glow, white text) |
| Secondary button | ice-white glass pill with navy text ("Change") |
| Toggle | on: blue-violet glass track with a white knob; off: navy track with a light knob |
| Selected card | white/blue 2 pt outline plus a round blue-violet check badge in the top-right corner |
| Sidebar item | 17 pt with SF Symbol; selected = `#1A2342` rounded fill |
| Window chrome | top-right "pop out" and "close" icons, no traffic lights |
| App icon | side-facing liquid-glass cursor with `^ ^` eyes and 3 neon dashes on a glass tile (`AppLogo`, LOGO.png) |
| Bot | front-facing liquid-glass cursor with `^ ^` eyes and two glass feet (`GlassBot`, BOT.png); Clicky avatars = small bot + color ring |

## Deviations from HeyClicky (Principle VIII)

| HeyClicky | MyClicky | Why |
|---|---|---|
| Account email, FREE/Pro plan | Local name + API spend this month | III: no accounts or plans |
| OpenAI voices (Cedar, Marin…) | Best installed Apple voices | II, and your choice: free voices only |
| Check for updates, community links | Version + local "What's new" | III: no auto-updates, no community |
| 60+ dictation languages | English + Spanish + auto-detect between them | Your choice |
| Intro video in the welcome tour | Animated intro cards | No hosted media |
| Agent message quotas | Step limit + "Keep going?" card; Claude subscription limits apply | III/I |
| Their logo and cloud mascot | Glass-cursor icon and glass bot (spec 013) | Your designs, original branding |
| Gray surfaces, lavender accents | Midnight navy, blue-violet glass accents | Your visual system (spec 013) |
| No API key setting | API key row in General | Needed for your own key |
| Push to talk: hold fn | Push to talk: hold ⌃ control + ⌥ option | Your choice (2026-09-26); dictation stays ⌃ fn |
