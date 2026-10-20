import SwiftUI
import MyClickyCore

/// A message in an open chat: yours on the right in a soft bubble, the Clicky's on the left beside its avatar.
struct MessageBubble: View {
    let message: Message
    let chat: Chat

    /// Custom renderers from later features (agent steps and Allow cards, spec 009). Return nil to use the default.
    static var custom: ((Message, Chat) -> AnyView?)?

    var body: some View {
        if let custom = Self.custom?(message, chat) {
            custom
        } else {
            switch message.role {
            case .user:
                HStack {
                    Spacer(minLength: 120)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(message.text).textStyle(.callout).foregroundStyle(.white).textSelection(.enabled)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Theme.userBubble, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        note
                    }
                }
            case .assistant:
                HStack(alignment: .top, spacing: 10) {
                    ChatAvatar(chat: chat, size: 26)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.text).textStyle(.callout).foregroundStyle(Theme.textPrimary).textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        note
                    }
                    Spacer(minLength: 80)
                }
            case .system:
                Text(message.text).textStyle(.footnote).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var note: some View {
        let parts = [message.via == .voice ? "Voice" : nil,
                     message.screensSeen > 0 ? "Looked at \(message.screensSeen) screen\(message.screensSeen == 1 ? "" : "s")" : nil,
                     message.createdAt.formatted(date: .omitted, time: .shortened)].compactMap { $0 }
        Text(parts.joined(separator: " · ")).textStyle(.caption).foregroundStyle(Theme.textTertiary)
    }
}
