import SwiftUI
import MyClickyCore

/// A chat's avatar: Talk uses the app logo, Clickys use the glass bot with their color as a ring (spec 013).
struct ChatAvatar: View {
    let chat: Chat
    var size: CGFloat = 42

    var body: some View {
        if chat.kind == .talk {
            ZStack {
                Circle().fill(Brand.deepNavy)
                AppLogo().frame(width: size * 1.2, height: size * 1.2)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            BotAvatar(ring: Color(hex: chat.avatarColor.blobHex), size: size)
        }
    }
}
