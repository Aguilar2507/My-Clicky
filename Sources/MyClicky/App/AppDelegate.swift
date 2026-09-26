import AppKit
import SwiftUI
import ApplicationServices
import MyClickyCore

/// App startup and wiring. MyClicky lives in the notch (003); the v0.1 menu bar icon is gone (004 FR-008):
/// everything it offered is in the app (Settings → General) or the notch's right-click menu.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel.shared
    private lazy var assistant = Assistant(model: model)
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
        case .triggered(.textMode): askByTyping() // spec 006 replaces this with the field beside the cursor
        default: break // dictation arrives in spec 008
        }
    }

    // MARK: Interim text mode (until 006)

    private func askByTyping() {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.assistant.ask(typed: text)
        }
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
