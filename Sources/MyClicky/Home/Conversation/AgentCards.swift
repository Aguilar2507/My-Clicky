import SwiftUI
import MyClickyCore

/// How agent messages look in a chat (spec 009 contracts/ui-agents.md): step rows, Allow cards, notices.
enum AgentCards {
    /// Plugs into MessageBubble.custom.
    @MainActor
    static func render(_ message: Message, chat: Chat) -> AnyView? {
        switch message.kind {
        case .text: return nil
        case .step: return AnyView(AgentStepRow(message: message))
        case .approval: return AnyView(AllowCard(message: message, chat: chat))
        case .notice:
            if message.status == "keepGoing" { return AnyView(KeepGoingCard(message: message, chat: chat)) }
            return AnyView(NoticeRow(message: message))
        }
    }
}

/// "Searching the web: ai news" with a spinner / ✓ / ✕.
struct AgentStepRow: View {
    let message: Message

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: Self.symbol(for: message.toolName ?? "")).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                .frame(width: 16)
            Text(message.text).font(.system(size: 13)).foregroundStyle(Theme.textSecondary).lineLimit(1)
            Spacer(minLength: 8)
            switch message.status {
            case "running": ProgressView().controlSize(.mini)
            case "failed": Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.red)
            default: Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.green)
            }
        }
        .padding(.leading, 36)
    }

    static func symbol(for tool: String) -> String {
        if tool.hasPrefix("mcp__myclicky__") { return "cursorarrow.rays" }
        if tool.hasPrefix("mcp__") { return "puzzlepiece.extension" }
        switch tool {
        case "WebSearch", "WebFetch": return "globe"
        case "Read", "Glob", "Grep": return "doc.text.magnifyingglass"
        case "Write", "Edit", "MultiEdit": return "pencil"
        case "Bash": return "terminal"
        case "TodoWrite": return "checklist"
        default: return "gearshape"
        }
    }
}

/// Several steps in a row collapse into "7 steps ▸" (tap to expand).
struct StepGroupView: View {
    let steps: [Message]
    @StateObject private var expanded = Box(false)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if expanded.value {
                ForEach(steps) { AgentStepRow(message: $0) }
            } else if let last = steps.last {
                AgentStepRow(message: last)
            }
            Button { expanded.value.toggle() } label: {
                Text(expanded.value ? "Hide steps ▾" : "\(steps.count) steps ▸").font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.lavender)
            }
            .buttonStyle(.plain)
            .padding(.leading, 36)
        }
    }
}

/// "{Name} wants to: Run a command · ls ~/Desktop" — Allow / Always allow for {Name} / Deny.
struct AllowCard: View {
    let message: Message
    let chat: Chat

    var body: some View {
        let pending = message.status == "pending" || message.status == "pendingSensitive"
        let sensitive = message.status == "pendingSensitive"
        SettingsCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ChatAvatar(chat: chat, size: 26)
                    Text("\(chat.title) wants to:").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                    if sensitive {
                        Text("Sensitive").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 2).background(Theme.red, in: Capsule())
                    }
                }
                Text(message.text).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.textPrimary)
                if let detail = message.detail, !detail.isEmpty {
                    Text(detail).font(.system(size: 12, design: .monospaced)).foregroundStyle(Theme.textSecondary)
                        .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        .textSelection(.enabled)
                }
                if pending {
                    HStack(spacing: 10) {
                        Button("Allow") { decide("allowed") }.buttonStyle(.pill(.primary, compact: true))
                        if !sensitive {
                            Button("Always allow for \(chat.title)") { decide("alwaysAllowed") }.buttonStyle(.pill(.secondary, compact: true))
                        }
                        Button("Deny") { decide("denied") }.buttonStyle(.plain).foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    Text(Self.outcome(message.status)).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(14)
        }
        .padding(.leading, 36)
        .frame(maxWidth: 560, alignment: .leading)
    }

    private func decide(_ answer: String) {
        guard let id = message.refID else { return }
        AppServices.shared?.agents.decide(id, answer)
    }

    static func outcome(_ status: String?) -> String {
        switch status {
        case "allowed": "Allowed"
        case "alwaysAllowed": "Always allowed for this Clicky"
        case "denied": "Denied"
        case "expired": "No answer after 10 minutes — denied"
        default: "Waiting…"
        }
    }
}

/// "{Name} has used 40 steps on this. Keep going?"
struct KeepGoingCard: View {
    @Environment(AppModel.self) private var model
    let message: Message
    let chat: Chat

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(message.text).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.textPrimary)
                if isLatest {
                    HStack(spacing: 10) {
                        Button("Keep going") { AppServices.shared?.agents.keepGoing(chatID: chat.id) }
                            .buttonStyle(.pill(.primary, compact: true))
                        Button("Stop here") { resolve() }.buttonStyle(.pill(.dark, compact: true))
                    }
                }
            }
            .padding(14)
        }
        .padding(.leading, 36)
        .frame(maxWidth: 520, alignment: .leading)
    }

    /// Buttons only on the newest card, and only while nothing is running.
    private var isLatest: Bool {
        chat.messages.last(where: { $0.kind == .notice })?.id == message.id && !model.workingChatIDs.contains(chat.id)
    }

    private func resolve() {
        model.updateChat(chat.id) { c in
            if let i = c.messages.firstIndex(where: { $0.id == message.id }) { c.messages[i].status = "stopped" }
        }
    }
}

struct NoticeRow: View {
    let message: Message
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: message.status == "failed" ? "exclamationmark.triangle.fill"
                  : message.status == "queued" ? "hourglass" : "stop.circle")
                .foregroundStyle(message.status == "failed" ? Theme.orange : Theme.textSecondary)
            Text(message.text).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 36)
    }
}
