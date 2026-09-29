import AppKit
import SwiftUI
import ApplicationServices
import MyClickyCore

/// App startup and wiring. MyClicky lives in the notch (003); the v0.1 menu bar icon is gone (004 FR-008):
/// everything it offered is in the app (Settings → General) or the notch's right-click menu.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel.shared
    private lazy var companion = CompanionController(model: model)
    private lazy var assistant = Assistant(model: model, companion: companion)
    private let textMode = TextModeField()
    private var quiet: QuietMonitor?
    private lazy var dictation = DictationController(model: model, companion: companion)
    private lazy var agents = AgentSupervisor(model: model, companion: companion)
    private var suggestions: SuggestionScheduler?
    private let topUpChip = TopUpChip()
    private var galleryWindow: NSWindow?
    private var notch: NotchController!
    private var shortcuts: ShortcutCenter!

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--gallery") { showDesignGallery() }
        EditShortcuts.install()

        notch = NotchController(model: model)
        notch.onOpenSettings = { [weak self] in self?.model.openSettings() }
        shortcuts = ShortcutCenter(model: model)
        shortcuts.onEvent = { [weak self] event in self?.handle(event) }
        shortcuts.onEscape = { [weak self] in self?.dictation.escape() ?? false }
        AppServices.shared = AppServices(shortcuts: shortcuts, notch: notch, assistant: assistant, agents: agents)
        assistant.agents = agents
        MessageBubble.custom = { message, chat in AgentCards.render(message, chat: chat) }
        ChatHeader.trailing = { chat, model in
            AnyView(Group {
                if model.workingChatIDs.contains(chat.id) {
                    Button("Stop") { AppServices.shared?.agents.stop(chatID: chat.id) }.buttonStyle(.pill(.dark, compact: true))
                }
            })
        }
        agents.announce = { [weak self] text, bubble in self?.assistant.announce(text, bubble: bubble) }

        observeChanges({ self.model.settings.showInDock }) { DockPolicy.apply(showInDock: $0) }
        observeChanges({ self.model.settings.showInScreenRecordings }) { _ in
            NSApp.windows.forEach { WindowSharing.apply(to: $0, model: self.model) }
        }

        requestPermissions()
        startShortcuts()
        quiet = QuietMonitor(model: model)
        PaidRequestGate.onWarn = { [weak self] percent, budget in
            self?.assistant.announce("You've used \(percent) percent of this month's budget.",
                                     bubble: "You've used \(percent)% of this month's \(UsageMonth.format(budget)) budget.")
        }
        PaidRequestGate.onBlock = { [weak self] resetsOn in
            guard let self else { return }
            let date = resetsOn.formatted(.dateTime.month(.abbreviated).day())
            self.companion.showBubble("Monthly budget reached. Paid requests are paused until \(date).", style: .info, autoHide: 15)
            self.topUpChip.show { PaidRequestGate.topUp(self.model) }
        }
        suggestions = SuggestionScheduler(model: model)
        suggestions?.onStart = { [weak self] idea in self?.startSuggestion(idea) }
        notch.extraMenuItems = { [weak self] menu in
            self?.addAgentsMenu(to: menu)
            self?.addQuietMenu(to: menu)
        }

        // Spec 012: first launch (or unfinished setup) opens the welcome tour. People upgrading with a working key
        // and all permissions aren't forced through it.
        model.settings.tour = TourFlow.initial(hasAPIKey: Keychain.apiKey() != nil,
                                               allPermissionsGranted: Permission.allCases.allSatisfy(\.isGranted),
                                               existing: model.settings.tour)
        WelcomeTour.controller = WelcomeWindowController(model: model)
        if !model.settings.tour.finished { WelcomeTour.controller?.show() }
    }

    // MARK: Permissions + shortcuts

    /// Permissions are asked step by step in the welcome tour; once it's done, ask again only for what's missing.
    private func requestPermissions() {
        guard model.settings.tour.finished else { return }
        if !AXIsProcessTrusted() { Permission.accessibility.request() }
        if !ScreenCapture.hasPermission { ScreenCapture.requestPermission() }
        Task { _ = await SpeechRecognizer.requestPermissions() }
    }

    /// The key tap needs Accessibility + Input Monitoring; retry every few seconds until they're granted.
    private func startShortcuts(attempt: Int = 0) {
        if shortcuts.start() {
            Log.shortcuts.notice("Shortcut listener started (attempt \(attempt))")
            return
        }
        if attempt == 0 {
            Log.shortcuts.notice("Shortcut listener waiting for permission: accessibility=\(AXIsProcessTrusted()) inputMonitoring=\(CGPreflightListenEventAccess())")
        }
        if !CGPreflightListenEventAccess() { CGRequestListenEventAccess() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in self?.startShortcuts(attempt: attempt + 1) }
    }

    private func handle(_ event: ShortcutMatcher.Event) {
        Log.shortcuts.notice("Shortcut: \(String(describing: event))")
        switch event {
        case .began(.pushToTalk): assistant.beginListening()
        case .ended(.pushToTalk): assistant.endListening()
        case .cancelled(.pushToTalk): assistant.cancelListening()
        case .triggered(.textMode): showTextMode()
        case .began(.dictate): dictation.holdBegan()
        case .ended(.dictate): dictation.holdEnded()
        case .cancelled(.dictate): dictation.holdCancelled()
        case .triggered(.handsFreeDictation), .began(.handsFreeDictation): dictation.toggleHandsFree()
        default: break
        }
    }

    // MARK: Text mode (spec 006 US5)

    private func showTextMode() {
        if textMode.isOpen { textMode.close(); return }
        textMode.onSubmit = { [weak self] text in self?.assistant.ask(typed: text) }
        textMode.show(near: NSEvent.mouseLocation)
    }

    // MARK: Agents menu (spec 009)

    private func addAgentsMenu(to menu: NSMenu) {
        if let ideas = suggestions?.todaysIdeas, !ideas.isEmpty {
            menu.addItem(MenuAction.item("Today's ideas (\(ideas.count))") { [weak self] in self?.suggestions?.show() })
        }
        if NSEvent.modifierFlags.contains(.option) { // developer: hold ⌥ while right-clicking
            menu.addItem(MenuAction.item("Run suggestions now") { [weak self] in Task { await self?.suggestions?.run() } })
        }
        let running = agents.runningChatIDs.compactMap { model.chat($0) }
        guard !running.isEmpty else { return }
        let item = NSMenuItem(title: "Stop agents", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for chat in running {
            sub.addItem(MenuAction.item("Stop \(chat.title)") { [weak self] in self?.agents.stop(chatID: chat.id) })
        }
        if running.count > 1 {
            sub.addItem(.separator())
            sub.addItem(MenuAction.item("Stop all") { [weak self] in self?.agents.stopAll() })
        }
        item.submenu = sub
        menu.addItem(.separator())
        menu.addItem(item)
    }

    /// A morning idea → its Clicky (by name), or a new Clicky.
    private func startSuggestion(_ idea: Suggestion) {
        let existing = model.clickys.first { SearchIndex.fold($0.title) == SearchIndex.fold(idea.clickyTitle ?? "") }
        let id = existing?.id ?? model.createClicky(purpose: idea.text)
        if existing == nil { Task { await ClickyNamer.name(id, from: idea.text, model: model) } }
        model.append(Message(role: .user, text: idea.text, via: .typed), to: id)
        agents.start(chatID: id, instruction: idea.text)
    }

    // MARK: Quiet mode (spec 007 US4)

    private func addQuietMenu(to menu: NSMenu) {
        let item = NSMenuItem(title: "Quiet mode", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let override = model.settings.quietOverride
        let active = override.until.map { $0 > Date() } ?? false
        let automatic = MenuAction.item("Automatic" + (model.isQuiet && !active ? " (quiet now)" : "")) { [weak self] in
            self?.model.settings.quietOverride = .init()
        }
        automatic.state = active ? .off : .on
        let on = MenuAction.item("Quiet for 1 hour") { [weak self] in
            self?.model.settings.quietOverride = .init(mode: .on, until: Date().addingTimeInterval(3600))
        }
        on.state = active && override.mode == .on ? .on : .off
        let off = MenuAction.item("Talk for 1 hour") { [weak self] in
            self?.model.settings.quietOverride = .init(mode: .off, until: Date().addingTimeInterval(3600))
        }
        off.state = active && override.mode == .off ? .on : .off
        [automatic, on, off].forEach(sub.addItem)
        item.submenu = sub
        menu.addItem(.separator())
        menu.addItem(item)
    }

    // MARK: Developer

    /// Design gallery (spec 002 US3): `MyClicky --gallery`.
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

    // MARK: Lifecycle

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        notch.popOutNow() // Dock icon click opens the window (spec 003 US5)
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.flush()
    }
}
