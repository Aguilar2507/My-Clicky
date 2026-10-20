import SwiftUI

/// The red, yellow and green buttons every Mac app has at its top-left corner (spec 015 US3).
/// macOS draws the real ones in MyClicky's window (spec 019: the only home); the row only keeps their space free.
enum WindowControls {
    case window
}

private struct WindowControlsKey: EnvironmentKey {
    static let defaultValue: WindowControls = .window
}

extension EnvironmentValues {
    var windowControls: WindowControls {
        get { self[WindowControlsKey.self] }
        set { self[WindowControlsKey.self] = newValue }
    }
}

/// The top row of a sidebar (spec 015/017): the window buttons, then MyClicky's logo and name, which take you home.
/// It leaves room for macOS's buttons and lines up with them; in full screen (no buttons) the logo moves to the edge,
/// so the corner is never empty.
struct SidebarHeader: View {
    @Environment(AppModel.self) private var model
    /// Narrow sidebars (Settings) show only the logo next to the window buttons.
    var compact = false

    var body: some View {
        let layout = self.layout
        HStack(spacing: 12) {
            if let reserved = layout.reserved { Color.clear.frame(width: reserved, height: 1) }
            SidebarBrand(showsName: !compact || layout.reserved == nil)
            Spacer(minLength: 0)
        }
        .frame(height: 30)
        .padding(.leading, layout.leading)
        .padding(.top, layout.top)
    }

    /// Leading inset, room kept for the macOS buttons (nil = none), and top inset so the row's center matches theirs.
    private var layout: (leading: CGFloat, reserved: CGFloat?, top: CGFloat) {
        if model.isWindowFullScreen { return (16, nil, 18) }
        let buttons = model.windowButtonsFrame ?? CGRect(x: 20, y: 10, width: 52, height: 14)
        return (0, buttons.maxX + 4, max(0, buttons.midY - 15))
    }
}

/// MyClicky's logo and name. Clicking it goes to the home greeting from anywhere.
struct SidebarBrand: View {
    @Environment(AppModel.self) private var model
    var showsName = true

    var body: some View {
        Button { Motion.withAnimation { model.goHome() } } label: {
            HStack(spacing: 7) {
                AppLogo().frame(width: 30, height: 30)
                if showsName {
                    Text("MyClicky").textStyle(.headline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                        .fixedSize()
                }
            }
            .padding(.trailing, showsName ? 8 : 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .help("Home")
        .accessibilityLabel("MyClicky, go home")
    }
}
