import AppKit
import MyClickyCore

/// Text received so far while an answer streams in.
@MainActor
private final class StreamState {
    var raw = ""
    var emitted = ""
    var splitter = SentenceSplitter()
    private var shownText = ""

    func shown(adding sentence: String) -> String {
        shownText += (shownText.isEmpty ? "" : " ") + sentence
        return shownText
    }
}

/// Orchestrates listening → screenshot → Claude → speech/pointing, and Clicky agent tasks.
/// Screen questions are saved in the pinned Talk chat; "agent…" requests go to Clickys (spec 005, ChatRouter).
@MainActor
final class Assistant {
    enum State: Equatable {
        case idle, listening, thinking, speaking
    }

    let model: AppModel
    private let speech = SpeechRecognizer()
    private let voice = SpeechQueue()
    private let quietChip = QuietPlayChip()
    let companion: CompanionController
    private let claude = ClaudeClient()
    private lazy var memory = MemoryManager(model: model)
    /// Set by AppDelegate: runs Clicky tasks (spec 009).
    weak var agents: AgentSupervisor?
    /// While announcing with its own bubble, the speech doesn't overwrite it.
    private var bubbleFollowsSpeech = true
    private var listenStart = Date()
    private var currentRequest: Task<Void, Never>?
    private var spokenSoFar = ""

    private(set) var state: State = .idle {
        didSet {
            model.talkState = state
            onChange?()
        }
    }
    var onChange: (() -> Void)?

    var settings: Settings { model.settings }

    init(model: AppModel, companion: CompanionController) {
        self.model = model
        self.companion = companion
        voice.onFinish = { [weak self] in
            guard let self, self.state == .speaking || self.state == .thinking else { return }
            self.bubbleFollowsSpeech = true
            self.state = .idle
            self.companion.setLook(.idle)
            self.companion.hideBubble(after: 3) // fades 3 s after speech ends (spec 006 US2)
        }
        // The bubble grows with the speech (spec 006 US2 / 007 FR-004).
        voice.onSentenceStart = { [weak self] sentence in
            guard let self else { return }
            self.spokenSoFar += (self.spokenSoFar.isEmpty ? "" : " ") + sentence
            self.state = .speaking
            self.companion.setLook(.speaking)
            if self.bubbleFollowsSpeech { self.companion.showBubble(self.spokenSoFar, style: .info) }
        }
        speech.onLevel = { [weak companion] level in companion?.setLevel(level) }
    }

    // MARK: Voice

    func beginListening() {
        guard state != .listening else { return }
        currentRequest?.cancel()
        voice.stopNow()
        quietChip.close()
        companion.cancelPointing()
        companion.clearDrawings()
        companion.hideBubble()
        do {
            try speech.start(settings)
            listenStart = Date()
            state = .listening
            companion.setLook(.listening)
        } catch {
            state = .idle
            companion.setLook(.idle)
            companion.showBubble(error.localizedDescription, style: .info, autoHide: 4)
        }
    }

