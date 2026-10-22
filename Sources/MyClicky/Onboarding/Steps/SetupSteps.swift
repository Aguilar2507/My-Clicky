import SwiftUI
import MyClickyCore

/// Three animated intro cards instead of HeyClicky's intro video (spec 012 deviation).
struct IntroStep: View {
    @StateObject private var card = Box(0)
    @StateObject private var forward = Box(true)
    private let cards: [(String, String, String)] = [
        ("menubar.rectangle", "MyClicky lives in your menu bar", "Click the bot in the menu bar or press option + space and your chats open."),
        ("cursorarrow.rays", "A companion beside your cursor", "Hold control + option and say “Jarvis…” to ask about anything on screen. It answers out loud and points the way."),
        ("person.3.fill", "Agents do the work", "Named helpers run tasks for you in the background, and ask before anything important."),
    ]

    var body: some View {
        VStack(spacing: 22) {
            StepTitle(title: "Welcome to MyClicky", subtitle: "Your own screen-aware Mac assistant. Setup takes a few minutes.")
            let item = cards[card.value]
            ZStack { VStack(spacing: 12) {
                Image(systemName: item.0).font(.icon(42)).foregroundStyle(Theme.accent)
                Text(item.1).textStyle(.title3).foregroundStyle(Theme.textPrimary)
                Text(item.2).textStyle(.subheadline).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: 440, minHeight: 170)
            .padding(20)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .id(card.value)
            .transition(.slide(forward: forward.value))
            }
            .frame(maxWidth: .infinity)
            .clipped()
            HStack(spacing: 8) {
                ForEach(0..<cards.count, id: \.self) { i in
                    Capsule().fill(i == card.value ? Theme.accent : Theme.track).frame(width: i == card.value ? 22 : 8, height: 8)
                        .onTapGesture { show(i) }
                }
            }
            .animation(Motion.standard, value: card.value)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.5))
                show((card.value + 1) % cards.count)
            }
        }
    }

    /// Point the slide, then move on the next turn so the leaving card goes the right way.
    private func show(_ index: Int) {
        guard index != card.value else { return }
        forward.value = index > card.value || (card.value == cards.count - 1 && index == 0)
        DispatchQueue.main.async { Motion.withAnimation { card.value = index } }
    }
}

struct NameStep: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 18) {
            StepTitle(title: "What should MyClicky call you?", subtitle: "It's used in greetings like “Evening, Jose.”")
            TextField("Your name", text: $model.settings.profileName).darkField().frame(maxWidth: 320)
        }
    }
}

/// Live ✓ for each permission, the 🌐 key setting, and a guided relaunch (spec 012 research R1).
struct PermissionsStep: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 16) {
            StepTitle(title: "Allow MyClicky to help", subtitle: "Five switches. Some only take effect after MyClicky restarts.")
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                VStack(spacing: 12) {
                    SettingsCard {
                        ForEach(Array(Permission.allCases.enumerated()), id: \.element) { index, permission in
                            if index > 0 { CardDivider() }
                            SettingsRow(title: permission.title, subtitle: permission.why) {
                                if permission.isGranted {
                                    Image(systemName: "checkmark.circle.fill").font(.icon(22)).foregroundStyle(Theme.green)
                                } else {
                                    Button("Grant") { permission.request() }.buttonStyle(.pill(.primary, compact: true))
                                }
                            }
                        }
                    }
                    if FnKeyAdvisor.needsWarning(bindings: ShortcutBinding.normalized(model.settings.shortcuts)) {
                        WarningCard(title: "Set the 🌐 key to “Do Nothing”",
                                    text: "Right now it opens “\(FnKeyAdvisor.currentActionName)”, which gets in the way of control + fn dictation.",
                                    button: "Keyboard Settings", action: FnKeyAdvisor.openKeyboardSettings)
                    }
                    if !Permission.screenRecording.isGranted || !Permission.inputMonitoring.isGranted {
                        HStack {
                            Text("Turned a switch on but still no ✓? macOS applies it after a restart.")
                                .textStyle(.footnote).foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Button("Relaunch MyClicky") { Relauncher.relaunch() }.buttonStyle(.pill(.secondary, compact: true))
                        }
                    }
                }
            }
        }
    }
}

