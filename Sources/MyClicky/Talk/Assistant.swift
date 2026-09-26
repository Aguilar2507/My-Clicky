import AppKit
import MyClickyCore

/// Orchestrates listening → screenshot → Claude → speech/pointing, and agent tasks.
/// Every Talk exchange is saved in the pinned Talk chat (text only).
@MainActor
final class Assistant {
    enum State: Equatable {
        case idle, listening, thinking, speaking
    }

    let model: AppModel
    private let speech = SpeechRecognizer()
    private let speaker = Speaker()
    private let overlay = OverlayController()
    private let claude = ClaudeClient()
    let agent = AgentRunner()
    private var listenStart = Date()
    private var listenedByVoice = false
    private var currentRequest: Task<Void, Never>?

    private(set) var state: State = .idle {
        didSet { onChange?() }
    }
    var onChange: (() -> Void)?

    var settings: Settings { model.settings }

    init(model: AppModel) {
        self.model = model
        speaker.onFinish = { [weak self] in
            guard let self, self.state == .speaking else { return }
            self.state = .idle
            if !self.agent.isRunning { self.overlay.hideStatus() }
        }
    }

    // MARK: Voice

    func beginListening() {
        guard state != .listening else { return }
        currentRequest?.cancel()
        speaker.stop()
        overlay.hidePointer()
        do {
            try speech.start(locale: settings.locale)
            listenStart = Date()
            state = .listening
            overlay.showStatus("Listening…", style: .listening)
        } catch {
            state = .idle
            overlay.showStatus(error.localizedDescription, style: .info, autoHide: 4)
        }
    }

    func endListening() {
        guard state == .listening else { return }
        let tooShort = Date().timeIntervalSince(listenStart) < 0.3
        currentRequest = Task {
            let text = await speech.stop()
            if tooShort || text.isEmpty {
                state = .idle
                overlay.showStatus(tooShort ? "Hold the key while you talk" : "I didn't catch that", style: .info, autoHide: 1.5)
                return
            }
            await handle(text, via: .voice)
        }
    }

    /// Push-to-talk was interrupted by a regular key (e.g. fn+arrow): stop without asking anything.
    func cancelListening() {
        guard state == .listening else { return }
        speech.cancel()
        state = .idle
        overlay.hideStatus()
    }

    // MARK: Typed input

    func ask(typed text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        currentRequest?.cancel()
        speaker.stop()
        currentRequest = Task { await handle(text, via: .typed) }
    }

    func stopSpeaking() {
        speaker.stop()
        overlay.hidePointer()
        overlay.hideStatus()
        state = .idle
    }

    func clearHistory() {
        let talkID = model.talkChat.id
        model.updateChat(talkID) { $0.messages.removeAll(); $0.memorySummary = "" }
        agent.resetSession()
    }

    // MARK: Core

    private func handle(_ text: String, via: Message.Via) async {
        if let task = Router.agentTask(text) {
            startAgent(task)
            return
        }
        guard let apiKey = Keychain.apiKey() else {
            say("Please set your Anthropic API key first.")
            return
        }

        state = .thinking
        overlay.showStatus("“\(text)”", style: .thinking)

        let modelID = Router.wantsPointing(text) ? settings.pointingModel : settings.fastModel
        var screenshots: [Screenshot] = []
        if ScreenCapture.hasPermission {
            screenshots = (try? await ScreenCapture.captureAll()) ?? []
        }

        let talkID = model.talkChat.id
        let history = recentTurns(in: talkID)
        do {
            let reply = try await claude.ask(question: text, screenshots: screenshots, history: history,
                                             model: modelID, apiKey: apiKey)
            model.recordUsage(reply.usage) // billed even if the user interrupted
            let (spoken, point) = PointTag.parse(reply.text)
            model.append(Message(role: .user, text: text, via: via, screensSeen: screenshots.count), to: talkID)
            model.append(Message(role: .assistant, text: spoken.isEmpty ? "Look here." : spoken, via: via), to: talkID)
            guard !Task.isCancelled else { return }

            if let point, screenshots.indices.contains(point.screen - 1) {
                let shot = screenshots[point.screen - 1]
                overlay.point(at: shot.globalPoint(x: point.x, y: point.y), label: point.label)
            }
            say(spoken.isEmpty ? "Look here." : spoken)
        } catch {
            guard !Task.isCancelled else { return }
            say("Sorry, something went wrong. \(error.localizedDescription)")
        }
    }

    /// The last `maxHistoryTurns` question/answer pairs of a chat.
    private func recentTurns(in chatID: UUID) -> [ChatTurn] {
        guard let chat = model.chat(chatID) else { return [] }
        var turns: [ChatTurn] = []
        var pendingUser: String?
        for message in chat.messages {
            switch message.role {
            case .user: pendingUser = message.text
            case .assistant:
                if let user = pendingUser { turns.append(ChatTurn(user: user, assistant: message.text)) }
                pendingUser = nil
            case .system: break
            }
        }
        return Array(turns.suffix(settings.maxHistoryTurns))
    }

    private func say(_ text: String) {
        state = .speaking
        overlay.showStatus(text, style: .info)
        speaker.speak(text, settings: settings)
    }

    // MARK: Agent

    private func startAgent(_ task: String) {
        guard !agent.isRunning else {
            say("I'm still working on the last agent task.")
            return
        }
        say("On it. I'll tell you when it's done.")
        onChange?()
        Task {
            let result: AgentRunner.Result
            do {
                result = try await agent.run(task: task, settings: settings)
            } catch {
                result = .init(summary: error.localizedDescription, isError: true)
            }
            onChange?()
            // Don't talk over the user.
            while state == .listening || state == .thinking {
                try? await Task.sleep(for: .milliseconds(300))
            }
            say((result.isError ? "The agent ran into a problem. " : "Agent done. ") + result.summary)
        }
    }
}
