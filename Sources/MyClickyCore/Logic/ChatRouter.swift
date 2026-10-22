import Foundation

/// Decides where a request goes (spec 005, research R5): Talk, an existing agent, or a new agent.
public enum ChatRouter {
    public enum Route: Equatable, Sendable {
        case talk(String)
        case agent(UUID, String)
        case newAgent(String)
    }

    public struct AgentRef: Sendable {
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

    public static func route(_ text: String, agents: [AgentRef], now: Date = Date()) -> Route {
        guard let task = Router.agentTask(text) else { return .talk(Router.talkQuestion(text)) }
        if let named = namedAgent(in: task, agents: agents) { return .agent(named.id, named.task) }
        if let recent = agents.filter({ ($0.lastAgentUseAt.map { now.timeIntervalSince($0) } ?? .infinity) < continuationWindow })
            .max(by: { $0.lastAgentUseAt! < $1.lastAgentUseAt! }) {
            return .agent(recent.id, task)
        }
        return .newAgent(task)
    }

    /// "ask Research Buddy to add sources", "tell Role Scout to…", "Research Buddy, add…", "pídele a Role Scout que…"
    static func namedAgent(in task: String, agents: [AgentRef]) -> (id: UUID, task: String)? {
        let folded = SearchIndex.fold(task)
        for agent in agents.sorted(by: { $0.title.count > $1.title.count }) {
            let name = SearchIndex.fold(agent.title)
            guard !name.isEmpty else { continue }
            let patterns = ["ask \(name) to ", "tell \(name) to ", "\(name), ", "\(name) ",
                            "pidele a \(name) que ", "dile a \(name) que ", "\(name) que "]
            for pattern in patterns where folded.hasPrefix(pattern) {
                let rest = String(task.dropFirst(pattern.count)).trimmingCharacters(in: .whitespaces)
                return (agent.id, rest.isEmpty ? task : rest)
            }
        }
        return nil
    }
}
