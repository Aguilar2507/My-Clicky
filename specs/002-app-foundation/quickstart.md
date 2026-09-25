# Quickstart: App Foundation

## Prerequisites

- v0.1 installed and run at least once (so `config.json` and `usage.json` exist). Make a copy of the folder first:
  `cp -R ~/Library/Application\ Support/MyClicky ~/Desktop/MyClicky-backup`

## Validate

1. `swift build`: no errors.
2. `swift run MyClickyChecks`: ends with `All N checks passed`, exit status 0.
3. `./build.sh && open ~/Applications/MyClicky.app`:
   - `settings.json` exists, and its values match the old `config.json`. `config.v1.backup.json` exists.
   - The menu shows the same "API this month" total as before.
4. Hold ⌃⌥ and ask "what app am I in?": spoken answer (baseline US1).
5. Ask "where is the Apple menu?": the pointer flies there (baseline US2).
6. Change a setting in `settings.json`, relaunch, and it's kept. Then run `pkill -9 MyClicky` right after a change
   made through the app (later features), relaunch, and it's kept.
7. `open ~/Applications/MyClicky.app --args --gallery`: the design gallery matches `references/heyclicky/03-settings-general.png`.

## Expected results

All steps pass. Report any mismatch honestly in the feature's notes.
