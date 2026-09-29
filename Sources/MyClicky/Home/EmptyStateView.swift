import SwiftUI
import MyClickyCore

/// The greeting screen (ref 02, spec 013): the glass bot standing on a glowing pill, "Evening, Jose." and the push-to-talk hint.
/// Clicking the pill starts listening; clicking again sends.
struct EmptyStateView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let listening = model.talkState == .listening
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Button { AppServices.shared?.assistant.toggleListening() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: listening ? "waveform" : "mic.fill").font(.system(size: 17, weight: .semibold))
                        Text(listening ? "Listening… click to send" : "Hi, how can I help ^_^?")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 236, height: 50)
                    .background {
                        BorderedCapsule(fill: AnyShapeStyle(Theme.accentGradient), border: Theme.accentBorder, borderWidth: 1.5,
                                        highlight: .white.opacity(0.35))
                    }
                    .shadow(color: Brand.electricBlue.opacity(0.5), radius: 14, y: 4)
                }
                .buttonStyle(.plain)
                // The bot stands on the pill, feet on its top edge.
                LivelyBot(sparkles: true)
                    .frame(width: 112, height: 112)
                    .offset(y: -42)
                    .allowsHitTesting(false)
            }
            .frame(height: 170)

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
