# MyClicky: Complete Beginner's Guide

## Part 1: Where everything is

Two separate things live on your Mac:

| What | Where | What it is |
|---|---|---|
| **The project (source code)** | `/Users/joseaguilar/Desktop/my-clicky` | The code you edit. Think of it as the recipe. |
| **The app** | `/Users/joseaguilar/Applications/MyClicky.app` | The finished program you use. Think of it as the cooked meal. |

When you change the code, you have to **build** again to update the app (see Part 5).

> **What does `~` mean?** It's shorthand for your home folder, `/Users/joseaguilar`.
> So `~/Desktop/my-clicky` is the same as `/Users/joseaguilar/Desktop/my-clicky`.

> **Careful: there are two "Applications" folders.** The main one (`/Applications`) holds apps like Safari and VS Code.
> MyClicky is in the **one inside your home folder** (`~/Applications`).

---

## Part 2: Find the project in Finder

**Option A: click your way there**
1. Click the **Finder** icon (the blue smiley face) in the Dock.
2. In the top menu bar, click **Go → Home** (or press **⌘ Command + ⇧ Shift + H**).
3. Double-click the **Desktop** folder.
4. Double-click the **my-clicky** folder. This is the project.

**Option B: jump straight there**
1. Open Finder.
2. Press **⌘ Command + ⇧ Shift + G**. A small "Go to Folder" box appears.
3. Type `~/Desktop/my-clicky` and press **Enter**.

**Tip:** drag the `my-clicky` folder into Finder's left sidebar (under Favorites) so it's always one click away.

### What's inside the folder

```
my-clicky/
├── Sources/MyClicky/     ← the code (the .swift files)
│   ├── Prompts.swift        personality and instructions for Claude (easiest to edit)
│   ├── Assistant.swift      main flow: listen → screenshot → Claude → speak
│   ├── Overlay.swift        the blue pointer and bubble on screen
│   ├── AgentRunner.swift    "agent" mode (runs Claude Code)
│   ├── AppDelegate.swift    menu bar icon and the ⌃⌥ hotkey
│   ├── SpeechRecognizer.swift  turns your voice into text
│   ├── Speaker.swift        reads answers out loud
│   ├── ScreenCapture.swift  takes the screenshots
│   ├── ClaudeClient.swift   talks to Claude over the internet
│   ├── Config.swift         settings
│   ├── Keychain.swift       stores your API key safely
│   └── Main.swift           starting point of the app
├── Resources/Info.plist  ← app name and permission messages
├── build.sh              ← script that builds and installs the app
├── README.md             ← short technical summary
└── GUIDE.md              ← this guide
```

---

## Part 3: Open the project in VS Code

