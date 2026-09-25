import Foundation

/// A conversation: the single pinned Talk chat, or a named Clicky. Stored as `chats/<id>.json`.
public struct Chat: Codable, Equatable, Identifiable, Sendable {
    public enum Kind: String, Codable, Sendable { case talk, clicky }

    public var id = UUID()
    public var kind: Kind = .clicky
    public var title = ""
    public var createdAt = Date()
    public var updatedAt = Date()
    public var messages: [Message] = []
    public var memorySummary = ""

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
        kind = c.value(.kind, default: .clicky)
        title = c.value(.title, default: "")
        createdAt = c.value(.createdAt, default: Date(timeIntervalSince1970: 0))
        updatedAt = c.value(.updatedAt, default: createdAt)
        messages = c.value(.messages, default: [])
        memorySummary = c.value(.memorySummary, default: "")
    }

    public mutating func append(_ message: Message) {
        messages.append(message)
        updatedAt = message.createdAt
    }
}
