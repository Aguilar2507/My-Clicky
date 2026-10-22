import AppKit
import SwiftUI
import MyClickyCore

/// Daily task ideas (spec 009 US6): the first time you use the Mac after 07:00 (at most every 20 h), Claude Code
/// (your Claude plan, never the API key) suggests 3 tasks from your Clickys' memories. They appear under the menu bar icon (spec 019).
@MainActor
final class SuggestionScheduler {
    let model: AppModel
    var onStart: (Suggestion) -> Void = { _ in }
    private var timer: Timer?
    private var lastActivity = Date.distantPast
    private var monitor: Any?
    private var isRunning = false
    private let panel = MorningPanel()

    init(model: AppModel) {
        self.model = model
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .keyDown]) { [weak self] _ in
            DispatchQueue.main.async { self?.lastActivity = Date() } // not assumeIsolated: see CompanionController.init
        }
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.check() }
        }
    }

    var todaysIdeas: [Suggestion] { SuggestionParser.current(model.settings.lastSuggestions) }

    private func check() {
        guard model.settings.suggestAgentTasks, Date().timeIntervalSince(lastActivity) < 120,
              SuggestionParser.isDue(last: model.settings.lastSuggestionsAt) else { return }
        Task { await run() }
    }

    /// Also used by the developer menu item "Run suggestions now".
    func run() async {
        guard !isRunning, let claude = ClaudeCodeLocator.find(model.settings) else { return }
        isRunning = true
        defer { isRunning = false }
        let context = model.clickys.prefix(12).map { chat in
            "- \(chat.title): \(chat.purpose.prefix(160)) \(chat.memorySummary.isEmpty ? "" : "Memory: \(chat.memorySummary.prefix(200))")"
        }.joined(separator: "\n")
        let prompt = """
        Suggest exactly 3 useful tasks the user's helpers ("Clickys") could do today, based on their jobs and memories below. \
        Reply with JSON only: [{"text": "one short sentence", "clicky": "exact Clicky name or null"}].
        Clickys:
        \(context.isEmpty ? "(none yet)" : context)
        """
        let output = await ClaudeCodeLocator.run(claude, ["-p", prompt, "--output-format", "json", "--max-turns", "1"])
        let text = ((try? JSONSerialization.jsonObject(with: Data(output.utf8))) as? [String: Any])?["result"] as? String ?? output
        let ideas = SuggestionParser.parse(text)
        guard !ideas.isEmpty else { return }
        model.settings.lastSuggestions = ideas
        model.settings.lastSuggestionsAt = Date()
        show()
    }

    func show() {
        let ideas = todaysIdeas
        guard !ideas.isEmpty else { return }
        panel.show(ideas: ideas, model: model) { [weak self] idea in self?.onStart(idea) }
    }
}

/// "☀️ 3 ideas for today" under the menu bar icon for 15 s, with Start buttons (spec 009 US6, see deviation note in tasks.md).
@MainActor
final class MorningPanel {
    private var window: NSPanel?
    private var hideWork: DispatchWorkItem?

    func show(ideas: [Suggestion], model: AppModel, start: @escaping (Suggestion) -> Void) {
        close()
        let icon = StatusItemController.anchorRect
        let screen = NSScreen.screens.first { $0.frame.intersects(icon) } ?? NSScreen.main ?? NSScreen.screens[0]
        let size = CGSize(width: 420, height: 64 + CGFloat(ideas.count) * 46)
        // Centered under the icon, kept on screen.
        let x = min(max(icon.midX - size.width / 2, screen.frame.minX + 8), screen.frame.maxX - size.width - 8)
        let panel = NSPanel(contentRect: CGRect(x: x, y: icon.minY - size.height - 6, width: size.width, height: size.height),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let view = MorningIdeasView(ideas: ideas) { [weak self] idea in
            self?.close()
            start(idea)
        } onClose: { [weak self] in self?.close() }
        panel.contentView = NSHostingView(rootView: view.environment(model))
        WindowSharing.apply(to: panel, model: model)
        panel.orderFrontRegardless()
        window = panel
        let work = DispatchWorkItem { [weak self] in self?.close() }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: work)
    }

    func close() {
        hideWork?.cancel()
        window?.orderOut(nil)
        window = nil
    }
}

struct MorningIdeasView: View {
    let ideas: [Suggestion]
    let onStart: (Suggestion) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("☀️  \(ideas.count) ideas for today").textStyle(.callout.weight(.bold)).foregroundStyle(.white)
                Spacer()
                Button(action: onClose) { Image(systemName: "xmark") }.buttonStyle(.pressable).foregroundStyle(Theme.icon)
            }
            ForEach(Array(ideas.enumerated()), id: \.offset) { _, idea in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(idea.text).textStyle(.footnote.weight(.medium)).foregroundStyle(.white).lineLimit(2)
                        if let clicky = idea.clickyTitle {
                            Text(clicky).textStyle(.caption2).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                    Button("Start") { onStart(idea) }.buttonStyle(.pill(.primary, compact: true))
                }
            }
        }
        .padding(14)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        // Black in both appearances, like a menu bar extra (spec 015).
        .environment(\.colorScheme, .dark)

    }
}
