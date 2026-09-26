import SwiftUI

/// Settings inside the notch panel or window: sidebar on the left, the selected page on the right (refs 03–10).
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    let page: SettingsPage
    @StateObject private var editingProfile = Box(false)

    /// Pages provided by later features (voice, cursor, agents…), keyed by page.
    static var pageViews: [SettingsPage: () -> AnyView] = [:]

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selected: page) { editingProfile.value = true }
                .frame(width: 209)
                .frame(maxHeight: .infinity)
                .background(Theme.sidebarBackground)
            ScrollView {
                content
                    .frame(maxWidth: 640, alignment: .leading)
                    .padding(.leading, 28)
                    .padding(.trailing, 36)
                    .padding(.top, 76)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.never)
            .background(Theme.windowBackground)
            .overlay(alignment: .top) { TopFade() }
        }
        .overlay {
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
        default:
            if let view = Self.pageViews[page] { view() } else { GeneralPage() }
        }
    }
}
