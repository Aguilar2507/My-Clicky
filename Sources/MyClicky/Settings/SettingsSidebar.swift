import SwiftUI

/// Left column of Settings (refs 03–10): Back + title, profile card, grouped pages, version footer.
struct SettingsSidebar: View {
    @Environment(AppModel.self) private var model
    let selected: SettingsPage
    var onEditProfile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SidebarHeader(compact: true).padding(.leading, -8).padding(.bottom, 16)
            HStack(spacing: 14) {
                Button { model.closeSettings() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.icon(13, .semibold))
                        Text("Back").textStyle(.callout.weight(.medium))
                    }
                    .foregroundStyle(Theme.textPrimary.opacity(0.85))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.card, in: Capsule(style: .continuous))
                    .hoverHighlight(radius: 20)
                }
                .buttonStyle(.pressable)
                Text("Settings").textStyle(.title2.weight(.bold)).foregroundStyle(Theme.textPrimary)
            }
            .padding(.bottom, 22)

            ProfileCard(onEdit: onEditProfile).padding(.bottom, 16)

            ForEach(Self.sections, id: \.label) { section in
                let pages = section.pages.filter(\.isAvailable)
                if !pages.isEmpty {
                    if let label = section.label {
                        Text(label).textStyle(.label).foregroundStyle(Theme.sectionLabel)
                            .padding(.leading, 10).padding(.top, 18).padding(.bottom, 8)
                    }
                    ForEach(pages) { page in item(page) }
                }
            }
            Spacer()
            Text("MyClicky \(AppInfo.versionString)").textStyle(.caption).foregroundStyle(Theme.textTertiary)
                .padding(.leading, 10).padding(.bottom, 14)
        }
        .padding(.horizontal, 8)
    }

    private static let sections: [(label: String?, pages: [SettingsPage])] = [
        (nil, [.general]),
        ("MYCLICKY", [.voice, .microphone, .dictation, .shortcuts, .cursor]),
        ("WORK", [.agents, .integrations]),
    ]

    private func item(_ page: SettingsPage) -> some View {
        Button { model.route = .settings(page) } label: {
            HStack(spacing: 12) {
                Image(systemName: page.symbol).font(.icon(15)).frame(width: 20)
                Text(page.title).textStyle(.body.weight(selected == page ? .semibold : .regular))
                Spacer()
            }
            .foregroundStyle(Theme.textPrimary.opacity(selected == page ? 1 : 0.85))
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(selected == page ? Theme.selectedItem : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .hoverHighlight(radius: 10, enabled: selected != page)
            .contentShape(Rectangle())
            .animation(Motion.quick, value: selected == page)
        }
        .buttonStyle(.pressableRow)
        .padding(.bottom, 3)
    }
}

enum AppInfo {
    static var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.4.0" }
    static var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "dev" }
    static var versionString: String { "\(version) (\(build))" }
}
