# MyClicky 1.0.0 — Implementation Report

**Date:** 2026-10-22 · **Specs:** `specs/002`–`020` (+ `specs/archive/`) · **Map:** [`HOW-IT-WORKS.md`](HOW-IT-WORKS.md) · **Screens:** [`docs/screens/`](screens/)

## In one minute

- **All 336 tasks are done.** The last one, 011 T013, compared MyClicky's October spend with console.anthropic.com:
  within 1.2% through yesterday (today's requests weren't on the Console yet). The Console also showed that prompt
  caching never applies (Haiku 4.5 caches only 4,096+ token prefixes), a cost item for a future spec.
- **Every feature was tried for real** on 2026-10-20–22 by driving the installed app end to end (keys, clicks,
  Accessibility, a synthetic voice through the speakers, screenshots). The results, line by line, are in
  [`docs/FOUNDATION-CHECKLIST.md`](FOUNDATION-CHECKLIST.md). That run found and fixed 20+ real bugs (see 1.0.0 below).
- **Build:** `swift build` and the release build both succeed with **0 compiler warnings**.
- **Automatic checks:** `swift run MyClickyChecks` → **All 521 checks passed**.
- **How we work from here:** main is the foundation; every improvement gets its own branch and pull request
  (see "Workflow" in `CLAUDE.md`). End-to-end helpers for future branches: `scripts/e2e/`.

## 1.0.0 (the foundation)

- **Speech:** macOS runs one speech recognition at a time, so with auto-detect English was never heard (every voice
  answer came back in Spanish). The main language listens live; every language then reads the whole recording, which
  also stopped long dictations from losing text before pauses. The language picker trusts a transcript that reads like
  its own language and ignores missing confidence. Auto-detect 10/10, answer latency median 1.77 s.
- **Agents:** Deny killed MyClicky (SIGPIPE on a closed bridge connection); + made agents never got a name or their own
  folder; computer use ignored your input during fast click runs; the unread dot was skipped with the window open
  behind another app. All fixed and re-tested.
- **Integrations:** GitHub needs your own OAuth app (no dynamic client registration); Asana back on an address that
  allows sign-in; claude.ai connectors listed; Connect runs `claude mcp login` directly.
- **Talk:** quiet mode forgot calls while you held ⌃⌥; pointing 6/10 → 8/10 with clearer instructions; the local time
  is sent with each question.
- **Smaller:** ⌃⌥ on the way to ⌃⌥⇧⌘3 started listening; long shortcuts squeezed Settings; a private CoreAudio device in
  the microphone list; the keychain prompt on every launch; a raw "invalid x-api-key" message.
- **Known limits:** screen-sharing detection and Mail weren't exercised (no sharing app running, no Mail account);
  the ⌥ developer menu item can't be opened with synthetic keys; the welcome tour's interview picks generic agents.
  Bot animation uses 10–12% of a core on a 120 Hz display (6% at 60 Hz).

## 0.4.0 (013–020)

- **020 Jarvis voice:** the assistant is Jarvis. "Jarvis…" asks the cursor, "Jarvis agent…" gives an agent a task.
  The name is matched by sound in English and Spanish (`WakeWords`), and answers stay in the language you spoke
  (`ReplyLanguage`). "Clickys" are called "agents" in all copy. 487 checks.
- **019 App home:** no notch. MyClicky is a normal window (Dock, ⌘Tab), with a menu bar bot icon and a news dot
  (`StatusItemController`), and ⌥Space shows or hides it. The `Notch/` folder is removed; the old pop-out window is now
  `App/MainWindowController.swift`.
- **018 Agent presence:** the agent bot flies in to take a task (`AgentBotPresenter`, `--demo-agent-bot`). Every
  task end gets a notification, a haptic, the unread dot and a queued spoken line (`TaskAlerts`). Fixed: the
  assistant stayed "listening" after agent requests.
- **017 Adaptive layout:** centered columns (Settings 720 pt, conversations 820 pt), an adaptive voice grid, and a
  sidebar header (logo and name → home). Works in full screen. New `-wide` snapshots.
- **016 Brand refresh:** 3D glass icon, bot and avatars. A lively bot: its eyes follow the pointer, it hops on
  hover and it has talk-state moods (`--bench-bot` measures its CPU).
- **015 Apple look:** Light/Dark following the Mac, system colors and accent, red/green hover on confirmations, a
  native-style switch and traffic lights. New `-dark` snapshots.
