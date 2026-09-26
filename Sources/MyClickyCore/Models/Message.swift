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
    // 009 agents: steps, Allow cards and notices live in the chat too.
    public enum Kind: String, Codable, Sendable { case text, step, approval, notice }
    public var kind: Kind = .text
    /// step: tool name · approval: tool name
    public var toolName: String?
    /// step/approval: the command, path or URL involved
    public var detail: String?
    /// step: running/done/failed · approval: pending/allowed/alwaysAllowed/denied/expired · notice: keepGoing/stopped/failed/queued
    public var status: String?
    /// step: tool_use id · approval: request id
    public var refID: String?

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
        kind = c.value(.kind, default: .text)
        toolName = c.value(.toolName, default: nil)
        detail = c.value(.detail, default: nil)
        status = c.value(.status, default: nil)
        refID = c.value(.refID, default: nil)
    }
}
