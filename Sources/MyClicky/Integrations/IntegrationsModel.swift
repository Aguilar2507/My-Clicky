import AppKit
import Observation
import MyClickyCore

/// Integrations are MCP servers in Claude Code's user scope (spec 010 research R1): every Clicky can use them, and
/// Claude Code keeps the sign-in tokens, so MyClicky never stores secrets (Principle IV).
@MainActor
@Observable
final class IntegrationsModel {
    let model: AppModel
    var statuses: [String: ConnectionStatus] = [:]
    var others: [MCPListParser.Entry] = []
    var isRefreshing = false
    var claudeAvailable = false
    var lastError: String?

    init(model: AppModel) { self.model = model }

    /// Catalog (bundled `integrations.json`) + your custom connectors.
    var all: [Integration] { Self.catalog + model.settings.customIntegrations }

    static let catalog: [Integration] = {
        let bundled = Bundle.main.url(forResource: "integrations", withExtension: "json")
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources/integrations.json")
        let data = bundled.flatMap { try? Data(contentsOf: $0) } ?? (try? Data(contentsOf: source)) ?? Data("[]".utf8)
        return Integration.loadCatalog(from: data)
    }()

    func status(_ integration: Integration) -> ConnectionStatus { statuses[integration.id] ?? .notAdded }

    var connected: [Integration] { all.filter { status($0) != .notAdded } }

    // MARK: claude mcp

    private var claude: String? { ClaudeCodeLocator.find(model.settings) }

    func refresh() async {
        guard let claude else { claudeAvailable = false; return }
        claudeAvailable = true
        isRefreshing = true
        defer { isRefreshing = false }
        let output = await Self.run(claude, ["mcp", "list"], timeout: 20)
        let split = MCPListParser.split(MCPListParser.parse(output))
        statuses = split.ours
        others = split.others
    }

    /// Adds the server; if it needs a browser sign-in, starts that (research R2).
    func connect(_ integration: Integration) async -> ConnectionStatus {
        guard let claude else { return .failed("Claude Code isn't installed") }
        statuses[integration.id] = .checking
        _ = await Self.run(claude, integration.addArguments, timeout: 20)
        await refresh()
        let now = status(integration)
        if now == .needsAuth || now == .notAdded { signIn(integration) }
        return now
    }

    func disconnect(_ integration: Integration) async {
        guard let claude else { return }
        _ = await Self.run(claude, ["mcp", "remove", integration.serverName, "-s", "user"], timeout: 20)
        if integration.isCustom { model.settings.customIntegrations.removeAll { $0.id == integration.id } }
        await refresh()
    }

    /// Opens Terminal running `claude mcp login <server>`, which opens the service's browser sign-in (spec 010 R2).
    /// It needs a terminal: without one, Claude Code 2.1.283 refuses to finish the sign-in.
    func signIn(_ integration: Integration) {
        guard let claude else { return }
        let script = model.paths.base.appendingPathComponent("connect-\(integration.id).command")
        let text = """
        #!/bin/zsh
        clear
        echo "MyClicky: connecting \(integration.name). Your browser opens: sign in there."
        echo "When it says you're done, close this window. MyClicky updates by itself."
        echo ""
        exec "\(claude)" mcp login "\(integration.serverName)"
        """
        try? JSONFile.write(Data(text.utf8), to: script)
        chmod(script.path, 0o755)
        NSWorkspace.shared.open(script)
    }

    /// Waits (polling every 3 s, up to 5 min) until the connector is connected.
    func waitUntilConnected(_ integration: Integration) async -> Bool {
        for _ in 0..<100 {
            try? await Task.sleep(for: .seconds(3))
            if Task.isCancelled { return false }
            await refresh()
            if status(integration) == .connected { return true }
        }
        return false
    }

    func addCustom(name: String, url: String?, command: String?) async -> String? {
        switch IntegrationFilter.custom(name: name, url: url, command: command, existing: all) {
        case .failure(let error):
            switch error {
            case .emptyName: return "Give it a name."
            case .nameTaken: return "Name already used."
            case .badURL: return "Use a full https:// address."
            case .emptyCommand: return "Enter the command that starts it."
            }
        case .success(let integration):
            if let exe = integration.command?.first, !exe.contains("/"),
               await Self.run("/usr/bin/which", [exe], timeout: 5).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "“\(exe)” wasn't found on this Mac."
            }
            model.settings.customIntegrations.append(integration)
            let result = await connect(integration)
            if case .failed(let message) = result { return "Added, but it failed to connect: \(message)" }
            return nil
        }
    }

    /// Runs a command with a time limit and returns stdout+stderr.
    static func run(_ path: String, _ args: [String], timeout: TimeInterval) async -> String {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args
            process.environment = ClaudeCodeLocator.environment
            let out = Pipe()
            process.standardOutput = out
            process.standardError = out
            process.standardInput = FileHandle.nullDevice
            let once = ResumeOnce(continuation)
            let finish: @Sendable (String) -> Void = { once.resume($0) }
            process.terminationHandler = { _ in finish(String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)) }
            do { try process.run() } catch { finish(""); return }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning { process.terminate() }
            }
        }
    }
}

/// Resumes a continuation exactly once (process exit vs. timeout).
private final class ResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<String, Never>?
    init(_ continuation: CheckedContinuation<String, Never>) { self.continuation = continuation }
    func resume(_ text: String) {
        lock.lock()
        let c = continuation
        continuation = nil
        lock.unlock()
        c?.resume(returning: text)
    }
}
