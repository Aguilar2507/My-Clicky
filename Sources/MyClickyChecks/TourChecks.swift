import Foundation
import MyClickyCore

/// Checks for spec 012 (welcome tour).
enum TourChecks {
    static func run() {
        Check.group("Tour flow") {
            var s = TourState()
            Check.equal(s.step, .intro)
            s = TourFlow.next(s, completing: true)
            Check.equal(s.step, .name)
            s = TourFlow.back(s)
            Check.equal(s.step, .intro, "back")
            for _ in 0..<3 { s = TourFlow.next(s, completing: true) }
            Check.equal(s.step, .apiKey)
            Check.expect(!TourFlow.canSkip(.apiKey), "the API key step can't be skipped")
            Check.expect(TourFlow.canSkip(.permissions), "permissions can be skipped with a warning")
            s = TourFlow.next(s, completing: true)
            s = TourFlow.next(s, completing: false) // skipped Claude Code
            Check.expect(!s.completed.contains(.claudeCode), "skipping doesn't mark complete")
            s = TourFlow.next(s, completing: true); s = TourFlow.next(s, completing: true)
            Check.equal(s.step, .done)
            Check.expect(s.finished)
            let resumed = try JSONFile.decoder.decode(TourState.self, from: JSONFile.encode(s))
            Check.equal(resumed, s, "resumes where it was")
            let replay = TourFlow.replay(s)
            Check.equal(replay.step, .intro)
            Check.expect(!replay.finished && replay.completed.contains(.apiKey), "replay keeps completed steps")
            Check.equal(TourFlow.progress(replay).total, 8)
        }

        Check.group("Tour: upgrading users") {
            let fresh = TourState()
            Check.expect(TourFlow.initial(hasAPIKey: true, allPermissionsGranted: true, existing: fresh).finished,
                         "key + permissions → not forced through the tour")
            Check.expect(!TourFlow.initial(hasAPIKey: true, allPermissionsGranted: false, existing: fresh).finished)
            var midway = TourState()
            midway.completed = [.intro]
            Check.expect(!TourFlow.initial(hasAPIKey: true, allPermissionsGranted: true, existing: midway).finished,
                         "a tour in progress continues")
        }

        Check.group("Interview → three Clickys") {
            let reply = #"""
            {"clickys": [
              {"name": "Signal Radar", "color": "peach", "purpose": "Watches AI news."},
              {"name": "Role Scout", "color": "lilac", "purpose": "Finds AI architect roles."},
              {"name": "Build Lab", "color": "butter", "purpose": "Plans portfolio projects."}
            ]}
            """#
            let result = InterviewParser.parse(reply, existing: ["Role Scout"])
            Check.equal(result.agents.map(\.name), ["Signal Radar", "Role Scout 2", "Build Lab"], "unique names")
            Check.equal(result.agents.map(\.color), [.peach, .lilac, .butter])
            Check.expect(!result.usedFallback)
            let partial = InterviewParser.parse(#"{"clickys":[{"name":"Shippy","purpose":"Ships things."}]}"#, existing: [])
            Check.equal(partial.agents.count, 3, "always three")
            Check.expect(partial.usedFallback)
            Check.equal(partial.agents.first?.name, "Shippy")
            let none = InterviewParser.parse("sorry", existing: ["Research Buddy"])
            Check.equal(none.agents.map(\.name), ["Research Buddy 2", "Build Lab", "Inbox Helper"], "generic starters")
        }
    }
}
