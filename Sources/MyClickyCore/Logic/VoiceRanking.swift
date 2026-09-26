import Foundation

/// Picks voices and maps speed to Apple's speech rate (spec 007, research R3/R4).
public enum VoiceRanking {
    /// What MyClicky knows about an installed voice (mirrors AVSpeechSynthesisVoice).
    public struct VoiceInfo: Equatable, Sendable {
        public let identifier: String
        public let name: String
        public let language: String   // "en-US"
        public let quality: Int       // 1 default, 2 enhanced, 3 premium
        public init(identifier: String, name: String, language: String, quality: Int) {
            self.identifier = identifier
            self.name = name
            self.language = language
            self.quality = quality
        }
    }

    /// Voices for a language ("en"/"es"), best first: quality, how natural the voice family sounds, preferred
    /// region, then name. Each name appears once (its best variant).
    public static func ranked(_ voices: [VoiceInfo], language: String, preferredRegion: String? = nil) -> [VoiceInfo] {
        let sorted = voices.filter { $0.language.hasPrefix(language + "-") || $0.language == language }
            .sorted { a, b in
                if a.quality != b.quality { return a.quality > b.quality }
                let na = naturalness(a.identifier), nb = naturalness(b.identifier)
                if na != nb { return na > nb }
                let ra = preferredRegion.map { a.language.hasSuffix($0) } ?? false
                let rb = preferredRegion.map { b.language.hasSuffix($0) } ?? false
                if ra != rb { return ra }
                return a.name < b.name
            }
        var seen = Set<String>()
        return sorted.filter { seen.insert($0.name).inserted }
    }

    /// Siri and Premium voices sound best; Eloquence and the old speech-synthesis voices sound robotic.
    public static func naturalness(_ identifier: String) -> Int {
        let id = identifier.lowercased()
        if id.contains("siri") || id.contains(".premium.") { return 4 }
        if id.contains(".enhanced.") { return 3 }
        if id.contains(".compact.") || id.hasPrefix("com.apple.voice.") && !id.contains("super-compact") { return 2 }
        if id.contains("super-compact") { return 1 }
        return 0 // eloquence, speech.synthesis
    }

    public static let speeds: [Double] = [0.5, 0.75, 1, 1.25, 1.5]

    /// AVSpeechUtterance rate for a speed multiplier (perceived speed isn't linear in the rate value).
    public static func rate(for speed: Double) -> Float {
        let table: [(Double, Float)] = [(0.5, 0.38), (0.75, 0.45), (1, 0.52), (1.25, 0.57), (1.5, 0.62)]
        return table.min { abs($0.0 - speed) < abs($1.0 - speed) }!.1
    }

    /// The speed chip closest to an old v0.1 rate.
    public static func speed(forRate rate: Float) -> Double {
        let table: [(Double, Float)] = [(0.5, 0.38), (0.75, 0.45), (1, 0.52), (1.25, 0.57), (1.5, 0.62)]
        return table.min { abs($0.1 - rate) < abs($1.1 - rate) }!.0
    }

    /// "com.apple.voice.premium.es-MX.Paulina" → "es".
    public static func language(ofIdentifier id: String) -> String? {
        let parts = id.split(separator: ".")
        for part in parts where part.count == 5 && part.dropFirst(2).first == "-" {
            return String(part.prefix(2)).lowercased()
        }
        return nil
    }

    /// Descriptor on the voice card ("Premium · US").
    public static func descriptor(for voice: VoiceInfo) -> String {
        let natural = naturalness(voice.identifier)
        let quality = voice.quality >= 3 ? "Premium" : voice.quality == 2 ? "Enhanced"
            : natural >= 1 ? "Standard" : "Robotic"
        let region = voice.language.split(separator: "-").last.map(String.init) ?? voice.language
        return "\(quality) · \(region)"
    }
}

/// When MyClicky stays quiet (spec 007 US4): calls, screen sharing, Focus — or a manual override for one hour.
public struct QuietPolicy: Equatable, Sendable {
    public enum Reason: String, Sendable { case call, screenSharing, focus }

    public static func isQuiet(reasons: Set<Reason>, override: Settings.QuietOverride, now: Date = Date()) -> Bool {
        if let until = override.until, now > until { return !reasons.isEmpty } // expired → automatic
        switch override.mode {
        case .on: return true
        case .off: return false
        case .auto: return !reasons.isEmpty
        }
    }
}
