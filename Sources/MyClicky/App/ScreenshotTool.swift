import AppKit
import AVFoundation
import ScreenCaptureKit

/// `open -n -g MyClicky.app --args --screenshot <out.png>`: saves every display as `<out>-1.png`, `<out>-2.png`… and
/// prints each display's frame, then exits. It runs as its own process with MyClicky's Screen Recording permission, so
/// end-to-end checks (`scripts/e2e/`) can see the companion, bubbles and drawings. Windows hidden from screen recordings
/// (Settings → General) stay hidden here too.
@MainActor
enum ScreenshotTool {
    static func run(output: String) -> Never {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        Task {
            var status: Int32 = 0
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                let base = (output as NSString).deletingPathExtension
                var log = ""
                for (index, display) in content.displays.enumerated() {
                    let screen = NSScreen.screens.first { $0.displayID == display.displayID }
                    let scale = screen?.backingScaleFactor ?? 1
                    let config = SCStreamConfiguration()
                    config.width = Int(Double(display.width) * scale)
                    config.height = Int(Double(display.height) * scale)
                    config.showsCursor = true
                    let filter = SCContentFilter(display: display, excludingWindows: [])
                    let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                    let path = "\(base)-\(index + 1).png"
                    try NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?
                        .write(to: URL(fileURLWithPath: path))
                    let f = screen?.frame ?? .zero
                    log += "\(path) frame=\(Int(f.minX)),\(Int(f.minY)),\(Int(f.width)),\(Int(f.height)) scale=\(scale)\n"
                }
                try log.write(toFile: base + ".txt", atomically: true, encoding: .utf8)
            } catch {
                try? "error: \(error.localizedDescription)\n".write(toFile: (output as NSString).deletingPathExtension + ".txt",
                                                                  atomically: true, encoding: .utf8)
                status = 1
            }
            exit(status)
        }
        app.run()
        exit(0)
    }
}

/// `open -n -g MyClicky.app --args --hold-mic <seconds>`: keeps the microphone busy like a call app would, then exits.
/// End-to-end checks use it to test quiet mode during calls (spec 007 US4) without a real call.
@MainActor
enum MicHolder {
    static func run(seconds: Double) -> Never {
        let engine = AVAudioEngine()
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: engine.inputNode.outputFormat(forBus: 0)) { _, _ in }
        try? engine.start()
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
        engine.stop()
        exit(0)
    }
}
