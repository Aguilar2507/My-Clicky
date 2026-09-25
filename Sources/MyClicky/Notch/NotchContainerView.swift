import SwiftUI
import MyClickyCore

/// Hosts one display's notch: the collapsed black shape, which grows into the app panel when opened (spec 003 US2).
struct NotchContainerView: View {
    @Environment(AppModel.self) private var model
    let ui: NotchPanelUI

    var body: some View {
        let panel = ui.geometry.expandedRect.size
        let collapsed = ui.geometry.collapsedInPanel
        let collapsedOffset = collapsed.midX - panel.width / 2
        let shape = NotchShape(width: ui.isExpanded ? panel.width : collapsed.width,
                               height: ui.isExpanded ? panel.height : collapsed.height,
                               bottomRadius: ui.isExpanded ? 26 : 14,
                               topFlare: ui.isExpanded ? 0 : 8,
                               offsetX: ui.isExpanded ? 0 : collapsedOffset)
        ZStack(alignment: .top) {
            shape.fill(ui.isExpanded ? Theme.windowBackground : .black)
            if ui.isExpanded {
                HomeRoot(chrome: HomeChrome(showsPopOut: true, onPopOut: ui.onPopOut, onClose: ui.onClose))
                    .clipShape(shape)
                    .transition(.opacity.animation(.easeOut(duration: 0.2).delay(0.12)))
            } else {
                NotchCollapsedView()
                    .frame(width: collapsed.width, height: collapsed.height)
                    .offset(x: collapsedOffset)
                    .transition(.opacity.animation(.easeOut(duration: 0.12)))
            }
        }
        .frame(width: panel.width, height: panel.height, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: ui.isExpanded)
    }
}
