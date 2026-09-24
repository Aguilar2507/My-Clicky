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
            config.save() // writes any newly added settings into the file
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

extension Config {
    /// Missing keys keep their defaults, so adding a setting later doesn't reset your config.json.
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fastModel = try c.decodeIfPresent(String.self, forKey: .fastModel) ?? fastModel
        pointingModel = try c.decodeIfPresent(String.self, forKey: .pointingModel) ?? pointingModel
        speechLocale = try c.decodeIfPresent(String.self, forKey: .speechLocale) ?? speechLocale
        voiceIdentifier = try c.decodeIfPresent(String.self, forKey: .voiceIdentifier) ?? voiceIdentifier
        speechRate = try c.decodeIfPresent(Float.self, forKey: .speechRate) ?? speechRate
        maxHistoryTurns = try c.decodeIfPresent(Int.self, forKey: .maxHistoryTurns) ?? maxHistoryTurns
        claudePath = try c.decodeIfPresent(String.self, forKey: .claudePath) ?? claudePath
        agentWorkingDirectory = try c.decodeIfPresent(String.self, forKey: .agentWorkingDirectory) ?? agentWorkingDirectory
        agentAllowedTools = try c.decodeIfPresent([String].self, forKey: .agentAllowedTools) ?? agentAllowedTools
    }
}
