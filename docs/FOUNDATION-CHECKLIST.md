# MyClicky 0.4 — Foundation checklist

The last hands-on checks before main is the finished foundation. Everything a script can check is already done (see
"Already checked" at the end). Each line needs your hands, eyes, microphone or accounts.

**How to fill it in:** change `[ ]` to `[x]` when it works. If it doesn't, leave `[ ]` and write what happened after
the line, e.g. `→ answered in English`. About 45 minutes in total. The groups can be done in any order, except
**G (welcome tour), which goes last.**

Your settings now: window shortcut **⌃⌥⇧⌘3**, push to talk **⌃⌥** (hold), text mode **⌃ ⌃** (double-tap), dictation
**⌃fn** (hold; double-tap for hands-free). The new build (0.4.0 + fixes) is already installed and running.

## A. Window, settings, shortcuts (002, 004)

- [x] ⌃⌥⇧⌘3 shows MyClicky; pressing it again hides it. The menu bar bot icon opens it too
      → ✓ 4 presses alternated shown/hidden; a click on the icon opens it. **Fixed:** the ⌃⌥ on the way started push to
      talk (two taps + a "Hold the key while you talk" bubble); now it cancels quietly
- [x] Settings → General: turn **Show in Dock** off → the Dock icon goes away; on → it's back
      → ✓ off: no longer running in the Dock (your pinned icon stays, as pinned apps do); on: back
- [x] Settings → General → What's new shows the changelog
      → ✓ the sheet lists 0.4.0 (4) and 0.3.0 (3).
- [x] Turn **Show in screen recordings** OFF, record the screen with QuickTime (File → New Screen Recording) with MyClicky
      open, and watch the recording: is MyClicky hidden? Write **hidden** or **visible**:
      → **hidden** ✓ checked with a ScreenCaptureKit capture (what screen recorders use): switched off, the
      window isn't in the image; on, it is.
- [x] Shortcuts: change Push to talk to ⌥ option → holding ⌥ talks. Try binding Text mode to ⌥ option → "Already used".
      **Reset to defaults**, then set your window shortcut back to ⌃⌥⇧⌘3
      → ✓ holding ⌥ started listening; "Already used for Push to talk."; Reset restored the defaults; ⌃⌥⇧⌘3 is
      back. **Fixed:** with five keys the "Open MyClicky" row squeezed its title ("MyClic / ky"); long shortcuts
      now show symbols (⌃ ⌥ ⇧ ⌘ 3).
- [x] Type in Notes for a couple of minutes using ⌃A, ⌃E and fn-arrows → MyClicky never starts by itself
      → ✓ (TextEdit, unsaved) text typed with ⌃A, ⌃E, fn-← and fn-→: no shortcut or listening events at all.
- [x] Quit MyClicky right after changing a setting (menu bar icon → right-click → Quit), reopen → the setting is kept
      → ✓ a switch change reached disk within 0.3 s, survived a force kill (kill -9) and showed after relaunch.

## B. Talk, companion, voice (005, 006, 007)

- [x] Hold ⌃⌥: "Jarvis, what app am I in?" → spoken answer; the cursor turns into sound waves while you talk
      → ✓ spoken answers in English (Zoe) and Spanish (Marisol); the cursor turned into blue sound waves while
      listening. **Fixed:** English was never recognized: macOS runs one speech recognition at a time, so with
      auto-detect only the second language (Spanish) heard anything and every voice answer came back in Spanish.
      Now the main language listens live and the other one reads the same audio afterwards (+0.35 s).
- [x] Type a follow-up in the Talk chat → the answer uses what came before
      → ✓ typed "How many hours apart are those two cities?" after asking about Tokyo and London → it answered
      about London and Tokyo. **Fixed:** time answers were guesses ("16 hours and 46 minutes ahead") because the
      request never said what time it is; each question now carries the local date, time and time zone (~20
      tokens).
