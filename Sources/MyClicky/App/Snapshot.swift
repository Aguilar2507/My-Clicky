import AppKit
import SwiftUI

/// Renders app screens to PNG files without launching the app, so layouts can be compared with
/// `references/heyclicky/` (developer tool; see CLAUDE.md).
@MainActor
enum Snapshot {
    /// Screen name → view and size. Features register their screens here.
    static var screens: [String: (size: CGSize, view: () -> AnyView)] = [
        "gallery": (CGSize(width: 1000, height: 1000), { AnyView(DesignGallery()) }),
    ]

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
