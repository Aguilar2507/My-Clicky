import Foundation

/// One event from `claude -p --output-format stream-json --verbose` (spec 009, research R1). One JSON object per line.
public enum AgentEvent: Equatable, Sendable {
    case initialized(sessionID: String)
    case text(String)
    case toolUse(id: String, name: String, input: [String: String])
    case toolResult(id: String, isError: Bool, summary: String)
    case result(subtype: String, text: String, turns: Int, sessionID: String?, isError: Bool)
}

public enum AgentEventParser {
    /// Parses one line; an assistant/user line can hold several events. Unknown lines → [].
    public static func parse(line: String) -> [AgentEvent] {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return [] }
        switch type {
        case "system":
            guard json["subtype"] as? String == "init", let id = json["session_id"] as? String else { return [] }
            return [.initialized(sessionID: id)]
        case "assistant":
            let blocks = (json["message"] as? [String: Any])?["content"] as? [[String: Any]] ?? []
            return blocks.compactMap { block in
                switch block["type"] as? String {
                case "text":
                    let text = (block["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return text.isEmpty ? nil : .text(text)
                case "tool_use":
                    return .toolUse(id: block["id"] as? String ?? "", name: block["name"] as? String ?? "tool",
                                    input: flatten(block["input"] as? [String: Any] ?? [:]))
                default:
                    return nil
                }
            }
        case "user":
            let blocks = (json["message"] as? [String: Any])?["content"] as? [[String: Any]] ?? []
            return blocks.compactMap { block in
                guard block["type"] as? String == "tool_result" else { return nil }
                return .toolResult(id: block["tool_use_id"] as? String ?? "", isError: block["is_error"] as? Bool ?? false,
                                   summary: summarize(block["content"]))
            }
        case "result":
            return [.result(subtype: json["subtype"] as? String ?? "success",
                            text: (json["result"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                            turns: json["num_turns"] as? Int ?? 0,
                            sessionID: json["session_id"] as? String,
                            isError: json["is_error"] as? Bool ?? false)]
        default:
            return []
        }
    }

    /// Tool inputs as short strings (for descriptions); nested values become compact JSON.
    public static func flatten(_ input: [String: Any]) -> [String: String] {
        var out: [String: String] = [:]
        for (key, value) in input {
            if let string = value as? String { out[key] = string }
            else if let number = value as? NSNumber { out[key] = number.stringValue }
            else if let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
                    let text = String(data: data, encoding: .utf8) { out[key] = text }
        }
        return out
    }

    static func summarize(_ content: Any?) -> String {
        if let text = content as? String { return String(text.prefix(200)) }
        if let blocks = content as? [[String: Any]] {
            return String(blocks.compactMap { $0["text"] as? String }.joined(separator: " ").prefix(200))
        }
        return ""
    }
}

/// Up to 3 agents work at once; the rest wait their turn (spec 009 FR-003).
public struct RunQueue: Equatable, Sendable {
    public static let limit = 3
    public private(set) var running: [UUID] = []
    public private(set) var waiting: [UUID] = []

    public init() {}

    /// Returns true if the run can start now; otherwise it's queued.
    public mutating func request(_ id: UUID) -> Bool {
        if running.contains(id) || waiting.contains(id) { return running.contains(id) }
        if running.count < Self.limit {
            running.append(id)
            return true
        }
        waiting.append(id)
        return false
    }

    /// Marks a run finished; returns the next run to start, if any.
    public mutating func finish(_ id: UUID) -> UUID? {
        waiting.removeAll { $0 == id }
        guard running.contains(id) else { return nil }
        running.removeAll { $0 == id }
        guard !waiting.isEmpty else { return nil }
        let next = waiting.removeFirst()
        running.append(next)
        return next
    }

    /// Steps before a run pauses with "Keep going?" (spec 009 FR-008).
    public static func stepLimit(autoApprove: Bool) -> Int { autoApprove ? 150 : 40 }
}

/// A daily task idea (spec 009 US6).
public struct Suggestion: Codable, Equatable, Sendable {
    public var text: String
    public var agentTitle: String?
    public var createdAt: Date

    /// Saved in settings as "clickyTitle" (its name before 1.0), so existing ideas keep loading.
    enum CodingKeys: String, CodingKey { case text, agentTitle = "clickyTitle", createdAt }

    public init(text: String, agentTitle: String?, createdAt: Date) {
        self.text = text
        self.agentTitle = agentTitle
        self.createdAt = createdAt
    }
}

public enum SuggestionParser {
    /// Parses `[{"text": "...", "agent": "Name or null"}]` (possibly surrounded by prose); keeps at most 3.
    public static func parse(_ reply: String, now: Date = Date()) -> [Suggestion] {
        guard let start = reply.firstIndex(of: "["), let end = reply.lastIndex(of: "]"), start < end,
              let data = String(reply[start...end]).data(using: .utf8),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return items.compactMap { item -> Suggestion? in
            guard let text = (item["text"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
            let agent = (item["clicky"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            return Suggestion(text: text, agentTitle: agent, createdAt: now)
        }.prefix(3).map { $0 }
    }

    /// Suggestions only live until the end of the day they were made.
    public static func current(_ suggestions: [Suggestion], now: Date = Date(), calendar: Calendar = .current) -> [Suggestion] {
        suggestions.filter { calendar.isDate($0.createdAt, inSameDayAs: now) }
    }

    /// Time for new ideas? First activity after 07:00, at most once every 20 hours.
    public static func isDue(last: Date?, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard calendar.component(.hour, from: now) >= 7 else { return false }
        guard let last else { return true }
        return now.timeIntervalSince(last) > 20 * 3600
    }
}
