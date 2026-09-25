import SwiftUI

/// HeyClicky-style switch: lavender glossy track with a black knob when on; gray track with a light knob when off.
struct GlossyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { configuration.isOn.toggle() }
            } label: {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    BorderedCapsule(fill: configuration.isOn ? AnyShapeStyle(Theme.lavenderGradient) : AnyShapeStyle(Color(hex: 0x4A4A50)),
                                    border: configuration.isOn ? Color(hex: 0x5C74D6) : Color(hex: 0x5A5A60),
                                    highlight: .white.opacity(configuration.isOn ? 0.5 : 0.1))
                    Circle()
                        .fill(configuration.isOn ? Color.black : Color(hex: 0xE5E5EA))
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
