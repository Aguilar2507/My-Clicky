import Foundation
import MyClickyCore

/// Finds the Claude Code CLI and whether it's signed in (spec 009 US4). Agents run on the Claude subscription.
enum ClaudeCodeLocator {
    struct Status: Equatable {
        var path: String?
        var version: String?
        var signedIn: Bool
        var isReady: Bool { path != nil && signedIn }
    }

    static func find(_ settings: Settings) -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [settings.claudePath, "\(home)/.local/bin/claude", "\(home)/.claude/local/claude",
                          "/opt/homebrew/bin/claude", "/usr/local/bin/claude"]
        return candidates.first { !$0.isEmpty && FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Runs `claude --version` (fast, no network) and checks for a saved sign-in.
    /// Sign-in detection is best-effort (research: verify once Claude Code is installed — task T001).
    static func status(_ settings: Settings) async -> Status {
        guard let path = find(settings) else { return Status(path: nil, version: nil, signedIn: false) }
        let version = await run(path, ["--version"]).trimmingCharacters(in: .whitespacesAndNewlines)
        return Status(path: path, version: version.isEmpty ? nil : String(version.prefix(40)), signedIn: signedIn())
    }

    static func signedIn() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        if let data = try? Data(contentsOf: home.appendingPathComponent(".claude.json")),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], json["oauthAccount"] != nil {
            return true
        }
        return FileManager.default.fileExists(atPath: home.appendingPathComponent(".claude/.credentials.json").path)
    }

    /// Environment for agent processes: never the API key (Principle I), a PATH that finds common tools.
    static var environment: [String: String] {
        var env = ProcessInfo.processInfo.environment
        env.removeValue(forKey: "ANTHROPIC_API_KEY")
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        env["PATH"] = "\(home)/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        return env
    }

    static func run(_ path: String, _ args: [String]) async -> String {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args
            process.environment = environment
            let out = Pipe()
            process.standardOutput = out
            process.standardError = Pipe()
            process.terminationHandler = { _ in
                continuation.resume(returning: String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self))
            }
            do { try process.run() } catch { continuation.resume(returning: "") }
        }
    }
}
