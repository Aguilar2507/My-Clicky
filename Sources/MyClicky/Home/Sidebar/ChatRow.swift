import SwiftUI
import MyClickyCore

/// One sidebar row (ref 02): unread dot, avatar, bold name, time, one-line preview, inset divider.
struct ChatRow: View {
    let chat: Chat
    var snippet: String?
    var isSelected: Bool
    var isWorking: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Circle().fill(chat.isUnread ? Theme.unreadBlue : .clear).frame(width: 9, height: 9).frame(width: 18)
                ChatAvatar(chat: chat, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(chat.title).font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.textPrimary).lineLimit(1).layoutPriority(1)
                        Spacer(minLength: 6)
                        if isWorking {
                            ActivityDots()
                        } else if !chat.messages.isEmpty {
                            Text(RelativeTime.format(chat.updatedAt)).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                                .lineLimit(1).fixedSize()
                        }
                    }
                    Text(snippet ?? previewText).font(.system(size: 14)).foregroundStyle(Theme.previewText).lineLimit(1)
                }
                .padding(.leading, 11)
                .padding(.trailing, 10)
                .frame(height: 58)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 1) }
            }
            .padding(.vertical, 1)
            .background(isSelected ? Theme.rowSelected : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var previewText: String {
        if chat.kind == .talk && chat.messages.isEmpty { return "Ask about anything on your screen" }
        if chat.messages.isEmpty { return chat.purpose.isEmpty ? "What should this Clicky do?" : chat.purpose }
        return chat.preview.replacingOccurrences(of: "\n", with: " ")
    }
}
