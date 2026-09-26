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
                            ForEach(messages) { message in
                                MessageBubble(message: message, chat: chat).id(message.id)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                    }
                    .scrollIndicators(.never)
                    .onAppear { scrollToEnd(proxy, chat) }
                    .onChange(of: chat.messages.count) { scrollToEnd(proxy, chat) }
                }
                Composer(chat: chat) { text in AppServices.shared?.assistant.send(text, toChat: chatID) }
            }
            .onAppear { model.markRead(chatID) }
            .overlay {
                if renaming.value { RenameCard(chat: chat) { renaming.value = false } }
                if confirmingDelete.value { deleteCard(chat) }
            }
        }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy, _ chat: Chat) {
        if let last = chat.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
    }

    @ViewBuilder
    private func emptyHint(_ chat: Chat) -> some View {
        VStack(spacing: 10) {
            ChatAvatar(chat: chat, size: 64)
            Text(chat.kind == .talk ? "Ask anything about your screen." : "Tell this Clicky what to work on.")
                .font(.system(size: 15)).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }

    private func deleteCard(_ chat: Chat) -> some View {
        ModalCard(width: 400, onDismiss: { confirmingDelete.value = false }) {
            Text(chat.kind == .talk ? "Clear Talk history?" : "Delete \(chat.title)?")
                .font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.textPrimary)
            Text(chat.kind == .talk ? "All questions and answers, and what MyClicky remembers from them, are removed."
                                    : "This Clicky and its conversation are removed from this Mac.")
                .font(Theme.rowSubtitle).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button("Cancel") { confirmingDelete.value = false }.buttonStyle(.pill(.dark))
                Button(chat.kind == .talk ? "Clear" : "Delete") {
                    if chat.kind == .talk { model.clearTalk() } else { model.deleteChat(chat.id) }
                    confirmingDelete.value = false
                }
                .buttonStyle(.pill(.primary))
            }
        }
    }
}

/// Rename a Clicky.
struct RenameCard: View {
    @Environment(AppModel.self) private var model
    let chat: Chat
    let onDone: () -> Void
    @StateObject private var name = Box("")

    var body: some View {
        ModalCard(width: 400, onDismiss: onDone) {
            Text("Rename Clicky").font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.textPrimary)
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
