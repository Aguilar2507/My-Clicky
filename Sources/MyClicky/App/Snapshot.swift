import AppKit
import SwiftUI
import MyClickyCore

/// Renders app screens to PNG files without launching the app, so layouts can be compared with
/// `references/heyclicky/` (developer tool; see CLAUDE.md).
@MainActor
enum Snapshot {
    /// Screen name → view and size. Features register their screens here.
    static var screens: [String: (size: CGSize, view: () -> AnyView)] = [
        "gallery": (CGSize(width: 1000, height: 1000), { AnyView(DesignGallery()) }),
        "notch-collapsed": (CGSize(width: 520, height: 60), { AnyView(notchPreview(expanded: false).frame(width: 520, height: 60, alignment: .top).background(Color(hex: 0x7A7A7A))) }),
        "notch-expanded": (NotchGeometry.expandedSize, { AnyView(notchPreview(expanded: true)) }),
        "settings-general": (NotchGeometry.expandedSize, { AnyView(routePreview(.settings(.general))) }),
        "settings-shortcuts": (NotchGeometry.expandedSize, { AnyView(routePreview(.settings(.shortcuts))) }),
        "settings-cursor": (NotchGeometry.expandedSize, { AnyView(routePreview(.settings(.cursor))) }),
        "settings-voice": (NotchGeometry.expandedSize, { AnyView(routePreview(.settings(.voice))) }),
        "settings-microphone": (NotchGeometry.expandedSize, { AnyView(routePreview(.settings(.microphone))) }),
        "settings-dictation": (NotchGeometry.expandedSize, {
            previewModel.settings.customWords = ["Anthropic", "MyClicky", "Jose"]
            return AnyView(routePreview(.settings(.dictation)))
        }),
        "settings-agents": (NotchGeometry.expandedSize, { AnyView(routePreview(.settings(.agents))) }),
        "agent-chat": (NotchGeometry.expandedSize, { AnyView(routePreview(.home, select: seedAgentChat())) }),
        "morning": (CGSize(width: 420, height: 202), { AnyView(MorningNotchView(ideas: [
            Suggestion(text: "Draft the weekly update from Build Lab's notes", clickyTitle: "Build Lab", createdAt: Date()),
            Suggestion(text: "Check new remote AI architect roles", clickyTitle: "Role Scout", createdAt: Date()),
            Suggestion(text: "Summarize today's top 3 AI announcements", clickyTitle: nil, createdAt: Date()),
        ], onStart: { _ in }, onClose: {})) }),
        "settings-integrations": (NotchGeometry.expandedSize, {
            let i = previewModel.integrations
            i.claudeAvailable = true
            i.statuses = ["github": .connected, "notion": .needsAuth]
            return AnyView(routePreview(.settings(.integrations)))
        }),
        "companion": (CGSize(width: 700, height: 420), { AnyView(CompanionDemo()) }),
        "home": (NotchGeometry.expandedSize, { seedChats(select: nil); return AnyView(routePreview(.home)) }),
        "conversation": (NotchGeometry.expandedSize, { AnyView(routePreview(.home, select: seedChats(select: "Research Buddy"))) }),
    ]

    /// A model backed by a temporary folder, so snapshots never read or change your real data.
    static let previewModel: AppModel = {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("MyClickySnapshot-\(UUID().uuidString)")
        return AppModel(paths: AppPaths(base: base))
    }()

    static func routePreview(_ route: HomeRoute, select: UUID? = nil) -> some View {
        previewModel.route = route
        if let select { previewModel.selectedChatID = select }
        previewModel.settings.profileName = "Jose"
        return HomeRoot(chrome: HomeChrome(showsPopOut: true, onPopOut: {}, onClose: {}))
            .environment(previewModel)
            .frame(width: NotchGeometry.expandedSize.width, height: NotchGeometry.expandedSize.height)
    }

    /// A Clicky mid-task: steps (grouped), an Allow card and a Keep going card (spec 009 UI contract).
    static func seedAgentChat() -> UUID {
        MessageBubble.custom = { message, chat in AgentCards.render(message, chat: chat) }
        let m = previewModel
        let id = m.createClicky(purpose: "Keep an eye on the latest AI news")
        func step(_ text: String, _ tool: String, _ status: String) -> Message {
            var s = Message(role: .system, text: text, via: .agent)
            s.kind = .step; s.toolName = tool; s.status = status; s.refID = UUID().uuidString
            return s
        }
        var allow = Message(role: .system, text: "Run a command", via: .agent)
        allow.kind = .approval; allow.detail = "ls ~/Desktop"; allow.status = "pending"; allow.refID = "demo"
        var keep = Message(role: .system, text: "Signal Radar has used 40 steps on this. Keep going?", via: .agent)
        keep.kind = .notice; keep.status = "keepGoing"
        m.updateChat(id) {
            $0.title = "Signal Radar"
            $0.avatarColor = .peach
            $0.messages = [
                Message(role: .user, text: "Make a one-page summary of today's top 3 AI news with sources, as a markdown file.", via: .voice),
                Message(role: .assistant, text: "I'll look up today's AI news first.", via: .agent),
                step("Searching the web: AI news today", "WebSearch", "done"),
                step("Reading techcrunch.com", "WebFetch", "done"),
                step("Reading theverge.com", "WebFetch", "done"),
                step("Writing ai-news.md", "Write", "done"),
                allow,
                keep,
            ]
        }
        return id
    }

