import SwiftUI

/// The app's home (ref 02): chats on the left; the open chat or the greeting on the right.
struct HomeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 270)
                .frame(maxHeight: .infinity)
                .background(Theme.sidebarBackground)
            ZStack {
                if let id = model.selectedChatID, model.chat(id) != nil {
                    ConversationView(chatID: id).id(id)
                } else {
                    EmptyStateView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bloomBackground)
            .overlay(alignment: .top) { TopFade().frame(height: 60) }
        }
    }
}
