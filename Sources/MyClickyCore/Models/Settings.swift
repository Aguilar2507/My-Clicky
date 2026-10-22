import Foundation

/// Every user preference, stored in `settings.json`. Each field has a default, so older files keep loading
/// (TolerantDecoder fills gaps). Features add fields in their own extension-free block below, marked by spec.
public struct Settings: Codable, Equatable, Sendable {
    public static let currentVersion = 6

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
    // `agentAllowedTools` (v0.1) was removed in 1.0: agents get a fixed safe tool list (`AgentSupervisor.safeTools`).
    // Old settings files that still have it load fine (unknown keys are ignored).

    // 003 → 019: the window is home, so it's in the Dock by default.
    public var showInDock = true

    // 004 settings shell
    public var profileName = Settings.defaultProfileName
    public var showInScreenRecordings = true
    public var shortcuts = ShortcutBinding.defaults

    // 006 cursor companion
    public var cursorColor: CursorColor = .red
    public var cursorDocked = false

    // 007 voice talk
    public var speechSpeed = 1.0
    public var voiceByLanguage: [String: String] = [:]
    public var microphoneUID = ""
    public var quietOverride = QuietOverride()

    public struct QuietOverride: Codable, Equatable, Sendable {
        public enum Mode: String, Codable, Sendable { case auto, on, off }
        public var mode: Mode = .auto
        public var until: Date?
        public init(mode: Mode = .auto, until: Date? = nil) {
            self.mode = mode
            self.until = until
        }
    }

    // 008 dictation
    public var dictationAutoDetect = true
    public var dictationLanguage = Settings.defaultDictationLanguage
    public var spanishLocale = Settings.defaultSpanishLocale
    public var customWords: [String] = []

    // 009 agents
    public var autoApproveExtraUsage = false
    public var alwaysAllowComputerUse = false
    public var suggestAgentTasks = true
    public var announceStartFinish = true
    public var showUpdatesBesideCursor = true
    public var lastSuggestionsAt: Date?
    public var lastSuggestions: [Suggestion] = []

    // 010 integrations (no secrets: Claude Code keeps sign-in tokens)
    public var customIntegrations: [Integration] = []
    /// Your own OAuth apps' client IDs by integration id (not secret; the client secret stays in Claude Code).
    public var oauthClientIDs: [String: String] = [:]

    // 011 spending and limits
    public var monthlyBudgetUSD = 7.0          // 0 = off; $20 ÷ ~3 months
    public var budgetTopUps: [String: Double] = [:]
    public var budgetWarnedMonth = ""
    public var creditUSD: Double?
    public var creditSince: Date?

    // 012 welcome tour
    public var tour = TourState()

    // 014 premium feel
    public var hapticFeedback = true

    public init() {}

    /// "es" if the Mac's language is Spanish, otherwise "en".
    public static var defaultDictationLanguage: String {
        Locale.current.language.languageCode?.identifier == "es" ? "es" : "en"
    }

    /// The Mac's region if it's a Spanish-speaking one, otherwise Mexico.
    public static var defaultSpanishLocale: String {
        let spanishRegions = ["ES", "MX", "US", "AR", "CO", "CL", "PE", "VE", "EC", "GT", "CU", "BO", "DO", "HN", "PY",
                              "SV", "NI", "CR", "PA", "UY", "PR"]
        let region = Locale.current.region?.identifier ?? ""
        return spanishRegions.contains(region) && region != "US" ? "es-\(region)" : "es-MX"
    }

    /// First word of the macOS account name ("Jose").
    public static var defaultProfileName: String {
        NSFullUserName().split(separator: " ").first.map(String.init) ?? NSUserName()
    }
}

/// The companion's color (Settings → Cursor, ref 08).
public enum CursorColor: String, Codable, CaseIterable, Sendable {
    case red, blue, yellow, green

    public var hex: UInt32 {
        switch self {
        case .red: 0xF0524A
        case .blue: 0x3E7BFA
        case .yellow: 0xE9B53A
        case .green: 0x3DBE72
        }
    }
}

/// One-way upgrades of older settings files. Each step runs once, in order, then `version` becomes current.
public enum SettingsMigrations {
    public static func upgrade(_ settings: inout Settings) {
        if settings.version < 2 {
            // v0.1 → v0.2: same keys, nothing to convert.
        }
        if settings.version < 3 {
            // 007: rate → speed chip; the chosen voice goes into its language slot.
            settings.speechSpeed = VoiceRanking.speed(forRate: settings.speechRate)
            if !settings.voiceIdentifier.isEmpty, let language = VoiceRanking.language(ofIdentifier: settings.voiceIdentifier) {
                settings.voiceByLanguage[language] = settings.voiceIdentifier
            }
        }
        if settings.version < 4 {
            // 008: v0.1's single speech language becomes the dictation language (+ Spanish region).
            let legacy = settings.speechLocale.lowercased()
            if legacy.hasPrefix("es") {
                settings.dictationLanguage = "es"
                settings.spanishLocale = settings.speechLocale.replacingOccurrences(of: "_", with: "-")
            } else if legacy.hasPrefix("en") {
                settings.dictationLanguage = "en"
            }
        }
        if settings.version < 5 {
            // Push to talk moved from fn to ⌃⌥. A custom key the user picked is kept.
            if let i = settings.shortcuts.firstIndex(where: { $0.action == .pushToTalk }),
               settings.shortcuts[i] == ShortcutBinding(.pushToTalk, KeyChord([.fn]), .hold) {
                settings.shortcuts[i] = ShortcutBinding.defaults[0]
            }
        }
        if settings.version < 6 {
            // 019: the notch is gone; the window is home, so it gets a Dock icon (the menu bar icon stays either way).
            settings.showInDock = true
        }
        settings.version = Settings.currentVersion
    }
}
