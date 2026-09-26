import AppKit
import QuartzCore
import MyClickyCore

/// The cursor companion (spec 006): a glowing triangle that trails the pointer on every display, shows answers in a
/// bubble, flies to point at things, draws on screen, and can dock in the notch.
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
        observeChanges({ model.isNotchOpen }) { [weak self] _ in self?.wake() }
    }

    // MARK: Public API

    var color: NSColor { NSColor(Color(hex: model.settings.cursorColor.hex)) }

    func setLook(_ look: CompanionLayer.Look) {
        self.look = look
        windows.forEach { $0.overlay.companion.setLook(look) }
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
        let start = model.settings.cursorDocked && flight == nil && hold == nil ? notchAnchor : spring.position
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
            guard let window = windows.first(where: { $0.frame == shot.screenFrame }) ?? windows.first else { continue }
            if let layer = DrawingLayer.make(mark, color: color,
                                             point: { x, y in window.local(shot.globalPoint(x: x, y: y)) },
                                             length: { shot.points($0) }) {
                window.overlay.drawings.addSublayer(layer)
            }
        }
        let work = DispatchWorkItem { [weak self] in self?.fadeDrawings() }
        fadeDrawingsWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: work)
    }

    func clearDrawings() {
        fadeDrawingsWork?.cancel()
        windows.forEach { $0.overlay.drawings.sublayers?.forEach { $0.removeFromSuperlayer() } }
    }

    /// Where the companion is now (global), for placing the text-mode field.
    var position: CGPoint { spring.position }

    // MARK: Windows

    private func rebuild() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.map { CompanionWindow(screen: $0) }
        windows.forEach {
            WindowSharing.apply(to: $0, model: model)
            $0.orderFrontRegardless()
            $0.overlay.companion.setLook(look)
            if let bubble { $0.overlay.bubble.set(bubble.text, style: bubble.style, accent: color) }
        }
        applyColor()
        displayLink?.invalidate()
        displayLink = windows.first?.overlay.displayLink(target: self, selector: #selector(tick(_:)))
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
                CATransaction.setCompletionBlock { layer.removeFromSuperlayer() }
                layer.opacity = 0
                CATransaction.commit()
            }
        }
    }

    /// The docked companion's home: the right wing of the notch.
    private var notchAnchor: CGPoint {
        let screen = NSScreen.screens.first { $0.auxiliaryTopLeftArea != nil } ?? NSScreen.main ?? NSScreen.screens[0]
        let rect = NotchController.geometry(for: screen).collapsedRect
        return CGPoint(x: rect.maxX - NotchGeometry.wingWidth / 2, y: rect.midY)
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
                    flight = Flight(start: h.point, control: CompanionLayout.arcControl(from: h.point, to: notchAnchor),
                                    end: notchAnchor, startTime: CACurrentMediaTime(),
                                    duration: CompanionLayout.flightDuration(from: h.point, to: notchAnchor), label: "",
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
        if !busy && !animating { link.isPaused = true }
    }

    private func arrived(at point: CGPoint, label: String) {
        hold = (point, Date().addingTimeInterval(6))
        for window in windows where window.frame.contains(point) {
            window.overlay.companion.bounce()
            window.overlay.label.set(label, color: color, near: window.local(point), within: window.overlay.bounds)
        }
    }

    private func render() {
        let pos = spring.position
        let flying = flight != nil || hold != nil
        let showCompanion = (flying || !model.settings.cursorDocked) && (flying || !model.isNotchOpen)
        let bubbleAnchor = showCompanion ? pos : CompanionLayout.anchor(mouse: NSEvent.mouseLocation,
                                                                       screen: NSScreen.main?.frame ?? .zero,
                                                                       size: CGSize(width: 22, height: 22))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for window in windows {
            let here = window.frame.insetBy(dx: -1, dy: -1).contains(pos)
            window.overlay.companion.isHidden = !(showCompanion && here)
            if here { window.overlay.companion.position = window.local(pos) }

            let bubbleHere = window.frame.contains(bubbleAnchor)
            if let bubble, bubbleHere, !model.isNotchOpen {
                _ = bubble
                let size = window.overlay.bubble.bounds.size
                let origin = CompanionLayout.bubbleOrigin(companion: bubbleAnchor, bubble: size, screen: window.frame)
                window.overlay.bubble.frame = CGRect(origin: window.local(origin), size: size)
                window.overlay.bubble.isHidden = false
            } else {
                window.overlay.bubble.isHidden = true
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
