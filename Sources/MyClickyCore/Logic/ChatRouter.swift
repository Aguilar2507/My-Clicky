import Foundation

/// Decides where a request goes (spec 005, research R5): Talk, an existing Clicky, or a new Clicky.
public enum ChatRouter {
    public enum Route: Equatable, Sendable {
        case talk(String)
        case clicky(UUID, String)
        case newClicky(String)
    }

    public struct ClickyRef: Sendable {
        public let id: UUID
        public let title: String
        public let lastAgentUseAt: Date?
        public init(id: UUID, title: String, lastAgentUseAt: Date?) {
            self.id = id
            self.title = title
            self.lastAgentUseAt = lastAgentUseAt
        }
    }

    public static let continuationWindow: TimeInterval = 15 * 60

    public static func route(_ text: String, clickys: [ClickyRef], now: Date = Date()) -> Route {
        guard let task = Router.agentTask(text) else { return .talk(Router.talkQuestion(text)) }
        if let named = namedClicky(in: task, clickys: clickys) { return .clicky(named.id, named.task) }
        if let recent = clickys.filter({ ($0.lastAgentUseAt.map { now.timeIntervalSince($0) } ?? .infinity) < continuationWindow })
            .max(by: { $0.lastAgentUseAt! < $1.lastAgentUseAt! }) {
            return .clicky(recent.id, task)
        }
        return .newClicky(task)
    }

    /// "ask Research Buddy to add sources", "tell Role Scout to…", "Research Buddy, add…", "pídele a Role Scout que…"
    static func namedClicky(in task: String, clickys: [ClickyRef]) -> (id: UUID, task: String)? {
        let folded = SearchIndex.fold(task)
        for clicky in clickys.sorted(by: { $0.title.count > $1.title.count }) {
            let name = SearchIndex.fold(clicky.title)
            guard !name.isEmpty else { continue }
            let patterns = ["ask \(name) to ", "tell \(name) to ", "\(name), ", "\(name) ",
                            "pidele a \(name) que ", "dile a \(name) que ", "\(name) que "]
            for pattern in patterns where folded.hasPrefix(pattern) {
                let rest = String(task.dropFirst(pattern.count)).trimmingCharacters(in: .whitespaces)
                return (clicky.id, rest.isEmpty ? task : rest)
            }
        }
        return nil
    }
}
