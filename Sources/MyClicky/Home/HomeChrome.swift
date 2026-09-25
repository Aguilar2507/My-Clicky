import SwiftUI

/// Top-right window chrome from the references: "pop out" (two overlapping windows) and close ✕. No traffic lights.
struct HomeChrome: View {
    var showsPopOut: Bool
    var onPopOut: () -> Void
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 26) {
            if showsPopOut {
                Button(action: onPopOut) { Image(systemName: "pip") }
                    .help("Pop out into a window")
            }
            Button(action: onClose) { Image(systemName: "xmark") }
                .help("Close")
        }
        .font(.system(size: 20, weight: .regular))
        .foregroundStyle(Theme.icon)
        .buttonStyle(.plain)
        .padding(.top, 30)
        .padding(.trailing, 48)
    }
}
