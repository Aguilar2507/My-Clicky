import Foundation
import MyClickyCore

/// Folds old exchanges into a chat's short memory summary (spec 005 US6, contracts/prompts.md). Haiku, text only.
@MainActor
final class MemoryManager {
    let model: AppModel
    private let claude = ClaudeClient()
    private var running: Set<UUID> = []

    init(model: AppModel) { self.model = model }

    static let system = """
    You maintain a short memory of a conversation between a user and their Mac assistant. Merge the existing \
    memory with the new exchanges. Keep facts, names, preferences, decisions and open tasks. Drop small talk. \
    At most 120 words, plain text, same language as the user.
    """

    /// Runs after an answer has been spoken, never before one.
    func foldIfNeeded(_ chatID: UUID) async {
        guard !running.contains(chatID), let chat = model.chat(chatID), let apiKey = Keychain.apiKey(),
              PaidRequestGate.allowsBackground(model) else { return }
        let window = ContextWindow(chat: chat)
        guard let last = window.toFold.last else { return }
        running.insert(chatID)
        defer { running.remove(chatID) }

        let exchanges = window.toFold.map { "User: \($0.user.text)\nAssistant: \($0.assistant.text)" }.joined(separator: "\n")
        let user = "Existing memory:\n\(window.summary.isEmpty ? "(none)" : window.summary)\n\nNew exchanges:\n\(exchanges)"
        do {
            let reply = try await claude.complete(system: Self.system, user: user, model: model.settings.fastModel,
                                                  maxTokens: 300, apiKey: apiKey)
            model.recordUsage(reply.usage, kind: .memory)
            guard !reply.text.isEmpty else { return }
            model.updateChat(chatID) {
                $0.memorySummary = reply.text
                $0.summarizedThroughID = last.assistant.id
            }
        } catch {
            // Try again after the next answer; nothing is lost (messages stay in the chat).
        }
    }
}

/// Names and colors a new agent from its first instruction (spec 005 US4, contracts/prompts.md).
@MainActor
enum AgentNamer {
    static let system = """
    Name a helper based on its job (the user's message is the job description; don't do the job). Reply with JSON only: {"name": 1-3 words, Title Case, playful but clear, \
    like "Research Buddy" or "Signal Radar"; "color": one of peach, sky, butter, lilac, pink, mint, coral, slate}.
    """

    static func name(_ chatID: UUID, from instruction: String, model: AppModel) async {
        guard let apiKey = Keychain.apiKey(), PaidRequestGate.allowsBackground(model) else { return } // keeps "New agent N"
        do {
            let reply = try await ClaudeClient().complete(system: system, user: instruction, model: model.settings.fastModel,
                                                          maxTokens: 60, prefill: "{", apiKey: apiKey)
            model.recordUsage(reply.usage, kind: .naming)
            guard let parsed = NamingParser.parse(reply.text) else {
                Log.events.notice("naming unparsed chars=\(reply.text.count, privacy: .public)")
                return
            }
            Log.events.notice("naming ok words=\(parsed.name.split(separator: " ").count, privacy: .public)")
            model.rename(chatID, to: parsed.name)
            if let color = parsed.color { model.recolor(chatID, to: color) }
        } catch {
            Log.events.notice("naming failed \(String(describing: type(of: error)), privacy: .public)") // keeps the fallback name
        }
    }
}
