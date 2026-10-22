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
        "settings-general": (MainWindowController.defaultSize, { AnyView(routePreview(.settings(.general))) }),
        "settings-shortcuts": (MainWindowController.defaultSize, { AnyView(routePreview(.settings(.shortcuts))) }),
        "settings-cursor": (MainWindowController.defaultSize, { AnyView(routePreview(.settings(.cursor))) }),
        "settings-voice": (MainWindowController.defaultSize, { AnyView(routePreview(.settings(.voice))) }),
        "settings-microphone": (MainWindowController.defaultSize, { AnyView(routePreview(.settings(.microphone))) }),
        "settings-dictation": (MainWindowController.defaultSize, {
            previewModel.settings.customWords = ["Anthropic", "MyClicky", "Jose"]
            return AnyView(routePreview(.settings(.dictation)))
        }),
        "settings-agents": (MainWindowController.defaultSize, { AnyView(routePreview(.settings(.agents))) }),
        "agent-chat": (MainWindowController.defaultSize, { AnyView(routePreview(.home, select: seedAgentChat())) }),
        "morning": (CGSize(width: 420, height: 202), { AnyView(MorningIdeasView(ideas: [
            Suggestion(text: "Draft the weekly update from Build Lab's notes", agentTitle: "Build Lab", createdAt: Date()),
            Suggestion(text: "Check new remote AI architect roles", agentTitle: "Role Scout", createdAt: Date()),
            Suggestion(text: "Summarize today's top 3 AI announcements", agentTitle: nil, createdAt: Date()),
        ], onStart: { _ in }, onClose: {})) }),
        "settings-integrations": (MainWindowController.defaultSize, {
            let i = previewModel.integrations
            i.claudeAvailable = true
            i.statuses = ["github": .connected, "notion": .needsAuth]
            return AnyView(routePreview(.settings(.integrations)))
        }),
        "spending": (MainWindowController.defaultSize, {
            seedChats(select: nil)
            let m = previewModel
            let cal = Calendar.current
            for back in 0..<5 {
                let date = cal.date(byAdding: .month, value: -back, to: Date())!
                for i in 0..<(20 + back * 7) {
                    let model = i % 5 == 0 ? "claude-sonnet-5" : "claude-haiku-4-5"
                    m.usageStore.record(TokenUsage(model: model, inputTokens: 1600, outputTokens: 90),
                                        kind: i % 9 == 0 ? .memory : .answer, now: date)
                }
            }
            m.settings.creditUSD = 20
            m.settings.creditSince = cal.date(byAdding: .day, value: -20, to: Date())
            m.showingSpending = true
            return AnyView(routePreview(.home))
        }),
        "welcome-intro": (CGSize(width: 720, height: 600), { tourPreview(.intro) }),
        "welcome-permissions": (CGSize(width: 720, height: 600), { tourPreview(.permissions) }),
        "welcome-handson": (CGSize(width: 720, height: 600), {
            previewModel.seenEvents = [.appOpened, .talkAnswered]
            return tourPreview(.handsOn)
        }),
        "welcome-interview": (CGSize(width: 720, height: 600), { tourPreview(.interview) }),
        "welcome-apikey": (CGSize(width: 720, height: 600), { tourPreview(.apiKey) }),
        "companion": (CGSize(width: 700, height: 420), { AnyView(CompanionDemo()) }),
        "companion-listening": (CGSize(width: 360, height: 380), { AnyView(CompanionDemo(listening: true)) }),
        "home": (MainWindowController.defaultSize, { seedChats(select: nil); return AnyView(routePreview(.home)) }),
        "conversation": (MainWindowController.defaultSize, { AnyView(routePreview(.home, select: seedChats(select: "Research Buddy"))) }),
    ]

    /// A model backed by a temporary folder, so snapshots never read or change your real data.
    static let previewModel: AppModel = {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("MyClickySnapshot-\(UUID().uuidString)")
        return AppModel(paths: AppPaths(base: base))
    }()

    static func tourPreview(_ step: TourState.Step) -> AnyView {
        previewModel.settings.profileName = "Jose"
        previewModel.settings.tour.step = step
        return AnyView(WelcomeView(onClose: {}).environment(previewModel))
    }

    static func routePreview(_ route: HomeRoute, select: UUID? = nil) -> some View {
        previewModel.route = route
        if let select { previewModel.selectedChatID = select }
        previewModel.settings.profileName = "Jose"
        previewModel.isWindowFullScreen = wide
        let size = wide ? wideSize : MainWindowController.defaultSize
        return HomeRoot(chrome: HomeChrome(controls: .window))
            .environment(previewModel)
            .frame(width: size.width, height: size.height)
    }

    /// An agent mid-task: steps (grouped), an Allow card and a Keep going card (spec 009 UI contract).
    static func seedAgentChat() -> UUID {
        MessageBubble.custom = { message, chat in AgentCards.render(message, chat: chat) }
        let m = previewModel
        let id = m.createAgent(purpose: "Keep an eye on the latest AI news")
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
        guard m.agents.isEmpty else { return m.agents.first { $0.title == title }?.id }
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
            let id = m.createAgent(purpose: preview)
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
        if let research = m.agents.first(where: { $0.title == "Research Buddy" }) {
            m.updateChat(research.id) {
                $0.messages = [
                    Message(role: .user, text: "Make a two-page summary of SpaceX's main competitors, with sources.", createdAt: day(5, 10, 50), via: .voice),
                    Message(role: .assistant, text: "On it. I'll compare Blue Origin, Rocket Lab and ULA on launch cadence, cost per kg and upcoming missions.", createdAt: day(5, 10, 51), via: .agent),
                    Message(role: .user, text: "Add a short table at the end.", createdAt: day(5, 10, 58)),
                    Message(role: .assistant, text: "Done. The summary with a comparison table is in your MyClickyAgent folder as spacex-competitors.md.", createdAt: day(5, 11), via: .agent),
                ]
            }
        }
        return m.agents.first { $0.title == title }?.id
    }

    /// Brand artwork (spec 013), drawn with SwiftUI's ImageRenderer because the layer render below drops blur and glow.
    /// Transparent background, 1 px per point.
    static var artwork: [String: (size: CGSize, view: () -> AnyView)] = [
        "app-icon": (CGSize(width: 1024, height: 1024), { AnyView(AppLogo()) }),
        // Menu bar icon (spec 019), shown large on both menu bar tints.
        "menubar-icon": (CGSize(width: 288, height: 144), {
            AnyView(HStack(spacing: 0) {
                ForEach([false, true], id: \.self) { dot in
                    MenuBarBot(dot: dot).padding(24).frame(width: 144, height: 144)
                        .background(dot ? Color(white: 0.92) : Color(white: 0.85))
                }
            })
        }),
        "bot": (CGSize(width: 1024, height: 1024), {
            AnyView(ZStack {
                Theme.contentBackground
                GlassBot(sparkles: true, lift: 0.03).frame(width: 600, height: 600).offset(x: -40, y: 40)
            })
        }),
        // Spec 016: every avatar color, plus Talk, at chat-list and bubble sizes.
        "avatars": (CGSize(width: 1000, height: 300), {
            AnyView(ZStack {
                Theme.contentBackground
                VStack(spacing: 28) {
                    HStack(spacing: 22) {
                        TalkAvatar(size: 84)
                        ForEach(AvatarColor.allCases, id: \.self) { BotAvatar(ring: Color(hex: $0.blobHex), size: 84) }
                    }
                    HStack(spacing: 22) {
                        TalkAvatar(size: 42)
                        ForEach(AvatarColor.allCases, id: \.self) { BotAvatar(ring: Color(hex: $0.blobHex), size: 42) }
                        TalkAvatar(size: 26)
                        ForEach(AvatarColor.allCases, id: \.self) { BotAvatar(ring: Color(hex: $0.blobHex), size: 26) }
                    }
                }
            })
        }),
    ]

    static func renderArtwork(_ entry: (size: CGSize, view: () -> AnyView), output: String) -> Bool {
        let renderer = ImageRenderer(content: entry.view().frame(width: entry.size.width, height: entry.size.height)
            .environment(\.colorScheme, snapshotScheme))
        renderer.scale = 1
        guard let cgImage = renderer.cgImage,
              let png = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]),
              (try? png.write(to: URL(fileURLWithPath: output))) != nil else {
            print("Rendering failed")
            return false
        }
        print("Wrote \(output)")
        return true
    }

    /// Screens render in Light Mode; add "-dark" to a screen name for Dark Mode (spec 015), e.g. `home-dark`.
    static var snapshotScheme: ColorScheme = .light
    /// Add "-wide" to render the app full screen on a 16" display (spec 017), e.g. `settings-general-wide`.
    static var wide = false
    static let wideSize = CGSize(width: 1728, height: 1080)

    static func run(screen: String, output: String) -> Bool {
        var screen = screen
        if screen.hasSuffix("-dark") {
            screen = String(screen.dropLast(5))
            snapshotScheme = .dark
        }
        if screen.hasSuffix("-wide") {
            screen = String(screen.dropLast(5))
            wide = true
        }
        _ = NSApplication.shared
        Keychain.snapshotMode = true
        DisplayPrefs.shared.forceSolid = true // renders can't draw live blur (spec 014)
        if let art = artwork[screen] { return renderArtwork(art, output: output) }
        guard let entry = screens[screen] else {
            let names = (Array(screens.keys) + Array(artwork.keys)).sorted()
            print("Unknown screen '\(screen)'. Available: \(names.joined(separator: ", "))")
            return false
        }
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let hosting = NSHostingView(rootView: entry.view().environment(\.colorScheme, snapshotScheme))
        let entrySize = wide ? wideSize : entry.size
        let rect = NSRect(origin: .zero, size: entrySize)
        let window = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: snapshotScheme == .dark ? .darkAqua : .aqua)
        window.contentView = hosting
        window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000)) // off-screen
        window.orderFrontRegardless()
        // Let SwiftUI lay out and finish first-frame work.
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        hosting.layoutSubtreeIfNeeded()
        // Render the real layer tree (cacheDisplay redraws shapes and adds artifacts at stroke seams).
        let scale: CGFloat = 2
        let width = Int(entrySize.width * scale), height = Int(entrySize.height * scale)
        guard let layer = hosting.layer,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        context.scaleBy(x: scale, y: scale)
        if layer.isGeometryFlipped {
            context.translateBy(x: 0, y: entrySize.height)
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
