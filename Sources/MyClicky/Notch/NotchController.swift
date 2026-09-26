import AppKit
import SwiftUI
import MyClickyCore

/// MyClicky's home in the notch (spec 003): one panel per display, hover to open, leave to close,
/// click outside or Esc to close, pop out into a window, right-click menu.
@MainActor
final class NotchController {
    private struct Entry {
        let panel: NotchPanel
        let ui: NotchPanelUI
    }

    let model: AppModel
    var onOpenSettings: () -> Void = {}
    private var entries: [CGDirectDisplayID: Entry] = [:]
    private var state = NotchState()
    private var activeScreen: CGDirectDisplayID?
    private var monitors: [Any] = []
    private var ticker: Timer?
    private var menuIsOpen = false
    let popOut = PopOutWindowController()

    init(model: AppModel) {
        self.model = model
        popOut.onClose = { [weak self] in
            self?.state.closeWindow()
            self?.apply()
        }
        rebuild()
        installMonitors()
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuild() }
        }
        NotificationCenter.default.addObserver(forName: NSMenu.didBeginTrackingNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.menuIsOpen = true }
        }
        NotificationCenter.default.addObserver(forName: NSMenu.didEndTrackingNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.menuIsOpen = false }
        }
        observeChanges({ model.settings.notchOnAllDisplays }) { [weak self] _ in self?.rebuild() }
    }

    // MARK: Panels

    private func rebuild() {
        entries.values.forEach { $0.panel.orderOut(nil) }
        entries.removeAll()
        state.collapse()
        let builtIn = NSScreen.screens.first { $0.auxiliaryTopLeftArea != nil } ?? NSScreen.main
        for screen in NSScreen.screens {
            guard let id = screen.displayID else { continue }
            if !model.settings.notchOnAllDisplays, screen != builtIn { continue }
            let geometry = Self.geometry(for: screen)
            let ui = NotchPanelUI(geometry: geometry)
            ui.onPopOut = { [weak self] in self?.popOutNow() }
            ui.onClose = { [weak self] in self?.collapseNow() }
            let panel = NotchPanel(frame: geometry.expandedRect)
            panel.contentView = NSHostingView(rootView: NotchContainerView(ui: ui).environment(model))
            WindowSharing.apply(to: panel, model: model)
            panel.orderFrontRegardless()
            entries[id] = Entry(panel: panel, ui: ui)
        }
    }

    static func geometry(for screen: NSScreen) -> NotchGeometry {
        NotchGeometry(screenFrame: screen.frame,
                      auxLeftWidth: screen.auxiliaryTopLeftArea?.width,
                      auxRightWidth: screen.auxiliaryTopRightArea?.width,
                      safeAreaTop: screen.safeAreaInsets.top,
                      menuBarHeight: NSStatusBar.system.thickness)
    }

    // MARK: Input

    private func installMonitors() {
        let moved: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged]
        if let m = NSEvent.addGlobalMonitorForEvents(matching: moved, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.pointerMoved() }
        }) { monitors.append(m) }
        if let m = NSEvent.addLocalMonitorForEvents(matching: moved, handler: { [weak self] event in
            MainActor.assumeIsolated { self?.pointerMoved() }
            return event
        }) { monitors.append(m) }
        // Clicks in other apps close the panel.
        if let m = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown], handler: { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.state.outsideClick(isBusy: self.isBusy)
                self.apply()
            }
        }) { monitors.append(m) }
        // Right-click on the collapsed shape → menu.
        if let m = NSEvent.addGlobalMonitorForEvents(matching: [.rightMouseDown], handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.rightClick() }
        }) { monitors.append(m) }
        if let m = NSEvent.addLocalMonitorForEvents(matching: [.keyDown], handler: { [weak self] event in
            guard event.keyCode == 53 else { return event } // Esc
            let handled = MainActor.assumeIsolated { () -> Bool in
                guard let self, self.state.isExpanded else { return false }
                self.state.escape()
                self.apply()
                return true
            }
            return handled ? nil : event
        }) { monitors.append(m) }
    }

    private var isBusy: Bool {
        guard let entry = activeEntry else { return false }
        return entry.panel.firstResponder is NSText || entry.panel.attachedSheet != nil || menuIsOpen
            || NSApp.modalWindow != nil
    }

    private var activeEntry: Entry? { activeScreen.flatMap { entries[$0] } }

    private func pointerMoved() {
        let point = NSEvent.mouseLocation
        let hovered = entries.first { $0.value.ui.geometry.collapsedRect.insetBy(dx: 0, dy: -2).contains(point) }
        if state.phase == .collapsed, let hovered { activeScreen = hovered.key }
        let inShape = hovered?.key == activeScreen && hovered != nil
        let inPanel = activeEntry.map { state.isExpanded && $0.ui.geometry.expandedRect.contains(point) } ?? false
        if state.phase == .poppedOut, inShape, !popOut.isOpen {
            state.closeWindow()
        }
        if state.phase == .poppedOut, inShape {
            popOut.show(model: model)
            return
        }
        if state.pointer(inShape: inShape, inPanel: inPanel, now: ProcessInfo.processInfo.systemUptime, isBusy: isBusy) {
            apply()
        }
        updateTicker()
    }

    /// A short-lived timer so the 150 ms rest and 500 ms grace fire even if the mouse stops moving.
    private func updateTicker() {
        let needsTicks: Bool
        switch state.phase {
        case .hovering: needsTicks = true
        case .expanded(let outsideSince): needsTicks = outsideSince != nil
        default: needsTicks = false
        }
        if needsTicks, ticker == nil {
            ticker = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.pointerMoved() }
            }
        } else if !needsTicks {
            ticker?.invalidate()
            ticker = nil
        }
    }

    private func apply() {
        for (id, entry) in entries {
            let open = state.isExpanded && id == activeScreen
            if entry.ui.isExpanded != open { entry.ui.isExpanded = open }
            entry.panel.ignoresMouseEvents = !open
            entry.panel.acceptsKey = open
            if !open, entry.panel.isKeyWindow { entry.panel.resignKey() }
        }
        model.isNotchOpen = state.isExpanded
        if state.isExpanded { model.emit(.notchExpanded) }
        updateTicker()
    }

    // MARK: Actions

    func openNow() {
        if activeScreen == nil {
            activeScreen = NSScreen.main?.displayID ?? entries.keys.first
        }
        if state.phase == .poppedOut { popOut.show(model: model); return }
        state.open()
        apply()
    }

    func collapseNow() {
        state.collapse()
        apply()
    }

    func popOutNow() {
        state.popOut()
        apply()
        popOut.show(model: model)
    }

    private func rightClick() {
        let point = NSEvent.mouseLocation
        guard entries.values.contains(where: { $0.ui.geometry.collapsedRect.contains(point) }) else { return }
        let menu = NSMenu()
        menu.addItem(MenuAction.item("Open MyClicky") { [weak self] in self?.openNow() })
        if !model.settings.tour.finished {
            menu.addItem(MenuAction.item("Finish setup…") { WelcomeTour.resume() })
        }
        menu.addItem(MenuAction.item("Settings…") { [weak self] in
            self?.openNow()
            self?.onOpenSettings()
        })
        extraMenuItems(menu)
        menu.addItem(.separator())
        menu.addItem(MenuAction.item("Quit MyClicky") { NSApp.terminate(nil) })
        menu.popUp(positioning: nil, at: point, in: nil)
    }

    /// Later features add items (quiet mode, stop agents).
    var extraMenuItems: (NSMenu) -> Void = { _ in }
}

/// NSMenuItem with a closure action.
@MainActor
final class MenuAction: NSObject {
    private let action: () -> Void
    private static var retained: [MenuAction] = []

    private init(_ action: @escaping () -> Void) { self.action = action }

    static func item(_ title: String, key: String = "", action: @escaping () -> Void) -> NSMenuItem {
        let target = MenuAction(action)
        retained.append(target)
        if retained.count > 200 { retained.removeFirst(100) }
        let item = NSMenuItem(title: title, action: #selector(run), keyEquivalent: key)
        item.target = target
        return item
    }

    @objc private func run() { action() }
}
