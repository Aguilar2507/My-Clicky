import Foundation
import MyClickyCore

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

    struct Reply {
        let text: String
        let usage: TokenUsage
    }

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    // MARK: Talk (screen questions)

    /// Request body for a screen question: system prompt (+ memory), recent exchanges, screenshots, the question.
    func talkBody(question: String, screenshots: [Screenshot], history: [ChatTurn], memory: String,
                  model: String) -> [String: Any] {
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

        var system = Prompts.assistant
        if !memory.isEmpty {
            system += "\n\nWhat you remember about this user and conversation:\n\(memory)"
        }
        var body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": [["type": "text", "text": system, "cache_control": ["type": "ephemeral"]]],
            "messages": messages,
        ]
        if !model.contains("haiku") {
            body["output_config"] = ["effort": "low"] // voice answers: favor speed
        }
        return body
    }

    func ask(question: String, screenshots: [Screenshot], history: [ChatTurn], memory: String = "",
             model: String, apiKey: String) async throws -> Reply {
        try await send(talkBody(question: question, screenshots: screenshots, history: history, memory: memory, model: model),
                       model: model, apiKey: apiKey)
    }

    // MARK: Small text requests (memory summaries, naming Clickys)

    func complete(system: String, user: String, model: String, maxTokens: Int = 300, apiKey: String) async throws -> Reply {
        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [["role": "user", "content": user]],
        ]
        return try await send(body, model: model, apiKey: apiKey)
    }

    // MARK: Transport

    func request(_ body: [String: Any], apiKey: String) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func send(_ body: [String: Any], model: String, apiKey: String) async throws -> Reply {
        let (data, response) = try await URLSession.shared.data(for: request(body, apiKey: apiKey))
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200, let json else {
            let error = json?["error"] as? [String: Any]
            throw APIError(message: (error?["message"] as? String) ?? "Claude API returned status \(status).")
        }
        let usageJSON = json["usage"] as? [String: Any] ?? [:]
        func tokens(_ key: String) -> Int { usageJSON[key] as? Int ?? 0 }
        let usage = TokenUsage(model: model,
                               inputTokens: tokens("input_tokens"),
                               outputTokens: tokens("output_tokens"),
                               cacheWriteTokens: tokens("cache_creation_input_tokens"),
                               cacheReadTokens: tokens("cache_read_input_tokens"))

        if json["stop_reason"] as? String == "refusal" {
            return Reply(text: "Sorry, I can't help with that one.", usage: usage)
        }
        let blocks = json["content"] as? [[String: Any]] ?? []
        let text = blocks.compactMap { $0["type"] as? String == "text" ? $0["text"] as? String : nil }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Reply(text: text, usage: usage)
    }
}
