import Foundation

/// Decides which path a request takes.
public enum Router {
    /// Whole words/phrases only, so "appointment" doesn't match "point" and a plain Spanish "como" stays on the
    /// cheap model. Only these go to the pricier pointing model.
    private static let pointingPattern = try! NSRegularExpression(
        pattern: #"\b(where|how (do|can|would|should) i|how to|show me|point (at|to|me)|find the|locate|click|"#
            + #"which (button|menu|icon|tab|option|setting)|dónde|donde|cómo (hago|puedo|le hago)|"#
            + #"como (hago|puedo|le hago)|muéstrame|muestrame|enséñame|ensename|señala|senala|clic|botón|boton|"#
            // 006: drawing requests also need the pointing model.
            + #"circle|draw|highlight|underline|encierra|dibuja|subraya|resalta)\b"#,
        options: [.caseInsensitive])

    /// If the request starts with "Jarvis agent" or "agent" (spec 018 `WakeWords`), returns the task without them.
    public static func agentTask(_ text: String) -> String? {
        guard let match = WakeWords.parse(text), match.target == .agent, !match.rest.isEmpty else { return nil }
        return match.rest
    }

    /// A Talk question without a leading "Jarvis" ("Jarvis, what's this?" → "what's this?").
    public static func talkQuestion(_ text: String) -> String {
        guard let match = WakeWords.parse(text), match.target == .talk, !match.rest.isEmpty else { return text }
        return match.rest
    }

    public static func wantsPointing(_ text: String) -> Bool {
        pointingPattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}
