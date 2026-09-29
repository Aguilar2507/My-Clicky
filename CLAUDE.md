# MyClicky

Personal macOS assistant that lives in the MacBook notch (Swift, AppKit + SwiftUI, SwiftPM). The goal is to feel
exactly like HeyClicky (heyclicky.com) while costing far less: Haiku by default, free Apple speech in and out, agents
on the Claude subscription via Claude Code, API spend always visible.

## Rules

- Project principles: `.specify/memory/constitution.md` (v2.0.0). Read it before designing anything. **Cost first**,
  and **HeyClicky parity** (Principle VIII).
- Roadmap, shared architecture, visual language and HeyClicky deviations: `specs/README.md`.
- Reference screenshots: `references/heyclicky/` (git-ignored). Match their **layout**. MyClicky's own design
  (icon, bot, palette, rules) is in `references/myclicky/` (spec 013). Match its **colors and art**.
- Features are specified in `specs/002`–`012` (spec, plan, research, data model, contracts, quickstart, tasks).
  **All are implemented** (0.3.0); open tasks are manual quickstarts + Claude Code verifications. Status and to-do list:
  `docs/IMPLEMENTATION-REPORT.md`. Each `tasks.md` ends with implementation notes (deviations, files, findings).
- Mark tasks with `.specify/scripts/local/mark_tasks.py <tasks.md> <ids|all-except:ids> [notes.md]`.
- Screens for comparison live in `docs/screens/` (re-render after UI changes).
- New features go through `/speckit-specify` → `/speckit-plan` → `/speckit-tasks`. Each spec states its API cost impact
  and its deviations from HeyClicky.
- **Small fixes** (bugs, wording, constants) are fixed directly. No spec is needed.
- The user builds features in order and says when to move on. Don't start API experiments unprompted.

## Build, check and run

- Check it compiles: `swift build`
- Core logic checks (after 002 lands): `swift run MyClickyChecks`. XCTest/Swift Testing don't work here (Command Line
  Tools only).
- Render a screen to PNG for comparison with the references: `.build/debug/MyClicky --snapshot <screen> <out.png>`
  (`--snapshot x` lists screens).
- SwiftUI `@State` does NOT compile here (macro plugin missing in Command Line Tools). Use
  `@StateObject private var x = Box(value)` (see `DesignSystem/Theme.swift`). `@Observable`, `@Bindable`,
  `@Environment`, `@FocusState` and `@StateObject` work.
- Stroked capsules render notches on macOS 27: use `BorderedCapsule` (layered fills) for capsule borders.
- Colors come from `Theme`/`Brand` tokens only. The icon and bot are drawn in `DesignSystem/Brand.swift`. After
  changing the logo, run `./scripts/make-icon.sh` (regenerates `Resources/AppIcon.icns`). Screen snapshots can't draw
  blur; `--snapshot app-icon` and `--snapshot bot` use ImageRenderer and do.
- Build, install and launch: `./build.sh && open ~/Applications/MyClicky.app` (VS Code: ⌘⇧B)
- `build.sh` signs with the self-signed `MyClicky Dev` certificate (login keychain), so permissions survive rebuilds.
  If it prints "Signed with: ad-hoc", the certificate is missing and each rebuild silently revokes Device Control and
  Data Access (macOS 27's name for Accessibility) and Input Monitoring.
- Diagnostic log: `/usr/bin/log show --last 10m --predicate 'subsystem == "com.myclicky.app"'` (plain `log` is a zsh
  builtin).
