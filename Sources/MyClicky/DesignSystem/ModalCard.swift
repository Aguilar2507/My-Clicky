import SwiftUI

/// A centered card over a dimmed background, used for small forms inside the panel (sheets are unreliable in
/// a non-activating panel).
struct ModalCard<Content: View>: View {
    var width: CGFloat = 460
    let onDismiss: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().onTapGesture(perform: onDismiss)
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(28)
                .frame(width: width, alignment: .leading)
                .background(Theme.modal, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.cardBorder))
                .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        }
        .transition(.opacity)
    }
}

/// Dark rounded text field matching the search field style.
struct FieldBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(.system(size: 16))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.cardBorder))
    }
}

extension View {
    func darkField() -> some View { modifier(FieldBackground()) }
}

/// A secret text box (API key) with an eye button to show or hide what's typed and a Paste button.
struct SecretField: View {
    let placeholder: String
    @Binding var text: String
    var onSubmit: () -> Void = {}
    @StateObject private var revealed = Box(false)

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if revealed.value {
                    TextField(placeholder, text: $text).onSubmit(onSubmit)
                } else {
                    SecureField(placeholder, text: $text).onSubmit(onSubmit)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 16, design: revealed.value ? .monospaced : .default))
            Button { revealed.value.toggle() } label: {
                Image(systemName: revealed.value ? "eye.slash" : "eye").font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.icon).frame(width: 26, height: 26).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(revealed.value ? "Hide" : "Show")
            Button("Paste") {
                if let pasted = NSPasteboard.general.string(forType: .string) {
                    text = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            .buttonStyle(.pill(.dark, compact: true))
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.cardBorder))
    }
}
