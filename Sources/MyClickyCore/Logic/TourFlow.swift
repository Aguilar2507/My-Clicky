import Foundation

/// The welcome tour's steps and rules (spec 012 data model): resumable, skippable where allowed, replayable.
public struct TourState: Codable, Equatable, Sendable {
    public enum Step: String, Codable, CaseIterable, Sendable {
        case intro, name, permissions, apiKey, claudeCode, handsOn, interview, done
    }

    public var version = 1
    public var step: Step = .intro
    public var completed: [Step] = []
    public var finished = false

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = c.value(.version, default: 1)
        step = c.value(.step, default: .intro)
        completed = c.value(.completed, default: [])
        finished = c.value(.finished, default: false)
    }
}

public enum TourFlow {
    /// Steps that can't be skipped: the API key must work (FR-003). Permissions can be skipped with a warning.
    public static let unskippable: Set<TourState.Step> = [.apiKey]

    public static func next(_ state: TourState, completing: Bool) -> TourState {
        var s = state
        if completing, !s.completed.contains(s.step) { s.completed.append(s.step) }
        let all = TourState.Step.allCases
        if let index = all.firstIndex(of: s.step), index + 1 < all.count { s.step = all[index + 1] }
        if s.step == .done {
            s.finished = true
            if !s.completed.contains(.done) { s.completed.append(.done) }
        }
        return s
    }

    public static func back(_ state: TourState) -> TourState {
        var s = state
        let all = TourState.Step.allCases
        if let index = all.firstIndex(of: s.step), index > 0 { s.step = all[index - 1] }
        return s
    }

    public static func canSkip(_ step: TourState.Step) -> Bool {
        !unskippable.contains(step) && step != .done && step != .intro
    }

    /// Replay starts at the intro and keeps what's already complete (✓ shown, one click to skip).
    public static func replay(_ state: TourState) -> TourState {
        var s = state
        s.step = .intro
        s.finished = false
        return s
    }

    /// Upgrading users who already have a working key and permissions aren't forced through the tour (spec 012 T001).
    public static func initial(hasAPIKey: Bool, allPermissionsGranted: Bool, existing: TourState) -> TourState {
        guard !existing.finished, existing.completed.isEmpty, hasAPIKey, allPermissionsGranted else { return existing }
        var s = existing
        s.finished = true
        s.step = .done
        return s
    }

    public static func progress(_ state: TourState) -> (index: Int, total: Int) {
        let all = TourState.Step.allCases
        return ((all.firstIndex(of: state.step) ?? 0), all.count)
    }
}

/// Parses the interview reply into three agents (spec 012 US3), with generic starters as the fallback.
public enum InterviewParser {
    public struct NewAgent: Equatable, Sendable {
        public let name: String
        public let color: AvatarColor
        public let purpose: String
    }

    public static let starters: [NewAgent] = [
        NewAgent(name: "Research Buddy", color: .mint, purpose: "Researches topics you ask about and writes short summaries with sources."),
        NewAgent(name: "Build Lab", color: .butter, purpose: "Plans and scopes projects step by step and keeps a to-do list."),
        NewAgent(name: "Inbox Helper", color: .sky, purpose: "Drafts replies and to-dos from the messages you share, and asks before sending anything."),
    ]

    /// Exactly three agents with unique names (against `existing` and each other); missing ones come from the starters.
    public static func parse(_ reply: String, existing: [String]) -> (agents: [NewAgent], usedFallback: Bool) {
        var parsed: [NewAgent] = []
        if let start = reply.firstIndex(of: "{"), let end = reply.lastIndex(of: "}"),
           let data = String(reply[start...end]).data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let items = json["clickys"] as? [[String: Any]] {
            for item in items {
                guard let rawName = item["name"] as? String, let purpose = (item["purpose"] as? String)?
                        .trimmingCharacters(in: .whitespacesAndNewlines), !purpose.isEmpty,
                      let naming = NamingParser.parse(#"{"name": "\#(rawName.replacingOccurrences(of: "\"", with: ""))"}"#) else { continue }
                let color = (item["color"] as? String).flatMap(AvatarColor.init(rawValue:)) ?? .next(avoiding: parsed.map(\.color))
                parsed.append(NewAgent(name: naming.name, color: color, purpose: purpose))
            }
        }
        let usedFallback = parsed.count < 3
        for starter in starters where parsed.count < 3 {
            parsed.append(starter)
        }
        var taken = existing
        let unique = parsed.prefix(3).map { agent -> NewAgent in
            let name = NamingParser.unique(agent.name, existing: taken)
            taken.append(name)
            return NewAgent(name: name, color: agent.color, purpose: agent.purpose)
        }
        return (Array(unique), usedFallback)
    }
}
