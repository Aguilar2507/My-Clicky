import AppKit
import QuartzCore
import MyClickyCore

/// The cursor companion (spec 006): a glowing triangle that trails the pointer on every display, shows answers in a
/// bubble, flies to point at things, draws on screen, and can dock beside the menu bar icon (spec 019).
@MainActor
final class CompanionController: NSObject {
    private struct Flight {
        let start: CGPoint
        let control: CGPoint
        let end: CGPoint
        let startTime: CFTimeInterval
        let duration: Double
        let label: String
        let returning: Bool
    }

    let model: AppModel
    private var windows: [CompanionWindow] = []
    private var spring = CompanionSpring(position: NSEvent.mouseLocation)
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var flight: Flight?
    private var hold: (point: CGPoint, until: Date)?
    private var look: CompanionLayer.Look = .idle
    private var bubble: (text: String, style: BubbleLayer.Style)?
    private var hideBubbleWork: DispatchWorkItem?
    private var fadeDrawingsWork: DispatchWorkItem?
    private var monitors: [Any] = []
    /// The agent bot is out (spec 018): the cursor companion steps aside.
    private var agentBotOut = false

    init(model: AppModel) {
        self.model = model
        super.init()
        rebuild()
        let moved: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        if let m = NSEvent.addGlobalMonitorForEvents(matching: moved, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.wake() }
        }) { monitors.append(m) }
        if let m = NSEvent.addLocalMonitorForEvents(matching: moved, handler: { [weak self] event in
            MainActor.assumeIsolated { self?.wake() }
            return event
        }) { monitors.append(m) }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuild() }
        }
        observeChanges({ model.settings.cursorColor }) { [weak self] _ in self?.applyColor() }
        observeChanges({ model.settings.cursorDocked }) { [weak self] _ in self?.wake() }
    }

    // MARK: Public API

    var color: NSColor { NSColor(Color(hex: model.settings.cursorColor.hex)) }

    func setLook(_ look: CompanionLayer.Look) {
        self.look = look
        windows.forEach { $0.overlay.companion.setLook(look) }
        wake()
    }

    /// Hides the cursor companion while the agent bot listens beside the pointer, and brings it back after.
    func setAgentBotOut(_ out: Bool) {
        agentBotOut = out
        wake()
    }

    func setLevel(_ level: Float) {
        windows.forEach { $0.overlay.companion.setLevel(level) }
    }

    /// Shows text beside the companion. `autoHide` hides it after that many seconds.
    func showBubble(_ text: String, style: BubbleLayer.Style = .info, autoHide: TimeInterval? = nil) {
        hideBubbleWork?.cancel()
        bubble = (text, style)
        windows.forEach { $0.overlay.bubble.set(text, style: style, accent: color) }
        if let autoHide { hideBubble(after: autoHide) }
        wake()
        render()
    }

    func hideBubble(after delay: TimeInterval = 0) {
        hideBubbleWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.bubble = nil
            self.render()
        }
        hideBubbleWork = work
        if delay <= 0 { work.perform() } else { DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work) }
    }

    /// Flies the companion to a global point, shows the label, and comes back (6 s, or when the pointer gets close).
    func point(at target: CGPoint, label: String) {
        let start = model.settings.cursorDocked && flight == nil && hold == nil ? dockAnchor : spring.position
        flight = Flight(start: start, control: CompanionLayout.arcControl(from: start, to: target), end: target,
                        startTime: CACurrentMediaTime(), duration: CompanionLayout.flightDuration(from: start, to: target),
                        label: label, returning: false)
        hold = nil
        windows.forEach { $0.overlay.label.isHidden = true }
        wake()
    }

    func cancelPointing() {
        flight = nil
        hold = nil
        windows.forEach { $0.overlay.label.isHidden = true }
        wake()
    }

    /// Draws up to 3 marks on the right displays; they fade after 8 s.
    func draw(_ marks: [ScreenMark], screenshots: [Screenshot]) {
        clearDrawings()
        for mark in marks where screenshots.indices.contains(mark.screen - 1) {
            let shot = screenshots[mark.screen - 1]
            guard let window = windows.first(where: { $0.screenFrame == shot.screenFrame }) ?? windows.first else { continue }
            // Drawings live in the display's coordinates (the drawings layer stays put while the window resizes).
            let origin = window.screenFrame.origin
            if let layer = DrawingLayer.make(mark, color: color,
                                             point: { x, y in
                                                 let p = shot.globalPoint(x: x, y: y)
                                                 return CGPoint(x: p.x - origin.x, y: p.y - origin.y)
                                             },
                                             length: { shot.points($0) }) {
                window.overlay.drawings.addSublayer(layer)
            }
        }
        wake()
        let work = DispatchWorkItem { [weak self] in self?.fadeDrawings() }
        fadeDrawingsWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: work)
    }

    func clearDrawings() {
        fadeDrawingsWork?.cancel()
        windows.forEach { $0.overlay.drawings.sublayers?.forEach { $0.removeFromSuperlayer() } }
        wake()
    }

    /// Where the companion is now (global), for placing the text-mode field.
    var position: CGPoint { spring.position }

    // MARK: Windows

    private func rebuild() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.map { CompanionWindow(screen: $0) }
        windows.forEach {
            WindowSharing.apply(to: $0, model: model)
            $0.overlay.companion.setLook(look)
            if let bubble { $0.overlay.bubble.set(bubble.text, style: bubble.style, accent: color) }
        }
        applyColor()
        displayLink?.invalidate()
        // From the display, not a window: the overlay windows hide when there's nothing to show, and a window's
        // display link stops with it.
        displayLink = (NSScreen.main ?? NSScreen.screens.first)?.displayLink(target: self, selector: #selector(tick(_:)))
        displayLink?.add(to: .main, forMode: .common)
        wake()
    }

    private func applyColor() {
        windows.forEach { $0.overlay.companion.setColor(color) }
        if let bubble { showBubble(bubble.text, style: bubble.style) }
    }

    private func fadeDrawings() {
        for window in windows {
            for layer in window.overlay.drawings.sublayers ?? [] {
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.6)
                CATransaction.setCompletionBlock { [weak self] in
                    layer.removeFromSuperlayer()
                    self?.wake() // shrink the window back once the drawings are gone
                }
                layer.opacity = 0
                CATransaction.commit()
            }
        }
    }

    /// The docked companion's home: just below the menu bar icon (spec 019; was the notch's right wing).
    private var dockAnchor: CGPoint {
        let rect = StatusItemController.anchorRect
        return CGPoint(x: rect.midX, y: rect.minY - CompanionLayer.size / 2 - 4)
    }

    // MARK: Animation loop

    private func wake() {
        displayLink?.isPaused = false
    }

    @objc private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = lastTimestamp == 0 ? 1.0 / 60 : now - lastTimestamp
        lastTimestamp = now
        var busy = false

        if let f = flight {
            let t = min(1, (CACurrentMediaTime() - f.startTime) / f.duration)
            let e = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2 // ease in-out
            spring.position = Self.bezier(f.start, f.control, f.end, e)
            spring.velocity = .zero
            busy = true
            if t >= 1 {
                flight = nil
                if !f.returning { arrived(at: f.end, label: f.label) }
            }
        } else if let h = hold {
            busy = true
            let mouse = NSEvent.mouseLocation
            if Date() > h.until || hypot(mouse.x - h.point.x, mouse.y - h.point.y) < 40 {
                hold = nil
                windows.forEach { $0.overlay.label.isHidden = true }
                if look == .pointing { setLook(.idle) }
                if model.settings.cursorDocked {
                    flight = Flight(start: h.point, control: CompanionLayout.arcControl(from: h.point, to: dockAnchor),
                                    end: dockAnchor, startTime: CACurrentMediaTime(),
                                    duration: CompanionLayout.flightDuration(from: h.point, to: dockAnchor), label: "",
                                    returning: true)
                }
            }
        } else if !model.settings.cursorDocked {
            let mouse = NSEvent.mouseLocation
            let screen = NSScreen.screens.first { $0.frame.contains(mouse) }?.frame ?? .zero
            let size = CGSize(width: CompanionLayer.size, height: CompanionLayer.size)
            let target = CompanionLayout.anchor(mouse: mouse, screen: screen, size: size)
            if hypot(target.x - spring.position.x, target.y - spring.position.y) > 600 {
                spring = CompanionSpring(position: target) // jumped displays or woke up: no long glide
            } else {
                spring.step(toward: target, dt: dt)
            }
            busy = !spring.isSettled(at: target)
        }

        render()
        let animating = look == .thinking || look == .speaking || look == .listening
        let bubbleFading = windows.contains { ($0.fadingBubble?.until ?? 0) > CACurrentMediaTime() }
        if !busy && !animating && !bubbleFading { link.isPaused = true }
    }

    private func arrived(at point: CGPoint, label: String) {
        hold = (point, Date().addingTimeInterval(6))
        for window in windows where window.screenFrame.contains(point) {
            window.overlay.companion.bounce()
            window.overlay.label.set(label, color: color, near: window.local(point), within: window.overlay.bounds)
        }
    }

    private func render() {
        let pos = spring.position
        let flying = flight != nil || hold != nil
        let showCompanion = (flying || !model.settings.cursorDocked) && !agentBotOut
        let bubbleAnchor = showCompanion ? pos : CompanionLayout.anchor(mouse: NSEvent.mouseLocation,
                                                                       screen: NSScreen.main?.frame ?? .zero,
                                                                       size: CGSize(width: 22, height: 22))
        let now = CACurrentMediaTime()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for window in windows {
            let screen = window.screenFrame
            let here = screen.insetBy(dx: -1, dy: -1).contains(pos)
            let companionShown = showCompanion && here

            var bubbleRect: CGRect?
            if bubble != nil, screen.contains(bubbleAnchor) {
                let size = window.overlay.bubble.bounds.size
                bubbleRect = CGRect(origin: CompanionLayout.bubbleOrigin(companion: bubbleAnchor, bubble: size, screen: screen),
                                    size: size)
                window.fadingBubble = nil
            } else if window.overlay.bubbleShown, let last = window.fadingBubble?.rect {
                window.fadingBubble = (last, now + 0.35) // animating away: keep its space a moment
            }
            let fading = window.fadingBubble.flatMap { $0.until > now ? $0.rect : nil }

            // Size the window to what it shows: the whole display only while pointing or drawing.
            if flying || window.hasDrawings {
                window.fit(screen)
            } else {
                var rect: CGRect? = companionShown ? CGRect(x: pos.x - 48, y: pos.y - 48, width: 96, height: 96) : nil
                if let b = bubbleRect ?? fading {
                    let padded = b.insetBy(dx: -16, dy: -16)
                    rect = rect.map { $0.union(padded) } ?? padded
                }
                window.fit(rect?.intersection(screen))
            }

            window.overlay.companion.isHidden = !companionShown
            if here { window.overlay.companion.position = window.local(pos) }
            if let bubbleRect {
                window.overlay.showBubble(frame: window.local(bubbleRect), from: window.local(bubbleAnchor))
                window.fadingBubble = (bubbleRect, 0)
            } else {
                if let fading { window.overlay.placeBubble(frame: window.local(fading)) }
                window.overlay.hideBubble(toward: window.local(bubbleAnchor))
            }
        }
        CATransaction.commit()
    }

    private static func bezier(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        let u = 1 - t
        return CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x, y: u * u * a.y + 2 * u * t * c.y + t * t * b.y)
    }
}

import SwiftUI
