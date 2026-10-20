import SwiftUI
import AppKit
import MyClickyCore

/// Settings → Agents (ref 09) plus a Claude Code status section (spec 009 deviation).
struct AgentsPage: View {
    @Environment(AppModel.self) private var model
    @StateObject private var status = Box<ClaudeCodeLocator.Status?>(nil)

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            PageHeader(title: "Agents", subtitle: SettingsPage.agents.subtitle)

            SectionLabel("Workspace")
            SettingsCard {
                Button(action: chooseFolder) {
                    SettingsRow(title: "Agent folder", subtitle: "Where agents spawn and put the things they make.") {
                        HStack(spacing: 6) {
                            Text(folderLabel).textStyle(.callout).foregroundStyle(Theme.textSecondary)
                            Image(systemName: "chevron.right").font(.icon(13, .semibold)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .hoverHighlight(radius: Theme.cardRadius)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressableRow)
            }

            SectionLabel("Autonomy").padding(.top, 10)
            SettingsCard {
                SettingsRow(title: "Auto-approve extra usage",
                            subtitle: "Let long tasks keep running without asking each time. Uses more of your Claude plan's usage.") {
                    Toggle("", isOn: $model.settings.autoApproveExtraUsage).toggleStyle(.glossy).labelsHidden()
                }
                CardDivider()
                SettingsRow(title: "Always allow computer use",
                            subtitle: "Let agents click and type on your Mac without asking first. Off means each turn asks with an Allow card.") {
                    Toggle("", isOn: $model.settings.alwaysAllowComputerUse).toggleStyle(.glossy).labelsHidden()
                }
                CardDivider()
                SettingsRow(title: "Suggest agent tasks",
                            subtitle: "Fresh task suggestions every 24 hours, shown under the menu bar icon each morning.") {
                    Toggle("", isOn: $model.settings.suggestAgentTasks).toggleStyle(.glossy).labelsHidden()
                }
            }

            SectionLabel("Announcements").padding(.top, 10)
            SettingsCard {
                SettingsRow(title: "Speak when an agent starts or finishes",
                            subtitle: "Jarvis tells you out loud what an agent got done.") {
                    Toggle("", isOn: $model.settings.announceStartFinish).toggleStyle(.glossy).labelsHidden()
                }
                CardDivider()
                SettingsRow(title: "Show updates beside the cursor",
                            subtitle: "An agent's reply streams in a bubble next to your cursor when it finishes.") {
                    Toggle("", isOn: $model.settings.showUpdatesBesideCursor).toggleStyle(.glossy).labelsHidden()
                }
            }
            Text("MyClicky always stays quiet while you're on a call, sharing your screen, or in Do Not Disturb. Finished work waits in the chat, and a dot on the menu bar icon shows when there's something new.")
                .textStyle(.footnote).foregroundStyle(Theme.textSecondary).padding(.horizontal, 8)
                .fixedSize(horizontal: false, vertical: true)

            SectionLabel("Claude Code").padding(.top, 10)
            SettingsCard { claudeCode }
        }
        .task { status.value = await ClaudeCodeLocator.status(model.settings) }
    }

    private var folderLabel: String {
        model.settings.agentWorkingDirectory == Settings().agentWorkingDirectory
            ? "MyClicky default" : (model.settings.agentWorkingDirectory as NSString).lastPathComponent
    }

    @ViewBuilder
    private var claudeCode: some View {
        if let s = status.value, s.isReady {
            SettingsRow(title: "Ready", subtitle: "\(s.version ?? "Claude Code") · signed in · runs on your Claude plan") {
                Image(systemName: "checkmark.circle.fill").font(.icon(24)).foregroundStyle(Theme.green)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(status.value?.path == nil ? "Not installed" : "Not signed in")
                    .textStyle(.headline).foregroundStyle(Theme.textPrimary)
                Text("Agents run on your Claude subscription through Claude Code. Open Terminal and run:")
                    .textStyle(.callout).foregroundStyle(Theme.textSecondary)
                if status.value?.path == nil { CommandCard(command: "curl -fsSL https://claude.ai/install.sh | bash") }
                CommandCard(command: "claude")
                Text("Choose to sign in with your Claude account (not an API key), finish in the browser, then type /exit.")
                    .textStyle(.footnote).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
                Button("Check again") { Task { status.value = await ClaudeCodeLocator.status(model.settings) } }
                    .buttonStyle(.pill(.secondary, compact: true))
            }
            .padding(Theme.rowPadding)
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Use this folder"
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            model.settings.agentWorkingDirectory = (url.path as NSString).abbreviatingWithTildeInPath
        }
    }
}

/// A monospaced command with a Copy button.
struct CommandCard: View {
    let command: String
    var body: some View {
        HStack {
            Text(command).textStyle(.footnote, design: .monospaced).foregroundStyle(Theme.textPrimary).textSelection(.enabled)
            Spacer()
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command, forType: .string)
            }
            .buttonStyle(.pill(.dark, compact: true))
        }
        .padding(10)
        .background(Theme.keycap, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
