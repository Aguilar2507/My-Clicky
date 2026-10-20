import SwiftUI

/// A centered card over a dimmed background, used for small forms inside the panel (sheets are unreliable in
/// a non-activating panel). Spec 014: navy glass that materializes (scale + blur clearing) over a fading dim, and
/// leaves the same way. Present it with `.modalOverlay(flag) { if flag { … } }` so the change animates.
struct ModalCard<Content: View>: View {
    var width: CGFloat = 460
    let onDismiss: () -> Void
    @ViewBuilder var content: Content
    @Environment(\.modalProgress) private var progress

    var body: some View {
        let still = DisplayPrefs.shared.reduceMotion
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
        ZStack {
            Color.black.opacity(0.22 * progress).ignoresSafeArea().onTapGesture(perform: onDismiss)
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(28)
                .frame(width: width, alignment: .leading)
                .glass(.floating, in: shape, tint: Theme.modal)
                .shadowToken(.large)
                .scaleEffect(still ? 1 : 0.96 + 0.04 * progress)
                .blur(radius: still ? 0 : 8 * (1 - progress))
                .opacity(progress)
        }
        .transition(.modifier(active: ModalPresentation(progress: 0), identity: ModalPresentation(progress: 1)))
    }
}

/// Hands the transition's progress to the dim and the card, frame by frame.
private struct ModalPresentation: ViewModifier, Animatable {
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.environment(\.modalProgress, progress)
    }
}

private struct ModalProgressKey: EnvironmentKey {
    static let defaultValue: Double = 1
}

extension EnvironmentValues {
    var modalProgress: Double {
        get { self[ModalProgressKey.self] }
        set { self[ModalProgressKey.self] = newValue }
    }
}

extension View {
    /// An overlay whose modal cards animate in and out whenever `trigger` changes.
    func modalOverlay<Trigger: Equatable, Overlay: View>(_ trigger: Trigger,
                                                         @ViewBuilder _ content: () -> Overlay) -> some View {
        overlay { ZStack { content() }.animation(Motion.standard, value: trigger) }
    }
}

/// Dark rounded text field matching the search field style.
struct FieldBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .textStyle(.body)
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).strokeBorder(Theme.cardBorder))
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
            .textStyle(.body, design: revealed.value ? .monospaced : .default)
            Button { revealed.value.toggle() } label: {
                Image(systemName: revealed.value ? "eye.slash" : "eye").font(.icon(15, .medium))
                    .foregroundStyle(Theme.icon).frame(width: 26, height: 26).contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
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
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).strokeBorder(Theme.cardBorder))
    }
}
