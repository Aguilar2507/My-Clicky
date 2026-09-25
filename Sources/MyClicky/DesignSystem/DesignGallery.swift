import SwiftUI

/// Developer screen showing every shared control, opened with `--gallery`. Compare with references/heyclicky/03.
struct DesignGallery: View {
    @StateObject private var dock = Box(true)
    @StateObject private var recordings = Box(false)
    @StateObject private var selected = Box(0)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "General", subtitle: "How MyClicky behaves on your Mac.")
                SectionLabel("Behavior")
                SettingsCard {
                    SettingsRow(title: "Show in Dock", subtitle: "Turn off to keep MyClicky notch only.") {
                        Toggle("", isOn: $dock.value).toggleStyle(.glossy).labelsHidden()
                    }
                    CardDivider()
                    SettingsRow(title: "Show in screen recordings", subtitle: "Let screen sharing and recording tools capture MyClicky.") {
                        Toggle("", isOn: $recordings.value).toggleStyle(.glossy).labelsHidden()
                    }
                }
                SectionLabel("Buttons")
                SettingsCard {
                    SettingsRow(title: "Pills") {
                        HStack {
                            Button("Connect") {}.buttonStyle(.pill(.primary))
                            Button("Change") {}.buttonStyle(.pill(.secondary))
                            Button("Disconnect") {}.buttonStyle(.pill(.dark))
                            Button { } label: { Image(systemName: "xmark") }.buttonStyle(CircleIconButtonStyle())
                        }
                    }
                    CardDivider()
                    SettingsRow(title: "Key caps") { HStack { KeyCap(text: "^ control"); KeyCap(text: "fn") } }
                }
                SectionLabel("Selectable cards")
                HStack(spacing: 16) {
                    ForEach(0..<4) { index in
                        SelectableCard(isSelected: selected.value == index, action: { selected.value = index }) {
                            Image(systemName: "play.fill").font(.system(size: 40)).foregroundStyle(.red)
                        }
                        .frame(width: 120, height: 120)
                    }
                }
                SectionLabel("Mascot")
                HStack(spacing: 20) {
                    MascotAvatar(blob: Color(hex: 0xF2B8A8), ring: Color(hex: 0xF7D9CC))
                    MascotAvatar(blob: Color(hex: 0x9CC7E8), ring: Color(hex: 0xCFE6F7))
                    MascotBlob(color: Color(hex: 0xE8A090), glow: true).frame(width: 160, height: 110)
                }
            }
            .padding(40)
        }
        .frame(minWidth: 900, minHeight: 700)
        .background(Theme.windowBackground)
        .preferredColorScheme(.dark)
    }
}
