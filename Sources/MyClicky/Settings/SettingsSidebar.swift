import SwiftUI

/// Left column of Settings (refs 03–10): Back + title, profile card, grouped pages, version footer.
struct SettingsSidebar: View {
    @Environment(AppModel.self) private var model
    let selected: SettingsPage
    var onEditProfile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                Button { model.closeSettings() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 13, weight: .semibold))
                        Text("Back").font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(Theme.textPrimary.opacity(0.85))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.card, in: Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                Text("Settings").font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.textPrimary)
            }
            .padding(.top, 20)
            .padding(.bottom, 26)

            ProfileCard(onEdit: onEditProfile).padding(.bottom, 16)

            ForEach(Self.sections, id: \.label) { section in
                let pages = section.pages.filter(\.isAvailable)
                if !pages.isEmpty {
                    if let label = section.label {
                        Text(label).font(Theme.sectionFont).tracking(1.6).foregroundStyle(Theme.sectionLabel)
                            .padding(.leading, 10).padding(.top, 18).padding(.bottom, 8)
                    }
                    ForEach(pages) { page in item(page) }
                }
            }
            Spacer()
            Text("MyClicky \(AppInfo.versionString)").font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
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
                Image(systemName: page.symbol).font(.system(size: 15)).frame(width: 20)
                Text(page.title).font(.system(size: 16, weight: selected == page ? .semibold : .regular))
                Spacer()
            }
            .foregroundStyle(Theme.textPrimary.opacity(selected == page ? 1 : 0.85))
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(selected == page ? Theme.selectedItem : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 3)
    }
}

enum AppInfo {
    static var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.3.0" }
    static var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "dev" }
    static var versionString: String { "\(version) (\(build))" }
}
