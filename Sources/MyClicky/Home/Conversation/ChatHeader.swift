import SwiftUI
import MyClickyCore

/// Top of an open chat: avatar, name, status, and the ⋯ menu (rename, color, delete / clear).
struct ChatHeader: View {
    @Environment(AppModel.self) private var model
    let chat: Chat
    var onRename: () -> Void
    var onDelete: () -> Void

    /// Extra header controls from later features (Stop for running agents, spec 009).
    static var trailing: ((Chat, AppModel) -> AnyView)?

    var body: some View {
        HStack(spacing: 12) {
            ChatAvatar(chat: chat, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(chat.title).textStyle(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary).lineLimit(1)
                Text(status).textStyle(.footnote).foregroundStyle(Theme.textSecondary).lineLimit(1)
            }
            Spacer()
            if let trailing = Self.trailing { trailing(chat, model) }
            Menu {
                if chat.kind == .clicky {
                    Button("Rename…", action: onRename)
                    Menu("Change color") {
                        ForEach(AvatarColor.allCases, id: \.self) { color in
                            Button(color.rawValue.capitalized) { model.recolor(chat.id, to: color) }
                        }
                    }
                    Divider()
                    Button("Delete…", role: .destructive, action: onDelete)
                } else {
                    Button("Clear history…", action: onDelete)
                }
            } label: {
                Image(systemName: "ellipsis").font(.icon(17, .semibold)).foregroundStyle(Theme.icon)
                    .frame(width: 34, height: 34)
                    .background(Theme.card, in: Circle())
            }
            .menuStyle(.button)
            .menuIndicator(.hidden)
            .buttonStyle(.plain)
            .fixedSize()
        }
        .padding(.leading, 28)
        .padding(.trailing, 28)
        .frame(maxWidth: Theme.Layout.conversationColumn)
        .frame(maxWidth: .infinity) // same column as the messages (spec 017)
        .padding(.top, 22)
        .padding(.bottom, 12)
    }

    private var status: String {
        if model.workingChatIDs.contains(chat.id) { return "Working…" }
        if chat.kind == .talk { return "Questions about your screen" }
        return chat.purpose.isEmpty ? "Agent" : chat.purpose.replacingOccurrences(of: "\n", with: " ")
    }
}
