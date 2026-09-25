import AppKit
import SwiftUI
import MyClickyCore

/// Renders app screens to PNG files without launching the app, so layouts can be compared with
/// `references/heyclicky/` (developer tool; see CLAUDE.md).
@MainActor
enum Snapshot {
    /// Screen name → view and size. Features register their screens here.
    static var screens: [String: (size: CGSize, view: () -> AnyView)] = [
        "gallery": (CGSize(width: 1000, height: 1000), { AnyView(DesignGallery()) }),
        "notch-collapsed": (CGSize(width: 520, height: 60), { AnyView(notchPreview(expanded: false).frame(width: 520, height: 60, alignment: .top).background(Color(hex: 0x7A7A7A))) }),
        "notch-expanded": (NotchGeometry.expandedSize, { AnyView(notchPreview(expanded: true)) }),
    ]

    /// A model backed by a temporary folder, so snapshots never read or change your real data.
    static let previewModel: AppModel = {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("MyClickySnapshot-\(UUID().uuidString)")
        return AppModel(paths: AppPaths(base: base))
    }()

    static func notchPreview(expanded: Bool) -> some View {
        // 16" MacBook Pro geometry (1728×1117 pt, 184 pt notch).
        let geometry = NotchGeometry(screenFrame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
                                     auxLeftWidth: 772, auxRightWidth: 772, safeAreaTop: 38, menuBarHeight: 24)
        let ui = NotchPanelUI(geometry: geometry)
        ui.isExpanded = expanded
        previewModel.previewUnreadCount = 1
        let view = NotchContainerView(ui: ui).environment(previewModel)
        return expanded ? AnyView(view) : AnyView(view.frame(width: 990, height: 60, alignment: .top).clipped()
            .frame(width: 520, height: 60))
    }

    static func run(screen: String, output: String) -> Bool {
        _ = NSApplication.shared
        guard let entry = screens[screen] else {
            print("Unknown screen '\(screen)'. Available: \(screens.keys.sorted().joined(separator: ", "))")
            return false
        }
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let hosting = NSHostingView(rootView: entry.view().environment(\.colorScheme, .dark))
        let rect = NSRect(origin: .zero, size: entry.size)
        let window = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = hosting
        window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000)) // off-screen
        window.orderFrontRegardless()
        // Let SwiftUI lay out and finish first-frame work.
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        hosting.layoutSubtreeIfNeeded()
        // Render the real layer tree (cacheDisplay redraws shapes and adds artifacts at stroke seams).
        let scale: CGFloat = 2
        let width = Int(entry.size.width * scale), height = Int(entry.size.height * scale)
        guard let layer = hosting.layer,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        context.scaleBy(x: scale, y: scale)
        if layer.isGeometryFlipped {
            context.translateBy(x: 0, y: entry.size.height)
            context.scaleBy(x: 1, y: -1)
        }
        layer.render(in: context)
        window.orderOut(nil)
        guard let cgImage = context.makeImage() else { return false }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let png = rep.representation(using: .png, properties: [:]) else {
            print("Rendering failed")
            return false
        }
        do {
            try png.write(to: URL(fileURLWithPath: output))
            print("Wrote \(output)")
            return true
        } catch {
            print("Write failed: \(error)")
            return false
        }
    }
}
