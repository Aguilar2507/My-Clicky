import SwiftUI

/// Everything inside MyClicky's window (spec 019). Later specs fill it (004 settings, 005 chats).
struct HomeRoot: View {
    @Environment(AppModel.self) private var model
    var chrome: HomeChrome

    var body: some View {
        ZStack(alignment: .topTrailing) {
            switch model.route {
            case .home:
                HomeView()
            case .settings(let page):
                SettingsView(page: page)
            }
        }
        .environment(\.windowControls, chrome.controls)
        // Switches and controls keep their active (accent) colors even while the window is in the background.
        .environment(\.controlActiveState, .key)
        .modalOverlay(model.showingSpending) {
            if model.showingSpending { SpendingSheet { model.showingSpending = false } }
        }
    }
}
