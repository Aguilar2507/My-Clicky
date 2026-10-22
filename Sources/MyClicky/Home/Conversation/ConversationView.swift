import SwiftUI
import MyClickyCore

/// An open chat: header, messages (newest 50 first, older ones load as you scroll up), composer.
struct ConversationView: View {
    @Environment(AppModel.self) private var model
    let chatID: UUID
    @StateObject private var shown = Box(50)
    @StateObject private var renaming = Box(false)
    @StateObject private var confirmingDelete = Box(false)

    var body: some View {
        if let chat = model.chat(chatID) {
            VStack(spacing: 0) {
                ChatHeader(chat: chat, onRename: { renaming.value = true }, onDelete: { confirmingDelete.value = true })
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            let messages = Array(chat.messages.suffix(shown.value))
                            if chat.messages.count > shown.value {
                                ProgressView().controlSize(.small).frame(maxWidth: .infinity)
                                    .onAppear { shown.value += 50 }
                            }
                            if messages.isEmpty { emptyHint(chat) }
                            ForEach(Self.group(messages), id: \.id) { item in
                                switch item {
                                case .message(let message): MessageBubble(message: message, chat: chat).id(message.id)
                                case .steps(let steps): StepGroupView(steps: steps).id(steps.last!.id)
                                }
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .frame(maxWidth: Theme.Layout.conversationColumn)
                        .frame(maxWidth: .infinity) // a centered reading column at any width (spec 017)
                    }
                    .scrollIndicators(.never)
                    .scrollEdgeFade(top: 14, bottom: 14)
                    .onAppear { scrollToEnd(proxy, chat) }
                    .onChange(of: chat.messages.count) { Motion.withAnimation { scrollToEnd(proxy, chat) } }
                }
                Composer(chat: chat) { text in AppServices.shared?.assistant.send(text, toChat: chatID) }
            }
            .onAppear { model.markRead(chatID) }
            .modalOverlay([renaming.value, confirmingDelete.value]) {
                if renaming.value { RenameCard(chat: chat) { renaming.value = false } }
                if confirmingDelete.value { deleteCard(chat) }
            }
        }
    }

    enum Item {
        case message(Message)
        case steps([Message])
        var id: UUID {
            switch self {
            case .message(let m): m.id
            case .steps(let s): s.first!.id
            }
        }
    }

    /// Consecutive agent steps collapse into one "N steps" group (contracts/ui-agents.md).
    static func group(_ messages: [Message]) -> [Item] {
        var items: [Item] = []
        var run: [Message] = []
        func flush() {
            if run.count == 1 { items.append(.message(run[0])) } else if run.count > 1 { items.append(.steps(run)) }
            run = []
        }
        for message in messages {
            if message.kind == .step { run.append(message) } else { flush(); items.append(.message(message)) }
        }
        flush()
        return items
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy, _ chat: Chat) {
        if let last = chat.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
    }

    @ViewBuilder
    private func emptyHint(_ chat: Chat) -> some View {
        VStack(spacing: 10) {
            ChatAvatar(chat: chat, size: 64)
            Text(chat.kind == .talk ? "Ask anything about your screen." : "Tell this agent what to work on.")
                .textStyle(.callout).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }

    private func deleteCard(_ chat: Chat) -> some View {
        ModalCard(width: 400, onDismiss: { confirmingDelete.value = false }) {
            Text(chat.kind == .talk ? "Clear Talk history?" : "Delete \(chat.title)?")
                .textStyle(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
            Text(chat.kind == .talk ? "All questions and answers, and what MyClicky remembers from them, are removed."
                                    : "This agent and its conversation are removed from this Mac.")
                .textStyle(.callout).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                // Hover tells you what happens: red deletes, green keeps it (spec 015).
                Button("Cancel") { confirmingDelete.value = false }.buttonStyle(.pill(.safe))
                    .keyboardShortcut(.cancelAction)
                Button(chat.kind == .talk ? "Clear" : "Delete") {
                    if chat.kind == .talk { model.clearTalk() } else { model.deleteChat(chat.id) }
                    confirmingDelete.value = false
                }
                .buttonStyle(.pill(.destructive))
            }
        }
    }
}

/// Rename an agent.
struct RenameCard: View {
    @Environment(AppModel.self) private var model
    let chat: Chat
    let onDone: () -> Void
    @StateObject private var name = Box("")

    var body: some View {
        ModalCard(width: 400, onDismiss: onDone) {
            Text("Rename agent").textStyle(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
            TextField("Name", text: $name.value).darkField().onSubmit(save)
            HStack {
                Spacer()
                Button("Cancel", action: onDone).buttonStyle(.pill(.dark))
                Button("Save", action: save).buttonStyle(.pill(.primary))
            }
        }
        .onAppear { name.value = chat.title }
    }

    private func save() {
        model.rename(chat.id, to: name.value)
        onDone()
    }
}
