import Foundation

/// Runs agent tasks with the Claude Code CLI, billed to your Claude subscription (not the API key).
@MainActor
final class AgentRunner {
    struct AgentError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    struct Result {
        let summary: String
        let isError: Bool
    }

    private(set) var isRunning = false
    private var process: Process?
    private var sessionID: String?
    private var lastRun = Date.distantPast
    /// Follow-ups within this window continue the same agent conversation.
    private let followUpWindow: TimeInterval = 15 * 60

    func resetSession() { sessionID = nil }

    func cancel() {
        process?.terminate()
    }

    static func findClaude(_ config: Config) -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [config.claudePath, "\(home)/.local/bin/claude", "\(home)/.claude/local/claude",
                          "/opt/homebrew/bin/claude", "/usr/local/bin/claude"]
        return candidates.first { !$0.isEmpty && FileManager.default.isExecutableFile(atPath: $0) }
    }

    func run(task: String, config: Config) async throws -> Result {
        guard let claude = Self.findClaude(config) else {
            throw AgentError(message: "Claude Code isn't installed yet. Install it and run claude once in Terminal to log in.")
        }
        let workDir = NSString(string: config.agentWorkingDirectory).expandingTildeInPath
        try FileManager.default.createDirectory(atPath: workDir, withIntermediateDirectories: true)

        var args = ["-p", task,
                    "--output-format", "json",
                    "--append-system-prompt", Prompts.agent(workingDirectory: workDir)]
        if let sessionID, Date().timeIntervalSince(lastRun) < followUpWindow {
            args += ["--resume", sessionID]
        }
        args += ["--allowedTools"] + config.agentAllowedTools // variadic, keep last

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claude)
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: workDir)
        var env = ProcessInfo.processInfo.environment
        env.removeValue(forKey: "ANTHROPIC_API_KEY") // make sure it uses the subscription login, not API billing
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        env["PATH"] = "\(home)/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = env
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        process.standardInput = FileHandle.nullDevice

        self.process = process
        isRunning = true
        defer {
            isRunning = false
            self.process = nil
            lastRun = Date()
        }

        try process.run()
        let (out, err) = await Task.detached {
            let out = stdout.fileHandleForReading.readDataToEndOfFile()
            let err = stderr.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return (out, err)
        }.value

        guard let json = (try? JSONSerialization.jsonObject(with: out)) as? [String: Any] else {
            if process.terminationReason == .uncaughtSignal { return Result(summary: "Agent stopped.", isError: true) }
            let detail = String(data: err, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw AgentError(message: detail.isEmpty ? "The agent exited without a result." : String(detail.prefix(300)))
        }
        if let id = json["session_id"] as? String { sessionID = id }
        let isError = json["is_error"] as? Bool ?? false
        let summary = (json["result"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Result(summary: summary.isEmpty ? "The agent finished." : summary, isError: isError)
    }
}
