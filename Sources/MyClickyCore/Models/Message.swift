import Foundation

/// One entry in a chat. Text only: screenshots are never stored (Principle IV).
public struct Message: Codable, Equatable, Identifiable, Sendable {
    public enum Role: String, Codable, Sendable { case user, assistant, system }
    public enum Via: String, Codable, Sendable { case voice, typed, agent }

    public var id = UUID()
    public var role: Role
    public var text: String
    public var createdAt = Date()
    public var via: Via = .typed
    public var screensSeen = 0

    public init(id: UUID = UUID(), role: Role, text: String, createdAt: Date = Date(), via: Via = .typed, screensSeen: Int = 0) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.via = via
        self.screensSeen = screensSeen
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(.id, default: UUID())
        role = c.value(.role, default: .system)
        text = c.value(.text, default: "")
        createdAt = c.value(.createdAt, default: Date(timeIntervalSince1970: 0))
        via = c.value(.via, default: .typed)
        screensSeen = c.value(.screensSeen, default: 0)
    }
}
