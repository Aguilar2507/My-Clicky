# MyClicky

Personal macOS assistant: a normal window plus a menu bar icon and ⌥Space shortcut (spec 019; the notch home is gone)
(Swift, AppKit + SwiftUI, SwiftPM). The goal is to feel
exactly like HeyClicky (heyclicky.com) while costing far less: Haiku by default, free Apple speech in and out, agents
on the Claude subscription via Claude Code, API spend always visible.

## Rules

- Project principles: `.specify/memory/constitution.md` (v2.0.0). Read it before designing anything. **Cost first**,
  and **HeyClicky parity** (Principle VIII).
- Roadmap, shared architecture, visual language and HeyClicky deviations: `specs/README.md`.
- Reference screenshots: `references/heyclicky/` (git-ignored). Match their **layout**. MyClicky's own design
  (icon, bot, palette, rules) is in `references/myclicky/` (spec 013). Match its **art** (logo, bot, avatars). App colors
  follow the Mac's Light/Dark appearance with system colors and the system accent (spec 015).
- Features are specified in `specs/002`–`020` (spec, plan, research, data model, contracts, quickstart, tasks).
  **All are implemented** (0.4.0); open tasks are the 002–012 manual quickstarts + Claude Code verifications. Status and
  to-do list: `docs/IMPLEMENTATION-REPORT.md`. Each `tasks.md` ends with implementation notes (deviations, files, findings).
- Mark tasks with `.specify/scripts/local/mark_tasks.py <tasks.md> <ids|all-except:ids> [notes.md]`. Passing
  `notes.md` **replaces** the file's existing implementation notes, so append notes by hand instead.
- Screens for comparison live in `docs/screens/` (re-render after UI changes).
- New features go through `/speckit-specify` → `/speckit-plan` → `/speckit-tasks`. Each spec states its API cost impact
  and its deviations from HeyClicky.
- **Small fixes** (bugs, wording, constants) are fixed directly. No spec is needed.
- **Rule: every task end tells the user** (spec 018). Anything that runs in the background (agents, Clickys, future
  task types) MUST, when it finishes, fails, pauses or stops unexpectedly: post a macOS notification (`TaskAlerts`),
  tap the haptic, set the unread dot/menu bar dot, and queue a spoken line + bubble (never dropped; skipped only while
  quiet or turned off in Settings → Agents). Use `AgentSupervisor.finishAnnouncement` or the same pieces.
- Voice: the assistant is **Jarvis** (spec 020; the app stays MyClicky). "Jarvis…" talks to the cursor companion;
  "Jarvis agent…" gives an agent a task. `WakeWords` matches the name by sound (English + Spanish). Replies stay in the
  language the user spoke (`ReplyLanguage`). Never call the assistant "Clicky" in copy or prompts.
- The user builds features in order and says when to move on. Don't start API experiments unprompted.

## Workflow (from 0.4.0)

- **main always builds and passes its checks.** Never commit feature work directly to main.
- **One branch per feature,** created from an up-to-date main: `git switch main && git pull && git switch -c NNN-short-name`.
  The name matches the spec folder (e.g. `021-…`; Spec Kit names the feature but does not create the branch).
  Small fixes go on `fix/<short-name>`.
- Spec work (`/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`) is committed on that branch,
  in small commits as it goes.
- **Before merging:** `swift build`, `swift run MyClickyChecks`, re-render the affected screens, and add a CHANGELOG entry
  under "Unreleased". Then push, open a PR (`gh pr create`), merge it into main and delete the branch.
- One feature branch open at a time; the user says when to start the next. Releases get a tag (`v0.4.0`, …) and
  `Resources/Info.plist` bumps the version.

## Build, check and run

- Check it compiles: `swift build`
- Core logic checks (after 002 lands): `swift run MyClickyChecks`. XCTest/Swift Testing don't work here (Command Line
  Tools only).
- Render a screen to PNG for comparison with the references: `.build/debug/MyClicky --snapshot <screen> <out.png>`
  (`--snapshot x` lists screens). Measure the animated bot's CPU: `.build/release/MyClicky --bench-bot` (spec 016).
- SwiftUI `@State` does NOT compile here (macro plugin missing in Command Line Tools). Use
  `@StateObject private var x = Box(value)` (see `DesignSystem/Theme.swift`). `@Observable`, `@Bindable`,
  `@Environment`, `@FocusState` and `@StateObject` work.
- Stroked capsules render notches on macOS 27: use `BorderedCapsule` (layered fills) for capsule borders.
- Motion, type, radii, shadows and surfaces come from `DesignSystem/` (spec 014): `Motion.*` springs (no fixed-duration
  easing), `.textStyle(...)` (no `.font(.system(size:))` on text), `.pressable`/`.hoverHighlight`, `.glass`,
  `Theme.Radius/Shadow`. Anything that animates or is translucent must respect `DisplayPrefs` (Reduce Motion /
  Transparency, Increase Contrast).
- Colors come from `Theme`/`Brand` tokens only. `Theme` colors are appearance-aware (spec 015); never hard-code navy,
  white or black text. Snapshots render Light Mode; append `-dark` to a screen name for Dark Mode (`home-dark`) and `-wide` for full
  screen on a 16" display (`settings-general-wide`, spec 017). Content columns use `Theme.Layout` widths. The icon and bot are drawn in `DesignSystem/Brand.swift`. After
  changing the logo, run `./scripts/make-icon.sh` (regenerates `Resources/AppIcon.icns`). Screen snapshots can't draw
  blur; `--snapshot app-icon` and `--snapshot bot` use ImageRenderer and do.
- Build, install and launch: `./build.sh && open ~/Applications/MyClicky.app` (VS Code: ⌘⇧B)
- `build.sh` signs with the self-signed `MyClicky Dev` certificate (login keychain), so permissions survive rebuilds.
  If it prints "Signed with: ad-hoc", the certificate is missing and each rebuild silently revokes Device Control and
  Data Access (macOS 27's name for Accessibility) and Input Monitoring.
- Each new build asks once for the API key ("MyClicky wants to use… in your keychain": click **Allow**). Apps without an
  Apple team ID are trusted per build; `Keychain` re-saves the key from each build, so its later launches don't ask.
- Diagnostic log: `/usr/bin/log show --last 10m --predicate 'subsystem == "com.myclicky.app"'` (plain `log` is a zsh
  builtin). The `events` category records what happened (never what was said): talk, voice, pointing, dictation,
  agents, alerts, budget, window.
- End-to-end checks drive the installed app: `source scripts/e2e/lib.sh` (keys, Accessibility, `say` into the mic,
  `shot` screenshots through `MyClicky --screenshot`, `--hold-mic` to fake a call). Needs Accessibility for the terminal.
