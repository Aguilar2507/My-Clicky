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
    private var galleryWindow: NSWindow?
    private var notch: NotchController!
    private var shortcuts: ShortcutCenter!

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--gallery") { showDesignGallery() }

        notch = NotchController(model: model)
        notch.onOpenSettings = { [weak self] in self?.model.openSettings() }
        shortcuts = ShortcutCenter(model: model)
        shortcuts.onEvent = { [weak self] event in self?.handle(event) }
        AppServices.shared = AppServices(shortcuts: shortcuts, notch: notch, assistant: assistant)

        observeChanges({ self.model.settings.showInDock }) { DockPolicy.apply(showInDock: $0) }
        observeChanges({ self.model.settings.showInScreenRecordings }) { _ in
            NSApp.windows.forEach { WindowSharing.apply(to: $0, model: self.model) }
        }

        requestPermissions()
        startShortcuts()
        quiet = QuietMonitor(model: model)
        notch.extraMenuItems = { [weak self] menu in self?.addQuietMenu(to: menu) }

        if Keychain.apiKey() == nil {
            // Until the welcome tour (012) exists, open Settings → General where the key is added.
            notch.openNow()
            model.openSettings(.general)
        }
    }

    // MARK: Permissions + shortcuts

    private func requestPermissions() {
        if !AXIsProcessTrusted() { Permission.accessibility.request() }
        if !ScreenCapture.hasPermission { ScreenCapture.requestPermission() }
        Task { _ = await SpeechRecognizer.requestPermissions() }
    }

    /// The key tap needs Accessibility + Input Monitoring; retry every few seconds until they're granted.
    private func startShortcuts() {
        if shortcuts.start() { return }
        if !CGPreflightListenEventAccess() { CGRequestListenEventAccess() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in self?.startShortcuts() }
    }

    private func handle(_ event: ShortcutMatcher.Event) {
        switch event {
        case .began(.pushToTalk): assistant.beginListening()
        case .ended(.pushToTalk): assistant.endListening()
        case .cancelled(.pushToTalk): assistant.cancelListening()
        case .triggered(.textMode): showTextMode()
        default: break // dictation arrives in spec 008
        }
    }

    // MARK: Text mode (spec 006 US5)

    private func showTextMode() {
        if textMode.isOpen { textMode.close(); return }
        textMode.onSubmit = { [weak self] text in self?.assistant.ask(typed: text) }
        textMode.show(near: NSEvent.mouseLocation)
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
