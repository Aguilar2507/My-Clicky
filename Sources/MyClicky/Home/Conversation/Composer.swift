import SwiftUI
import MyClickyCore

/// Message field at the bottom of a chat. Return sends, ⌥Return adds a line. The mic dictates into the field.
struct Composer: View {
    let chat: Chat
    let onSend: (String) -> Void
    @StateObject private var text = Box("")
    @StateObject private var dictation = ComposerDictation()
    @FocusState private var focused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(placeholder, text: $text.value, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1...6)
                .focused($focused)
                .onSubmit(send)
                .padding(.vertical, 4)
            Button { dictation.toggle { text.value += (text.value.isEmpty ? "" : " ") + $0 } } label: {
                Image(systemName: dictation.isListening ? "waveform.circle.fill" : "mic.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(dictation.isListening ? Theme.red : Theme.icon)
            }
            .buttonStyle(.plain)
            .help(dictation.isListening ? "Stop dictating" : "Dictate into the message")
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 26))
                    .foregroundStyle(canSend ? Theme.accent : Theme.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.cardBorder))
        .padding(.horizontal, 28)
        .padding(.bottom, 22)
        .onAppear { focused = true }
    }

    private var placeholder: String {
        if chat.kind == .clicky && chat.messages.isEmpty { return "What should this Clicky do?" }
        return "Message \(chat.title)…"
    }

    private var canSend: Bool { !text.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func send() {
        guard canSend else { return }
        onSend(text.value)
        text.value = ""
    }
}

/// Mic button in the composer: on-device dictation into the text field (never sent until Return).
@MainActor
final class ComposerDictation: ObservableObject {
    @Published private(set) var isListening = false
    private let speech = SpeechRecognizer()

    func toggle(append: @escaping (String) -> Void) {
        if isListening {
            isListening = false
            Task {
                let text = await speech.stop()
                if !text.isEmpty { append(text) }
            }
        } else {
            do {
                try speech.start(AppModel.shared.settings)
                isListening = true
            } catch {
                isListening = false
            }
        }
    }
}
