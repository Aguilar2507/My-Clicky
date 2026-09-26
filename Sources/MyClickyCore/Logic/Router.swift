import Foundation

/// Decides which path a request takes.
public enum Router {
    private static let agentPrefixes = ["hey agent", "ok agent", "okay agent", "clicky agent", "agent", "agente"]

    /// Whole words/phrases only, so "appointment" doesn't match "point" and a plain Spanish "como" stays on the
    /// cheap model. Only these go to the pricier pointing model.
    private static let pointingPattern = try! NSRegularExpression(
        pattern: #"\b(where|how (do|can|would|should) i|how to|show me|point (at|to|me)|find the|locate|click|"#
            + #"which (button|menu|icon|tab|option|setting)|dónde|donde|cómo (hago|puedo|le hago)|"#
            + #"como (hago|puedo|le hago)|muéstrame|muestrame|enséñame|ensename|señala|senala|clic|botón|boton|"#
            // 006: drawing requests also need the pointing model.
            + #"circle|draw|highlight|underline|encierra|dibuja|subraya|resalta)\b"#,
        options: [.caseInsensitive])

    /// If the request starts with "agent", returns the task without that word.
    public static func agentTask(_ text: String) -> String? {
        let lower = text.lowercased()
        for prefix in agentPrefixes where lower.hasPrefix(prefix) {
            let rest = text.dropFirst(prefix.count)
            // Must be a whole word ("agent, ..." not "agenda ...").
            if let next = rest.first, next.isLetter { continue }
            let task = rest.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespaces))
            return task.isEmpty ? nil : task
        }
        return nil
    }

    public static func wantsPointing(_ text: String) -> Bool {
        pointingPattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}
