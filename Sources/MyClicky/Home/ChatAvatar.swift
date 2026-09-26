import SwiftUI
import MyClickyCore

/// A chat's avatar: Talk uses the MyClicky logo, Clickys use the pastel blob.
struct ChatAvatar: View {
    let chat: Chat
    var size: CGFloat = 42

    var body: some View {
        if chat.kind == .talk {
            ZStack {
                Circle().fill(Color(hex: 0x2C2C30))
                MyClickyLogo().frame(width: size * 0.5, height: size * 0.5)
            }
            .frame(width: size, height: size)
        } else {
            MascotAvatar(blob: Color(hex: chat.avatarColor.blobHex), ring: Color(hex: chat.avatarColor.ringHex), size: size)
        }
    }
}

/// MyClicky's own mark: the companion cursor with a small spark (original, not HeyClicky's logo).
struct MyClickyLogo: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack(alignment: .topTrailing) {
                TriangleShape()
                    .stroke(.white, style: StrokeStyle(lineWidth: s * 0.1, lineJoin: .round))
                    .rotationEffect(.degrees(-20))
                    .frame(width: s * 0.8, height: s * 0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                Image(systemName: "sparkle").font(.system(size: s * 0.34, weight: .bold)).foregroundStyle(.white)
            }
        }
    }
}
