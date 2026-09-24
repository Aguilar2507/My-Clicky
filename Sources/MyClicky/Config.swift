import Foundation

/// User-editable settings, stored at ~/Library/Application Support/MyClicky/config.json.
struct Config: Codable {
    /// Cheap, fast model for normal questions.
    var fastModel = "claude-haiku-4-5"
    /// Stronger model used only when you ask where something is / how to do something on screen.
    var pointingModel = "claude-sonnet-5"
    /// Speech recognition language, e.g. "en-US" or "es-ES". Empty = system language.
    var speechLocale = ""
    /// AVSpeechSynthesisVoice identifier. Empty = best installed voice for the speech language.
    var voiceIdentifier = ""
    /// Speaking rate, 0.0–1.0 (AVSpeechUtterance default is 0.5).
    var speechRate: Float = 0.52
    /// How many previous question/answer pairs to remember.
    var maxHistoryTurns = 10
    /// Path to the Claude Code CLI used for agent mode. Empty = search common locations.
    var claudePath = ""
    /// Folder the agent works in.
    var agentWorkingDirectory = "~/MyClickyAgent"
    /// Tools the agent may use without asking. Edit to taste.
    var agentAllowedTools = ["Read", "Write", "Edit", "Glob", "Grep", "WebSearch", "WebFetch", "Bash"]

    static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MyClicky", isDirectory: true)
    }
    static var fileURL: URL { directory.appendingPathComponent("config.json") }

    static func load() -> Config {
        if let data = try? Data(contentsOf: fileURL),
           let config = try? JSONDecoder().decode(Config.self, from: data) {
            return config
        }
        let config = Config()
        config.save()
        return config
    }

    func save() {
        try? FileManager.default.createDirectory(at: Config.directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(self) {
            try? data.write(to: Config.fileURL)
        }
    }

    var locale: Locale {
        speechLocale.isEmpty ? Locale.current : Locale(identifier: speechLocale)
    }
}
