import AppKit
import SwiftUI

/// The app as a normal, movable window (spec 003 US3). Remembers its frame; hidden titlebar, no traffic lights.
@MainActor
final class PopOutWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    var onClose: () -> Void = {}

    var isOpen: Bool { window?.isVisible ?? false }

    func show(model: AppModel) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 990, height: 650),
                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        [.closeButton, .miniaturizeButton, .zoomButton].forEach { window.standardWindowButton($0)?.isHidden = true }
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 760, height: 520)
        window.backgroundColor = NSColor(Theme.windowBackground)
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        window.delegate = self
        let root = HomeRoot(chrome: HomeChrome(showsPopOut: false, onPopOut: {}, onClose: { [weak self] in self?.close() }))
            .environment(model)
        window.contentView = NSHostingView(rootView: root)
        if !window.setFrameUsingName("MyClickyWindow") { window.center() }
        window.setFrameAutosaveName("MyClickyWindow")
        WindowSharing.apply(to: window, model: model)
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        onClose()
    }
}
