import Foundation

/// A connector agents can use (spec 010 data model): from the bundled catalog or added by the user.
public struct Integration: Codable, Equatable, Identifiable, Sendable {
    public enum Transport: String, Codable, Sendable { case http, sse, stdio }

    public var id: String
    public var name: String
    public var description: String
    public var transport: Transport
    public var url: String?
    public var command: [String]?
    public var icon: String
    public var isCustom: Bool

    public init(id: String, name: String, description: String, transport: Transport, url: String? = nil,
                command: [String]? = nil, icon: String = "", isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.transport = transport
        self.url = url
        self.command = command
        self.icon = icon.isEmpty ? "letter:\(name.prefix(1).uppercased())" : icon
        self.isCustom = isCustom
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = c.value(.name, default: id)
        description = c.value(.description, default: "")
        transport = c.value(.transport, default: .http)
        url = c.value(.url, default: nil)
        command = c.value(.command, default: nil)
        icon = c.value(.icon, default: "letter:\(name.prefix(1).uppercased())")
        isCustom = c.value(.isCustom, default: false)
    }

    /// The Claude Code server name MyClicky manages ("myclicky-github").
    public var serverName: String { "myclicky-\(id)" }

    /// Arguments for `claude mcp add` (user scope, so every Clicky can use it).
    public var addArguments: [String] {
        switch transport {
        case .http, .sse: return ["mcp", "add", "--transport", transport.rawValue, "-s", "user", serverName, url ?? ""]
        case .stdio: return ["mcp", "add", "-s", "user", serverName, "--"] + (command ?? [])
        }
    }

    public static func loadCatalog(from data: Data) -> [Integration] {
        (try? JSONFile.decoder.decode([Integration].self, from: data)) ?? []
    }
}

/// Status of a connector as Claude Code reports it.
public enum ConnectionStatus: Equatable, Sendable {
    case notAdded, checking, connected, needsAuth, failed(String)
}

/// Parses `claude mcp list` (spec 010 research R1): "name: target (transport) - ✓ Connected".
public enum MCPListParser {
    public struct Entry: Equatable, Sendable {
        public let name: String
        public let target: String
        public let status: ConnectionStatus

        public init(name: String, target: String, status: ConnectionStatus) {
            self.name = name
            self.target = target
            self.status = status
        }
    }

    public static func parse(_ output: String) -> [Entry] {
        output.split(whereSeparator: \.isNewline).compactMap { raw in
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard let colon = line.firstIndex(of: ":"), let dash = line.range(of: " - ", options: .backwards) else { return nil }
            let name = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            guard !name.contains(" "), !name.isEmpty else { return nil }
            let target = String(line[line.index(after: colon)..<dash.lowerBound]).trimmingCharacters(in: .whitespaces)
            let statusText = String(line[dash.upperBound...]).trimmingCharacters(in: .whitespaces)
            return Entry(name: name, target: target, status: status(statusText))
        }
    }

    static func status(_ text: String) -> ConnectionStatus {
        let lower = text.lowercased()
        if lower.contains("connected") && !lower.contains("failed") && !lower.contains("not connected") { return .connected }
        if lower.contains("auth") { return .needsAuth }
        return .failed(text.trimmingCharacters(in: CharacterSet(charactersIn: "✓✗⚠ ")))
    }

    /// MyClicky's own connectors (by id) and everything else ("managed in Claude Code").
    public static func split(_ entries: [Entry]) -> (ours: [String: ConnectionStatus], others: [Entry]) {
        var ours: [String: ConnectionStatus] = [:]
        var others: [Entry] = []
        for entry in entries {
            if entry.name.hasPrefix("myclicky-") { ours[String(entry.name.dropFirst("myclicky-".count))] = entry.status }
            else if entry.name != "myclicky" { others.append(entry) }
        }
        return (ours, others)
    }
}

/// Search and validation for the Integrations page.
public enum IntegrationFilter {
    public static func filter(_ items: [Integration], query: String) -> [Integration] {
        let q = SearchIndex.fold(query.trimmingCharacters(in: .whitespaces))
        guard !q.isEmpty else { return items }
        return items.filter { SearchIndex.fold($0.name).contains(q) || SearchIndex.fold($0.description).contains(q) }
    }

    public enum ValidationError: Error, Equatable { case emptyName, nameTaken, badURL, emptyCommand }

    /// Makes a custom connector from the sheet's fields (the command's existence is checked by the app).
    public static func custom(name: String, url: String?, command: String?, existing: [Integration]) -> Result<Integration, ValidationError> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyName) }
        let id = trimmed.lowercased().map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
            .split(separator: "-").joined(separator: "-")
        guard !id.isEmpty, !existing.contains(where: { $0.id == id || SearchIndex.fold($0.name) == SearchIndex.fold(trimmed) }) else {
            return .failure(.nameTaken)
        }
        if let url {
            guard let parsed = URL(string: url.trimmingCharacters(in: .whitespaces)), parsed.scheme == "https", parsed.host != nil else {
                return .failure(.badURL)
            }
            return .success(Integration(id: id, name: trimmed, description: parsed.host ?? "", transport: .http,
                                        url: parsed.absoluteString, isCustom: true))
        }
        let parts = (command ?? "").split(separator: " ").map(String.init)
        guard !parts.isEmpty else { return .failure(.emptyCommand) }
        return .success(Integration(id: id, name: trimmed, description: parts.joined(separator: " "), transport: .stdio,
                                    command: parts, isCustom: true))
    }
}
