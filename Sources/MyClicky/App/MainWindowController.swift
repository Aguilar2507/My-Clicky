import AppKit
import SwiftUI

/// MyClicky's home (spec 019, was the spec 003 pop-out): a normal window that remembers its frame. Spec 015: the real
/// red/yellow/green buttons (close, minimize to the Dock, full screen) over a transparent titlebar.
/// Opened from the Dock, ⌘Tab, the menu bar icon or the "Open MyClicky" shortcut.
@MainActor
final class MainWindowController: NSObject, NSWindowDelegate {
    private let model: AppModel
    private var window: NSWindow?
    /// The app that was in front before the shortcut or menu bar icon brought MyClicky up; it comes back on hide.
    private var previousApp: NSRunningApplication?

    init(model: AppModel) {
        self.model = model
    }

    /// Visible, not minimized, and MyClicky is the active app.
    var isFrontmost: Bool {
        guard let window else { return false }
        return window.isVisible && !window.isMiniaturized && NSApp.isActive
    }

    func show(fullScreen: Bool = false) {
        let front = NSWorkspace.shared.frontmostApplication
        if front?.processIdentifier != ProcessInfo.processInfo.processIdentifier { previousApp = front }
        let window = self.window ?? makeWindow()
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        updateOpen()
        model.emit(.appOpened)
        if fullScreen { enterFullScreen(window) }
    }

    /// Hides the window (it keeps its place and size) and gives the focus back to the app you came from.
    func hide() {
        guard let window, window.isVisible else { return }
        if window.styleMask.contains(.fullScreen) { window.miniaturize(nil) } else { window.orderOut(nil) }
        updateOpen()
        previousApp?.activate()
        previousApp = nil
    }

    func toggle() {
        if isFrontmost { hide() } else { show() }
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: Self.defaultSize),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.title = "MyClicky"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 760, height: 520)
        window.backgroundColor = NSColor(Theme.contentBackground)
        window.isReleasedWhenClosed = false
        window.delegate = self
        let root = HomeRoot(chrome: HomeChrome(controls: .window)).environment(model)
        window.contentView = NSHostingView(rootView: root)
        // A frame saved on a display that's gone falls back to the main display.
        if !window.setFrameUsingName("MyClickyWindow") || !NSScreen.screens.contains(where: { $0.visibleFrame.intersects(window.frame) }) {
            window.center()
        }
        window.setFrameAutosaveName("MyClickyWindow")
        WindowSharing.apply(to: window, model: model)
        self.window = window
        measureButtons(window)
        return window
    }

    /// The window's default size (also the size screens are rendered at with `--snapshot`).
    static let defaultSize = CGSize(width: 990, height: 650)

    private func updateOpen() {
        let open = window.map { $0.isVisible && !$0.isMiniaturized } ?? false
        if model.isWindowOpen != open { model.isWindowOpen = open }
    }

    /// Where macOS put the window buttons (top-left based), so the sidebar header lines up with them (spec 017).
    private func measureButtons(_ window: NSWindow) {
        DispatchQueue.main.async { [weak self] in
            let buttons: [NSButton] = [.closeButton, .miniaturizeButton, .zoomButton].compactMap { window.standardWindowButton($0) }
            guard let content = window.contentView, !buttons.isEmpty else { return }
            let rects = buttons.map { content.convert($0.convert($0.bounds, to: nil), from: nil) }
            let union = rects.dropFirst().reduce(rects[0]) { $0.union($1) }
            let flipped = CGRect(x: union.minX, y: content.isFlipped ? union.minY : content.bounds.height - union.maxY,
                                 width: union.width, height: union.height)
            self?.model.windowButtonsFrame = flipped
        }
    }

    func windowDidEnterFullScreen(_ notification: Notification) { model.isWindowFullScreen = true }
    func windowWillExitFullScreen(_ notification: Notification) { model.isWindowFullScreen = false }
    func windowDidMiniaturize(_ notification: Notification) { updateOpen() }
    func windowDidDeminiaturize(_ notification: Notification) { updateOpen() }
    func windowDidBecomeKey(_ notification: Notification) { updateOpen() }

    private func enterFullScreen(_ window: NSWindow) {
        guard !window.styleMask.contains(.fullScreen) else { return }
        // Let the window finish appearing first, or the full-screen animation starts from nowhere.
        DispatchQueue.main.async { window.toggleFullScreen(nil) }
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        model.isWindowOpen = false
        model.isWindowFullScreen = false
    }
}
