import AppKit

/// Orchestrates listening → screenshot → Claude → speech/pointing, and agent tasks.
@MainActor
final class Assistant {
    enum State: Equatable {
        case idle, listening, thinking, speaking
    }

    private(set) var config = Config.load()
    private let speech = SpeechRecognizer()
    private let speaker = Speaker()
    private let overlay = OverlayController()
    private let claude = ClaudeClient()
    let agent = AgentRunner()
    private var history: [ChatTurn] = []
    private var listenStart = Date()
    private var currentRequest: Task<Void, Never>?

    private(set) var state: State = .idle {
        didSet { onChange?() }
    }
    var onChange: (() -> Void)?

    init() {
        speaker.onFinish = { [weak self] in
            guard let self, self.state == .speaking else { return }
            self.state = .idle
            if !self.agent.isRunning { self.overlay.hideStatus() }
        }
    }

    func reloadConfig() { config = Config.load() }

    // MARK: Voice

    func beginListening() {
        guard state != .listening else { return }
        currentRequest?.cancel()
        speaker.stop()
        overlay.hidePointer()
        do {
            try speech.start(locale: config.locale)
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
                overlay.showStatus(tooShort ? "Hold ⌃⌥ while you talk" : "I didn't catch that", style: .info, autoHide: 1.5)
                return
            }
            await handle(text)
        }
    }

    // MARK: Typed input

    func ask(typed text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        currentRequest?.cancel()
        speaker.stop()
        currentRequest = Task { await handle(text) }
    }

    func stopSpeaking() {
        speaker.stop()
        overlay.hidePointer()
        overlay.hideStatus()
        state = .idle
    }

    func clearHistory() {
        history.removeAll()
        agent.resetSession()
    }

    // MARK: Core

    private func handle(_ text: String) async {
        if let task = Router.agentTask(text) {
            startAgent(task)
            return
        }
        guard let apiKey = Keychain.apiKey() else {
            say("Please set your Anthropic API key first, from the menu bar icon.")
            return
        }

        state = .thinking
        overlay.showStatus("“\(text)”", style: .thinking)

        let model = Router.wantsPointing(text) ? config.pointingModel : config.fastModel
        var screenshots: [Screenshot] = []
        if ScreenCapture.hasPermission {
            screenshots = (try? await ScreenCapture.captureAll()) ?? []
        }

        do {
            let reply = try await claude.ask(question: text, screenshots: screenshots, history: history,
                                             model: model, apiKey: apiKey)
            guard !Task.isCancelled else { return }
            let (spoken, point) = PointTag.parse(reply)
            remember(ChatTurn(user: text, assistant: spoken))

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

    private func remember(_ turn: ChatTurn) {
        history.append(turn)
        if history.count > config.maxHistoryTurns {
            history.removeFirst(history.count - config.maxHistoryTurns)
        }
    }

    private func say(_ text: String) {
        state = .speaking
        overlay.showStatus(text, style: .info)
        speaker.speak(text, config: config)
    }

    // MARK: Agent

    private func startAgent(_ task: String) {
        guard !agent.isRunning else {
            say("I'm still working on the last agent task. You can stop it from the menu bar.")
            return
        }
        say("On it. I'll tell you when it's done.")
        onChange?()
        Task {
            let result: AgentRunner.Result
            do {
                result = try await agent.run(task: task, config: config)
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
