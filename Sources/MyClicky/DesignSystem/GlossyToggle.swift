import SwiftUI

/// A macOS-style switch in the system accent color (spec 015), with 014's haptic tap when it flips.
/// Drawn in SwiftUI instead of the AppKit switch because MyClicky's window is often in the background, and AppKit
/// draws switches gray in inactive windows. Kept as `.glossy` so every settings row keeps working unchanged.
struct GlossyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Button {
                Haptics.tap(.toggle)
                Motion.withAnimation(.bouncy) { configuration.isOn.toggle() }
            } label: {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule(style: .continuous)
                        .fill(configuration.isOn ? Theme.accent : Theme.track)
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
                        .overlay(Circle().strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5))
                        .padding(2)
                }
                .frame(width: 42, height: 24)
                .contentShape(Capsule())
            }
            .buttonStyle(SwitchPress())
            .accessibilityValue(configuration.isOn ? "On" : "Off")
            .accessibilityAddTraits(.isToggle)
        }
    }
}

/// Pressing a switch darkens it slightly, like the system one.
private struct SwitchPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.brightness(configuration.isPressed ? -0.06 : 0)
    }
}

extension ToggleStyle where Self == GlossyToggleStyle {
    static var glossy: GlossyToggleStyle { GlossyToggleStyle() }
}
