import Foundation

/// Which messages go with a new request, and which are old enough to fold into the memory summary (spec 005 US6).
/// Requests send the summary + the last 6 exchanges; exchanges beyond 12 unsummarized ones get folded.
public struct ContextWindow: Sendable {
    public static let recentExchanges = 6
    public static let foldThreshold = 12

    public struct Exchange: Equatable, Sendable {
        public let user: Message
        public let assistant: Message
    }

    public let summary: String
    public let recent: [Exchange]
    /// Exchanges to fold into the summary now (empty unless more than `foldThreshold` are unsummarized).
    public let toFold: [Exchange]

    public init(chat: Chat) {
        summary = chat.memorySummary
        var exchanges: [Exchange] = []
        var pendingUser: Message?
        var afterSummary = chat.summarizedThroughID == nil
        var unsummarized: [Exchange] = []
        for message in chat.messages {
            switch message.role {
            case .user: pendingUser = message
            case .assistant:
                if let user = pendingUser {
                    let exchange = Exchange(user: user, assistant: message)
                    exchanges.append(exchange)
                    if afterSummary { unsummarized.append(exchange) }
                }
                pendingUser = nil
            case .system: break
            }
            if message.id == chat.summarizedThroughID { afterSummary = true }
        }
        recent = Array(exchanges.suffix(Self.recentExchanges))
        toFold = unsummarized.count > Self.foldThreshold ? Array(unsummarized.dropLast(Self.recentExchanges)) : []
    }
}
