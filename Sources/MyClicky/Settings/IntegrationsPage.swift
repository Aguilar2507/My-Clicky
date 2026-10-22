import SwiftUI
import MyClickyCore

/// Settings → Integrations (ref 10): search, Add custom connector, CONNECTED and AVAILABLE INTEGRATIONS.
struct IntegrationsPage: View {
    @Environment(AppModel.self) private var model
    @StateObject private var query = Box("")
    @StateObject private var signingIn = Box<Integration?>(nil)
    @StateObject private var addingCustom = Box(false)
    let integrations: IntegrationsModel

    var body: some View {
        let items = IntegrationFilter.filter(integrations.all, query: query.value)
        let connected = items.filter { integrations.status($0) != .notAdded }
        let available = items.filter { integrations.status($0) == .notAdded && !$0.isCustom }
        VStack(alignment: .leading, spacing: 14) {
            PageHeader(title: "Integrations", subtitle: SettingsPage.integrations.subtitle)
            HStack(spacing: 12) {
                SearchField(text: $query.value, placeholder: "Search integrations")
                Button("Add custom connector") { addingCustom.value = true }.buttonStyle(.pill(.secondary))
                    .disabled(!integrations.claudeAvailable)
            }
            if !integrations.claudeAvailable {
                WarningCard(title: "Integrations need Claude Code",
                            text: "Your agents use connected apps through Claude Code. Set it up in Settings → Agents.",
                            button: "Open Agents") { model.route = .settings(.agents) }
            }
            if !connected.isEmpty || !integrations.others.isEmpty {
                HStack {
                    SectionLabel("Connected")
                    if integrations.isRefreshing { ProgressView().controlSize(.small) }
                }
                SettingsCard {
                    ForEach(Array(connected.enumerated()), id: \.element.id) { index, integration in
                        if index > 0 { CardDivider() }
                        IntegrationRow(integration: integration, status: integrations.status(integration),
                                       onConnect: { connect(integration) },
                                       onDisconnect: { Task { await integrations.disconnect(integration) } })
                    }
                    ForEach(integrations.others, id: \.name) { other in
                        CardDivider()
                        SettingsRow(title: other.name, subtitle: "Managed in Claude Code · \(other.target)")
                    }
                }
            }
            if !available.isEmpty {
                SectionLabel("Available integrations").padding(.top, 10)
                SettingsCard {
                    ForEach(Array(available.enumerated()), id: \.element.id) { index, integration in
                        if index > 0 { CardDivider() }
                        IntegrationRow(integration: integration, status: .notAdded, onConnect: { connect(integration) },
                                       onDisconnect: {})
                    }
                }
            }
            if items.isEmpty {
                Text("No integrations match “\(query.value)”").textStyle(.subheadline).foregroundStyle(Theme.textSecondary)
            }
        }
        .task { await integrations.refresh() }
        .modalOverlay([signingIn.value?.id, addingCustom.value ? "custom" : nil]) {
            if let integration = signingIn.value {
                SignInCard(integration: integration, integrations: integrations) { signingIn.value = nil }
            }
            if addingCustom.value { CustomConnectorSheet(integrations: integrations) { addingCustom.value = false } }
        }
    }

    private func connect(_ integration: Integration) {
        signingIn.value = integration
    }
}

/// One connector row: icon, name, status, description, actions (ref 10).
struct IntegrationRow: View {
    let integration: Integration
    let status: ConnectionStatus
    let onConnect: () -> Void
    let onDisconnect: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            IntegrationIcon(integration: integration, size: 40)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Text(integration.name).textStyle(.title3).foregroundStyle(Theme.textPrimary)
                    statusLabel
                }
                Text(integration.description).textStyle(.subheadline).foregroundStyle(Theme.textSecondary).lineLimit(2)
            }
            Spacer(minLength: 12)
            actions.fixedSize()
        }
        .padding(Theme.rowPadding)
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch status {
        case .connected: Label("Connected", systemImage: "circle.fill").labelStyle(DotLabel(color: Theme.green))
        case .needsAuth: Label("Reconnect required", systemImage: "circle.fill").labelStyle(DotLabel(color: Theme.orange))
        case .failed: Label("Failed", systemImage: "circle.fill").labelStyle(DotLabel(color: Theme.red))
        case .checking: ProgressView().controlSize(.small)
        case .notAdded: EmptyView()
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch status {
        case .connected:
            Button("Disconnect", action: onDisconnect).buttonStyle(.pill(.destructive))
        case .needsAuth, .failed:
            HStack(spacing: 10) {
                Button("Reconnect", action: onConnect).buttonStyle(.pill(.primary))
                Button(action: onDisconnect) { Image(systemName: "xmark") }.buttonStyle(CircleIconButtonStyle())
            }
        case .notAdded:
            Button("Connect", action: onConnect).buttonStyle(.pill(.primary))
        case .checking:
            EmptyView()
        }
    }
}

struct DotLabel: LabelStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            configuration.title.textStyle(.footnote.weight(.semibold)).foregroundStyle(color)
        }
    }
}

/// Letter tile (brand logos aren't bundled; see spec 010 notes).
struct IntegrationIcon: View {
    let integration: Integration
    var size: CGFloat = 40
    var body: some View {
        let letter = integration.icon.hasPrefix("letter:") ? String(integration.icon.dropFirst(7)) : String(integration.name.prefix(1))
        Text(letter).font(.system(size: size * 0.45, weight: .bold)).foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Self.color(for: integration.id), in: RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
    }

