import AppKit
import MyClickyCore

/// Runs agent tasks with Claude Code on the Claude subscription (spec 009): up to 3 at once, live steps in the chat,
/// Allow cards for sensitive actions, a step cap with "Keep going?", a 30-minute limit and a stall watchdog.
@MainActor
final class AgentSupervisor {
    private final class Run {
        let chatID: UUID
        let instruction: String
        /// "en" or "es": the request's language; the agent replies and is announced in it (spec 020).
        let language: String
        let startedAt = Date()
        var lastEventAt = Date()
        var process: Process?
        var buffer = Data()
        var steps = 0
        var lastText: String?
        var computerApproved = false
        var finished = false
        var stopReason: String?

        init(chatID: UUID, instruction: String, language: String) {
            self.chatID = chatID
            self.instruction = instruction
            self.language = language
        }
    }

    static let timeLimit: TimeInterval = 30 * 60
    static let stallLimit: TimeInterval = 5 * 60
    static let approvalTimeout: TimeInterval = 10 * 60

    let model: AppModel
    let computer: ComputerActions
    /// Speaks + shows a line (Assistant.announce), respecting quiet mode.
    var announce: (_ text: String, _ bubble: String?, _ language: String?) -> Void = { _, _, _ in }

    private var runs: [UUID: Run] = [:]
    private var queue = RunQueue()
    private var waiting: [UUID: String] = [:]
    /// Each chat's last request language, so "Please continue." keeps it.
    private var languages: [UUID: String] = [:]
    private var approvals: [String: CheckedContinuation<String, Never>] = [:]
    private let approvalChip = ApprovalChip()
    private var server: BridgeSocketServer?
    private var watchdog: Timer?

