import SwiftUI
import MyClickyCore

/// Settings → General (ref 03). MyClicky swaps Updates/Community for API key and Permissions (spec 004 deviations).
struct GeneralPage: View {
    @Environment(AppModel.self) private var model
    @StateObject private var editingKey = Box(false)
    @StateObject private var showingChangelog = Box(false)
    @StateObject private var keyRevision = Box(0)

    /// Extra sections that later features add (spending 011, welcome tour 012).
    static var extraSections: [(AppModel) -> AnyView] = []

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            PageHeader(title: "General", subtitle: SettingsPage.general.subtitle)

            SectionLabel("Behavior")
            SettingsCard {
                SettingsRow(title: "Show in Dock", subtitle: "Turn off to keep MyClicky in the menu bar only.") {
                    Toggle("", isOn: $model.settings.showInDock).toggleStyle(.glossy).labelsHidden()
                }
                CardDivider()
                SettingsRow(title: "Show in screen recordings",
                            subtitle: "Let screen sharing and recording tools capture MyClicky.") {
                    Toggle("", isOn: $model.settings.showInScreenRecordings).toggleStyle(.glossy).labelsHidden()
                }
                CardDivider()
                SettingsRow(title: "Haptic feedback",
                            subtitle: "A light tap on the trackpad when MyClicky starts or stops listening, a switch flips or an agent finishes.") {
                    Toggle("", isOn: $model.settings.hapticFeedback).toggleStyle(.glossy).labelsHidden()
                }
            }

            SectionLabel("Anthropic").padding(.top, 10)
            SettingsCard {
                SettingsRow(title: "API key", subtitle: keySubtitle) {
                    Button(Keychain.apiKey() == nil ? "Add" : "Change") { editingKey.value = true }
                        .buttonStyle(.pill(.secondary))
                }
            }

            SectionLabel("Permissions").padding(.top, 10)
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                SettingsCard {
                    ForEach(Array(Permission.allCases.enumerated()), id: \.element) { index, permission in
                        if index > 0 { CardDivider() }
                        SettingsRow(title: permission.title, subtitle: permission.why) {
                            if permission.isGranted {
                                Image(systemName: "checkmark.circle.fill").font(.icon(24))
                                    .foregroundStyle(Theme.green)
                            } else {
                                Button("Open") { permission.request() }.buttonStyle(.pill(.primary))
                            }
                        }
                    }
                }
            }

            SpendingSection()

            SectionLabel("Version").padding(.top, 10)
            SettingsCard {
                SettingsRow(title: "App version", subtitle: "You're on version \(AppInfo.versionString).")
                CardDivider()
                Button { showingChangelog.value = true } label: {
                    SettingsRow(title: "What's new", subtitle: "Everything that changed in MyClicky.") {
                        Image(systemName: "arrow.up.right").foregroundStyle(Theme.icon)
                    }
                    .hoverHighlight(radius: Theme.cardRadius)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressableRow)
            }

            SectionLabel("Welcome tour").padding(.top, 10)
            SettingsCard {
                Button { WelcomeTour.replay(model) } label: {
                    SettingsRow(title: "Replay the welcome tour",
                                subtitle: "Watch the intro again, then redo the hands-on tour and the interview. MyClicky makes three new agents from your answers; the ones you have stay.") {
                        Image(systemName: "play.fill").foregroundStyle(Theme.icon)
                    }
                    .hoverHighlight(radius: Theme.cardRadius)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressableRow)
            }

            ForEach(Array(Self.extraSections.enumerated()), id: \.offset) { _, section in section(model) }
        }
        .modalOverlay([editingKey.value, showingChangelog.value]) {
            if editingKey.value {
                APIKeyEditor { editingKey.value = false; keyRevision.value += 1 }
            }
            if showingChangelog.value { WhatsNewSheet { showingChangelog.value = false } }
        }
    }

    private var keySubtitle: String {
        _ = keyRevision.value
        guard let key = Keychain.apiKey() else { return "Not set — MyClicky needs it to answer questions." }
        return "\(key.prefix(7))…\(key.suffix(4))  ·  stored in your Keychain"
    }
}

/// Paste a new Anthropic API key (stored in the Keychain only).
struct APIKeyEditor: View {
    @StateObject private var key = Box("")
    let onDone: () -> Void

    var body: some View {
        ModalCard(onDismiss: onDone) {
            Text("Anthropic API key").textStyle(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
            Text("Used for questions about your screen. Stored in your macOS Keychain. Create one at console.anthropic.com and set a monthly limit there.")
                .textStyle(.callout).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            SecretField(placeholder: "sk-ant-…", text: $key.value, onSubmit: save)
            HStack {
                Spacer()
                Button("Cancel", action: onDone).buttonStyle(.pill(.dark))
                Button("Save", action: save).buttonStyle(.pill(.primary))
            }
        }
    }

    private func save() {
        let trimmed = key.value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { Keychain.setAPIKey(trimmed) }
        onDone()
    }
}

/// "What's new": the bundled CHANGELOG.md.
struct WhatsNewSheet: View {
    let onDone: () -> Void

    var body: some View {
        ModalCard(width: 600, onDismiss: onDone) {
            HStack {
                Text("What's new").textStyle(.title2.weight(.bold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Button(action: onDone) { Image(systemName: "xmark") }.buttonStyle(.pressable).foregroundStyle(Theme.icon)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(Self.lines.enumerated()), id: \.offset) { _, line in
                        Self.render(line)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 380)
        }
    }

    static var lines: [String] {
        let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md")
        let text = url.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "# Changelog\n\nNot available in this build."
        return text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    @ViewBuilder
    static func render(_ line: String) -> some View {
        if line.hasPrefix("## ") {
            Text(line.dropFirst(3)).textStyle(.body.weight(.bold)).foregroundStyle(Theme.textPrimary).padding(.top, 10)
        } else if line.hasPrefix("# ") {
            EmptyView()
        } else {
            let body = line.hasPrefix("- ") ? "•  " + line.dropFirst(2) : Substring(line)
            Text((try? AttributedString(markdown: String(body))) ?? AttributedString(String(body)))
                .textStyle(.subheadline).foregroundStyle(Theme.textSecondary)
        }
    }
}
