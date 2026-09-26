import Foundation

/// One recognizer's final result (spec 008 data model).
public struct RecognitionResult: Equatable, Sendable {
    public let languageCode: String      // "en" / "es"
    public let text: String
    public let segmentConfidences: [Float]

    public init(languageCode: String, text: String, segmentConfidences: [Float]) {
        self.languageCode = languageCode
        self.text = text
        self.segmentConfidences = segmentConfidences
    }

    public var meanConfidence: Float {
        segmentConfidences.isEmpty ? 0 : segmentConfidences.reduce(0, +) / Float(segmentConfidences.count)
    }
}

/// Auto-detect between English and Spanish (spec 008 research R2): the result the recognizer was more confident
/// about wins; when it's close (< 0.1 apart), `tieBreak` (a language guess from the text) decides.
public enum LanguagePicker {
    public static func pick(_ results: [RecognitionResult], default preferred: String,
                            tieBreak: (String) -> String? = { _ in nil }) -> RecognitionResult? {
        let candidates = results.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !candidates.isEmpty else { return nil }
        guard candidates.count > 1 else { return candidates[0] }
        let sorted = candidates.sorted { $0.meanConfidence > $1.meanConfidence }
        if sorted[0].meanConfidence - sorted[1].meanConfidence >= 0.1 { return sorted[0] }
        let votes = candidates.compactMap { result in tieBreak(result.text).map { ($0, result) } }
        if let agreed = votes.first(where: { $0.0 == $0.1.languageCode })?.1 { return agreed }
        return candidates.first { $0.languageCode == preferred } ?? sorted[0]
    }

    /// Which recognizers to run for the settings: one language, or English + Spanish when auto-detecting.
    public static func locales(autoDetect: Bool, language: String, spanishLocale: String) -> [String] {
        let english = "en-US"
        if autoDetect { return language == "es" ? [spanishLocale, english] : [english, spanishLocale] }
        return [language == "es" ? spanishLocale : english]
    }
}

/// "Words MyClicky should spell right": forces exact spelling of whole words, ignoring case and accents.
public enum CustomWords {
    public static func apply(_ words: [String], to text: String) -> String {
        var result = text
        for word in words.sorted(by: { $0.count > $1.count }) where !word.isEmpty {
            let escaped = NSRegularExpression.escapedPattern(for: word)
            guard let regex = try? NSRegularExpression(pattern: "(?<![\\p{L}\\p{N}])\(escaped)(?![\\p{L}\\p{N}])",
                                                       options: [.caseInsensitive]) else { continue }
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range,
                                                    withTemplate: NSRegularExpression.escapedTemplate(for: word))
        }
        return result
    }

    /// Trimmed, unique (case-insensitive), at most 200.
    public static func normalized(_ words: [String]) -> [String] {
        var seen = Set<String>()
        return words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
            .prefix(200).map { $0 }
    }
}

/// Whether dictated text needs a leading space where it's inserted (spec 008 research R5).
public enum SpacingRule {
    public static func needsLeadingSpace(before text: String, previousCharacter: Character?) -> Bool {
        guard let previous = previousCharacter, let first = text.first else { return false }
        if previous.isWhitespace || previous.isNewline { return false }
        if "([{\"'“‘¿¡/".contains(previous) { return false }
        if first.isPunctuation && !"¿¡(\"“".contains(first) { return false }
        return true
    }
}
