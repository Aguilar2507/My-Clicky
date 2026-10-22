import Foundation

/// Chat search (spec 005 US5): case- and accent-insensitive, with a snippet around the first hit.
public enum SearchIndex {
    public static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    public struct Hit: Equatable, Sendable {
        public let chatID: UUID
        public let snippet: String
    }

    /// nil = no match. Title matches use the latest message as the snippet.
    public static func search(_ query: String, in chat: Chat) -> Hit? {
        let q = fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !q.isEmpty else { return Hit(chatID: chat.id, snippet: chat.preview) }
        if fold(chat.title).contains(q) { return Hit(chatID: chat.id, snippet: chat.preview) }
        for message in chat.messages.reversed() {
            let folded = fold(message.text)
            if let range = folded.range(of: q) {
                return Hit(chatID: chat.id, snippet: snippet(message.text, folded: folded, hit: range))
            }
        }
        return nil
    }

    static func snippet(_ original: String, folded: String, hit: Range<String.Index>) -> String {
        // Folding keeps character counts for Latin text, so offsets map back to the original.
        let start = folded.distance(from: folded.startIndex, to: hit.lowerBound)
        let chars = Array(original)
        guard start < chars.count else { return original }
        let from = max(0, start - 40), to = min(chars.count, start + 40 + folded.distance(from: hit.lowerBound, to: hit.upperBound))
        return (from > 0 ? "…" : "") + String(chars[from..<to]) + (to < chars.count ? "…" : "")
    }
}

/// Parses the Clicky naming reply {"name": "...", "color": "..."} and keeps names unique (spec 005 R4).
public enum NamingParser {
    public static func parse(_ reply: String) -> (name: String, color: AvatarColor?)? {
        guard let start = reply.firstIndex(of: "{"), let end = reply.lastIndex(of: "}"),
              let data = String(reply[start...end]).data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawName = json["name"] as? String else { return nil }
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let words = name.split(separator: " ")
        // Asked for 1-3 words; a fourth ("PC History Deep Diver") is still a fine name, better than "New agent 3".
        guard !name.isEmpty, words.count <= 4, name.count <= 32 else { return nil }
        return (name, (json["color"] as? String).flatMap(AvatarColor.init(rawValue:)))
    }

    /// "Research Buddy" → "Research Buddy 2" if taken (case-insensitive).
    public static func unique(_ name: String, existing: [String]) -> String {
        let taken = Set(existing.map(SearchIndex.fold))
        guard taken.contains(SearchIndex.fold(name)) else { return name }
        var n = 2
        while taken.contains(SearchIndex.fold("\(name) \(n)")) { n += 1 }
        return "\(name) \(n)"
    }

    public static func fallbackName(existing: [String]) -> String {
        unique("New agent", existing: existing)
    }
}