    init(model: AppModel, companion: CompanionController) {
        self.model = model
        computer = ComputerActions(companion: companion)
        let server = BridgeSocketServer(path: model.paths.agentSocket.path) { [weak self] request in
            await self?.handle(request) ?? BridgeResponse(id: request.id, ok: false, content: [.text("MyClicky is closing")])
        }
        try? server.start()
        self.server = server
        watchdog = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkLimits() }
        }
    }

    var runningChatIDs: [UUID] { Array(runs.keys) }

    // MARK: Start / stop

    /// Gives an agent its next instruction (the caller already saved the user's message). `language` is the request's
    /// ("en"/"es"); without it, a guess from the text, else the chat's last language.
    func start(chatID: UUID, instruction: String, language: String? = nil) {
        languages[chatID] = ReplyLanguage.resolve(spoken: language, guessed: SpeechRecognizer.guessLanguage(instruction),
                                                  previous: languages[chatID], fallback: model.settings.dictationLanguage)
        guard runs[chatID] == nil, waiting[chatID] == nil else {
            notice(chatID, "Still working on the last instruction. Stop it first or wait for it to finish.", status: "queued")
            return
        }
        guard ClaudeCodeLocator.find(model.settings) != nil else {
            notice(chatID, "Claude Code isn't installed yet. Settings → Agents shows how to set it up.", status: "failed")
            announce("Agents need Claude Code. Open Settings, Agents, to set it up.", nil, nil)
            return
        }
        Log.events.notice("agent start chat=\(chatID.uuidString.prefix(8), privacy: .public) lang=\(self.languages[chatID] ?? "?", privacy: .public)")
        if queue.request(chatID) {
            launchWhenNamed(chatID: chatID, instruction: instruction)
        } else {
            waiting[chatID] = instruction
            notice(chatID, "Waiting for another agent to finish…", status: "queued")
            refreshWorking()
        }
    }

    func stop(chatID: UUID) {
        if waiting.removeValue(forKey: chatID) != nil {
            _ = queue.finish(chatID)
            notice(chatID, "Stopped.", status: "stopped")
            refreshWorking()
            return
        }
        guard let run = runs[chatID], let process = run.process else { return }
        run.stopReason = "Stopped."
        Log.events.notice("agent stop requested chat=\(chatID.uuidString.prefix(8), privacy: .public)")
        process.interrupt() // SIGINT, then SIGTERM after 2 s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { if process.isRunning { process.terminate() } }
    }

    func stopAll() { runningChatIDs.forEach(stop) }

    /// "Keep going?" → continue the same session.
    func keepGoing(chatID: UUID) {
        start(chatID: chatID, instruction: "Please continue.")
    }

    // MARK: Launch

    /// A brand-new agent's folder comes from its name, which arrives ~1.5 s after its first instruction. Without
    /// waiting, every agent got the placeholder's folder ("new-agent", "new-agent") and shared it with the others.
    private func launchWhenNamed(chatID: UUID, instruction: String) {
        guard let chat = model.chat(chatID), chat.folderName.isEmpty, NamingParser.isFallback(chat.title) else {
            launch(chatID: chatID, instruction: instruction)
            return
        }
        Task { @MainActor [weak self] in
            for _ in 0..<30 { // up to 3 s, then the placeholder name it is
                try? await Task.sleep(for: .milliseconds(100))
                guard let title = self?.model.chat(chatID)?.title, NamingParser.isFallback(title) else { break }
            }
            self?.launch(chatID: chatID, instruction: instruction)
        }
    }

    private func launch(chatID: UUID, instruction: String) {
        guard let chat = model.chat(chatID), let claude = ClaudeCodeLocator.find(model.settings) else { return }
        let folder = folder(for: chat)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let mcpConfig = writeMCPConfig(chatID: chatID)
        let language = languages[chatID] ?? "en"
        let run = Run(chatID: chatID, instruction: instruction, language: language)
        runs[chatID] = run

        var args = ["-p", instruction, "--output-format", "stream-json", "--verbose",
                    "--append-system-prompt", Prompts.agentRole(name: chat.title, purpose: chat.purpose, folder: folder.path,
                                                                    language: language),
                    "--max-turns", "\(RunQueue.stepLimit(autoApprove: model.settings.autoApproveExtraUsage))",
                    "--mcp-config", mcpConfig.path,
                    "--permission-prompt-tool", "mcp__myclicky__approve"]
        if let session = chat.agentSessionID { args += ["--resume", session] }
        args += ["--allowedTools"] + Self.safeTools // variadic, keep last

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claude)
        process.arguments = args
        process.currentDirectoryURL = folder
        process.environment = ClaudeCodeLocator.environment
        let out = Pipe(), err = Pipe()
        process.standardOutput = out
        process.standardError = err
        process.standardInput = FileHandle.nullDevice
        out.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            Task { @MainActor in self?.consume(data, chatID: chatID) }
        }
        process.terminationHandler = { [weak self] process in
            let status = process.terminationStatus
            let errorText = String(decoding: err.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            Task { @MainActor in self?.ended(chatID: chatID, status: status, stderr: errorText) }
        }
        run.process = process
        do {
            try process.run()
        } catch {
            runs[chatID] = nil
            notice(chatID, "Couldn't start Claude Code: \(error.localizedDescription)", status: "failed")
            advanceQueue(after: chatID)
            return
        }
        refreshWorking()
        if model.settings.announceStartFinish { announce(ReplyLanguage.text(.onIt(chat.title), language), nil, language) }
    }

    /// Read, search and web tools run without asking; edits only inside the agent's folder.
    /// Everything else (commands, edits elsewhere, computer use, integrations) asks with an Allow card.
    static let safeTools = ["Read", "Glob", "Grep", "WebSearch", "WebFetch", "TodoWrite", "Edit(./**)", "Write(./**)"]

    private func folder(for chat: Chat) -> URL {
        let base = URL(fileURLWithPath: NSString(string: model.settings.agentWorkingDirectory).expandingTildeInPath)
        var name = chat.folderName
        if name.isEmpty {
            name = chat.title.lowercased().map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
                .split(separator: "-").joined(separator: "-")
            if name.isEmpty { name = "clicky" }
            model.updateChat(chat.id) { $0.folderName = name }
        }
        return base.appendingPathComponent(name, isDirectory: true)
    }

    private func writeMCPConfig(chatID: UUID) -> URL {
        let bridge = Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("MyClickyComputer").path ?? "MyClickyComputer"
        let config: [String: Any] = ["mcpServers": ["myclicky": ["command": bridge,
                                                                 "args": ["--chat", chatID.uuidString, "--socket", model.paths.agentSocket.path]]]]
        let url = model.paths.base.appendingPathComponent("mcp-\(chatID.uuidString).json")
        if let data = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys]) {
            try? JSONFile.write(data, to: url)
        }
        return url
    }

    // MARK: Events → chat

    private func consume(_ data: Data, chatID: UUID) {
        guard let run = runs[chatID], !data.isEmpty else { return }
        run.buffer.append(data)
        while let newline = run.buffer.firstIndex(of: 0x0A) {
            let line = String(decoding: run.buffer[run.buffer.startIndex..<newline], as: UTF8.self)
            run.buffer.removeSubrange(run.buffer.startIndex...newline)
            run.lastEventAt = Date()
            AgentEventParser.parse(line: line).forEach { apply($0, run: run) }
        }
    }

    private func apply(_ event: AgentEvent, run: Run) {
        let chatID = run.chatID
        switch event {
        case .initialized(let session):
            model.updateChat(chatID) { $0.agentSessionID = session }
        case .text(let text):
            run.lastText = text
            model.append(Message(role: .assistant, text: text, via: .agent), to: chatID)
        case .toolUse(let id, let name, let input):
            run.steps += 1
            var step = Message(role: .system, text: PermissionDescriber.stepSummary(tool: name, input: input), via: .agent)
            step.kind = .step
            step.toolName = name
            step.detail = input["command"] ?? input["file_path"] ?? input["url"] ?? input["query"]
            step.status = "running"
            step.refID = id
            model.append(step, to: chatID)
        case .toolResult(let id, let isError, _):
            model.updateChat(chatID) { chat in
                if let index = chat.messages.lastIndex(where: { $0.kind == .step && $0.refID == id }) {
                    chat.messages[index].status = isError ? "failed" : "done"
                }
            }
        case .result(let subtype, let text, let turns, let session, let isError):
            run.finished = true
            model.updateChat(chatID) {
                if let session { $0.agentSessionID = session }
                $0.lastAgentUseAt = Date()
            }
            let name = model.chat(chatID)?.title ?? "Your agent"
            if subtype == "error_max_turns" {
                notice(chatID, "\(name) has used \(turns) steps on this. Keep going?", status: "keepGoing")
                finishAnnouncement(chatID, ReplyLanguage.text(.paused(name, steps: turns), run.language),
                                   title: "\(name) paused", body: "Used \(turns) steps. Open the chat to keep going.")
            } else if isError {
                notice(chatID, text.isEmpty ? "\(name) ran into a problem." : text, status: "failed")
                finishAnnouncement(chatID, ReplyLanguage.text(.problem(name), run.language), title: "\(name) ran into a problem",
                                   body: text.isEmpty ? "Open the chat to see what happened." : Self.firstSentence(text))
            } else {
                if !text.isEmpty && text != run.lastText {
                    model.append(Message(role: .assistant, text: text, via: .agent), to: chatID)
                }
                let final = text.isEmpty ? (run.lastText ?? "Done.") : text
                finishAnnouncement(chatID, ReplyLanguage.text(.finished(name), run.language) + " " + Self.firstSentence(final),
                                   bubble: final,
                                   title: "\(name) finished", body: Self.firstSentence(final))
            }
        }
    }

    private func ended(chatID: UUID, status: Int32, stderr: String) {
        guard let run = runs[chatID] else { return }
        run.process?.standardOutput.flatMap { $0 as? Pipe }?.fileHandleForReading.readabilityHandler = nil
        if !run.finished {
            let name = model.chat(chatID)?.title ?? "Your agent"
            if let reason = run.stopReason {
                notice(chatID, reason, status: "stopped")
            } else {
                let detail = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                notice(chatID, detail.isEmpty ? "\(name) stopped unexpectedly." : String(detail.prefix(300)), status: "failed")
                finishAnnouncement(chatID, ReplyLanguage.text(.stopped(name), run.language), title: "\(name) stopped",
                                   body: "It stopped unexpectedly. Open the chat for details.")
            }
        }
        runs[chatID] = nil
        computer.runEnded(chatID.uuidString)
        try? FileManager.default.removeItem(at: model.paths.base.appendingPathComponent("mcp-\(chatID.uuidString).json"))
        advanceQueue(after: chatID)
    }

    private func advanceQueue(after chatID: UUID) {
        if let next = queue.finish(chatID), let instruction = waiting.removeValue(forKey: next) {
            launch(chatID: next, instruction: instruction)
        }
        refreshWorking()
    }

    private func refreshWorking() {
        model.workingChatIDs = Set(runs.keys).union(waiting.keys)
        model.isAgentRunning = !runs.isEmpty
    }

    private func checkLimits() {
        let now = Date()
        for run in runs.values where run.process?.isRunning == true {
            if now.timeIntervalSince(run.startedAt) > Self.timeLimit {
                run.stopReason = "Stopped after 30 minutes (time limit)."
                run.process?.terminate()
            } else if now.timeIntervalSince(run.lastEventAt) > Self.stallLimit {
                run.stopReason = "Stopped: no progress for 5 minutes."
                run.process?.terminate()
            }
        }
    }

    private func notice(_ chatID: UUID, _ text: String, status: String) {
        var message = Message(role: .system, text: text, via: .agent)
        message.kind = .notice
        message.status = status
        model.append(message, to: chatID)
    }

    /// Project rule (spec 018): every task end tells you. Always: a macOS notification (opens the chat), a haptic tap,
    /// the unread dot and the menu bar dot. Per settings: the spoken line (queued until MyClicky is free, skipped only
    /// while quiet) and the bubble beside the cursor.
    private func finishAnnouncement(_ chatID: UUID, _ spoken: String, bubble: String? = nil, title: String, body: String) {
        let language = languages[chatID]
        Log.events.notice("agent finished chat=\(chatID.uuidString.prefix(8), privacy: .public) spoken=\(self.model.settings.announceStartFinish, privacy: .public)")
        let unseen = model.visibleChatID != chatID
        Log.events.notice("agent result unread=\(unseen, privacy: .public) windowOpen=\(self.model.isWindowOpen, privacy: .public)")
        if unseen { model.updateChat(chatID) { $0.isUnread = true } }
        TaskAlerts.shared.post(chatID: chatID, title: title, body: body)
        Haptics.tap(.done)
        let speak = model.settings.announceStartFinish
        let show = model.settings.showUpdatesBesideCursor ? (bubble ?? spoken) : nil
        if speak || show != nil { announce(speak ? spoken : "", show, language) }
    }

    static func firstSentence(_ text: String) -> String {
        var splitter = SentenceSplitter()
        return (splitter.append(text + " ").first ?? text).prefix(160).description
    }

    // MARK: Bridge requests (Allow cards + computer use)

    private func handle(_ request: BridgeRequest) async -> BridgeResponse {
        guard let chatID = UUID(uuidString: request.chatID), let run = runs[chatID], let chat = model.chat(chatID) else {
            return BridgeResponse(id: request.id, ok: false, content: [.text(#"{"behavior":"deny","message":"This agent isn't running."}"#)])
        }
        run.lastEventAt = Date()
        if request.tool == "approve" {
            let toolName = request.input["tool_name"]?.string ?? "tool"
            let rawInput = request.input["input"]?.any as? [String: Any] ?? [:]
            let decision = await approve(tool: toolName, input: rawInput, run: run, chat: chat)
            let json: [String: Any] = decision
                ? ["behavior": "allow", "updatedInput": rawInput]
                : ["behavior": "deny", "message": "The user didn't allow this. Explain what you wanted to do and ask them."]
            return BridgeResponse(id: request.id, ok: true, content: [.text(MCPProtocol.encode(json))])
        }
        if computer.interrupted.contains(request.chatID) {
            let goOn = await ask(chat: chat, text: "You used the mouse or keyboard. Should \(chat.title) keep using your Mac?",
                                 detail: nil, tool: "computer", sensitive: true)
            computer.clearInterruption(request.chatID)
            guard goOn != "denied" else {
                return BridgeResponse(id: request.id, ok: false, content: [.text("The user paused computer use.")])
            }
        }
        return await computer.perform(request.tool, input: request.input, chatID: request.chatID)
    }

    private func approve(tool: String, input: [String: Any], run: Run, chat: Chat) async -> Bool {
        let flat = AgentEventParser.flatten(input)
        let description = PermissionDescriber.describe(tool: tool, input: flat)
        if description.isComputerUse && (model.settings.alwaysAllowComputerUse || run.computerApproved) { return true }
        if PermissionDescriber.isPreApproved(description, rules: chat.alwaysAllowed) { return true }
        let answer = await ask(chat: chat, text: description.text, detail: description.detail, tool: tool,
                               sensitive: description.sensitive, rule: description.rule)
        switch answer {
        case "allowed":
            if description.isComputerUse { run.computerApproved = true } // once per instruction
            return true
        case "alwaysAllowed":
            if description.isComputerUse { run.computerApproved = true }
            if !description.sensitive { model.updateChat(chat.id) { $0.alwaysAllowed.append(description.rule) } }
            return true
        default:
            return false
        }
    }

    /// Shows an Allow card (in the chat, and beside the cursor if the chat isn't visible) and waits for an answer.
    private func ask(chat: Chat, text: String, detail: String?, tool: String, sensitive: Bool, rule: String = "") async -> String {
        let requestID = UUID().uuidString
        var card = Message(role: .system, text: text, via: .agent)
        card.kind = .approval
        card.toolName = tool
        card.detail = detail
        card.status = sensitive ? "pendingSensitive" : "pending"
        card.refID = requestID
        model.append(card, to: chat.id)
        Log.events.notice("agent approval asked tool=\(tool, privacy: .public) sensitive=\(sensitive, privacy: .public)")
        if model.visibleChatID != chat.id {
            approvalChip.show(title: "\(chat.title) wants to: \(text)", detail: detail, allowAlways: !sensitive) { [weak self] answer in
                self?.decide(requestID, answer)
            }
            announce("", "\(chat.title) needs your OK: \(text)", nil)
        }
        let timeout = DispatchWorkItem { [weak self] in self?.decide(requestID, "expired") }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.approvalTimeout, execute: timeout)
        let answer = await withCheckedContinuation { approvals[requestID] = $0 }
        timeout.cancel()
        return answer
    }

    /// Called by the Allow card / chip: "allowed", "alwaysAllowed", "denied" (or "expired").
    func decide(_ requestID: String, _ answer: String) {
        guard let continuation = approvals.removeValue(forKey: requestID) else { return }
        approvalChip.close()
        Log.events.notice("agent approval \(answer, privacy: .public)")
        for chat in model.chats where chat.messages.contains(where: { $0.refID == requestID }) {
            model.updateChat(chat.id) { chat in
                if let i = chat.messages.lastIndex(where: { $0.refID == requestID }) { chat.messages[i].status = answer }
            }
        }
        continuation.resume(returning: answer)
    }
}

/// Allow / Always / Deny chip next to the cursor when the agent's chat isn't open (spec 009 US2).
@MainActor
final class ApprovalChip: NSObject {
    private var panel: NSPanel?
    private var handler: ((String) -> Void)?

    func show(title: String, detail: String?, allowAlways: Bool, handler: @escaping (String) -> Void) {
        close()
        self.handler = handler
        let width: CGFloat = 380
        let content = NSStackView()
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 8
        content.edgeInsets = NSEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        let label = NSTextField(wrappingLabelWithString: title)
        label.textColor = .labelColor
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.preferredMaxLayoutWidth = width - 28
        content.addArrangedSubview(label)
        if let detail, !detail.isEmpty {
            let detailLabel = NSTextField(wrappingLabelWithString: String(detail.prefix(160)))
            detailLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            detailLabel.textColor = .secondaryLabelColor
            detailLabel.preferredMaxLayoutWidth = width - 28
            content.addArrangedSubview(detailLabel)
        }
        let buttons = NSStackView()
        buttons.spacing = 8
        buttons.addArrangedSubview(button("Allow", "allowed"))
        if allowAlways { buttons.addArrangedSubview(button("Always allow", "alwaysAllowed")) }
        buttons.addArrangedSubview(button("Deny", "denied"))
        content.addArrangedSubview(buttons)

        let size = content.fittingSize
        let mouse = NSEvent.mouseLocation
        let panel = NSPanel(contentRect: CGRect(x: mouse.x + 18, y: mouse.y - 40 - max(size.height, 90), width: width,
                                                height: max(size.height, 90)),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let background = NSVisualEffectView()
        background.material = .popover // Light/Dark like a macOS popover (spec 015)
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 14
        background.addSubview(content)
        content.frame = CGRect(origin: .zero, size: CGSize(width: width, height: max(size.height, 90)))
        panel.contentView = background
        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func button(_ title: String, _ answer: String) -> NSButton {
        let button = NSButton(title: title, target: self, action: #selector(tapped(_:)))
        button.identifier = NSUserInterfaceItemIdentifier(answer)
        button.bezelStyle = .rounded
        if answer == "allowed" { button.keyEquivalent = "\r" }
        return button
    }

    @objc private func tapped(_ sender: NSButton) {
        let answer = sender.identifier?.rawValue ?? "denied"
        let handler = self.handler
        close()
        handler?(answer)
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
        handler = nil
    }
}
