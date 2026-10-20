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
                        Image(systemName: listening ? "waveform" : "mic.fill").font(.icon(17, .semibold))
                        Text(listening ? "Listening… click to send" : "Hi, how can I help ^_^?")
                            .textStyle(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 236, height: 50)
                    .background(listening ? Theme.red : Theme.accent, in: Capsule(style: .continuous))
                    .shadowToken(.medium)
                    .animation(Motion.standard, value: listening)
                }
                .buttonStyle(.pressable)
                // The bot stands on the pill, feet on its top edge. It hops when you point at it (spec 016), and
                // clicking it does what the pill does.
                LivelyBot(sparkles: true)
                    .frame(width: 112, height: 112)
                    .offset(y: -42)
                    .onTapGesture { AppServices.shared?.assistant.toggleListening() }
            }
            .frame(height: 170)

            Text(Greeting.title(name: model.settings.profileName, hour: Calendar.current.component(.hour, from: Date())))
                .textStyle(.title2.weight(.bold)).foregroundStyle(Theme.textPrimary).padding(.top, 20)
            Text(Greeting.hint(for: pushToTalk)).textStyle(.subheadline).foregroundStyle(Theme.textSecondary).padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pushToTalk: ShortcutBinding {
        ShortcutBinding.normalized(model.settings.shortcuts).first { $0.action == .pushToTalk }!
    }
}