    /// Sample chats shaped like ref 02 (names, colors, times, previews).
    @discardableResult
    static func seedChats(select title: String?) -> UUID? {
        let m = previewModel
        guard m.clickys.isEmpty else { return m.clickys.first { $0.title == title }?.id }
        let cal = Calendar.current
        let now = Date()
        func day(_ back: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: cal.date(byAdding: .day, value: -back, to: now)!)!
        }
        let samples: [(String, AvatarColor, Date, String, Bool)] = [
            ("Signal Radar", .peach, day(0, 12, 29), "Today's new signals: GenAI pricing moves, two funding rounds and a new model release.", true),
            ("Browser Buddy", .sky, day(2, 10), "The iPhone 18 Pro Max starts at $1,199 in the US store.", false),
            ("Build Lab", .butter, day(3, 16), "Plans and scopes portfolio projects step by step.", false),
            ("Role Scout", .lilac, day(3, 9), "Hunts down AI architect roles that match your profile.", false),
            ("Shippy", .pink, day(5, 18), "Your personalized one-screen launch checklist is ready.", false),
            ("Research Buddy", .mint, day(5, 11), "Two-page SpaceX competitor summary with sources.", false),
        ]
        for (name, color, date, preview, unread) in samples.reversed() {
            let id = m.createClicky(purpose: preview)
            m.updateChat(id) {
                $0.title = name
                $0.avatarColor = color
                $0.append(Message(role: .user, text: "Please work on this.", createdAt: date.addingTimeInterval(-60)))
                $0.append(Message(role: .assistant, text: preview, createdAt: date, via: .agent))
                $0.isUnread = unread
            }
        }
        m.append(Message(role: .user, text: "What app am I in?", createdAt: day(6, 9), via: .voice, screensSeen: 2), to: m.talkChat.id)
        m.append(Message(role: .assistant, text: "You're in Safari, on the Apple Store page.", createdAt: day(6, 9)), to: m.talkChat.id)
        if let research = m.clickys.first(where: { $0.title == "Research Buddy" }) {
            m.updateChat(research.id) {
                $0.messages = [
                    Message(role: .user, text: "Make a two-page summary of SpaceX's main competitors, with sources.", createdAt: day(5, 10, 50), via: .voice),
                    Message(role: .assistant, text: "On it. I'll compare Blue Origin, Rocket Lab and ULA on launch cadence, cost per kg and upcoming missions.", createdAt: day(5, 10, 51), via: .agent),
                    Message(role: .user, text: "Add a short table at the end.", createdAt: day(5, 10, 58)),
                    Message(role: .assistant, text: "Done. The summary with a comparison table is in your MyClickyAgent folder as spacex-competitors.md.", createdAt: day(5, 11), via: .agent),
                ]
            }
        }
        return m.clickys.first { $0.title == title }?.id
    }

    static func notchPreview(expanded: Bool) -> some View {
        // 16" MacBook Pro geometry (1728×1117 pt, 184 pt notch).
        let geometry = NotchGeometry(screenFrame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
                                     auxLeftWidth: 772, auxRightWidth: 772, safeAreaTop: 38, menuBarHeight: 24)
        let ui = NotchPanelUI(geometry: geometry)
        ui.isExpanded = expanded
        previewModel.previewUnreadCount = 1
        let view = NotchContainerView(ui: ui).environment(previewModel)
        return expanded ? AnyView(view) : AnyView(view.frame(width: 990, height: 60, alignment: .top).clipped()
            .frame(width: 520, height: 60))
    }

    static func run(screen: String, output: String) -> Bool {
        _ = NSApplication.shared
        guard let entry = screens[screen] else {
            print("Unknown screen '\(screen)'. Available: \(screens.keys.sorted().joined(separator: ", "))")
            return false
        }
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let hosting = NSHostingView(rootView: entry.view().environment(\.colorScheme, .dark))
        let rect = NSRect(origin: .zero, size: entry.size)
        let window = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = hosting
        window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000)) // off-screen
        window.orderFrontRegardless()
        // Let SwiftUI lay out and finish first-frame work.
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        hosting.layoutSubtreeIfNeeded()
        // Render the real layer tree (cacheDisplay redraws shapes and adds artifacts at stroke seams).
        let scale: CGFloat = 2
        let width = Int(entry.size.width * scale), height = Int(entry.size.height * scale)
        guard let layer = hosting.layer,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        context.scaleBy(x: scale, y: scale)
        if layer.isGeometryFlipped {
            context.translateBy(x: 0, y: entry.size.height)
            context.scaleBy(x: 1, y: -1)
        }
        layer.render(in: context)
        window.orderOut(nil)
        guard let cgImage = context.makeImage() else { return false }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let png = rep.representation(using: .png, properties: [:]) else {
            print("Rendering failed")
            return false
        }
        do {
            try png.write(to: URL(fileURLWithPath: output))
            print("Wrote \(output)")
            return true
        } catch {
            print("Write failed: \(error)")
            return false
        }
    }
}
