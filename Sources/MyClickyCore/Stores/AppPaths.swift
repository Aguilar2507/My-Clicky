import Foundation

/// Where MyClicky keeps its files (`~/Library/Application Support/MyClicky/`). Checks use a temporary base folder.
public struct AppPaths: Sendable {
    public let base: URL

    public init(base: URL) { self.base = base }

    public static var standard: AppPaths {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return AppPaths(base: support.appendingPathComponent("MyClicky", isDirectory: true))
    }

    public var settings: URL { base.appendingPathComponent("settings.json") }
    public var chats: URL { base.appendingPathComponent("chats", isDirectory: true) }
    public var usage: URL { base.appendingPathComponent("usage.json") }
    public var legacyConfig: URL { base.appendingPathComponent("config.json") }
    public var legacyBackup: URL { base.appendingPathComponent("config.v1.backup.json") }
    public var agentSocket: URL { base.appendingPathComponent("agent.sock") }
    public var mcpConfig: URL { base.appendingPathComponent("mcp.json") }

    public func chatFile(_ id: UUID) -> URL { chats.appendingPathComponent("\(id.uuidString).json") }
}