- **014 Premium feel:** springs and press/hover feedback everywhere, glass surfaces, one type scale, live Reduce
  Motion / Transparency / Increase Contrast, haptics.
- **013 Visual identity:** app icon and glass bot drawn from your LOGO.png/BOT.png. Push to talk is ⌃⌥ (was fn).

## Per feature

| # | Feature | Tasks | Checks | Screens | Open |
|---|---|---|---|---|---|
| 002 | App foundation | 26/27 | 70 | gallery | T027 quickstart |
| 003 | Notch home (superseded by 019) | 19/20 | — | — | — |
| 004 | Settings, General, Shortcuts | 23/24 | 37 | settings-general, settings-shortcuts | T024 quickstart |
| 005 | Clickys and chats | 25/26 | 37 | home, conversation | T026 quickstart |
| 006 | Cursor companion | 18/19 | 26 | companion, settings-cursor | T019 quickstart |
| 007 | Voice talk | 17/18 | 40 | settings-voice, settings-microphone | T018 quickstart |
| 008 | Dictation | 14/15 | 23 | settings-dictation | T015 quickstart |
| 009 | Agents | 24/26 | 57 | agent-chat, settings-agents, morning | T001 Claude Code sample, T026 quickstart |
| 010 | Integrations | 12/15 | 21 | settings-integrations | T001–T002 verify with Claude Code, T015 quickstart |
| 011 | Spending and limits | 12/13 | 21 | spending | T013 compare with Console after a week |
| 012 | Welcome tour | 17/18 | 23 | welcome-intro, -permissions, -handson, -interview | T018 quickstart |
| | **Total** | **207/221** | **377** | **21** | **14** |

## How it works now

1. **It's a normal window** (019, replaces the 003 notch home). Open it from the Dock, ⌘Tab, the bot icon in the
   menu bar or ⌥Space (again to hide). The menu bar icon shows a dot when a Clicky has news or an agent is working;
   right-click it for Open, Settings, Quit, quiet mode, stop agents and today's ideas. Nothing opens on hover.
2. **The app looks like HeyClicky's** (002/004/005): the dark sidebar of chats, glossy lavender buttons and toggles,
   cards, the greeting with the mascot over the "Hi, how can I help ^_^?" pill, and Settings with the same 8 pages.
   MyClicky uses its own logo and mascot art.
3. **You talk with control + option** (004/007). Hold ⌃⌥, ask, release. Your screens are captured (MyClicky itself is left out)
   and the answer streams in. It's spoken sentence by sentence with an Apple voice in your language, and the bubble
   beside your cursor grows with it. Double-tap control to type instead, in a box next to your cursor. Every key can
   be changed in Settings → Shortcuts.
4. **The companion** (006): a glowing triangle trails your pointer. It pulses while listening, shimmers while
   thinking and bounces while speaking. It flies to things to point at them, draws circles, arrows, boxes and
   underlines, and can dock in the notch. There are 4 colors.
5. **Chats** (005): Talk (screen questions) is pinned; Clickys are named helpers. There's search (ignoring accents),
   rename, recolor, delete, unread dots and a notch badge. Each chat keeps a short written memory, never images.
6. **Dictation** (008): hold control + fn to type by voice in any app, or double-tap it for hands-free (Esc
   cancels). It works in English, Spanish or auto-detect, with your own spellings. Password fields are refused and
   your clipboard is restored.
7. **Clickys do real work** (009) with Claude Code on your Claude plan:
   - live steps in the chat
   - Allow cards for commands, edits outside their folder, connected apps and computer use (sending, deleting,
     buying and posting always ask)
   - up to 3 at once, a 30-minute limit, and a pause with "Keep going?" at 40 steps
   - stop from the chat or the notch
   - start and finish announcements, plus daily ideas
8. **Integrations** (010): a catalog (GitHub, Notion, Linear, Jira & Confluence, Asana, Sentry) and custom
   connectors, added to Claude Code. Sign-in happens in your browser, and MyClicky stores no secrets.
9. **Spending** (011): every paid request goes through one gate. The default budget is $7/month (≈ 3 months for
   $20); you get a notice once at 80%, and at 100% requests pause with "Allow $2 more this month". The footer ring
   and the Spending sheet show charts and how long your credit will last.
