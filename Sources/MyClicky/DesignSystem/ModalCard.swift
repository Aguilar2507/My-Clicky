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
                .background(Color(hex: 0x252527), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
