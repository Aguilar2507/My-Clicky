import Foundation

struct ChatTurn {
    let user: String
    let assistant: String
}

/// Minimal Anthropic Messages API client (raw HTTPS — there is no official Swift SDK).
struct ClaudeClient {
    struct APIError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    func ask(question: String, screenshots: [Screenshot], history: [ChatTurn],
             model: String, apiKey: String) async throws -> String {
        var messages: [[String: Any]] = []
        for turn in history {
            messages.append(["role": "user", "content": turn.user])
            messages.append(["role": "assistant", "content": turn.assistant])
        }
        // Cache breakpoint at the end of the stable history, so only the new turn is billed at full price.
        if var last = messages.last, let text = last["content"] as? String {
            last["content"] = [["type": "text", "text": text, "cache_control": ["type": "ephemeral"]]]
            messages[messages.count - 1] = last
        }

        var content: [[String: Any]] = []
        for (index, shot) in screenshots.enumerated() {
            let cursorNote = shot.containsMouse ? ", the user's mouse cursor is on this screen" : ""
            content.append(["type": "text",
                            "text": "Screen \(index + 1) of \(screenshots.count) (\(shot.pixelWidth)x\(shot.pixelHeight) pixels\(cursorNote)):"])
            content.append(["type": "image",
                            "source": ["type": "base64", "media_type": "image/jpeg",
                                       "data": shot.jpeg.base64EncodedString()]])
        }
        if screenshots.isEmpty {
            content.append(["type": "text", "text": "(No screenshot available — screen recording permission may be missing.)"])
        }
        content.append(["type": "text", "text": question])
        messages.append(["role": "user", "content": content])

        var body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": [["type": "text", "text": Prompts.assistant, "cache_control": ["type": "ephemeral"]]],
            "messages": messages,
        ]
        if !model.contains("haiku") {
            body["output_config"] = ["effort": "low"] // voice answers: favor speed
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200, let json else {
            let error = json?["error"] as? [String: Any]
            throw APIError(message: (error?["message"] as? String) ?? "Claude API returned status \(status).")
        }
        if json["stop_reason"] as? String == "refusal" {
            return "Sorry, I can't help with that one."
        }
        let blocks = json["content"] as? [[String: Any]] ?? []
        return blocks.compactMap { $0["type"] as? String == "text" ? $0["text"] as? String : nil }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Extracts the optional `[POINT:x,y:label:screen N]` tag from a reply.
struct PointTag {
    let x: Double
    let y: Double
    let label: String
    let screen: Int

    static let regex = try! NSRegularExpression(
        pattern: #"\[POINT:\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*(?::\s*([^\]]*?))?\s*(?::\s*screen\s*(\d+))?\s*\]"#,
        options: [.caseInsensitive])

    /// Returns the spoken text (tag removed) and the tag, if any.
    static func parse(_ reply: String) -> (spoken: String, point: PointTag?) {
        let range = NSRange(reply.startIndex..., in: reply)
        guard let match = regex.firstMatch(in: reply, range: range) else { return (reply, nil) }
        func group(_ i: Int) -> String? {
            Range(match.range(at: i), in: reply).map { String(reply[$0]) }
        }
        let spoken = regex.stringByReplacingMatches(in: reply, range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let point = PointTag(
            x: Double(group(1) ?? "") ?? 0,
            y: Double(group(2) ?? "") ?? 0,
            label: group(3)?.trimmingCharacters(in: .whitespaces) ?? "",
            screen: Int(group(4) ?? "") ?? 1)
        return (spoken, point)
    }
}
