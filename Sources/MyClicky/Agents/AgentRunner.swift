import Foundation
import MyClickyCore

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
        var sessionID: String? = nil
    }

    private(set) var isRunning = false
    private var process: Process?

    func cancel() {
        process?.terminate()
    }

    static func findClaude(_ settings: Settings) -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [settings.claudePath, "\(home)/.local/bin/claude", "\(home)/.claude/local/claude",
                          "/opt/homebrew/bin/claude", "/usr/local/bin/claude"]
        return candidates.first { !$0.isEmpty && FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Runs one instruction. Pass the Clicky's `sessionID` to continue its earlier conversation (spec 005).
    func run(task: String, settings: Settings, sessionID: String? = nil) async throws -> Result {
        guard let claude = Self.findClaude(settings) else {
            throw AgentError(message: "Claude Code isn't installed yet. Install it and run claude once in Terminal to log in.")
        }
        let workDir = NSString(string: settings.agentWorkingDirectory).expandingTildeInPath
        try FileManager.default.createDirectory(atPath: workDir, withIntermediateDirectories: true)

        var args = ["-p", task,
                    "--output-format", "json",
                    "--append-system-prompt", Prompts.agent(workingDirectory: workDir)]
        if let sessionID { args += ["--resume", sessionID] }
        args += ["--allowedTools"] + settings.agentAllowedTools // variadic, keep last

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
        let isError = json["is_error"] as? Bool ?? false
        let summary = (json["result"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Result(summary: summary.isEmpty ? "The agent finished." : summary, isError: isError,
                      sessionID: json["session_id"] as? String ?? sessionID)
    }
}
