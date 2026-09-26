import Foundation

/// Every user preference, stored in `settings.json`. Each field has a default, so older files keep loading
/// (TolerantDecoder fills gaps). Features add fields in their own extension-free block below, marked by spec.
public struct Settings: Codable, Equatable, Sendable {
    public static let currentVersion = 2

    public var version = Settings.currentVersion

    // 001/002 (carried over from v0.1 config.json)
    public var fastModel = "claude-haiku-4-5"
    public var pointingModel = "claude-sonnet-5"
    public var speechLocale = ""          // superseded by dictation languages (008)
    public var voiceIdentifier = ""       // superseded by voiceByLanguage (007)
    public var speechRate: Float = 0.52   // superseded by speechSpeed (007)
    public var maxHistoryTurns = 10
    public var claudePath = ""
    public var agentWorkingDirectory = "~/MyClickyAgent"
    public var agentAllowedTools = ["Read", "Write", "Edit", "Glob", "Grep", "WebSearch", "WebFetch", "Bash"]

    // 003 notch home
    public var showInDock = false
    public var notchOnAllDisplays = true

    // 004 settings shell
    public var profileName = Settings.defaultProfileName
    public var showInScreenRecordings = true
    public var shortcuts = ShortcutBinding.defaults

    public init() {}

    /// First word of the macOS account name ("Jose").
    public static var defaultProfileName: String {
        NSFullUserName().split(separator: " ").first.map(String.init) ?? NSUserName()
    }
}

/// One-way upgrades of older settings files. Each step runs once, in order, then `version` becomes current.
public enum SettingsMigrations {
    public static func upgrade(_ settings: inout Settings) {
        if settings.version < 2 {
            // v0.1 → v0.2: same keys, nothing to convert.
        }
        settings.version = Settings.currentVersion
    }
}
