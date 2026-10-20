import Foundation

/// The language a request was made in, so the reply stays in it (spec 020): the speech recognizer's winning language
/// for voice, a text guess for typed requests, else the last request's language, else the dictation language.
public enum ReplyLanguage {
    public static let supported = ["en", "es"]

    public static func resolve(spoken: String?, guessed: String?, previous: String?, fallback: String) -> String {
        for candidate in [spoken, guessed, previous] {
            if let candidate, supported.contains(candidate) { return candidate }
        }
        return supported.contains(fallback) ? fallback : "en"
    }

    /// One line added to the request (outside the cached system prompt) so screenshots or earlier messages in the
    /// other language can't pull the reply over.
    public static func instruction(_ code: String) -> String {
        code == "es"
            ? "The user spoke Spanish. Reply only in Spanish, even if the screen or earlier messages are in English."
            : "The user spoke English. Reply only in English, even if the screen or earlier messages are in Spanish."
    }

    /// Short spoken lines about agent tasks, in the language of the request.
    public enum Line: Equatable, Sendable {
        case onIt(String)
        case finished(String)
        case paused(String, steps: Int)
        case problem(String)
        case stopped(String)
    }

    public static func text(_ line: Line, _ code: String) -> String {
        let es = code == "es"
        switch line {
        case .onIt(let name): return es ? "\(name) está en ello." : "\(name) is on it."
        case .finished(let name): return es ? "\(name) terminó." : "\(name) finished."
        case .paused(let name, let steps):
            return es ? "\(name) se detuvo después de \(steps) pasos. Continúa desde su chat."
                      : "\(name) paused after \(steps) steps. Keep going from its chat."
        case .problem(let name): return es ? "\(name) tuvo un problema." : "\(name) ran into a problem."
        case .stopped(let name): return es ? "\(name) se detuvo inesperadamente." : "\(name) stopped unexpectedly."
        }
    }
}
