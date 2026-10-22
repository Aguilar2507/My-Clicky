# Quickstart: Notch Home

> **Superseded by spec 019 (2026-10-01):** the notch home was removed. This quickstart can't run anymore and is kept as
> history. See `specs/019-app-home/` for the window, menu bar icon and ⌥Space.

1. `swift build` and `swift run MyClickyChecks` (NotchGeometry + NotchState groups pass).
2. `./build.sh && open ~/Applications/MyClicky.app`.
3. The built-in display shows a black notch extension. The external display shows a top-center pill.
4. Rest the pointer on the notch: it opens in < 0.5 s. Compare with `references/heyclicky/02-app-home.png`.
5. Move away: it closes after ~0.5 s. Press Esc while open: it closes at once.
6. Browse Safari with tabs near the top for 5 minutes: no accidental opens.
7. Pop out: a window appears. Move it, quit and relaunch, pop out again: same place. ✕ closes it.
8. Right-click the notch: Open / Settings… / Quit work.
9. Enter a full-screen app: the notch still opens.
10. Activity Monitor: MyClicky under 1% CPU while collapsed.
