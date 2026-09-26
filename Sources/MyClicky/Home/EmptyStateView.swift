import SwiftUI
import MyClickyCore

/// The greeting screen (ref 02): the mascot peeking over a glossy pill, "Evening, Jose." and the push-to-talk hint.
/// Clicking the pill starts listening; clicking again sends.
struct EmptyStateView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let listening = model.talkState == .listening
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                MascotBlob(color: Color(hex: 0xE8A090), glow: true)
                    .frame(width: 136, height: 98)
                    .offset(y: -30)
                Button { AppServices.shared?.assistant.toggleListening() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: listening ? "waveform" : "mic.fill").font(.system(size: 17, weight: .semibold))
                        Text(listening ? "Listening… click to send" : "Hi, how can I help ^_^?")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: 0x1C2340))
                    .frame(width: 226, height: 50)
                    .background {
                        BorderedCapsule(fill: AnyShapeStyle(Theme.lavenderGradient), border: .white, borderWidth: 2,
                                        highlight: .white.opacity(0.6))
                    }
                    .overlay(Capsule(style: .continuous).fill(Color(hex: 0x3A3A3E)).padding(-3).mask(
                        Capsule(style: .continuous).stroke(lineWidth: 6).padding(-3)).allowsHitTesting(false))
                }
                .buttonStyle(.plain)
                // Two little paws resting on the pill.
                HStack(spacing: 52) {
                    Capsule().fill(Color(hex: 0xE8A090)).frame(width: 22, height: 12)
                    Capsule().fill(Color(hex: 0xE8A090)).frame(width: 22, height: 12)
                }
                .offset(y: -44)
                .allowsHitTesting(false)
            }
            .frame(height: 150)

            Text(Greeting.title(name: model.settings.profileName, hour: Calendar.current.component(.hour, from: Date())))
                .font(.system(size: 21, weight: .bold)).foregroundStyle(Theme.textPrimary).padding(.top, 20)
            Text(Greeting.hint(for: pushToTalk)).font(.system(size: 14)).foregroundStyle(Theme.textSecondary).padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pushToTalk: ShortcutBinding {
        ShortcutBinding.normalized(model.settings.shortcuts).first { $0.action == .pushToTalk }!
    }
}
