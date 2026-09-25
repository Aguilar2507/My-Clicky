import AppKit
import SwiftUI
import ApplicationServices
import MyClickyCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let model = AppModel.shared
    private lazy var assistant = Assistant(model: model)
    private var statusItem: NSStatusItem!
    private var hotkeyMonitors: [Any] = []
    private var hotkeyDown = false
    private var galleryWindow: NSWindow?
    private var notch: NotchController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        assistant.onChange = { [weak self] in self?.updateIcon() }
        updateIcon()

        requestPermissions()
        installHotkey()

        // Spec 003: MyClicky lives in the notch. (The v0.1 status item stays until spec 004 replaces it.)
        notch = NotchController(model: model)
        observeChanges({ self.model.settings.showInDock }) { DockPolicy.apply(showInDock: $0) }

        if Keychain.apiKey() == nil {
            promptForAPIKey()
        }
        if CommandLine.arguments.contains("--gallery") { showDesignGallery() }
    }

    /// Developer screen with every shared control (spec 002, US3).
    private func showDesignGallery() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 760),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "MyClicky Design Gallery"
        window.contentView = NSHostingView(rootView: DesignGallery())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        galleryWindow = window
    }

    // MARK: Permissions

    private func requestPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options) // needed for the global hotkey
        if !ScreenCapture.hasPermission { ScreenCapture.requestPermission() }
        Task { _ = await SpeechRecognizer.requestPermissions() }
    }

    // MARK: Hotkey — hold Control + Option to talk

    private func installHotkey() {
        let handler: (NSEvent) -> Void = { [weak self] event in
            MainActor.assumeIsolated { self?.flagsChanged(event.modifierFlags) }
        }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handler) {
            hotkeyMonitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: { event in
            handler(event)
            return event
        }) {
            hotkeyMonitors.append(local)
        }
    }

    private func flagsChanged(_ flags: NSEvent.ModifierFlags) {
        let relevant = flags.intersection([.control, .option, .command, .shift])
        let pressed = relevant == [.control, .option]
        if pressed && !hotkeyDown {
            hotkeyDown = true
            assistant.beginListening()
        } else if !pressed && hotkeyDown {
            hotkeyDown = false
            assistant.endListening()
        }
    }

    // MARK: Menu

    private func updateIcon() {
        let symbol: String
        switch assistant.state {
        case .listening: symbol = "mic.fill"
        case .thinking: symbol = "ellipsis.circle"
        case .speaking: symbol = "speaker.wave.2.fill"
        case .idle: symbol = assistant.agent.isRunning ? "gearshape.2.fill" : "cursorarrow.rays"
        }
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "MyClicky")
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let hint = NSMenuItem(title: "Hold ⌃ Control + ⌥ Option and talk", action: nil, keyEquivalent: "")
        hint.isEnabled = false
        menu.addItem(hint)
        let agentHint = NSMenuItem(title: "Start with “agent…” to run a task", action: nil, keyEquivalent: "")
        agentHint.isEnabled = false
        menu.addItem(agentHint)
        menu.addItem(.separator())

        menu.addItem(item("Ask by Typing…", #selector(askByTyping), key: "t"))
        if assistant.state == .speaking {
            menu.addItem(item("Stop Speaking", #selector(stopSpeaking), key: "."))
        }
        if assistant.agent.isRunning {
            menu.addItem(item("Stop Agent", #selector(stopAgent), key: ""))
        }
        menu.addItem(item("Start Fresh Conversation", #selector(clearHistory), key: ""))
        menu.addItem(.separator())

        let permissions = NSMenuItem(title: "Permissions", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        sub.addItem(permissionItem("Screen Recording", ok: ScreenCapture.hasPermission,
                                   pane: "Privacy_ScreenCapture"))
        sub.addItem(permissionItem("Accessibility (hotkey)", ok: AXIsProcessTrusted(), pane: "Privacy_Accessibility"))
        sub.addItem(permissionItem("Microphone", ok: nil, pane: "Privacy_Microphone"))
        sub.addItem(permissionItem("Speech Recognition", ok: nil, pane: "Privacy_SpeechRecognition"))
        permissions.submenu = sub
        menu.addItem(permissions)

        menu.addItem(item(Keychain.apiKey() == nil ? "Set Anthropic API Key…" : "Change Anthropic API Key…",
                          #selector(promptForAPIKey), key: ""))
        menu.addItem(item("Open Settings File", #selector(openSettings), key: ","))
        let claudeFound = AgentRunner.findClaude(model.settings) != nil
        let agentStatus = NSMenuItem(title: claudeFound ? "Agent: Claude Code ready" : "Agent: Claude Code not installed",
                                     action: nil, keyEquivalent: "")
        agentStatus.isEnabled = false
        menu.addItem(agentStatus)
        let month = model.thisMonth
        let spend = NSMenuItem(title: "API this month: \(month.formattedCost) · \(month.questions) questions",
                               action: nil, keyEquivalent: "")
        spend.isEnabled = false
        menu.addItem(spend)
        menu.addItem(.separator())
        menu.addItem(item("Quit MyClicky", #selector(quit), key: "q"))
    }

    private func item(_ title: String, _ action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func permissionItem(_ name: String, ok: Bool?, pane: String) -> NSMenuItem {
        let mark = ok == nil ? "" : (ok! ? "✓ " : "✗ ")
        let item = item("\(mark)\(name)…", #selector(openPrivacyPane(_:)), key: "")
        item.representedObject = pane
        return item
    }

    // MARK: Actions

    @objc private func askByTyping() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Ask MyClicky"
        alert.informativeText = "It will look at your screen. Start with “agent” to run a task."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        field.placeholderString = "e.g. where is the export button?"
        alert.accessoryView = field
        alert.addButton(withTitle: "Ask")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let text = field.stringValue
        // Let the alert disappear before the screenshot is taken.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.assistant.ask(typed: text)
        }
    }

    @objc private func stopSpeaking() { assistant.stopSpeaking() }
    @objc private func stopAgent() { assistant.agent.cancel() }
    @objc private func clearHistory() { assistant.clearHistory() }
    @objc private func quit() { NSApp.terminate(nil) }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        notch?.popOutNow() // Dock icon click opens the window (spec 003 US5)
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.flush()
    }

    @objc private func openSettings() {
        model.flush()
        NSWorkspace.shared.open(model.paths.settings)
    }

    @objc private func openPrivacyPane(_ sender: NSMenuItem) {
        guard let pane = sender.representedObject as? String,
              let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func promptForAPIKey() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Anthropic API key"
        alert.informativeText = "Used for screen questions (Haiku/Sonnet). Stored in your macOS Keychain. " +
            "Create one at console.anthropic.com and set a monthly spend limit there."
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        field.placeholderString = "sk-ant-…"
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let key = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty { Keychain.setAPIKey(key) }
    }
}
