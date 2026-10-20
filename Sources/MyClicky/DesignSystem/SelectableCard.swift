import SwiftUI

/// A card that shows an accent outline and a round check badge when selected (voice, cursor color, language).
/// Press, hover and selection all animate (spec 014).
struct SelectableCard<Content: View>: View {
    let isSelected: Bool
    var dimmed = false
    let action: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                    .fill(Theme.accent.opacity(isSelected ? 0.08 : 0)).allowsHitTesting(false))
                .hoverHighlight(radius: Theme.Radius.xl, enabled: !isSelected)
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                    .strokeBorder(isSelected ? Theme.accent : Theme.cardBorder, lineWidth: isSelected ? 2 : 1))
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        CheckBadge().padding(10).transition(.grow(from: .center))
                    }
                }
                .opacity(dimmed ? 0.45 : 1)
                .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.xl))
                .animation(Motion.quick, value: isSelected)
        }
        .buttonStyle(.pressable)
    }
}

/// Round accent check mark used on selected cards and radio rows.
struct CheckBadge: View {
    var size: CGFloat = 30
    var body: some View {
        ZStack {
            Circle().fill(Theme.accentFill)
            Image(systemName: "checkmark").font(.icon(size * 0.45, .bold)).foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Radio circle for single-choice rows (microphone input).
struct RadioMark: View {
    let isOn: Bool
    var body: some View {
        ZStack {
            if isOn {
                CheckBadge(size: 32).transition(.grow(from: .center))
            } else {
                Circle().strokeBorder(Theme.textTertiary, lineWidth: 2).frame(width: 32, height: 32).transition(.opacity)
            }
        }
        .frame(width: 32, height: 32)
        .animation(Motion.quick, value: isOn)
    }
}
