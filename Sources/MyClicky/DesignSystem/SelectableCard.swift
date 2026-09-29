import SwiftUI

/// A card that shows a white/blue glass outline and a round check badge when selected (voice, cursor color, language).
struct SelectableCard<Content: View>: View {
    let isSelected: Bool
    var dimmed = false
    let action: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isSelected ? Theme.selectedItem : Theme.card,
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(isSelected ? AnyShapeStyle(LinearGradient(colors: [.white, Theme.accent],
                                                                             startPoint: .top, endPoint: .bottom))
                                             : AnyShapeStyle(Theme.cardBorder),
                                  lineWidth: isSelected ? 2.5 : 1))
                .overlay(alignment: .topTrailing) {
                    if isSelected { CheckBadge().padding(10) }
                }
                .opacity(dimmed ? 0.45 : 1)
                .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
}

/// Round blue-violet check mark used on selected cards and radio rows.
struct CheckBadge: View {
    var size: CGFloat = 30
    var body: some View {
        ZStack {
            Circle().fill(Theme.accentGradient)
            Circle().strokeBorder(.white, lineWidth: 2)
            Image(systemName: "checkmark").font(.system(size: size * 0.45, weight: .bold)).foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Radio circle for single-choice rows (microphone input).
struct RadioMark: View {
    let isOn: Bool
    var body: some View {
        if isOn {
            CheckBadge(size: 32)
        } else {
            Circle().strokeBorder(Theme.textTertiary, lineWidth: 2).frame(width: 32, height: 32)
        }
    }
}
