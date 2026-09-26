import SwiftUI

/// Everything inside the notch panel or the pop-out window. Later specs fill it (004 settings, 005 chats).
struct HomeRoot: View {
    @Environment(AppModel.self) private var model
    var chrome: HomeChrome

    var body: some View {
        ZStack(alignment: .topTrailing) {
            switch model.route {
            case .home:
                GreetingPlaceholder()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.windowBackground)
                    .overlay(alignment: .top) { TopFade() }
                    .overlay(alignment: .bottomLeading) {
                        Button { model.openSettings() } label: { Image(systemName: "gearshape.fill") }
                            .buttonStyle(.plain).font(.system(size: 22)).foregroundStyle(Theme.icon).padding(24)
                    }
            case .settings(let page):
                SettingsView(page: page)
            }
            chrome
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

/// Placeholder greeting until spec 005 delivers the real empty state.
struct GreetingPlaceholder: View {
    var body: some View {
        VStack(spacing: 18) {
            MascotBlob(color: Color(hex: 0xE8A090), glow: true).frame(width: 200, height: 140)
            Text("Hi, how can I help ^_^?").font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.textPrimary)
        }
    }
}
