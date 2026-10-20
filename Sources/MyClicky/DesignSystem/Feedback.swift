import SwiftUI
import AppKit
import MyClickyCore

// MARK: Press (spec 014 US1, apple-design skill §1, §10)

/// Sinks slightly and changes brightness the moment it's pressed (mouse-down), springs back on release or when the
/// pointer drags off. The action still commits on release.
private struct PressEffect: ViewModifier {
    let isPressed: Bool
    var brightness: Double = -0.06
    var scales = true

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed && scales && !DisplayPrefs.shared.reduceMotion ? 0.97 : 1)
            .brightness(isPressed ? brightness : 0)
            .animation(Motion.quick, value: isPressed)
    }
}

extension View {
    func pressEffect(_ isPressed: Bool, brightness: Double = -0.06, scales: Bool = true) -> some View {
        modifier(PressEffect(isPressed: isPressed, brightness: brightness, scales: scales))
    }
}

/// For buttons that used `.plain`: same look, plus press feedback. Small things (icons, chips, cards) sink a little;
/// full-width rows only brighten, since a 3 % scale on a wide row is a big jump (Apple's lists don't scale either).
struct PressableButtonStyle: ButtonStyle {
    var scales = true

    func makeBody(configuration: Configuration) -> some View {
        PressableBody(configuration: configuration, scales: scales)
    }

    private struct PressableBody: View {
        let configuration: Configuration
        let scales: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .pressEffect(configuration.isPressed, brightness: 0.05, scales: scales)
                .opacity(isEnabled ? 1 : 0.45)
        }
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    /// Icons, chips, cards.
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
    /// Full-width rows.
    static var pressableRow: PressableButtonStyle { PressableButtonStyle(scales: false) }
}

// MARK: Hover

/// A soft highlight while the pointer is over a row or card, distinct from the selected fill.
private struct HoverHighlight: ViewModifier {
    var radius: CGFloat
    var enabled: Bool
    @StateObject private var hovering = Box(false)

    func body(content: Content) -> some View {
        content
            .overlay {
                // On top, so it also shows on controls with their own fill.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.overlayColor(light: 0.04, dark: 0.06).opacity(enabled && hovering.value ? 1 : 0))
                    .allowsHitTesting(false)
            }
            .onHover { inside in
                withAnimation(Motion.quick) { hovering.value = inside }
            }
    }
}

extension View {
    /// `enabled: false` for the selected row, which already has its own fill.
    func hoverHighlight(radius: CGFloat = Theme.Radius.md, enabled: Bool = true) -> some View {
        modifier(HoverHighlight(radius: radius, enabled: enabled))
    }
}

// MARK: Feedback kinds (skill §16: status, completion, warning, error)

enum FeedbackKind {
    case status, completion, warning, error

    var color: Color {
        switch self {
        case .status: Theme.accent
        case .completion: Theme.green
        case .warning: Theme.orange
        case .error: Theme.red
        }
    }

    var symbol: String {
        switch self {
        case .status: "info.circle.fill"
        case .completion: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }
}

/// An inline message in one of the four feedback kinds: symbol + text in the kind's color.
struct FeedbackLabel: View {
    let kind: FeedbackKind
    let text: String
    init(_ kind: FeedbackKind, _ text: String) {
        self.kind = kind
        self.text = text
    }

    var body: some View {
        Label {
            Text(text).textStyle(.footnote).foregroundStyle(kind == .status ? Theme.textSecondary : kind.color)
        } icon: {
            Image(systemName: kind.symbol).font(.icon(Theme.IconSize.small, .semibold)).foregroundStyle(kind.color)
        }
    }
}

// MARK: Haptics (spec 014 US6, skill §13)

/// A light tap on a Force Touch trackpad, on the same frame as the visual change. Only for moments that matter:
/// push-to-talk starts/stops, a toggle flips, an agent finishes. Silent when the setting is off or there's no trackpad.
@MainActor
enum Haptics {
    enum Moment { case listen, toggle, done }

    static func tap(_ moment: Moment) {
        Log.events.notice("haptic \("\(moment)", privacy: .public) on=\(AppModel.shared.settings.hapticFeedback, privacy: .public)")
        guard AppModel.shared.settings.hapticFeedback else { return }
        let pattern: NSHapticFeedbackManager.FeedbackPattern = moment == .done ? .generic : .levelChange
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
}
