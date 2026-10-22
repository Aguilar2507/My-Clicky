# Changelog

## 1.0.0 (5)

**MyClicky 1.0, the foundation.** Every feature was tried for real on your Mac, and these were fixed:

- **English is heard again:** with auto-detect on, only Spanish was ever recognized, so voice answers came back in
  Spanish. Now English and Spanish both listen, and long dictations keep every word, even across pauses.
- **Quiet during calls really stays quiet:** answers no longer speak out loud when you ask during a call.
- **Denying an agent's request no longer closes MyClicky,** and Stop is sturdier.
- **Agents get their own name and folder,** also when you make them with +.
- **Computer use pauses when you touch the mouse,** even in the middle of a fast run of clicks.
- **The unread dot shows** when a task finishes while you're in another app, even with MyClicky open behind.
- **GitHub connects** using your own GitHub OAuth app (GitHub doesn't allow the usual sign-in). Asana connects again.
  Your claude.ai connectors show under Connected. Allow cards say "GitHub", not "Github".
- **Pointing is more accurate:** Jarvis always points when you ask where something is, at the exact item you named.
- **Time questions are right:** Jarvis knows your local date, time and time zone.
- **Smaller fixes:** opening the window with ⌃⌥⇧⌘3 no longer starts listening; long shortcuts fit in Settings; the
  microphone list hides a system helper device; the API key asks once per update instead of every launch; a wrong
  API key gets a clear message.

## 0.4.0 (4)

- **Say "Jarvis":** the assistant is now called Jarvis (the app is still MyClicky). Start with "Jarvis…" to ask the
  cursor, or "Jarvis agent…" / "Jarvis agente…" to give an agent a task. It understands the name however it's heard,
  in English or Spanish ("Harvis", "Yarvis", "Jarbis", "jar vis"…), and ignores look-alikes like "harvest".
- **Answers stay in your language:** ask in Spanish and the whole answer is in Spanish, in the Spanish voice, even
  with an English page on screen; same in English. Agents answer and announce their results in the language you used.
- Clickys are now called **agents** everywhere in the app.
- **No more notch:** MyClicky is now a normal window you can put beside your work. Open it from the Dock, ⌘Tab, the
  bot icon in the menu bar, or **option + space** from any app (press again to hide). Nothing opens when your pointer
  passes the top of the screen anymore. The menu bar bot shows a dot when an agent has news or an agent is working;
  right-click it for the old notch menu. Today's ideas now drop down from the menu bar icon.
- **Fixed:** copy and paste (⌘C ⌘V ⌘X ⌘A ⌘Z) didn't work in any MyClicky text box. The API key box also has an eye
  button to show or hide the key, and a Paste button.
- **Fixed:** MyClicky crashed right after opening (a missing macOS permission text for Focus/Do Not Disturb).
- **Push to talk is now control + option** (hold both, speak, let go). fn alone no longer talks. Your old fn
  setting moves over automatically; a key you picked yourself is kept.
- **A new look:** MyClicky's own app icon (a glass cursor with a smile) and a glass bot that stands on the greeting
  pill and blinks. The whole app is now midnight navy with blue-violet glass buttons and toggles.
- **The bot takes agent tasks:** when you say "Jarvis agent…", the cursor steps aside and the bot pops out of the
  bottom-left corner to listen beside your pointer, then nods and flies back to its corner to work.
- **You always know when a task is done:** a notification (click it to open the chat), a spoken line when MyClicky
  is free, the bubble and a tap on the trackpad.
- **Fixed:** after giving a task by voice, MyClicky stayed "listening": its announcements never played and the next
  push-to-talk was ignored.
- **You can see MyClicky listening:** while you hold control + option, the cursor beside yours turns into sound
  waves that move with your voice, and turns back into the cursor when you let go.
- **Looks right at any size:** in a big window or full screen, Settings and conversations sit in a centered,
  readable column instead of hugging the left. MyClicky's logo and name sit at the top of the sidebar; click them to
  go home from anywhere.
- **A new icon, bot and avatars:** a 3D glass cursor with a friendly face on a light Mac icon tile. The bot on the
  greeting is now a shaded 3D character: it breathes, blinks, follows your pointer with its eyes, hops when you
  point at it, looks up while thinking and moves its mouth while talking. Each Clicky's avatar is a white bot on its
  own color, like Contacts.
- **Looks like an Apple app:** white and light gray in Light Mode, dark in Dark Mode, following your Mac. Black
  titles, gray text, your accent color for selection, switches and buttons. Buttons react to the pointer: Delete
  turns red and Cancel green when you point at them. Red, yellow and green window buttons at the top-left: close,
  minimize and full screen (in the notch: close, back to the notch, open full screen).
- **Feels more premium:** buttons, rows and cards react the moment you press them, and light up when you point at
  them. Everything moves on smooth springs you can interrupt: the notch grows out of the notch, cards appear like
  glass and leave the same way, and tour steps slide the way you're going. The panel, bubble and text box are
  navy glass. Text follows one type scale. MyClicky follows Reduce Motion, Reduce Transparency and Increase
  Contrast. A light trackpad tap marks push-to-talk, switches and finished Clickys (Settings → General to turn off).

## 0.3.0 (3)

- **Chats like any AI app:** a pinned Talk chat for screen questions and named **Clickys** for tasks. Search, rename,
  recolor, delete. Unread dots and a notch badge. MyClicky keeps short written memories (never screenshots).
- **A companion beside your cursor:** a glowing triangle that listens, thinks and speaks, shows answers in a bubble,
  flies to point at things and draws circles, arrows and boxes. Pick its color or dock it in Settings → Cursor.
- **Faster voice:** answers start speaking while they're still arriving. Choose voices (English and Spanish), speed
  and microphone. Stays quiet during calls, screen sharing and Focus.
- **Dictation anywhere:** hold control + fn to type by voice in any app; double-tap for hands-free.
- **Clickys do real work** with Claude Code on your Claude plan: live steps, Allow cards, computer use, daily ideas.
- **Integrations:** GitHub, Notion, Linear, Jira & Confluence, Asana, Sentry, or your own connector.
- **Spending:** a monthly budget ($7 by default) with a ring, notices at 80% and 100%, and a Spending sheet.
- **Welcome tour** on first launch.

## 0.2.0 (2)

- MyClicky now lives in your notch. Rest the pointer on it to open the app; move away to close it.
- Pop the app out into a normal window, or send it back to the notch with ✕.
- New Settings with General and Shortcuts pages, like HeyClicky.
- Push to talk is now **fn** (hold). Double-tap **control** to type instead. Change any shortcut in Settings → Shortcuts.
- Your API key, permissions and version live in Settings → General. The old menu bar icon is gone.
- Settings are saved safely in `settings.json`; your old settings were moved over automatically.
- Every question and answer is kept in your Talk chat (text only, never screenshots).

## 0.1.0 (1)

- Hold ⌃ Control + ⌥ Option and talk; MyClicky looks at your screens, answers out loud and points.
- Start with "agent" to run a background task with Claude Code.
