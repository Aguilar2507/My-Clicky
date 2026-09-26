import Foundation

/// Cuts streaming text into sentences so speech can start before the answer is complete (spec 007, research R2).
/// Doesn't split on abbreviations ("e.g.", "Sr."), decimals ("3.5") or versions ("v2.1").
public struct SentenceSplitter: Sendable {
    public static let abbreviations: Set<String> = [
        "e.g", "i.e", "mr", "mrs", "ms", "dr", "vs", "etc", "st", "jr", "sr", "sra", "srta", "ud", "uds", "p.ej", "ej",
        "no", "approx", "min", "max", "fig", "cf", "inc", "ltd", "co", "p", "pág", "aprox",
    ]
    /// The very first chunk may be flushed at a comma after this many characters, to start speaking sooner.
    public static let earlyCommaLength = 60

    private var buffer = ""
    private var emittedAny = false

    public init() {}

    /// Adds text; returns any sentences that are now complete.
    public mutating func append(_ text: String) -> [String] {
        buffer += text
        var sentences: [String] = []
        while let cut = nextBoundary() {
            let sentence = String(buffer[..<cut]).trimmingCharacters(in: .whitespacesAndNewlines)
            buffer = String(buffer[cut...])
            if !sentence.isEmpty {
                sentences.append(sentence)
                emittedAny = true
            }
        }
        return sentences
    }

    /// The rest when the stream ends.
    public mutating func finish() -> String? {
        let rest = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        buffer = ""
        return rest.isEmpty ? nil : rest
    }

    /// Index just after a sentence end that is followed by whitespace (so we know it's really over).
    private func nextBoundary() -> String.Index? {
        let chars = Array(buffer)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == "\n" { return buffer.index(buffer.startIndex, offsetBy: i + 1) }
            if ".!?…".contains(c) {
                // Include closing quotes/brackets and repeated marks ("?!", "...").
                var end = i + 1
                while end < chars.count, ".!?…\"'”’)]".contains(chars[end]) { end += 1 }
                guard end < chars.count else { return nil } // need to see what follows
                if chars[end].isWhitespace && !isFalseStop(chars, at: i) {
                    return buffer.index(buffer.startIndex, offsetBy: end)
                }
                i = end
                continue
            }
            if c == ",", !emittedAny, i >= Self.earlyCommaLength, i + 1 < chars.count, chars[i + 1].isWhitespace {
                return buffer.index(buffer.startIndex, offsetBy: i + 1)
            }
            i += 1
        }
        return nil
    }

    private func isFalseStop(_ chars: [Character], at i: Int) -> Bool {
        guard chars[i] == "." else { return false }
        // Decimal or version: digit before and digit after ("3.5", "v2.1").
        if i > 0, chars[i - 1].isNumber, i + 1 < chars.count, chars[i + 1].isNumber { return true }
        // Abbreviation: the word before the dot.
        var start = i
        while start > 0, chars[start - 1].isLetter || chars[start - 1] == "." { start -= 1 }
        let word = String(chars[start..<i]).lowercased()
        return Self.abbreviations.contains(word)
    }
}
