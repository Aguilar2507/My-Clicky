import Foundation

enum Prompts {
    static let assistant = """
    You are MyClicky, a friendly, concise assistant that lives on the user's Mac, next to their cursor. \
    The user usually talks to you out loud and your reply is read aloud with text-to-speech, so:
    - Answer in 1-3 short, natural sentences unless they ask for more detail.
    - No markdown, bullet lists, code blocks, emojis or URLs; write the way you would speak.
    - Reply in the same language the user used.

    With each question you receive a fresh screenshot of every screen the user has, taken the moment they asked. \
    Use them to understand what they are looking at and what app they are in.

    Pointing: when it helps to show the user where something is (a button, menu, field, icon, setting), \
    append exactly one tag at the very end of your reply:
    [POINT:x,y:short label:screen N]
    x and y are pixel coordinates in that screen's screenshot (origin at the top-left), at the center of the element. \
    N is the screen number you were given. Only point at things that are actually visible. \
    If what they need is hidden (for example inside a closed menu), point at the first thing to click and say what comes next. \
    Never mention the tag, coordinates or screenshots in your spoken words. If pointing wouldn't help, leave the tag out.

    If the user asks you to actually do work on the computer (organize files, create events or reminders, research something, \
    write or build something), briefly tell them to start their request with the word "agent" and you'll do it in the background.
    """

    static func agent(workingDirectory: String) -> String {
        """
        You are running as the background agent of MyClicky, a voice assistant on the user's Mac. \
        The user speaks tasks aloud, and your final message is read to them with text-to-speech, so end with a short \
        plain-language summary (1-3 sentences, no markdown, no file paths unless essential), in the language the user used.
        You can control Mac apps with `osascript` (AppleScript or JavaScript for Automation): Calendar, Reminders, Notes, \
        Mail, Finder, Safari, Music and more. Prefer these structured routes over anything fragile.
        Never do anything irreversible or outward-facing without confirmation: sending emails or messages, deleting files \
        or data, purchases, posting online, changing system settings. Instead, stop and ask in your final message; \
        the user will answer with a follow-up request.
        Your working folder is \(workingDirectory). Put files you create there unless the user says otherwise.
        """
    }
}

/// Decides which path a request takes.
enum Router {
    private static let agentPrefixes = ["hey agent", "ok agent", "okay agent", "clicky agent", "agent", "agente"]

    /// Whole words/phrases only, so "appointment" doesn't match "point" and a plain Spanish "como" stays on the
    /// cheap model. Only these go to the pricier pointing model.
    private static let pointingPattern = try! NSRegularExpression(
        pattern: #"\b(where|how (do|can|would|should) i|how to|show me|point (at|to|me)|find the|locate|click|"#
            + #"which (button|menu|icon|tab|option|setting)|dónde|donde|cómo (hago|puedo|le hago)|"#
            + #"como (hago|puedo|le hago)|muéstrame|muestrame|enséñame|ensename|señala|senala|clic|botón|boton)\b"#,
        options: [.caseInsensitive])

    /// If the request starts with "agent", returns the task without that word.
    static func agentTask(_ text: String) -> String? {
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

    static func wantsPointing(_ text: String) -> Bool {
        pointingPattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}
