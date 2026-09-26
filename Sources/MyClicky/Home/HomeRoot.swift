import SwiftUI

/// Everything inside the notch panel or the pop-out window. Later specs fill it (004 settings, 005 chats).
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
            chrome
        }
        .overlay {
            if model.showingSpending { SpendingSheet { model.showingSpending = false } }
        }
        .environment(\.colorScheme, .dark)
    }
}

/// The black-to-clear fade where the panel meets the notch (ref 02).
struct TopFade: View {
    var body: some View {
        LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
            .frame(height: 90)
            .allowsHitTesting(false)
    }
}
