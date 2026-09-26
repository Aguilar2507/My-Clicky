import AppKit
import MyClickyCore

/// Orchestrates listening → screenshot → Claude → speech/pointing, and Clicky agent tasks.
/// Screen questions are saved in the pinned Talk chat; "agent…" requests go to Clickys (spec 005, ChatRouter).
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
    private lazy var memory = MemoryManager(model: model)
    let agent = AgentRunner()
    private var listenStart = Date()
    private var currentRequest: Task<Void, Never>?

    private(set) var state: State = .idle {
        didSet {
            model.talkState = state
            onChange?()
        }
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

    /// The greeting screen's pill: click to start listening, click again to send.
    func toggleListening() {
        state == .listening ? endListening() : beginListening()
    }

    // MARK: Typed input

    /// Text mode and voice go through the router ("agent…" → Clickys, otherwise Talk).
    func ask(typed text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        currentRequest?.cancel()
        speaker.stop()
        currentRequest = Task { await handle(text, via: .typed) }
    }

    /// The composer sends straight to the open chat: Talk asks about the screen, a Clicky gets an instruction.
    func send(_ text: String, toChat chatID: UUID) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let chat = model.chat(chatID) else { return }
        if chat.kind == .talk {
            currentRequest?.cancel()
            speaker.stop()
            currentRequest = Task { await talk(text, via: .typed) }
        } else {
            startAgent(text, in: chatID, via: .typed)
        }
    }

    func stopSpeaking() {
        speaker.stop()
        overlay.hidePointer()
        overlay.hideStatus()
        state = .idle
    }

    // MARK: Routing

    private func handle(_ text: String, via: Message.Via) async {
        switch ChatRouter.route(text, clickys: model.clickyRefs) {
        case .talk(let question):
            await talk(question, via: via)
        case .clicky(let id, let task):
            startAgent(task, in: id, via: via)
        case .newClicky(let task):
            let id = model.createClicky(purpose: task)
            Task { await ClickyNamer.name(id, from: task, model: model) }
            startAgent(task, in: id, via: via)
        }
    }

    // MARK: Talk (screen questions)

    private func talk(_ text: String, via: Message.Via) async {
        guard let apiKey = Keychain.apiKey() else {
            say("Please set your Anthropic API key first, in Settings, General.")
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
        let window = ContextWindow(chat: model.talkChat)
        let history = window.recent.map { ChatTurn(user: $0.user.text, assistant: $0.assistant.text) }
        model.append(Message(role: .user, text: text, via: via, screensSeen: screenshots.count), to: talkID)
        do {
            let reply = try await claude.ask(question: text, screenshots: screenshots, history: history,
                                             memory: window.summary, model: modelID, apiKey: apiKey)
            model.recordUsage(reply.usage) // billed even if the user interrupted
            let (spoken, point) = PointTag.parse(reply.text)
            let answer = spoken.isEmpty ? "Look here." : spoken
            model.appendReply(Message(role: .assistant, text: answer, via: via), to: talkID)
            guard !Task.isCancelled else { return }

            if let point, screenshots.indices.contains(point.screen - 1) {
                let shot = screenshots[point.screen - 1]
                overlay.point(at: shot.globalPoint(x: point.x, y: point.y), label: point.label)
            }
            say(answer)
            await memory.foldIfNeeded(talkID)
        } catch {
            guard !Task.isCancelled else { return }
            say("Sorry, something went wrong. \(error.localizedDescription)")
        }
    }

    private func say(_ text: String) {
        state = .speaking
        overlay.showStatus(text, style: .info)
        speaker.speak(text, settings: settings)
    }

    // MARK: Clickys (agents; replaced by AgentSupervisor in spec 009)

    private func startAgent(_ task: String, in chatID: UUID, via: Message.Via) {
        model.append(Message(role: .user, text: task, via: via), to: chatID)
        guard !agent.isRunning else {
            model.appendReply(Message(role: .system, text: "Waiting: another Clicky is still working. Try again when it finishes."),
                              to: chatID)
            say("I'm still working on the last agent task.")
            return
        }
        let name = model.chat(chatID)?.title ?? "Your Clicky"
        say("\(name) is on it.")
        model.isAgentRunning = true
        model.workingChatIDs.insert(chatID)
        onChange?()
        let sessionID = model.chat(chatID)?.agentSessionID
        Task {
            let result: AgentRunner.Result
            do {
                result = try await agent.run(task: task, settings: settings, sessionID: sessionID)
            } catch {
                result = .init(summary: error.localizedDescription, isError: true)
            }
            model.isAgentRunning = false
            model.workingChatIDs.remove(chatID)
            model.updateChat(chatID) {
                $0.lastAgentUseAt = Date()
                if let id = result.sessionID { $0.agentSessionID = id }
            }
            model.appendReply(Message(role: .assistant, text: result.summary, via: .agent), to: chatID)
            onChange?()
            // Don't talk over the user.
            while state == .listening || state == .thinking {
                try? await Task.sleep(for: .milliseconds(300))
            }
            let latestName = model.chat(chatID)?.title ?? name
            say((result.isError ? "\(latestName) ran into a problem. " : "\(latestName) finished. ") + result.summary)
        }
    }
}
