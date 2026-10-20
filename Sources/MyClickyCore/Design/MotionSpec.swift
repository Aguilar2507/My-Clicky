import Foundation

/// The app's shared motions (spec 014, apple-design skill §4). Springs are described the way Apple does: `response`
/// (seconds to reach the target, not a duration) and `damping` (1 = no overshoot, < 1 = bounce).
public struct MotionSpec: Equatable, Sendable {
    public let name: String
    public let response: Double
    public let damping: Double

    /// Panels, modals, tour steps, selection: settles without overshoot.
    public static let standard = MotionSpec(name: "standard", response: 0.35, damping: 1.0)
    /// Press, hover, small controls, meters.
    public static let quick = MotionSpec(name: "quick", response: 0.2, damping: 1.0)
    /// Toggle knob and gesture-driven motion only: momentum earns the bounce.
    public static let bouncy = MotionSpec(name: "bouncy", response: 0.35, damping: 0.8)

    /// What replaces every spring when Reduce Motion is on: a short cross-fade.
    public static let fadeDuration = 0.18

    public static let all = [standard, quick, bouncy]

    /// Core Animation's physical parameters for the same spring (mass 1).
    public var stiffness: Double { pow(2 * .pi / response, 2) }
    public var dampingCoefficient: Double { 4 * .pi * damping / response }

    /// Rules from the skill: damping in (0, 1], response 0.15–0.5 s, and only `bouncy` may overshoot.
    public var isValid: Bool {
        damping > 0 && damping <= 1 && (0.15...0.5).contains(response) && (damping == 1 || name == "bouncy")
    }
}

/// Direction of a step change in the welcome tour, so steps slide the way you're going and back out the way they came.
public enum TourDirection: Equatable, Sendable {
    case forward, back, same

    public static func between(_ old: TourState.Step, _ new: TourState.Step) -> TourDirection {
        let steps = TourState.Step.allCases
        guard let a = steps.firstIndex(of: old), let b = steps.firstIndex(of: new), a != b else { return .same }
        return b > a ? .forward : .back
    }
}
