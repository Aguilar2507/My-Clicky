import SwiftUI
import MyClickyCore

/// A chat's avatar (spec 016): Talk is the logo's cursor on the brand gradient; each Clicky is a white glass bot on
/// its own color, Apple Contacts style.
struct ChatAvatar: View {
    let chat: Chat
    var size: CGFloat = 42

    var body: some View {
        if chat.kind == .talk {
            TalkAvatar(size: size)
        } else {
            BotAvatar(ring: Color(hex: chat.avatarColor.blobHex), size: size)
        }
    }
}
