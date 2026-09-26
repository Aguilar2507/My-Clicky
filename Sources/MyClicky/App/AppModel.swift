import Foundation
import SwiftUI
import Observation
import MyClickyCore

/// The app's single source of truth: settings, chats and stores. Views read it; services update it.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    let paths: AppPaths
    @ObservationIgnored let settingsStore: SettingsStore
    @ObservationIgnored let chatStore: ChatStore
    @ObservationIgnored let usageStore: UsageStore

    var settings: Settings {
        didSet { if settings != oldValue { settingsStore.save(settings) } }
    }

    /// All chats, including the single Talk chat (created on first use).
    var chats: [Chat] = []
    /// Chat files that couldn't be read at launch (renamed `.damaged`).
    var damagedChatFiles: [URL] = []

    init(paths: AppPaths = .standard) {
        self.paths = paths
        settingsStore = SettingsStore(paths: paths)
        chatStore = ChatStore(paths: paths)
        usageStore = UsageStore(paths: paths)
        settings = settingsStore.load()
        let loaded = chatStore.loadAll()
        chats = loaded.chats
        damagedChatFiles = loaded.setAside
        _ = talkChat // Talk is always pinned at the top (spec 005)
    }

    // MARK: Chats

    var talkChat: Chat {
        if let talk = chats.first(where: { $0.kind == .talk }) { return talk }
        let talk = Chat.talk()
        chats.append(talk)
        chatStore.save(talk)
        return talk
    }

    func chat(_ id: UUID) -> Chat? { chats.first { $0.id == id } }

    /// Talk without creating it (for lists).
    var talkChatIfExists: Chat? { chats.first { $0.kind == .talk } }

    /// Clickys with an agent task running right now (spec 009 fills this for real; 005 sets it around each run).
    var workingChatIDs: Set<UUID> = []

    /// Applies a change to a chat and saves it (debounced).
    func updateChat(_ id: UUID, _ change: (inout Chat) -> Void) {
        guard let index = chats.firstIndex(where: { $0.id == id }) else { return }
        change(&chats[index])
        chatStore.save(chats[index])
    }

    func append(_ message: Message, to id: UUID) {
        updateChat(id) { $0.append(message) }
    }

    // MARK: Clickys (spec 005)

    /// The chat open on the right side (nil = greeting screen).
    var selectedChatID: UUID?
    /// True while the pop-out window is open.
    var isWindowOpen = false

    /// The chat the user can currently see, if any (for unread dots).
    var visibleChatID: UUID? {
        guard isNotchOpen || isWindowOpen, route == .home else { return nil }
        return selectedChatID
    }

    /// Clickys, newest activity first (Talk is pinned separately).
    var clickys: [Chat] {
        chats.filter { $0.kind == .clicky }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var clickyRefs: [ChatRouter.ClickyRef] {
        clickys.map { ChatRouter.ClickyRef(id: $0.id, title: $0.title, lastAgentUseAt: $0.lastAgentUseAt) }
    }

    /// Adds a reply to a chat and marks it unread if the user isn't looking at it.
    func appendReply(_ message: Message, to id: UUID) {
        let unseen = visibleChatID != id
        updateChat(id) {
            $0.append(message)
            if unseen && $0.kind == .clicky { $0.isUnread = true }
        }
    }

    func select(_ id: UUID?) {
        // Drop a "+" draft the user left without writing anything.
        if let previous = selectedChatID, previous != id, let draft = chat(previous),
           draft.kind == .clicky, draft.messages.isEmpty, draft.purpose.isEmpty {
            deleteChat(previous)
        }
        selectedChatID = id
        if let id { markRead(id) }
    }

    func markRead(_ id: UUID) {
        if chat(id)?.isUnread == true { updateChat(id) { $0.isUnread = false } }
    }

    /// A new, empty Clicky (named after its first message).
    @discardableResult
    func createClicky(purpose: String = "") -> UUID {
        var clicky = Chat(kind: .clicky, title: NamingParser.fallbackName(existing: chats.map(\.title)))
        clicky.avatarColor = AvatarColor.next(avoiding: clickys.map(\.avatarColor))
        clicky.purpose = purpose
        chats.append(clicky)
        chatStore.save(clicky)
        return clicky.id
    }

    func rename(_ id: UUID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let others = chats.filter { $0.id != id }.map(\.title)
        updateChat(id) { $0.title = NamingParser.unique(trimmed, existing: others) }
    }

    func recolor(_ id: UUID, to color: AvatarColor) {
        updateChat(id) { $0.avatarColor = color }
    }

    func deleteChat(_ id: UUID) {
        guard chat(id)?.kind == .clicky else { return } // Talk can only be cleared
        chats.removeAll { $0.id == id }
        chatStore.delete(id: id)
        if selectedChatID == id { selectedChatID = nil }
    }

    func clearTalk() {
        updateChat(talkChat.id) {
            $0.messages.removeAll()
            $0.memorySummary = ""
            $0.summarizedThroughID = nil
        }
    }

    // MARK: Navigation

    /// What the notch panel / window shows. Settings' Back returns to `previousRoute`.
    var route: HomeRoute = .home
    @ObservationIgnored var previousRoute: HomeRoute = .home

    func openSettings(_ page: SettingsPage = .general) {
        if case .settings = route {} else { previousRoute = route }
        route = .settings(page)
    }

    func closeSettings() { route = previousRoute }

    // MARK: Notch status

    /// Clickys with something new (blue dot); drives the notch badge. Filled in by spec 005.
    var unreadCount: Int { previewUnreadCount ?? chats.filter { $0.kind == .clicky && $0.isUnread }.count }
    /// Snapshot/preview override for the badge.
    var previewUnreadCount: Int?
    /// Mirrors the talk flow (listening, thinking, speaking) for views like the greeting pill.
    var talkState: Assistant.State = .idle
    /// Why MyClicky is keeping quiet right now (spec 007 US4), from QuietMonitor.
    var quietReasons: Set<QuietPolicy.Reason> = []
    var isQuiet: Bool { QuietPolicy.isQuiet(reasons: quietReasons, override: settings.quietOverride) }
    /// True while dictation records (spec 008), so the mic isn't mistaken for a call.
    var isDictating = false
    /// True while any agent task runs (notch activity indicator).
    var isAgentRunning = false
    /// True while the notch panel is open (the companion hides over it).
    var isNotchOpen = false {
        didSet { if isNotchOpen, let id = visibleChatID { markRead(id) } }
    }
    /// Color of the companion when docked in the notch (spec 006); nil = not docked.
    var dockedCompanionColor: Color? { settings.cursorDocked ? Color(hex: settings.cursorColor.hex) : nil }

    // MARK: Usage

    func recordUsage(_ usage: TokenUsage, countsAsQuestion: Bool = true) {
        usageStore.record(usage, countsAsQuestion: countsAsQuestion)
        usageRevision += 1
    }

    /// Bumped on every recorded usage so views showing spend refresh.
    var usageRevision = 0

    var thisMonth: UsageMonth {
        _ = usageRevision
        return usageStore.month()
    }

    // MARK: Lifecycle

    func flush() {
        settingsStore.flush()
        chatStore.flush()
    }
}