10. **Welcome tour** (012) on first launch:
    - name, permissions with a live ✓, and the API key test
    - Claude Code setup
    - hands-on practice that ticks itself off
    - an interview that creates your first three Clickys
    - replay it anytime from Settings → General

## Bugs found and fixed while building (by checks and snapshots)

- **Dates:** chats didn't save and load back exactly (fractions of a second were lost, and floating-point rounding
  shifted them). Dates are now stored as exact milliseconds.
- **Companion motion:** the spring was unstable at 30–60 fps (overshoot and "teleporting"). It now uses the exact
  critically damped formula.
- **Voice:** "p. ej." was split as a sentence end. Spanish abbreviations were added.
- **Voices:** robotic voices were chosen first because your Mac has no Premium voices. The ranking now prefers
  natural voice families, and Samantha is the default.
- **Budget:** $5.60 of $7 didn't count as 80% (7 × 0.8 = 5.6000000000000005). Thresholds now have a tolerance.
- **Layout:**
  - Row buttons and key caps wrapped onto two lines.
  - The Cursor page glow rendered as a solid disc, and the triangle angle was off.
  - Long names truncated more than HeyClicky's.
  - The footer spend text pushed the sidebar sideways.
  - A "default" branch in Settings was never used (the only compiler warning).
- **macOS 27 toolchain quirks** (documented in CLAUDE.md):
  - SwiftUI `@State` doesn't compile with Command Line Tools, so views use a small `Box` instead.
  - Outlined capsules draw notches at their ends, so borders are drawn as layered fills.
- **Privacy:** snapshots now use a fake API key, so no screenshot can show yours.

## Real findings about your Mac

- **The 🌐/fn key opens "Show Emoji & Symbols".** Set System Settings → Keyboard → "Press 🌐 key to" → **Do Nothing**,
  or ⌃ fn dictation will also open the emoji picker.
- **Only basic voices are installed.** Download a Premium or Enhanced voice for English and Spanish (Settings →
  Voice → Get more voices).
- **Claude Code 2.1.283 is installed** (2026-09-26) at `~/.local/bin/claude`, and `~/.local/bin` was added to your
  PATH in `~/.zshrc`. It still needs you to **sign in once**: run `claude` in a terminal and log in with your Claude
  account. Until then agents, integrations and daily ideas can't run.
- **Your microphones** (System Default, MacBook Pro Microphone, Microsoft Teams Audio) show up correctly on the
  Microphone page.

## Known limits (honest list)

- **Unverified until Claude Code is installed:** the Claude Code flags, stream format, permission rule syntax, the
  `claude mcp` commands and the catalog addresses. They follow the documentation, and the parsers are checked
  against hand-written samples in `specs/009-agents/samples/` and `specs/010-integrations/samples/`.
- **Best-effort quiet mode:** Focus/Do Not Disturb detection may be refused for an app that isn't signed by a
  registered developer. Screen-sharing detection looks for known sharing windows. The notch menu's "Quiet for 1 hour"
  covers misses.
- **Screen recordings:** "Show in screen recordings: off" may not hide MyClicky from every recorder on macOS 27. It
  needs to be tested (004 quickstart).
- **A few simplifications,** each listed in the feature's notes:
  - morning ideas appear in a panel under the notch instead of the notch widening
  - integrations use letter tiles instead of brand logos
  - the composer's new line is ⌥Return
- **Permissions after each rebuild:** macOS asks again for Screen Recording and Accessibility every time the app is
  rebuilt with the default signature (see the README for the self-signed certificate fix).

## Your to-do list, in order

1. **Optional but recommended:** download Premium voices, and sign in to Claude Code once (`claude` in a terminal).
2. **Run each feature's `quickstart.md`** (002 → 012) and write the results into its tasks.md notes. Those are the
   11 open "quickstart" tasks.
3. **With Claude Code ready:** do 009 T001 and 010 T001–T002. Save a real agent stream and real `claude mcp list`
   output into the `samples/` folders, and I'll update the parsers if anything differs.
4. **After a week:** compare the Spending sheet with console.anthropic.com (011 T013).

## Where things are

- Specs, plans, research, tasks with notes: `specs/NNN-*/`
- Roadmap and design rules: `specs/README.md` · Constitution: `.specify/memory/constitution.md`
- Screens: `docs/screens/*.png`. Re-render any of them with `.build/debug/MyClicky --snapshot <name> <file.png>`.
- Checks: `swift run MyClickyChecks` · Changelog: `Resources/CHANGELOG.md`
