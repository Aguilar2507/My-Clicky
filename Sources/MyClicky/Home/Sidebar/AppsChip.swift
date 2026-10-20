import SwiftUI
import MyClickyCore

/// Sidebar "Apps +" chip (ref 02): icons of connected integrations; opens Settings → Integrations.
struct AppsChip: View {
    @Environment(AppModel.self) private var model
    let integrations: IntegrationsModel

    var body: some View {
        Button { model.openSettings(.integrations) } label: {
            HStack(spacing: 6) {
                ForEach(integrations.connected.prefix(3)) { IntegrationIcon(integration: $0, size: 18) }
                Text("Apps").textStyle(.callout.weight(.medium)).foregroundStyle(Theme.textPrimary)
                Image(systemName: "plus").font(.icon(12, .semibold)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Theme.card, in: Capsule(style: .continuous))
            .hoverHighlight(radius: 20)
        }
        .buttonStyle(.pressable)
        .task { await integrations.refresh() }
    }
}
