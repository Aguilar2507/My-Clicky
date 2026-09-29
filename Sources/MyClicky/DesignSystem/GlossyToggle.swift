import SwiftUI

/// HeyClicky-style switch: blue-violet glass track with a white knob when on; navy track with a light knob when off.
struct GlossyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { configuration.isOn.toggle() }
            } label: {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    BorderedCapsule(fill: configuration.isOn ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.track),
                                    border: configuration.isOn ? Theme.accentBorder : Theme.trackBorder,
                                    highlight: .white.opacity(configuration.isOn ? 0.35 : 0.08))
                    Circle()
                        .fill(configuration.isOn ? Color.white : Color(hex: 0xC9D0E6))
                        .frame(width: 30, height: 30)
                        .padding(4)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                }
                .frame(width: 76, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityValue(configuration.isOn ? "On" : "Off")
        }
    }
}

extension ToggleStyle where Self == GlossyToggleStyle {
    static var glossy: GlossyToggleStyle { GlossyToggleStyle() }
}
