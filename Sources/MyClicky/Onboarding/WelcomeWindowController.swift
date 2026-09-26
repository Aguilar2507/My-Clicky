import AppKit
import SwiftUI
import MyClickyCore

/// The welcome window (spec 012): a normal centered window so permission prompts and System Settings jumps behave.
@MainActor
final class WelcomeWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    let model: AppModel

    init(model: AppModel) { self.model = model }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 600),
                              styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(Theme.windowBackground)
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: WelcomeView { [weak self] in self?.close() }.environment(model))
        window.center()
        WindowSharing.apply(to: window, model: model)
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() { window?.close() }

    func windowWillClose(_ notification: Notification) { window = nil }
}

/// Relaunches MyClicky (some permissions only apply after a restart) and the tour resumes at the same step.
@MainActor
enum Relauncher {
    static func relaunch() {
        AppModel.shared.flush()
        let path = Bundle.main.bundleURL.path
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 1; open -n \"\(path)\""]
        try? task.run()
        NSApp.terminate(nil)
    }
}

/// Where the tour can be reopened from (Settings → General → Replay, the notch's "Finish setup").
@MainActor
enum WelcomeTour {
    static var controller: WelcomeWindowController?

    static func replay(_ model: AppModel) {
        model.settings.tour = TourFlow.replay(model.settings.tour)
        controller?.show()
    }

    static func resume() { controller?.show() }
}
