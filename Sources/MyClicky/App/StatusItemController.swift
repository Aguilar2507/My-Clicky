import AppKit
import SwiftUI
import MyClickyCore

/// MyClicky's menu bar icon (spec 019): the bot as a template image. Click shows or hides the window; right-click or
/// ⌃-click opens the menu that used to be on the notch. A dot appears while an agent has news, an agent is working or
/// setup isn't finished.
@MainActor
final class StatusItemController: NSObject {
    private let model: AppModel
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var onToggle: () -> Void = {}
    var onOpen: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    /// Later features add items (quiet mode, stop agents).
    var extraMenuItems: (NSMenu) -> Void = { _ in }

    private static weak var shared: StatusItemController?

    init(model: AppModel) {
        self.model = model
        super.init()
        Self.shared = self
        if let button = item.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityLabel("MyClicky")
            button.toolTip = "MyClicky"
        }
        observeChanges({ model.unreadCount > 0 || model.isAgentRunning || !model.settings.tour.finished }) { [weak self] dot in
            self?.item.button?.image = Self.icon(dot: dot)
        }
    }

    /// Where the menu bar icon is on screen (global coordinates), for things that hang from it: the morning ideas
    /// card and the docked companion. Falls back to the top-right of the main display.
    static var anchorRect: CGRect {
        if let frame = shared?.item.button?.window?.frame, frame.width > 0 { return frame }
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let height = NSStatusBar.system.thickness
        return CGRect(x: screen.frame.maxX - 180, y: screen.frame.maxY - height, width: height, height: height)
    }

    @objc private func clicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            onToggle()
        }
    }

    private func showMenu() {
        guard let button = item.button else { return }
        let menu = NSMenu()
        menu.addItem(MenuAction.item("Open MyClicky") { [weak self] in self?.onOpen() })
        if !model.settings.tour.finished {
            menu.addItem(MenuAction.item("Finish setup…") { WelcomeTour.resume() })
        }
        menu.addItem(MenuAction.item("Settings…") { [weak self] in
            self?.onOpen()
            self?.onOpenSettings()
        })
        extraMenuItems(menu)
        menu.addItem(.separator())
        menu.addItem(MenuAction.item("Quit MyClicky") { NSApp.terminate(nil) })
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    // MARK: Icon

    /// The bot's silhouette with its visor and eyes cut out, drawn as a template so macOS tints it for the menu bar.
    static func icon(dot: Bool) -> NSImage {
        let renderer = ImageRenderer(content: MenuBarBot(dot: dot).padding(2).frame(width: 18, height: 18))
        renderer.scale = 2
        let image = renderer.nsImage ?? NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: nil)!
        image.isTemplate = true
        image.accessibilityDescription = "MyClicky"
        return image
    }
}

/// Monochrome bot for the menu bar: body, visor cut out, "^ ^" eyes, and an optional dot at the top-right.
struct MenuBarBot: View {
    var dot = false

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height)
            ZStack {
                GlassBot.bodyShape.fill(Color.black)
                RoundedRectangle(cornerRadius: w * 0.09, style: .continuous)
                    .frame(width: w * 0.5, height: w * 0.25)
                    .position(x: w * 0.5, y: w * 0.565)
                    .blendMode(.destinationOut)
                ForEach([-1.0, 1.0], id: \.self) { side in
                    ChevronEye()
                        .stroke(Color.black, style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round))
                        .frame(width: w * 0.11, height: w * 0.05)
                        .position(x: w * (0.5 + side * 0.1), y: w * 0.58)
                }
                if dot {
                    Circle().frame(width: w * 0.42, height: w * 0.42)
                        .position(x: w * 0.86, y: w * 0.16)
                        .blendMode(.destinationOut)
                    Circle().fill(Color.black).frame(width: w * 0.28, height: w * 0.28)
                        .position(x: w * 0.86, y: w * 0.16)
                }
            }
            .compositingGroup()
            .frame(width: w, height: w)
        }
    }
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
