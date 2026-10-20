import SwiftUI
import MyClickyCore

/// Settings → Shortcuts (ref 07): rebindable shortcuts (spec 019 adds Open MyClicky), key caps, Change, Reset to defaults.
struct ShortcutsPage: View {
    @Environment(AppModel.self) private var model
    @StateObject private var recording = Box<ShortcutAction?>(nil)

    var body: some View {
        let bindings = ShortcutBinding.normalized(model.settings.shortcuts)
        VStack(alignment: .leading, spacing: 14) {
            PageHeader(title: "Shortcuts", subtitle: SettingsPage.shortcuts.subtitle)

            TimelineView(.periodic(from: .now, by: 2)) { _ in
                VStack(alignment: .leading, spacing: 14) {
                    if !Permission.accessibility.isGranted || !Permission.inputMonitoring.isGranted {
                        WarningCard(title: "Shortcuts need two permissions",
                                    text: "Turn on \(Permission.accessibilityName) and Input Monitoring for MyClicky, then reopen it.",
                                    button: "Open Settings") {
                            (Permission.accessibility.isGranted ? Permission.inputMonitoring : Permission.accessibility).request()
                        }
                    }
                    if FnKeyAdvisor.needsWarning(bindings: bindings) {
                        WarningCard(title: "Your 🌐 fn key opens “\(FnKeyAdvisor.currentActionName)”",
                                    text: "Set “Press 🌐 key to” to “Do Nothing” in Keyboard settings so fn only works with MyClicky.",
                                    button: "Keyboard Settings", action: FnKeyAdvisor.openKeyboardSettings)
                    }
                }
            }

            SectionLabel("Talk to MyClicky")
            SettingsCard {
                row(bindings, .pushToTalk)
                CardDivider()
                row(bindings, .textMode)
            }
            SectionLabel("Dictation").padding(.top, 10)
            SettingsCard {
                row(bindings, .dictate)
                CardDivider()
                row(bindings, .handsFreeDictation)
            }
            SectionLabel("Window").padding(.top, 10)
            SettingsCard {
                row(bindings, .openApp)
            }
            SettingsCard {
                Button { model.settings.shortcuts = ShortcutBinding.defaults } label: {
                    SettingsRow(title: "Reset to defaults").hoverHighlight(radius: Theme.cardRadius).contentShape(Rectangle())
                }
                .buttonStyle(.pressableRow)
            }
            .padding(.top, 10)
        }
        .modalOverlay(recording.value) {
            if let action = recording.value {
                ShortcutRecorderView(action: action) { recording.value = nil }
            }
        }
    }

    private func row(_ bindings: [ShortcutBinding], _ action: ShortcutAction) -> some View {
        let binding = bindings.first { $0.action == action }!
        return SettingsRow(title: action.title, subtitle: action.subtitle) {
            HStack(spacing: 8) {
                ForEach(Array(KeyCapLabels.caps(for: binding.chord, gesture: binding.gesture).enumerated()), id: \.offset) {
                    KeyCap(text: $0.element)
                }
                Button("Change") { recording.value = action }.buttonStyle(.pill(.secondary)).padding(.leading, 8)
            }
        }
    }
}

/// "Press the new shortcut" capture card.
struct ShortcutRecorderView: View {
    @Environment(AppModel.self) private var model
    let action: ShortcutAction
    let onDone: () -> Void
    @StateObject private var live = Box<Set<Modifier>>([])
    @StateObject private var error = Box<String?>(nil)

    var body: some View {
        ModalCard(onDismiss: cancel) {
            Text("New shortcut for \(action.title)").textStyle(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
            Text("Hold keys, double-tap them, or press a key combination. Esc cancels.")
                .textStyle(.callout).foregroundStyle(Theme.textSecondary)
            HStack(spacing: 8) {
                if live.value.isEmpty {
                    Text("Press the new shortcut…").textStyle(.body).foregroundStyle(Theme.textTertiary)
                } else {
                    ForEach(live.value.sorted(), id: \.self) { KeyCap(text: KeyCapLabels.label($0)) }
                }
            }
            .frame(height: 40)
            if let message = error.value {
                Text(message).textStyle(.subheadline.weight(.medium)).foregroundStyle(Theme.orange)
            }
            if AppServices.shared == nil {
                Text("Shortcut recording works in the running app.").textStyle(.footnote).foregroundStyle(Theme.textTertiary)
            }
            HStack { Spacer(); Button("Cancel", action: cancel).buttonStyle(.pill(.dark)) }
        }
        .onAppear(perform: start)
    }

    private func start() {
        guard let center = AppServices.shared?.shortcuts else { return }
        center.onRecordingChange = { mods in live.value = mods }
        center.beginRecording { chord, gesture in
            let candidate = ShortcutBinding(action, chord, gesture)
            let bindings = ShortcutBinding.normalized(model.settings.shortcuts)
            if !candidate.isValid {
                error.value = "That can't be a shortcut. Try again."
                start()
            } else if let other = ShortcutBinding.conflict(for: candidate, in: bindings) {
                error.value = "Already used for \(other.title)."
                live.value = []
                start()
            } else {
                model.settings.shortcuts = bindings.map { $0.action == action ? candidate : $0 }
                onDone()
            }
        }
    }

    private func cancel() {
        AppServices.shared?.shortcuts.cancelRecording()
        onDone()
    }
}

/// Orange-accented card for things that need attention.
struct WarningCard: View {
    let title: String
    let text: String
    let button: String
    let action: () -> Void

    var body: some View {
        SettingsCard {
            HStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill").font(.icon(20)).foregroundStyle(Theme.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).textStyle(.headline).foregroundStyle(Theme.textPrimary)
                    Text(text).textStyle(.callout).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button(button, action: action).buttonStyle(.pill(.primary))
            }
            .padding(Theme.rowPadding)
        }
    }
}
