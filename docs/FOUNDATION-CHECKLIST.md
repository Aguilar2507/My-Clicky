# MyClicky 0.4 — Foundation checklist

The last hands-on checks before main is the finished foundation. Everything a script can check is already done (see
"Already checked" at the end). Each line needs your hands, eyes, microphone or accounts.

**How to fill it in:** change `[ ]` to `[x]` when it works. If it doesn't, leave `[ ]` and write what happened after
the line, e.g. `→ answered in English`. About 45 minutes in total. The groups can be done in any order, except
**G (welcome tour), which goes last.**

Your settings now: window shortcut **⌃⌥⇧⌘3**, push to talk **⌃⌥** (hold), text mode **⌃ ⌃** (double-tap), dictation
**⌃fn** (hold; double-tap for hands-free). The new build (0.4.0 + fixes) is already installed and running.

## A. Window, settings, shortcuts (002, 004)

- [ ] ⌃⌥⇧⌘3 shows MyClicky; pressing it again hides it. The menu bar bot icon opens it too
- [ ] Settings → General: turn **Show in Dock** off → the Dock icon goes away; on → it's back
- [ ] Settings → General → What's new shows the changelog
- [ ] Turn **Show in screen recordings** OFF, record the screen with QuickTime (File → New Screen Recording) with MyClicky
      open, and watch the recording: is MyClicky hidden? Write **hidden** or **visible**:
- [ ] Shortcuts: change Push to talk to ⌥ option → holding ⌥ talks. Try binding Text mode to ⌥ option → "Already used".
      **Reset to defaults**, then set your window shortcut back to ⌃⌥⇧⌘3
- [ ] Type in Notes for a couple of minutes using ⌃A, ⌃E and fn-arrows → MyClicky never starts by itself
- [ ] Quit MyClicky right after changing a setting (menu bar icon → right-click → Quit), reopen → the setting is kept

## B. Talk, companion, voice (005, 006, 007)

- [ ] Hold ⌃⌥: "Jarvis, what app am I in?" → spoken answer; the cursor turns into sound waves while you talk
- [ ] Type a follow-up in the Talk chat → the answer uses what came before
- [ ] **Pointing (10 tries):** ask "Jarvis, where is …?" for things in Finder, Safari and System Settings. Hits out of 10
      (target 8 or more):
- [ ] "Jarvis, circle the search field in Safari" → a circle draws itself and fades
- [ ] Double-tap ⌃ → a text box appears by the cursor; type a question + Return → answer, and it's saved in Talk
- [ ] Settings → Cursor: change the color (it changes at once). Dock cursor ON → it rests under the menu bar icon,
      pointing still flies out and back. Then turn it OFF again
- [ ] Ask something long, then hold ⌃⌥ mid-answer → it stops at once and listens
- [ ] With an English page on screen, ask in Spanish: "Jarvis, ¿qué hay en mi pantalla?" → the whole answer is in Spanish,
      in a Spanish voice
- [ ] **Speed (10 tries):** time from letting go of ⌃⌥ to the first spoken word. Median (target 2.5 s or less):
- [ ] Settings → Voice: tap a voice to preview; Settings → Microphone: the test bars move when you talk
- [ ] During a FaceTime/Teams call (or with Voice Memos recording), ask a question → bubble only, no voice. Did quiet
      mode kick in by itself? Write **auto** or **no**:
- [ ] Right-click the menu bar icon → Quiet for 1 hour → answers are silent; turn it back off

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