**Option A: from inside VS Code (easiest)**
1. Open **Visual Studio Code** (in your main Applications folder, or press **⌘ Space**, type `Visual Studio Code`, press Enter).
2. In the top menu, click **File → Open Folder…**
3. In the window that opens, go to your home folder (click `joseaguilar` in the sidebar, or press **⌘ ⇧ H**).
4. Click **Desktop** once, then click **my-clicky** once (don't go inside it).
5. Click the **Open** button.
6. If VS Code asks **"Do you trust the authors of the files in this folder?"**, click **Yes, I trust the authors**.

**Option B: drag and drop**
- Drag the `my-clicky` folder from Finder onto the VS Code icon in the Dock.

**Next time:** VS Code remembers it. Use **File → Open Recent → my-clicky**.

### Getting around VS Code

- **Left sidebar (Explorer, ⌘ ⇧ E):** all the project files. Click one to open it.
- **Middle:** the file you're editing. Save with **⌘ S**.
- **Bottom panel (Terminal):** open it with **Terminal → New Terminal** in the top menu, or press **⌃ Control + `** (the key under Esc).
  This terminal already starts **inside your project folder**, so the commands below just work.
- **Source Control (⌃ ⇧ G):** shows which files you changed.

---

## Part 4: What is the Terminal, and what do the commands mean?

The **Terminal** is a window where you type commands instead of clicking. You can open it in two ways:
- **Inside VS Code:** Terminal → New Terminal (recommended; it's already in the project folder).
- **The Terminal app:** press **⌘ Space**, type `Terminal`, press Enter. It starts in your home folder, so first type
  `cd ~/Desktop/my-clicky` and press Enter.

To run a command, **type it (or paste it) and press Enter.**

### Command dictionary

| Command | What it means | When to use it |
|---|---|---|
| `cd ~/Desktop/my-clicky` | **c**hange **d**irectory: "go into this folder". Like double-clicking a folder in Finder. | Only in the separate Terminal app, before the other commands. |
| `./build.sh` | Runs the build script in this folder (`./` means "in this folder"). It **(1)** turns the code into a program, **(2)** packages it as `MyClicky.app`, **(3)** quits the old app, **(4)** copies the new app to `~/Applications`. Takes about 30 seconds. | After every change to the code. |
| `open ~/Applications/MyClicky.app` | Starts the app, the same as double-clicking it in Finder. | After building, or any time you want to start it. |
| `swift build` | Only checks that the code compiles; doesn't install anything. | To quickly check for mistakes after editing. |
| `swift run MyClickyChecks` | Runs MyClicky's automatic checks and ends with "All N checks passed" (or lists what failed). | After every change, before building the app. |
| `pkill -x MyClicky` | Force-quits the app ("kill the process named exactly MyClicky"). | If the app gets stuck. |
| `curl -fsSL https://claude.ai/install.sh \| bash` | Downloads Anthropic's official Claude Code installer (`curl`) and runs it (`\| bash`). | **Once**, to enable "agent" mode. |
| `claude` | Opens Claude Code in the terminal. The first time, it asks you to log in. | **Once**, to log in with your Claude subscription. Type `/exit` to leave. |
| `git status` | Shows which files you changed since the last save point. | Whenever you're curious. |

---

## Part 5: The everyday cycle (edit → build → try)

1. **Edit** a file in VS Code, then press **⌘ S** to save.
2. **Build and relaunch.** In VS Code press **⌘ ⇧ B** (this runs `./build.sh` and opens the app for you).
   Or type in the terminal: `./build.sh && open ~/Applications/MyClicky.app`
3. **Try it:** hold **fn** and talk.

If the build shows red **error** lines, the code has a mistake. The message gives the file and line number.

> Each rebuild makes macOS ask again for the **Screen Recording** and **Accessibility** permissions (see Part 6, step 3).
> That's normal for this kind of homemade app.

---

## Part 6: First-time setup (do this once)

1. **Start the app.** In Finder, go to `~/Applications` (⌘ ⇧ G, type `~/Applications`) and double-click **MyClicky**.
   It has **no window**. It lives in the **notch** at the top of your screen: rest your pointer on the notch and the app opens.
2. **Add your Anthropic API key**, which pays for the screen questions:
   - Go to **console.anthropic.com**, sign in, open **API Keys**, and create a key.
   - Also open **Billing → Limits** and set a monthly limit (for example $10).
   - Open the notch → ⚙ Settings → General → API key → **Change**, paste the key, and click **Save**.
3. **Allow the permissions.** macOS asks for Microphone and Speech Recognition (click **Allow**).
   The others need manual steps in System Settings:
   - Open **System Settings → Privacy & Security → Screen & System Audio Recording** and turn on **MyClicky**.
   - Open **System Settings → Privacy & Security → Accessibility** and turn on **MyClicky**.
   - Open **System Settings → Privacy & Security → Input Monitoring** and turn on **MyClicky** (for the fn shortcut).
   - Open **System Settings → Keyboard**, set **Press 🌐 key to** → **Do Nothing**.
   - Then quit MyClicky (right-click the notch → Quit) and open it again.
   - Shortcut: Settings → General → **Permissions** shows ✓ or an **Open** button for each.
4. **Enable agent mode.** Open a terminal and run the two commands below, one at a time:
   ```
   curl -fsSL https://claude.ai/install.sh | bash
   claude
   ```
   When `claude` starts, choose to log in with your **Claude account/subscription** (not an API key) and finish the login in the browser.
   Type `/exit` to leave.
5. **Optional: nicer voice.** Go to System Settings → Accessibility → Spoken Content → System Voice → **Manage Voices…**,
   and download a voice marked **Premium** or **Enhanced** for your language.

---

## Part 7: Using MyClicky

| You want to… | Do this |
|---|---|
| Open the app | Rest your pointer on the **notch**. |
| Ask about your screen | Hold **fn**, speak, then let go. |
| Have it point at something | Ask "where is…" or "how do I…" (it uses the smarter model). |
| See your chats | Open the notch: **Talk** (screen questions) is pinned on top, your **Clickys** below. |
| Have it do a task | Click **+** and type the task, or say **"agent, …"**: "agent, create a reminder to call mom at 6". |
| Give a Clicky more work | Open it and type, or say "agent, ask Research Buddy to …". |
| Answer a Clicky's question | Open its chat and reply, or within 15 minutes say "agent, yes go ahead". |
| Type instead of talk | Double-tap **control**. |
| Make it stop talking | Press **fn** again. |
| Change settings or shortcuts | Open the notch → ⚙ Settings. |

---

## Part 8: Troubleshooting

| Problem | Fix |
|---|---|
| I can't find MyClicky | It lives in the notch (a black shape around it). Check that it's running: `pgrep -l MyClicky`. |
| fn does nothing / opens emoji | Turn on Accessibility and Input Monitoring, and set "Press 🌐 key to" → Do Nothing (Part 6, step 3). Restart the app. |
| It answers without seeing my screen | The Screen Recording permission is off (Part 6, step 3). |
| It says "set your API key" | Part 6, step 2. |
| "Claude Code isn't installed" | Part 6, step 4. |
| Everything is stuck | Run `pkill -x MyClicky`, then `open ~/Applications/MyClicky.app`. |
