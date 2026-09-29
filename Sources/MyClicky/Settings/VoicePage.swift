import SwiftUI
import AVFoundation
import MyClickyCore

/// Settings → Voice (ref 04): speed chips and a grid of installed Apple voices per language, tap to hear.
struct VoicePage: View {
    @Environment(AppModel.self) private var model
    @StateObject private var preview = VoicePreview()

    private static let icons: [(String, Color)] = [
        ("tree.fill", Color(hex: 0x5FBF7F)), ("water.waves", Color(hex: 0x4FA3F7)), ("circle.grid.cross.fill", Color(hex: 0x9A9AA0)),
        ("cloud.fill", Color(hex: 0x9A9AA0)), ("music.note", Color(hex: 0xB270E8)), ("heart.fill", Color(hex: 0xF07A86)),
        ("dot.radiowaves.left.and.right", Color(hex: 0x4FA3F7)), ("leaf.fill", Color(hex: 0x5FBF7F)),
        ("sparkles", Color(hex: 0xF2C94C)), ("text.bubble.fill", Color(hex: 0xF29E5B)),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PageHeader(title: "Voice", subtitle: SettingsPage.voice.subtitle)

            SectionLabel("Speech speed")
            HStack(spacing: 10) {
                ForEach(VoiceRanking.speeds, id: \.self) { speed in
                    let selected = model.settings.speechSpeed == speed
                    Button { model.settings.speechSpeed = speed } label: {
                        Text(Self.label(speed)).font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(selected ? Color.white : Theme.textPrimary.opacity(0.85))
                            .frame(width: 70, height: 38)
                            .background {
                                if selected {
                                    BorderedCapsule(fill: AnyShapeStyle(Theme.accentGradient), border: .white, borderWidth: 2)
                                } else {
                                    Capsule(style: .continuous).fill(Theme.track)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text("Takes effect on the next spoken reply.").font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                .padding(.leading, 8)

            section("English", language: "en")
            section("Spanish", language: "es")

            Text("Tap a voice to hear it. The pick applies to future spoken replies.")
                .font(.system(size: 13)).foregroundStyle(Theme.textSecondary).padding(.leading, 8)
            SettingsCard {
                Button {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?SpokenContent")!)
                } label: {
                    SettingsRow(title: "Get more voices",
                                subtitle: "Download Premium or Enhanced voices in System Settings → Accessibility → Spoken Content.") {
                        Image(systemName: "arrow.up.right").foregroundStyle(Theme.icon)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, language: String) -> some View {
        let voices = Array(VoiceRanking.ranked(SpeechQueue.installedVoices(), language: language,
                                               preferredRegion: Locale.current.region?.identifier).prefix(10))
        let selected = model.settings.voiceByLanguage[language] ?? voices.first?.identifier
        SectionLabel("Voice — \(title)").padding(.top, 10)
        if !voices.isEmpty && !voices.contains(where: { $0.quality >= 2 || VoiceRanking.naturalness($0.identifier) >= 4 }) {
            Text("Only basic \(title) voices are installed. For a natural voice, use “Get more voices” and download a Premium or Enhanced one.")
                .font(.system(size: 13)).foregroundStyle(Theme.orange).padding(.leading, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
        if voices.isEmpty {
            Text("No \(title) voices installed. Use “Get more voices” below.").font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary).padding(.leading, 8)
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(114), spacing: 12), count: 5), alignment: .leading, spacing: 12) {
                ForEach(Array(voices.enumerated()), id: \.element.identifier) { index, voice in
                    SelectableCard(isSelected: voice.identifier == selected, action: {
                        model.settings.voiceByLanguage[language] = voice.identifier
                        preview.play(voice, name: model.settings.profileName, speed: model.settings.speechSpeed)
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: Self.icons[index % Self.icons.count].0).font(.system(size: 26))
                                .foregroundStyle(Self.icons[index % Self.icons.count].1)
                            Text(voice.name).font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.textPrimary)
                                .lineLimit(1).minimumScaleFactor(0.8)
                            Text(VoiceRanking.descriptor(for: voice)).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(8)
                    }
                    .frame(width: 114, height: 112)
                }
            }
        }
    }

    static func label(_ speed: Double) -> String {
        speed == 1 ? "1x" : String(format: "%gx", speed)
    }
}

/// Plays "Hi {name}, this is how I sound." in a voice (tap on a card).
@MainActor
final class VoicePreview: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func play(_ voice: VoiceRanking.VoiceInfo, name: String, speed: Double) {
        synthesizer.stopSpeaking(at: .immediate)
        let spanish = voice.language.hasPrefix("es")
        let utterance = AVSpeechUtterance(string: spanish ? "Hola \(name), así es como sueno." : "Hi \(name), this is how I sound.")
        utterance.voice = AVSpeechSynthesisVoice(identifier: voice.identifier)
        utterance.rate = VoiceRanking.rate(for: speed)
        synthesizer.speak(utterance)
    }
}