/// Paste the key, test it with a tiny request (~$0.0001), and learn about the $7 budget.
struct APIKeyStep: View {
    @Environment(AppModel.self) private var model
    let canContinue: Box<Bool>
    @StateObject private var key = Box("")
    @StateObject private var result = Box<(ok: Bool, text: String)?>(nil)
    @StateObject private var testing = Box(false)

    var body: some View {
        VStack(spacing: 16) {
            StepTitle(title: "Your Anthropic API key",
                      subtitle: "MyClicky answers with your own key. Create one at console.anthropic.com → API Keys, and set a spend limit there too.")
            HStack(spacing: 10) {
                SecretField(placeholder: Keychain.apiKey() == nil ? "sk-ant-…" : "Saved — paste a new one to replace it", text: $key.value)
                Button(testing.value ? "Testing…" : "Test") { test() }.buttonStyle(.pill(.secondary)).disabled(testing.value)
            }
            .frame(maxWidth: 520)
            if let result = result.value {
                Label(result.text, systemImage: result.ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .foregroundStyle(result.ok ? Theme.green : Theme.red).textStyle(.subheadline.weight(.medium))
            }
            Text("Monthly budget: \(UsageMonth.format(model.settings.monthlyBudgetUSD)) (change it later in Settings → General → Spending).")
                .textStyle(.footnote).foregroundStyle(Theme.textSecondary)
        }
        .onAppear { canContinue.value = model.settings.tour.completed.contains(.apiKey) }
    }

    private func test() {
        let candidate = key.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let keyToTest = candidate.isEmpty ? Keychain.apiKey() : candidate
        guard let keyToTest else { result.value = (false, "Paste your key first."); return }
        testing.value = true
        Task {
            defer { testing.value = false }
            do {
                let reply = try await ClaudeClient().complete(system: "Reply with OK.", user: "hi", model: model.settings.fastModel,
                                                              maxTokens: 1, apiKey: keyToTest)
                PaidRequestGate.record(model, reply.usage, kind: .interview)
                if !candidate.isEmpty { Keychain.setAPIKey(candidate) }
                result.value = (true, "Key works")
                canContinue.value = true
            } catch {
                // Anthropic's own text ("invalid x-api-key") means little to most people.
                let message = error.localizedDescription
                result.value = (false, message.localizedCaseInsensitiveContains("x-api-key")
                                ? "That key didn't work. Copy it again from console.anthropic.com → API Keys." : message)
                canContinue.value = false
            }
        }
    }
}

/// Claude Code for agents: status, copyable commands, check again, or skip.
struct ClaudeCodeStep: View {
    @Environment(AppModel.self) private var model
    @StateObject private var status = Box<ClaudeCodeLocator.Status?>(nil)

    var body: some View {
        VStack(spacing: 16) {
            StepTitle(title: "Agents work on your Claude plan",
                      subtitle: "Background tasks run with Claude Code, signed in with your Claude subscription (not the API key).")
            if let s = status.value, s.isReady {
                Label("Claude Code is ready\(s.version.map { " (\($0))" } ?? "")", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.green).textStyle(.callout.weight(.semibold))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(status.value?.path == nil ? "Open Terminal and run these, one at a time:" : "Claude Code is installed. Sign in once:")
                        .textStyle(.subheadline).foregroundStyle(Theme.textSecondary)
                    if status.value?.path == nil { CommandCard(command: "curl -fsSL https://claude.ai/install.sh | bash") }
                    CommandCard(command: "claude")
                    Text("Choose to sign in with your Claude account, finish in the browser, then type /exit. You can also skip this and do it later from Settings → Agents.")
                        .textStyle(.footnote).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
                    Button("Check again") { Task { status.value = await ClaudeCodeLocator.status(model.settings) } }
                        .buttonStyle(.pill(.secondary, compact: true))
                }
                .frame(maxWidth: 520)
            }
        }
        .task { status.value = await ClaudeCodeLocator.status(model.settings) }
    }
}
