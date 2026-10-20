import AppKit
import SwiftUI
import QuartzCore

/// The agent bot beside the cursor (spec 018 US2). When you say "Jarvis agent", the home page's bot pops out of the
/// bottom-left corner of the display, lands beside your pointer and listens (floating, blinking, eyes wide and
/// following you). When you let go it nods and flies back into the same corner, as if it went off to work (the task
/// really runs in the background). Reduce Motion: it fades in and out beside the pointer.
///
/// A small panel that exists only while the bot is out, so nothing stays on screen or on other Spaces.
@MainActor
final class AgentBotPresenter {
    private final class Presence: ObservableObject {
        @Published var shown = false
        @Published var nodding = false
    }

    private static let side: CGFloat = 132
    private var panel: NSPanel?
    private let presence = Presence()
    private var follow: CADisplayLink?
    private var dismissing = false
    private(set) var isOut = false

    // MARK: Arrive

    func summon() {
        guard !isOut else { return }
        isOut = true
        dismissing = false
        let panel = self.panel ?? makePanel()
        self.panel = panel
        let still = DisplayPrefs.shared.reduceMotion
        let target = Self.beside(NSEvent.mouseLocation)
        panel.setFrame(still ? target : Self.corner(for: NSEvent.mouseLocation), display: false)
        presence.shown = false
        presence.nodding = false
        panel.orderFrontRegardless()

        withAnimation(still ? .easeOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.68)) {
            presence.shown = true
        }
        guard !still else { startFollowing(); return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            // A little overshoot: it pops up beside the pointer.
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1.18, 0.36, 1)
            panel.animator().setFrame(target, display: true)
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated { self?.startFollowing() }
        })
    }

    // MARK: Leave

    /// `nod`: it heard a task and nods before leaving. `completion` runs once it's gone.
    func dismiss(nod: Bool, completion: @escaping () -> Void = {}) {
        guard isOut, !dismissing, let panel else { completion(); return }
        dismissing = true
        stopFollowing()
        let still = DisplayPrefs.shared.reduceMotion
        let leave = { [weak self] in
            guard let self else { return }
            withAnimation(.easeIn(duration: still ? 0.2 : 0.42)) { self.presence.shown = false }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = still ? 0.2 : 0.45
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.5, 0, 0.9, 0.4)
                if !still { panel.animator().setFrame(Self.corner(for: panel.frame.center), display: true) }
            }, completionHandler: { [weak self] in
                MainActor.assumeIsolated {
                    guard let self, self.dismissing else { return }
                    panel.orderOut(nil)
                    self.isOut = false
                    self.dismissing = false
                    completion()
                }
            })
        }
        guard nod, !still else { leave(); return }
        // "Got it": a quick nod, then off to work.
        withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { presence.nodding = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { self?.presence.nodding = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { leave() }
    }

    // MARK: Follow the pointer while listening

    private func startFollowing() {
        guard isOut, !dismissing, follow == nil else { return }
        follow = (NSScreen.main ?? NSScreen.screens.first)?.displayLink(target: self, selector: #selector(step))
        follow?.add(to: .main, forMode: .common)
    }

    private func stopFollowing() {
        follow?.invalidate()
        follow = nil
    }

    @objc private func step() {
        guard let panel else { return }
        let target = Self.beside(NSEvent.mouseLocation).origin
        let current = panel.frame.origin
        let next = CGPoint(x: current.x + (target.x - current.x) * 0.18, y: current.y + (target.y - current.y) * 0.18)
        if abs(next.x - current.x) > 0.3 || abs(next.y - current.y) > 0.3 { panel.setFrameOrigin(next) }
    }

    // MARK: Geometry

    /// Beside the pointer (below and to the right, like the companion), kept on the display.
    private static func beside(_ point: CGPoint) -> CGRect {
        let screen = NSScreen.screens.first { $0.frame.contains(point) }?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        var origin = CGPoint(x: point.x + 18, y: point.y - side + 6)
        origin.x = min(max(origin.x, screen.minX + 4), screen.maxX - side - 4)
        origin.y = min(max(origin.y, screen.minY + 4), screen.maxY - side - 4)
        return CGRect(origin: origin, size: CGSize(width: side, height: side))
    }

    /// The bottom-left corner of the display with the pointer: where the bot comes from and goes back to.
    private static func corner(for point: CGPoint) -> CGRect {
        let screen = NSScreen.screens.first { $0.frame.contains(point) }?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        return CGRect(x: screen.minX - side * 0.25, y: screen.minY - side * 0.25, width: side, height: side)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: CGRect(x: 0, y: 0, width: Self.side, height: Self.side),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient]
        panel.animationBehavior = .none
        panel.contentView = NSHostingView(rootView: AgentBotStage(presence: presence))
        WindowSharing.apply(to: panel, model: AppModel.shared)
        return panel
    }

    private struct AgentBotStage: View {
        @ObservedObject var presence: Presence

        var body: some View {
            LivelyBot(sparkles: true)
                .frame(width: 104, height: 104)
                .scaleEffect(presence.shown ? (presence.nodding ? 1.1 : 1) : 0.3, anchor: .bottom)
                .offset(y: presence.nodding ? 6 : 0)
                .opacity(presence.shown ? 1 : 0)
                .frame(width: AgentBotPresenter.side, height: AgentBotPresenter.side)
        }
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
