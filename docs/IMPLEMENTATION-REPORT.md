# MyClicky 0.3.0 — Implementation Report

**Date:** 2026-09-25 · **Specs:** `specs/002`–`012` · **Screens:** [`docs/screens/`](screens/)

## In one minute

- **207 of 221 tasks are done** (93.7%). Each finished task is marked `[X]` in its feature's `tasks.md`, with
  implementation notes at the bottom of that file.
- **The 14 open tasks are ones only you can do:**
  - **11 are "run the quickstart" tasks**, one per feature. They need the app running on your Mac, with your
    permissions, microphone and API key.
  - **3 need Claude Code installed and signed in** with your Claude plan: checking its commands and output format for
    agents (009 T001) and integrations (010 T001–T002).
- **Build:** `swift build` and the release build (`./build.sh --no-install`) both succeed from a clean cache, with
  **0 compiler warnings**.
- **Automatic checks:** `swift run MyClickyChecks` → **All 377 checks passed** (55 groups).
- **Visual check:** every screen was rendered with `MyClicky --snapshot` and compared with your HeyClicky screenshots.
  Several layout bugs were found and fixed this way.
- **Not yet done:** nobody has launched the finished app on your Mac and clicked through it. Until you run the
  quickstarts, anything that needs real hardware, permissions or the network is **built but unverified**: the notch
  hover, fn push-to-talk, the voice, dictation into other apps, agents and integrations.

## Per feature

| # | Feature | Tasks | Checks | Screens | Open |
|---|---|---|---|---|---|
| 002 | App foundation | 26/27 | 70 | gallery | T027 quickstart |
| 003 | Notch home | 19/20 | 22 | notch-collapsed, notch-expanded | T020 quickstart |
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

1. **It lives in your notch** (003). A black shape extends your notch, with an unread badge on the left and the
   docked cursor or agent activity on the right. Rest the pointer on it for 0.15 s and it grows into the app; move
   away for 0.5 s and it folds back. There's a pop-out window, a right-click menu (Open, Settings, Quit, quiet mode,
   stop agents, today's ideas) and a pill on your external monitor.
2. **The app looks like HeyClicky's** (002/004/005): the dark sidebar of chats, glossy lavender buttons and toggles,
   cards, the greeting with the mascot over the "Hi, how can I help ^_^?" pill, and Settings with the same 8 pages.
   MyClicky uses its own logo and mascot art.
3. **You talk with fn** (004/007). Hold fn, ask, release. Your screens are captured (MyClicky itself is left out)
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
  or fn push-to-talk will also open the emoji picker.
- **Only basic voices are installed.** Download a Premium or Enhanced voice for English and Spanish (Settings →
  Voice → Get more voices).
- **Claude Code isn't installed,** so agents, integrations and daily ideas can't run yet.
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

1. **Install and open:** `./build.sh && open ~/Applications/MyClicky.app`. The welcome tour starts.
2. **In the tour:** grant the five permissions (relaunch when asked), set the 🌐 key to Do Nothing, and test your API key.
3. **Optional but recommended:** download Premium voices; install Claude Code and sign in with your Claude plan
   (`curl -fsSL https://claude.ai/install.sh | bash`, then `claude`).
4. **Run each feature's `quickstart.md`** (002 → 012) and write the results into its tasks.md notes. Those are the
   11 open "quickstart" tasks.
5. **With Claude Code ready:** do 009 T001 and 010 T001–T002. Save a real agent stream and real `claude mcp list`
   output into the `samples/` folders, and I'll update the parsers if anything differs.
6. **After a week:** compare the Spending sheet with console.anthropic.com (011 T013).

## Where things are

- Specs, plans, research, tasks with notes: `specs/NNN-*/`
- Roadmap and design rules: `specs/README.md` · Constitution: `.specify/memory/constitution.md`
- Screens: `docs/screens/*.png`. Re-render any of them with `.build/debug/MyClicky --snapshot <name> <file.png>`.
- Checks: `swift run MyClickyChecks` · Changelog: `Resources/CHANGELOG.md`