    static func color(for id: String) -> Color {
        let palette: [UInt32] = [0x24292F, 0x2B2B2B, 0x5E6AD2, 0x0052CC, 0xF06A6A, 0x362D59, 0x3A7BD5, 0x2E8B57]
        let index = abs(id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }) % palette.count
        return Color(hex: palette[index])
    }
}

/// "Finish signing in to {Name}" while we poll Claude Code (research R2). Services that need your own OAuth app
/// (GitHub) first ask for its client ID and secret, unless the connector is already added.
struct SignInCard: View {
    @Environment(AppModel.self) private var model
    let integration: Integration
    let integrations: IntegrationsModel
    let onDone: () -> Void
    @StateObject private var state = Box("Adding \u{2026}")
    @StateObject private var askingForApp = Box(false)
    @StateObject private var clientID = Box("")
    @StateObject private var clientSecret = Box("")

    var body: some View {
        ModalCard(width: 460, onDismiss: onDone) {
            HStack(spacing: 12) {
                IntegrationIcon(integration: integration, size: 36)
                Text("Connect \(integration.name)").textStyle(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
            }
            if askingForApp.value, let port = integration.oauthCallbackPort {
                Text("\(integration.name) needs your own OAuth app (free, once). Create one with the homepage http://localhost and the callback URL below, then paste its Client ID and a client secret. The secret goes to Claude Code only.")
                    .textStyle(.callout).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
                Text("http://localhost:\(port)/callback").textStyle(.callout, design: .monospaced).foregroundStyle(Theme.textPrimary)
                    .textSelection(.enabled)
                TextField("Client ID", text: $clientID.value).darkField()
                SecretField(placeholder: "Client secret", text: $clientSecret.value)
                HStack {
                    Button("Open \(integration.name)") { openAppPage() }.buttonStyle(.pill(.secondary, compact: true))
                    Spacer()
                    Button("Cancel", action: onDone).buttonStyle(.pill(.dark, compact: true))
                    Button("Connect") {
                        model.settings.oauthClientIDs[integration.id] = clientID.value.trimmingCharacters(in: .whitespacesAndNewlines)
                        askingForApp.value = false
                        Task { await start(secret: clientSecret.value.trimmingCharacters(in: .whitespacesAndNewlines)) }
                    }
                    .buttonStyle(.pill(.primary, compact: true))
                    .disabled(clientID.value.trimmingCharacters(in: .whitespaces).isEmpty
                              || clientSecret.value.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } else {
                Text(state.value).textStyle(.callout).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
                HStack {
                    ProgressView().controlSize(.small)
                    Spacer()
                    Button("Open sign-in again") { integrations.signIn(integration) }.buttonStyle(.pill(.secondary, compact: true))
                    Button("Cancel", action: onDone).buttonStyle(.pill(.dark, compact: true))
                }
            }
        }
        .task {
            // Already added (only the sign-in is missing): Claude Code has the app's secret, go straight to sign-in.
            if integration.oauthCallbackPort != nil, integrations.status(integration) == .notAdded {
                clientID.value = model.settings.oauthClientIDs[integration.id] ?? ""
                askingForApp.value = true
                return
            }
            await start(secret: nil)
        }
    }

    private func start(secret: String?) async {
        let status = await integrations.connect(integration, clientSecret: secret)
        if status == .connected { onDone(); return }
        state.value = "Finish signing in to \(integration.name): your browser opened (from a small Terminal window). Sign in there. Waiting for \(integration.name)…"
        if await integrations.waitUntilConnected(integration) { onDone() } else { state.value = "Sign-in wasn't finished. Try again." }
    }

    /// Where you create the OAuth app (only GitHub needs one today).
    private func openAppPage() {
        let page = integration.id == "github" ? "https://github.com/settings/applications/new" : (integration.url ?? "")
        if let url = URL(string: page) { NSWorkspace.shared.open(url) }
    }
}

/// Add custom connector: a web address or a command on this Mac (no header secrets in v1, research R4).
struct CustomConnectorSheet: View {
    let integrations: IntegrationsModel
    let onDone: () -> Void
    @StateObject private var name = Box("")
    @StateObject private var isURL = Box(true)
    @StateObject private var value = Box("")
    @StateObject private var error = Box<String?>(nil)
    @StateObject private var busy = Box(false)

    var body: some View {
        ModalCard(width: 480, onDismiss: onDone) {
            Text("Add custom connector").textStyle(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
            TextField("Name", text: $name.value).darkField()
            Picker("", selection: $isURL.value) {
                Text("Web address").tag(true)
                Text("Command on this Mac").tag(false)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            TextField(isURL.value ? "https://example.com/mcp" : "npx -y @some/mcp-server", text: $value.value).darkField()
            if let message = error.value {
                Text(message).textStyle(.footnote.weight(.medium)).foregroundStyle(Theme.orange)
            }
            HStack {
                if busy.value { ProgressView().controlSize(.small) }
                Spacer()
                Button("Cancel", action: onDone).buttonStyle(.pill(.dark))
                Button("Add") {
                    busy.value = true
                    Task {
                        error.value = await integrations.addCustom(name: name.value, url: isURL.value ? value.value : nil,
                                                                   command: isURL.value ? nil : value.value)
                        busy.value = false
                        if error.value == nil { onDone() }
                    }
                }
                .buttonStyle(.pill(.primary))
                .disabled(busy.value)
            }
        }
    }
}