- [x] **Pointing (10 tries):** ask "Jarvis, where is …?" for things in Finder, Safari and System Settings. Hits out of 10
      (target 8 or more):
      → **8/10** ✓ (checked against each element's real on-screen frame). Finder 3/3 (Apple menu, Applications
      in the sidebar, Downloads), System Settings 3/3 (Wi-Fi, Bluetooth, Battery), Safari 2/4 (address bar and
      new tab hit; "back button" went to VS Code's ← just above Safari; "share" was mis-heard). First round was
      6/10; **fixed:** the prompt now says to always point for "where is…" and at the exact item named ("in the
      sidebar").
- [x] "Jarvis, circle the search field in Safari" → a circle draws itself and fades
      → ✓ "draw a circle around the address bar in Safari" → a blue circle around the address bar plus the
      pointer and its label; gone a few seconds later. (A first try was heard as "circular" and didn't draw: a
      hearing slip with the synthetic voice.)
- [x] Double-tap ⌃ → a text box appears by the cursor; type a question + Return → answer, and it's saved in Talk
      → ✓ double-tap ⌃ opened the box; "what is the capital of France?" + Return → "The capital of France is
      Paris.", saved in Talk as typed.
- [x] Settings → Cursor: change the color (it changes at once). Dock cursor ON → it rests under the menu bar icon,
      pointing still flies out and back. Then turn it OFF again
      → ✓ Green showed at once beside the pointer. Dock ON: the companion is hidden and stops following (as the
      setting says; not drawn under the icon), and a "where is" question still flew it out to point, then it
      went away. Set back to Blue, undocked.
- [x] Ask something long, then hold ⌃⌥ mid-answer → it stops at once and listens
      → ✓ speech stopped 1 ms after ⌃⌥ went down; listening started 67 ms later.
- [x] With an English page on screen, ask in Spanish: "Jarvis, ¿qué hay en mi pantalla?" → the whole answer is in Spanish,
      in a Spanish voice
      → ✓ "Jarvis, ¿qué aplicación estoy usando?" with English windows on screen → answered fully in Spanish
      with Marisol (es-ES); English questions get Zoe in English.
- [x] **Speed (10 tries):** time from letting go of ⌃⌥ to the first spoken word. Median (target 2.5 s or less):
      → **1.77 s** median over 18 spoken questions (1.49–2.41 s), from letting go of ⌃⌥ to the first spoken word
      ✓
- [x] Settings → Voice: tap a voice to preview; Settings → Microphone: the test bars move when you talk
      → ✓ tapping Zoe played the preview (speakers became active) without changing your voice; the test bars
      moved with the voice. **Fixed:** the device list showed "CADefaultDeviceAggregate-…", a hidden helper
      device macOS makes for MyClicky's own audio; it's filtered out now.
- [x] During a FaceTime/Teams call (or with Voice Memos recording), ask a question → bubble only, no voice. Did quiet
      mode kick in by itself? Write **auto** or **no**:
      → **auto** ✓ with the microphone held by another process (like a call app), the answer came as a silent
      bubble (quiet, reason: call). **Fixed:** quiet mode forgot the call as soon as you held ⌃⌥ (it can't tell
      whose mic use it sees while listening), so answers were spoken during calls.
- [x] Right-click the menu bar icon → Quiet for 1 hour → answers are silent; turn it back off
      → ✓ menu → Quiet for 1 hour → the next answer came only as a silent bubble (no voice); set back to
      Automatic.

## C. Dictation (008)

First copy the text `CLIPBOARD-TEST` (select it, ⌘C).

- [ ] Hold ⌃fn and say a sentence in **Notes**, **Safari** (any text field), **VS Code** and **Mail** → inserted with
      correct spacing in each one
- [ ] After that, ⌘V still pastes `CLIPBOARD-TEST` (your clipboard was restored)
- [ ] In a password field (any Safari login) → refused with a notice
- [ ] Click the desktop (no text field) and dictate → the notice says it's copied; ⌘V pastes what you said
- [ ] Hands-free: double-tap ⌃fn, talk for ~1 minute, double-tap again → everything inserted. Esc cancels
- [ ] Auto-detect: 5 English + 5 Spanish sentences. Correct out of 10 (target 9 or more):
- [ ] Settings → Dictation → add "Anthropic" to WORDS → dictating it comes out spelled exactly like that

## D. Agents (005, 009)

- [ ] **+** → "Make a one-page summary of today's top 3 AI news with sources, as a markdown file" → named within 2 s,
      live steps, the file appears in `~/MyClickyAgent/<agent>/`, final message
- [ ] Start a long task and stop it from the chat header; again from the menu bar icon (right-click → Stop agents) →
      it stops within 2 s
- [ ] "run `ls ~/Desktop` and tell me what's there" → Allow card. Deny once, then Allow. **Always allow** → the next
      `ls` doesn't ask
- [ ] "delete the file you made" → it asks first (never silent)
- [ ] "open Calculator and compute 128 × 46" → Allow card, the companion moves to each click, result 5,888. Move your
      mouse during the run → it pauses and asks to continue
- [ ] Switch to another app and let a ~1-minute task finish → notification + trackpad tap + spoken line + blue dot +
      menu bar dot
- [ ] Say "Jarvis agent, ask <that agent's name> to also add a fourth story" → it goes to that agent
- [ ] Tomorrow (or after a restart): a follow-up in the same agent remembers its earlier work
- [ ] Hold ⌥ and right-click the menu bar icon → Run suggestions now → today's ideas drop down from the icon
- [ ] Rename, recolor and delete an agent; search "summary" finds the right chat (also without accents)

## E. Integrations (010) — GitHub only

- [ ] Settings → Integrations → GitHub → **Connect** → a small Terminal window opens and your browser asks you to sign in
      → back in MyClicky it shows ● Connected within a few seconds. You can close the Terminal window
- [ ] In an agent: "list my open pull requests" → Allow card → an answer from GitHub
- [ ] Your claude.ai connectors (Claude Docs, Canva) show under Connected as "Managed in Claude Code"
- [ ] On github.com → Settings → Applications, revoke access → reopen the page → "Reconnect required" → Reconnect works
- [ ] **Disconnect** → GitHub goes back to Available
- [ ] Add custom connector with `http://bad` → error; with `https://mcp.sentry.dev/mcp` → added. Then remove it
- [ ] The **Apps** chip in the sidebar shows the connected icon and opens this page

## F. Spending (011)

- [ ] Ask 5 questions, one of them "Jarvis, where is …?" → the footer total grows; the Spending sheet's splits add up;
      Sonnet appears under "By model"
- [ ] Set the budget to **$0.05** → keep asking → an 80% notice once → at 100% the next question is blocked with a
      button → "Allow $2 more" → questions work again. Agents still run while it's blocked
- [ ] Put the budget back to **$7**
- [ ] console.anthropic.com → Usage → **October** total so far: $ (I compare it with MyClicky's count)

## G. Welcome tour from zero (012) — last

Tell me when you get here. I move your data folder to the Desktop first, and put it back afterwards. Your API key stays
in Keychain.

- [ ] Open MyClicky → the welcome tour starts. Time from the first screen to the first answer (target under 10 min):
- [ ] Each permission shows its ✓; after the relaunch, the tour picks up where it was
- [ ] API key: a wrong key shows an error, your real key shows "Key works"
- [ ] Hands-on practice: each action ticks itself off
- [ ] Interview: answer the three questions → three agents appear. Do they make sense? (yes / meh / no):
- [ ] Settings → General → Replay → finish it → three more agents; the earlier ones are still there

## Already checked (2026-10-20, no need to redo)

- **Build:** `swift build`, `swift run MyClickyChecks` (501 checks) and the release build pass. The app bundle has
  `MyClickyComputer` and `integrations.json`. It's signed with `MyClicky Dev`, so permissions survive rebuilds.
- **Launch:** no errors or faults in the app log for the last 3 days, and no crash reports.
- **Data:** `settings.json` (v6) and the v1 backup exist. The Talk chat has a written memory and no images. Agent chats
  store text only. `usage.json` has no agent spend (agents run on the Claude plan).
- **Claude Code** 2.1.283 is signed in. A real agent run, and a real `claude mcp` add/list/get/remove round trip,
  match what the app expects. Two problems were found and fixed (claude.ai connectors weren't listed; sign-in now goes
  straight to the browser).
- **Connectors:** all six catalog addresses are live. Atlassian and Asana moved to their current addresses.
- **Screens:** all 33 re-rendered, matching HeyClicky's layout. Bot CPU: 10–12% of one core on the built-in 120 Hz display
  (spec 016 measured 6.1%, most likely at 60 Hz).