    func endListening() {
        guard state == .listening else { return }
        let tooShort = Date().timeIntervalSince(listenStart) < 0.3
        currentRequest = Task {
            let text = await speech.stop()
            if tooShort || text.isEmpty {
                state = .idle
                companion.setLook(.idle)
                companion.showBubble(tooShort ? "Hold the key while you talk" : "I didn't catch that", style: .info, autoHide: 1.5)
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
        companion.setLook(.idle)
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
        voice.stopNow()
        quietChip.close()
        currentRequest = Task { await handle(text, via: .typed) }
    }

    /// The composer sends straight to the open chat: Talk asks about the screen, a Clicky gets an instruction.
    func send(_ text: String, toChat chatID: UUID) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let chat = model.chat(chatID) else { return }
        if chat.kind == .talk {
            currentRequest?.cancel()
            voice.stopNow()
        quietChip.close()
            currentRequest = Task { await talk(text, via: .typed) }
        } else {
            startAgent(text, in: chatID, via: .typed)
        }
    }

    func stopSpeaking() {
        voice.stopNow()
        quietChip.close()
        companion.cancelPointing()
        companion.hideBubble()
        companion.setLook(.idle)
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

    /// Streams the answer and speaks it sentence by sentence as it arrives (spec 007 US1).
    private func talk(_ text: String, via: Message.Via) async {
        guard let apiKey = Keychain.apiKey() else {
            say("Please set your Anthropic API key first, in Settings, General.")
            return
        }
        guard PaidRequestGate.allow(model) else { return } // monthly budget reached (spec 011); notice already shown

        state = .thinking
        companion.setLook(.thinking)
        companion.showBubble("“\(text)”", style: .thinking)

        let modelID = Router.wantsPointing(text) ? settings.pointingModel : settings.fastModel
        var screenshots: [Screenshot] = []
        if ScreenCapture.hasPermission {
            screenshots = (try? await ScreenCapture.captureAll()) ?? []
        }

        let talkID = model.talkChat.id
        let window = ContextWindow(chat: model.talkChat)
        let history = window.recent.map { ChatTurn(user: $0.user.text, assistant: $0.assistant.text) }
        model.append(Message(role: .user, text: text, via: via, screensSeen: screenshots.count), to: talkID)
        let body = claude.talkBody(question: text, screenshots: screenshots, history: history, memory: window.summary, model: modelID)

        let quiet = model.isQuiet
        let stream = StreamState()
        spokenSoFar = ""
        if !quiet { voice.begin() }
        let settings = self.settings
        let feed: @MainActor (String) -> Void = { [weak self] sentence in
            guard let self else { return }
            if quiet { self.companion.showBubble(stream.shown(adding: sentence), style: .quiet) }
            else { self.voice.enqueue(sentence, settings: settings) }
        }

        do {
            let reply = try await claude.stream(body, model: modelID, apiKey: apiKey) { piece in
                stream.raw += piece
                let visible = ScreenTags.visibleText(partial: stream.raw)
                guard visible.hasPrefix(stream.emitted) else { return }
                let delta = String(visible.dropFirst(stream.emitted.count))
                stream.emitted = visible
                stream.splitter.append(delta).forEach(feed)
            }
            if let rest = stream.splitter.finish() { feed(rest) }
            model.recordUsage(reply.usage) // billed even if the user interrupted
            let parsed = ScreenTags.parse(reply.text)
            let answer = parsed.text.isEmpty ? "Look here." : parsed.text
            model.appendReply(Message(role: .assistant, text: answer, via: via), to: talkID)
            guard !Task.isCancelled else { return }

            model.emit(.talkAnswered)
            if via == .typed { model.emit(.textModeSent) }
            if case .point(let x, let y, let label, let screen)? = parsed.point, screenshots.indices.contains(screen - 1) {
                let shot = screenshots[screen - 1]
                companion.point(at: shot.globalPoint(x: x, y: y), label: label)
                model.emit(.pointed)
            }
            if !parsed.drawings.isEmpty { companion.draw(parsed.drawings, screenshots: screenshots) }
            if parsed.text.isEmpty && !quiet { voice.enqueue(answer, settings: settings) }

            if quiet {
                finishQuietly(answer)
            } else {
                voice.close()
            }
            await memory.foldIfNeeded(talkID)
        } catch let interrupted as ClaudeClient.StreamInterrupted {
            model.recordUsage(interrupted.usage)
            let partial = ScreenTags.parse(interrupted.partial).text
            if !partial.isEmpty { model.appendReply(Message(role: .assistant, text: partial + " …connection lost", via: via), to: talkID) }
            if let rest = stream.splitter.finish(), !quiet { voice.enqueue(rest, settings: settings) }
            companion.showBubble((partial.isEmpty ? "Sorry, the answer didn't arrive." : partial) + " …connection lost",
                                 style: .info, autoHide: 6)
            if quiet { state = .idle; companion.setLook(.idle) } else { voice.close() }
        } catch {
            guard !Task.isCancelled else { return }
            say("Sorry, something went wrong. \(error.localizedDescription)")
        }
    }

    /// Quiet mode (spec 007 US4): show the answer without sound, with a chip to play it.
    private func finishQuietly(_ answer: String) {
        state = .idle
        companion.setLook(.idle)
        companion.showBubble("🔇 " + answer, style: .quiet, autoHide: 12)
        quietChip.show(near: NSEvent.mouseLocation) { [weak self] in
            guard let self else { return }
            self.spokenSoFar = ""
            self.voice.speakAll(answer, settings: self.settings)
        }
    }

    /// Speaks a complete sentence or two (errors, agent announcements), unless MyClicky is keeping quiet.
    private func say(_ text: String) {
        if model.isQuiet {
            companion.showBubble("🔇 " + text, style: .quiet, autoHide: 8)
            state = .idle
            return
        }
        state = .speaking
        spokenSoFar = ""
        companion.setLook(.speaking)
        companion.showBubble(text, style: .info)
        voice.speakAll(text, settings: settings)
    }

    // MARK: Clickys (agents run in AgentSupervisor, spec 009)

    private func startAgent(_ task: String, in chatID: UUID, via: Message.Via) {
        model.append(Message(role: .user, text: task, via: via), to: chatID)
        agents?.start(chatID: chatID, instruction: task)
    }

    /// Agent start/finish announcements (spec 009 US5): an optional bubble beside the cursor, and a spoken line
    /// unless MyClicky is keeping quiet. Waits so it never talks over you.
    func announce(_ text: String, bubble: String?) {
        Task {
            while state == .listening || state == .thinking {
                try? await Task.sleep(for: .milliseconds(300))
            }
            if let bubble { companion.showBubble(bubble, style: .agent, autoHide: 10) }
            guard !text.isEmpty, !model.isQuiet, state != .speaking else { return }
            bubbleFollowsSpeech = bubble == nil
            spokenSoFar = ""
            state = .speaking
            voice.speakAll(text, settings: settings)
        }
    }
}
