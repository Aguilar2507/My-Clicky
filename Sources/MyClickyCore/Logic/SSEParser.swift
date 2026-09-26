import Foundation

/// Events from the Anthropic Messages streaming API (spec 007, research R1).
public enum MessageStreamEvent: Equatable, Sendable {
    case start(inputTokens: Int, cacheReadTokens: Int, cacheWriteTokens: Int)
    case textDelta(String)
    case stop(reason: String?, outputTokens: Int)
    case error(type: String, message: String)
    case ping
}

/// Turns server-sent-event lines into stream events. Feed it one line at a time (without the newline).
/// Only `data:` lines matter: each carries a JSON object with a `type`.
public struct SSEParser: Sendable {
    public init() {}

    public func parse(line: String) -> MessageStreamEvent? {
        guard line.hasPrefix("data:") else { return nil }
        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return nil }
        func int(_ dict: [String: Any]?, _ key: String) -> Int { dict?[key] as? Int ?? 0 }
        switch type {
        case "message_start":
            let usage = (json["message"] as? [String: Any])?["usage"] as? [String: Any]
            return .start(inputTokens: int(usage, "input_tokens"), cacheReadTokens: int(usage, "cache_read_input_tokens"),
                          cacheWriteTokens: int(usage, "cache_creation_input_tokens"))
        case "content_block_delta":
            guard let delta = json["delta"] as? [String: Any], delta["type"] as? String == "text_delta",
                  let text = delta["text"] as? String else { return nil }
            return .textDelta(text)
        case "message_delta":
            let delta = json["delta"] as? [String: Any]
            return .stop(reason: delta?["stop_reason"] as? String, outputTokens: int(json["usage"] as? [String: Any], "output_tokens"))
        case "error":
            let error = json["error"] as? [String: Any]
            return .error(type: error?["type"] as? String ?? "error", message: error?["message"] as? String ?? "Unknown error")
        case "ping":
            return .ping
        default:
            return nil // message_stop, content_block_start/stop, future events
        }
    }
}
