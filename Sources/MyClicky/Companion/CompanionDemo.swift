import SwiftUI
import MyClickyCore

/// Snapshot-only scene of the companion's layers (triangle, bubble, pointing label, a drawing) on a sample background.
struct CompanionDemo: NSViewRepresentable {
    /// Shows the listening look (sound waves) instead of the bubble scene.
    var listening = false

    func makeNSView(context: Context) -> NSView {
        let size = CGSize(width: 700, height: 420)
        let root = NSView(frame: CGRect(origin: .zero, size: size))
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor(calibratedRed: 0.93, green: 0.94, blue: 0.96, alpha: 1).cgColor
        let fakeButton = CALayer()
        fakeButton.frame = CGRect(x: 470, y: 250, width: 120, height: 36)
        fakeButton.backgroundColor = NSColor.white.cgColor
        fakeButton.cornerRadius = 8
        fakeButton.borderColor = NSColor.lightGray.cgColor
        fakeButton.borderWidth = 1
        root.layer?.addSublayer(fakeButton)

        let overlay = CompanionOverlayView(frame: root.bounds)
        root.addSubview(overlay)
        let red = NSColor(Color(hex: CursorColor.red.hex))
        overlay.companion.setColor(red)
        overlay.companion.isHidden = false
        overlay.companion.position = CGPoint(x: 180, y: 190)
        if listening {
            overlay.companion.setLook(.listening)
            overlay.companion.setLevel(0.7)
            overlay.companion.removeAllAnimations()
            return root
        }
        let bubbleSize = overlay.bubble.set("The Export button is at the top right. Click it, then choose PDF.", style: .info, accent: red)
        let origin = CompanionLayout.bubbleOrigin(companion: overlay.companion.position, bubble: bubbleSize, screen: root.bounds)
        overlay.showBubble(frame: CGRect(origin: origin, size: bubbleSize), from: overlay.companion.position)
        let pointed = CompanionLayer()
        pointed.setColor(red)
        pointed.position = CGPoint(x: 520, y: 268)
        overlay.layer?.addSublayer(pointed)
        overlay.label.set("Export", color: red, near: pointed.position, within: root.bounds)
        if let circle = DrawingLayer.make(.circle(x: 530, y: 268, r: 70, screen: 1), color: red,
                                          point: { x, y in CGPoint(x: x, y: y) }, length: { CGFloat($0) }) {
            circle.removeAllAnimations()
            overlay.drawings.addSublayer(circle)
        }
        return root
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
