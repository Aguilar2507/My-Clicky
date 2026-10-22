import Foundation

/// Turns an agent's tool request into plain words for the Allow card, and flags sensitive actions
/// (spec 009 FR-004/FR-005, research R4).
public enum PermissionDescriber {
    public struct Description: Equatable, Sendable {
        public let text: String          // "Run a command"
        public let detail: String?       // "ls ~/Desktop"
        public let sensitive: Bool       // always needs a fresh Allow
        public let rule: String          // key for "Always allow for this agent"
        public let isComputerUse: Bool
    }

    public static let computerTools: Set<String> = ["screenshot", "click", "type", "key", "scroll", "move"]

    public static func describe(tool: String, input: [String: String]) -> Description {
        if tool.hasPrefix("mcp__myclicky__") {
            let action = String(tool.dropFirst("mcp__myclicky__".count))
            let text: String
            switch action {
            case "screenshot": text = "Look at your screen"
            case "click": text = "Click on your screen"
            case "type": text = "Type on your Mac"
            case "key": text = "Press keys on your Mac"
            case "scroll": text = "Scroll on your screen"
            default: text = "Move the pointer"
            }
            let detail = action == "type" ? input["text"] : action == "key" ? input["combo"] : nil
            return Description(text: text, detail: detail, sensitive: false, rule: "computer", isComputerUse: true)
        }
        if tool.hasPrefix("mcp__") {
            let parts = tool.split(separator: "_", omittingEmptySubsequences: true)
            let server = parts.count > 1 ? String(parts[1]).replacingOccurrences(of: "myclicky-", with: "") : "an app"
            let action = parts.count > 2 ? parts[2...].joined(separator: " ") : "an action"
            let sensitive = ["create", "update", "delete", "post", "send", "publish", "merge", "comment", "write"]
                .contains { action.lowercased().contains($0) }
            return Description(text: "Use \(appName(server)): \(action)", detail: input.isEmpty ? nil : compact(input),
                               sensitive: sensitive, rule: tool, isComputerUse: false)
        }
        switch tool {
        case "Bash":
            let command = input["command"] ?? ""
            let first = command.split(separator: " ").first.map(String.init) ?? command
            return Description(text: "Run a command", detail: command, sensitive: isSensitive(command: command),
                               rule: "Bash(\(first):*)", isComputerUse: false)
        case "Write", "Edit", "MultiEdit", "NotebookEdit":
            let path = input["file_path"] ?? input["notebook_path"] ?? ""
            return Description(text: tool == "Write" ? "Create or replace a file" : "Change a file", detail: path,
                               sensitive: false, rule: "Edit", isComputerUse: false)
        case "WebFetch":
            return Description(text: "Open a web page", detail: input["url"], sensitive: false, rule: "WebFetch", isComputerUse: false)
        case "WebSearch":
            return Description(text: "Search the web", detail: input["query"], sensitive: false, rule: "WebSearch", isComputerUse: false)
        case "Read", "Glob", "Grep":
            return Description(text: "Read files", detail: input["file_path"] ?? input["path"] ?? input["pattern"],
                               sensitive: false, rule: "Read", isComputerUse: false)
        default:
            return Description(text: "Use \(tool)", detail: input.isEmpty ? nil : compact(input), sensitive: false,
                               rule: tool, isComputerUse: false)
        }
    }

    /// Commands that delete, send, publish, buy or change the system always need a fresh confirmation.
    public static func isSensitive(command: String) -> Bool {
        let patterns = [
            #"(^|[;&|\s])rm\s"#, #"(^|[;&|\s])rmdir\s"#, #"(^|[;&|\s])sudo\s"#, #"mv\s.*\s/dev/null"#, #"git\s+push"#,
            #"git\s+reset\s+--hard"#, #"defaults\s+write"#, #"curl\s.*-X\s*(POST|PUT|DELETE|PATCH)"#,
            #"curl\s.*(--data|-d\s)"#, #"osascript.*\bsend\b"#, #"osascript.*\bdelete\b"#, #"(^|[;&|\s])shutdown\b"#,
            #"(^|[;&|\s])killall\s"#, #"diskutil\s+erase"#, #">\s*/etc/"#, #"launchctl\s"#,
        ]
        return patterns.contains { command.range(of: $0, options: [.regularExpression, .caseInsensitive]) != nil }
    }

    /// Whether a request is covered by "Always allow for this agent" (never for sensitive ones).
    public static func isPreApproved(_ description: Description, rules: [String]) -> Bool {
        !description.sensitive && rules.contains(description.rule)
    }

    /// Short, human-ish step summary for the chat ("Searching the web: ai news").
    public static func stepSummary(tool: String, input: [String: String]) -> String {
        switch tool {
        case "WebSearch": return "Searching the web" + (input["query"].map { ": \($0)" } ?? "")
        case "WebFetch": return "Reading " + (input["url"].flatMap { URL(string: $0)?.host } ?? "a web page")
        case "Read": return "Reading " + (input["file_path"].map { ($0 as NSString).lastPathComponent } ?? "a file")
        case "Write": return "Writing " + (input["file_path"].map { ($0 as NSString).lastPathComponent } ?? "a file")
        case "Edit", "MultiEdit": return "Editing " + (input["file_path"].map { ($0 as NSString).lastPathComponent } ?? "a file")
        case "Glob", "Grep": return "Looking through files"
        case "Bash": return "Running " + String((input["command"] ?? "a command").prefix(60))
        case "TodoWrite": return "Planning the next steps"
        default: return describe(tool: tool, input: input).text
        }
    }

    static func compact(_ input: [String: String]) -> String {
        input.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: ", ").prefix(160).description
    }

    /// The catalog's spelling for its servers ("GitHub", not "Github"); others are capitalized.
    static func appName(_ server: String) -> String {
        let names = ["github": "GitHub", "notion": "Notion", "linear": "Linear", "atlassian": "Jira & Confluence",
                     "asana": "Asana", "sentry": "Sentry", "myclicky": "MyClicky"]
        return names[server.lowercased()] ?? server.capitalized
    }
}
