import Foundation

/// Who you're talking to (spec 018, name changed in spec 020): "Jarvis…" is the cursor companion (Talk), "Jarvis
/// agent…" gives a task to an agent run by Claude Code. Recognized at the start of what you said, after an optional
/// greeting. The name is matched by sound, not spelling, so the ways English and Spanish speech recognition write it
/// ("Harvis", "Yarvis", "Jarbis", "jar vis", "Járvis") all count.
public enum WakeWords {
    public enum Target: Equatable, Sendable { case talk, agent }

    public struct Match: Equatable, Sendable {
        public let target: Target
        /// What you said after the wake words (may be empty while you're still talking).
        public let rest: String
    }

    public static let name = "Jarvis"
    /// Phrases both recognizers are told to expect, so they spell the name right more often.
    public static let hints = ["Jarvis", "Hey Jarvis", "Oye Jarvis", "Jarvis agent", "Jarvis agente"]

    private static let greetings: Set<String> = ["hey", "hi", "hello", "ok", "okay", "oye", "hola", "eh", "ey", "oiga"]
    private static let agentWords: Set<String> = ["agent", "agents", "agente", "agentes"]
    /// Real words that sound within one step of "Jarvis" but aren't it.
    private static let notTheName: Set<String> = ["harvest", "harvests", "harvested", "carvings", "parvis"]
    private static let nameKey = soundKey("jarvis")

    /// The wake words at the start of `text`, if any.
    public static func parse(_ text: String) -> Match? {
        scan(text).map { Match(target: $0.target, rest: $0.rest) }
    }

    /// True as soon as the live transcript starts with "Jarvis agent" (or "agent"), even before the task is said.
    public static func isAgentCall(_ partial: String) -> Bool {
        parse(partial)?.target == .agent
    }

    /// `text` with the name spelled "Jarvis" wherever it was heard as a variant at the start ("Harvis, …").
    public static func canonical(_ text: String) -> String {
        guard let found = scan(text), let range = found.nameRange else { return text }
        return text.replacingCharacters(in: range, with: name)
    }

    /// True if one word (or two run together) sounds like "Jarvis".
    public static func soundsLikeName(_ word: String) -> Bool {
        let letters = normalized(word)
        guard letters.count >= 4, !notTheName.contains(letters) else { return false }
        let key = soundKey(letters)
        // The v/b sound is what tells "Jarvis" from Harris, Charles, Paris…
        return key.contains("B") && distance(key, nameKey) <= 1
    }

    // MARK: Scanning

    private struct Found {
        let target: Target
        let rest: String
        let nameRange: Range<String.Index>?
    }

    private struct Token {
        let text: String
        let range: Range<String.Index>
        var word: String { normalized(text) }
    }

    private static let tokenPattern = try! NSRegularExpression(pattern: #"[\p{L}\p{M}']+"#)

    private static func tokens(_ text: String, limit: Int = 6) -> [Token] {
        let matches = tokenPattern.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.prefix(limit).compactMap { m in
            Range(m.range, in: text).map { Token(text: String(text[$0]), range: $0) }
        }
    }

    private static func scan(_ text: String) -> Found? {
        let words = tokens(text)
        // Only separators (spaces, punctuation) may come before the first word.
        guard let first = words.first,
              text[text.startIndex..<first.range.lowerBound].allSatisfy({ !$0.isLetter && !$0.isNumber }) else { return nil }
        var i = greetings.contains(first.word) && words.count > 1 ? 1 : 0

        var nameRange: Range<String.Index>?
        if soundsLikeName(words[i].word), !agentWords.contains(words[i].word) {
            nameRange = words[i].range
            i += 1
        } else if i + 1 < words.count, words[i].word.count <= 5, words[i + 1].word.count <= 5,
                  !agentWords.contains(words[i + 1].word), soundsLikeName(words[i].word + words[i + 1].word) {
            // "jar vis", "har bis": the name heard as two words.
            nameRange = words[i].range.lowerBound..<words[i + 1].range.upperBound
            i += 2
        }

        if i < words.count, agentWords.contains(words[i].word) {
            return Found(target: .agent, rest: rest(of: text, after: words[i].range.upperBound), nameRange: nameRange)
        }
        guard let nameRange else { return nil }
        return Found(target: .talk, rest: rest(of: text, after: nameRange.upperBound), nameRange: nameRange)
    }

    /// What follows the wake words, without the comma or period after them; the question's own "¿…?" is kept.
    private static func rest(of text: String, after index: String.Index) -> String {
        let separators = CharacterSet(charactersIn: ",.:;!?-").union(.whitespaces)
        return String(text[index...].drop { $0.unicodeScalars.allSatisfy(separators.contains) })
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: Sound matching

    /// Lowercase letters only, accents removed ("Járvis," → "jarvis").
    static func normalized(_ word: String) -> String {
        word.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased().filter(\.isLetter)
    }

    /// A rough sound spelling that treats English and Spanish look-alikes the same: j/h/y/ll/soft g/ch → H,
    /// v/b/w → B, s/z/x/soft c → S, c/k/q → K, vowels → A, I (e, i) or U (o, u). Repeats collapse.
    static func soundKey(_ word: String) -> String {
        let w = Array(normalized(word))
        var out: [Character] = []
        var i = 0
        while i < w.count {
            let c = w[i]
            let next: Character? = i + 1 < w.count ? w[i + 1] : nil
            let k: Character
            switch c {
            case "j", "h": k = "H"
            case "y": k = i == 0 ? "H" : "I"
            case "g": k = next == "e" || next == "i" ? "H" : "G"
            case "l" where next == "l": k = "H"; i += 1
            case "c" where next == "h": k = "H"; i += 1
            case "c": k = next == "e" || next == "i" || next == "y" ? "S" : "K"
            case "k", "q": k = "K"
            case "v", "b", "w": k = "B"
            case "s", "z", "x": k = "S"
            case "a": k = "A"
            case "e", "i": k = "I"
            case "o", "u": k = "U"
            default: k = Character(c.uppercased())
            }
            if out.last != k { out.append(k) }
            i += 1
        }
        return String(out)
    }

    /// Edit distance (insert, delete, replace one character).
    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var row = Array(0...b.count)
        for i in 1...a.count {
            var previous = row[0]
            row[0] = i
            for j in 1...b.count {
                let current = row[j]
                row[j] = min(row[j] + 1, row[j - 1] + 1, previous + (a[i - 1] == b[j - 1] ? 0 : 1))
                previous = current
            }
        }
        return row[b.count]
    }
}
