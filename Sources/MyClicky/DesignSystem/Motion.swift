import SwiftUI
import QuartzCore
import MyClickyCore

/// Every animation in the app comes from here (spec 014, apple-design skill §3–§7). Springs start from what's on
/// screen and keep its velocity, so any motion can be interrupted and reversed without a jump. With Reduce Motion on,
/// each one becomes a short cross-fade.
enum Motion {
    static var standard: Animation { animation(.standard) }
    static var quick: Animation { animation(.quick) }
    static var bouncy: Animation { animation(.bouncy) }

    static func animation(_ spec: MotionSpec) -> Animation {
        if DisplayPrefs.shared.reduceMotion { return .easeOut(duration: MotionSpec.fadeDuration) }
        return .spring(response: spec.response, dampingFraction: spec.damping)
    }

    /// `withAnimation` with one of the shared motions.
    @discardableResult
    static func withAnimation<Result>(_ spec: MotionSpec = .standard, _ body: () throws -> Result) rethrows -> Result {
        try SwiftUI.withAnimation(animation(spec), body)
    }

    /// The same spring for Core Animation layers (companion bubble).
    static func caSpring(_ keyPath: String, from: Any?, to: Any?, _ spec: MotionSpec = .standard) -> CAAnimation {
        if DisplayPrefs.shared.reduceMotion {
            let fade = CABasicAnimation(keyPath: keyPath)
            fade.fromValue = from
            fade.toValue = to
            fade.duration = MotionSpec.fadeDuration
            fade.timingFunction = CAMediaTimingFunction(name: .easeOut)
            return fade
        }
        let spring = CASpringAnimation(keyPath: keyPath)
        spring.fromValue = from
        spring.toValue = to
        spring.mass = 1
        spring.stiffness = spec.stiffness
        spring.damping = spec.dampingCoefficient
        spring.duration = spring.settlingDuration
        return spring
    }
}

// MARK: Transitions

extension AnyTransition {
    /// Glass arriving: scales up slightly while its blur clears (skill §12 "materialize, don't just fade").
    /// Leaves the same way it came. Opacity only with Reduce Motion.
    static var materialize: AnyTransition {
        .modifier(active: MaterializeEffect(progress: 0), identity: MaterializeEffect(progress: 1))
    }

    /// Slides along x in the direction of travel: forward enters from the trailing edge, back undoes that path.
    static func slide(forward: Bool) -> AnyTransition {
        if DisplayPrefs.shared.reduceMotion { return .opacity }
        return .push(from: forward ? .trailing : .leading)
    }

    /// Grows out of its source (a trigger) and shrinks back into it.
    static func grow(from anchor: UnitPoint) -> AnyTransition {
        if DisplayPrefs.shared.reduceMotion { return .opacity }
        return .scale(scale: 0.94, anchor: anchor).combined(with: .opacity)
    }
}

private struct MaterializeEffect: ViewModifier {
    let progress: Double

    func body(content: Content) -> some View {
        let still = DisplayPrefs.shared.reduceMotion
        content
            .scaleEffect(still ? 1 : 0.96 + 0.04 * progress)
            .blur(radius: still ? 0 : 8 * (1 - progress))
            .opacity(progress)
    }
}
