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

    /// Applies a change to a chat and saves it (debounced).
    func updateChat(_ id: UUID, _ change: (inout Chat) -> Void) {
        guard let index = chats.firstIndex(where: { $0.id == id }) else { return }
        change(&chats[index])
        chatStore.save(chats[index])
    }

    func append(_ message: Message, to id: UUID) {
        updateChat(id) { $0.append(message) }
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
    var unreadCount: Int { previewUnreadCount ?? 0 }
    /// Snapshot/preview override for the badge.
    var previewUnreadCount: Int?
    /// True while any agent task runs (notch activity indicator).
    var isAgentRunning = false
    /// True while the notch panel is open (the companion hides over it).
    var isNotchOpen = false
    /// Color of the companion when docked in the notch (spec 006); nil = not docked.
    var dockedCompanionColor: Color? { nil }

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

extension Settings {
    /// Speech recognition / voice language. Empty = system language.
    var locale: Locale { speechLocale.isEmpty ? Locale.current : Locale(identifier: speechLocale) }
}
