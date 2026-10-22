import Foundation

/// A conversation: the single pinned Talk chat, or a named agent. Stored as `chats/<id>.json`.
public struct Chat: Codable, Equatable, Identifiable, Sendable {
    /// Agents are stored as "clicky", their name before 1.0, so existing chat files keep loading.
    public enum Kind: String, Codable, Sendable { case talk, agent = "clicky" }

    public var id = UUID()
    public var kind: Kind = .agent
    public var title = ""
    public var createdAt = Date()
    public var updatedAt = Date()
    public var messages: [Message] = []
    public var memorySummary = ""
    // 005 agents and chats
    public var avatarColor: AvatarColor = .sky
    public var purpose = ""
    public var isUnread = false
    public var summarizedThroughID: UUID?
    public var agentSessionID: String?
    public var lastAgentUseAt: Date?
    // 009 agents
    public var alwaysAllowed: [String] = []
    public var folderName = ""

    public init(id: UUID = UUID(), kind: Kind, title: String, createdAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    public static func talk() -> Chat { Chat(kind: .talk, title: "Talk") }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = try c.decodeIfPresent(UUID.self, forKey: .id) else {
            throw DecodingError.keyNotFound(CodingKeys.id, .init(codingPath: [], debugDescription: "Chat without id"))
        }
        self.id = id
        kind = c.value(.kind, default: .agent)
        title = c.value(.title, default: "")
        createdAt = c.value(.createdAt, default: Date(timeIntervalSince1970: 0))
        updatedAt = c.value(.updatedAt, default: createdAt)
        messages = c.value(.messages, default: [])
        memorySummary = c.value(.memorySummary, default: "")
        avatarColor = c.value(.avatarColor, default: .sky)
        purpose = c.value(.purpose, default: "")
        isUnread = c.value(.isUnread, default: false)
        summarizedThroughID = c.value(.summarizedThroughID, default: nil)
        agentSessionID = c.value(.agentSessionID, default: nil)
        lastAgentUseAt = c.value(.lastAgentUseAt, default: nil)
        alwaysAllowed = c.value(.alwaysAllowed, default: [])
        folderName = c.value(.folderName, default: "")
    }

    /// Preview line for the sidebar: the latest non-empty message.
    public var preview: String {
        messages.last { !$0.text.isEmpty && $0.role != .system && $0.kind == .text }?.text ?? (purpose.isEmpty ? "" : purpose)
    }

    public mutating func append(_ message: Message) {
        messages.append(message)
        updatedAt = message.createdAt
    }
}
