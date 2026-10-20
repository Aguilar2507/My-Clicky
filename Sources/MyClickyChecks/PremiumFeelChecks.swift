import Foundation
import MyClickyCore

/// Checks for spec 014: motion rules, the type scale and the tour's slide direction.
enum PremiumFeelChecks {
    static func run() {
        Check.group("Premium feel: motions follow the skill") {
            for motion in MotionSpec.all {
                Check.expect(motion.isValid, "\(motion.name) is a valid spring")
            }
            Check.equal(MotionSpec.standard.damping, 1.0, "default settles without overshoot")
            Check.equal(MotionSpec.all.filter { $0.damping < 1 }.map(\.name), ["bouncy"], "only bouncy bounces")
            Check.expect(MotionSpec.quick.response < MotionSpec.standard.response, "quick is snappier")
            Check.expect(MotionSpec.fadeDuration <= 0.25, "reduce-motion fades are short")
            Check.near(MotionSpec.standard.stiffness, pow(2 * .pi / 0.35, 2), "stiffness from response")
        }

        Check.group("Premium feel: type scale") {
            let text = TypeStyle.all.filter { !$0.uppercase }
            for (a, b) in zip(text, text.dropFirst()) {
                Check.expect(a.size >= b.size, "\(a.name) is not smaller than \(b.name)")
                Check.expect(a.tracking <= b.tracking, "\(a.name) is tracked no wider than \(b.name)")
            }
            Check.expect(TypeStyle.largeTitle.tracking < 0, "large text is tightened")
            Check.expect(TypeStyle.label.tracking > TypeStyle.body.tracking, "uppercase labels are opened up")
            Check.expect(TypeStyle.body.lineSpacing > TypeStyle.largeTitle.lineSpacing, "body leading is looser")
            Check.equal(Set(TypeStyle.all.map(\.name)).count, TypeStyle.all.count, "names are unique")
        }

        Check.group("Premium feel: tour direction") {
            Check.equal(TourDirection.between(.intro, .name), .forward)
            Check.equal(TourDirection.between(.apiKey, .permissions), .back)
            Check.equal(TourDirection.between(.done, .done), .same)
        }

        Check.group("Premium feel: haptics setting") {
            Check.expect(Settings().hapticFeedback, "on by default")
            let old = #"{"version": 5, "profileName": "Jose"}"#.data(using: .utf8)!
            let decoded = try TolerantDecoder.decode(Settings.self, from: old, defaults: Settings())
            Check.expect(decoded.hapticFeedback, "older settings files get haptics on")
            Check.equal(decoded.profileName, "Jose", "and keep their values")
        }
    }
}
