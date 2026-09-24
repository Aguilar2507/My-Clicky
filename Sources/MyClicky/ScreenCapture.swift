import AppKit
import ScreenCaptureKit

/// One screenshot per display, downscaled for the model.
struct Screenshot {
    let jpeg: Data
    let pixelWidth: Int
    let pixelHeight: Int
    /// The display's frame in AppKit global coordinates (points, origin bottom-left).
    let screenFrame: CGRect
    let containsMouse: Bool

    /// Converts a point in screenshot pixels (origin top-left) to AppKit global coordinates.
    func globalPoint(x: Double, y: Double) -> CGPoint {
        let px = min(max(x, 0), Double(pixelWidth))
        let py = min(max(y, 0), Double(pixelHeight))
        return CGPoint(
            x: screenFrame.minX + px * screenFrame.width / Double(pixelWidth),
            y: screenFrame.maxY - py * screenFrame.height / Double(pixelHeight)
        )
    }
}

enum ScreenCapture {
    static let maxDimension = 1280.0
    static let jpegQuality = 0.8

    static var hasPermission: Bool { CGPreflightScreenCaptureAccess() }
    static func requestPermission() { CGRequestScreenCaptureAccess() }

    /// Captures every display; the one with the mouse cursor comes first.
    @MainActor
    static func captureAll() async throws -> [Screenshot] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        let ownApps = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
        let mouse = NSEvent.mouseLocation

        var shots: [Screenshot] = []
        for display in content.displays {
            guard let screen = NSScreen.screens.first(where: { $0.displayID == display.displayID }) else { continue }

            let filter = SCContentFilter(display: display, excludingApplications: ownApps, exceptingWindows: [])
            let config = SCStreamConfiguration()
            let scale = min(1.0, maxDimension / Double(max(display.width, display.height)))
            config.width = Int(Double(display.width) * scale)
            config.height = Int(Double(display.height) * scale)
            config.showsCursor = true

            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            let rep = NSBitmapImageRep(cgImage: image)
            guard let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: jpegQuality]) else { continue }

            shots.append(Screenshot(
                jpeg: jpeg,
                pixelWidth: image.width,
                pixelHeight: image.height,
                screenFrame: screen.frame,
                containsMouse: screen.frame.contains(mouse)
            ))
        }
        return shots.sorted { $0.containsMouse && !$1.containsMouse }
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
