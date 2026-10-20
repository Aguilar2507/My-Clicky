import SwiftUI

/// Settings inside MyClicky's window: sidebar on the left, the selected page on the right (refs 03–10).
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    let page: SettingsPage
    @StateObject private var editingProfile = Box(false)

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selected: page) { editingProfile.value = true }
                .frame(width: 209)
                .frame(maxHeight: .infinity)
                .background(Theme.sidebarSurface)
            ScrollView {
                // A centered column that grows with the window up to a comfortable width (spec 017).
                content
                    .frame(maxWidth: Theme.Layout.settingsColumn, alignment: .leading)
                    .padding(.horizontal, 32)
                    .padding(.top, 76)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.never)
            .background(Theme.windowBackground)
        }
        .modalOverlay(editingProfile.value) {
            if editingProfile.value { ProfileEditor { editingProfile.value = false } }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .general: GeneralPage()
        case .shortcuts: ShortcutsPage()
        case .cursor: CursorPage()
        case .voice: VoicePage()
        case .microphone: MicrophonePage()
        case .dictation: DictationPage()
        case .agents: AgentsPage()
        case .integrations: IntegrationsPage(integrations: model.integrations)
        }
    }
}
