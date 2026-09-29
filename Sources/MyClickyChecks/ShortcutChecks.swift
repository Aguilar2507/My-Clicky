import Foundation
import MyClickyCore

/// Checks for spec 004: shortcut matching, recording, labels and conflicts.
enum ShortcutChecks {
    static func run() {
        let defaults = ShortcutBinding.defaults

        Check.group("Shortcuts: ⌃⌥ hold (push to talk)") {
            var m = ShortcutMatcher(bindings: defaults)
            Check.equal(m.flagsChanged([.control], at: 0), [], "⌃ alone does nothing yet")
            Check.equal(m.flagsChanged([.control, .option], at: 0.05), [.began(.pushToTalk)], "⌃⌥ has no double-tap → begins at once")
            Check.equal(m.flagsChanged([.control], at: 2), [.ended(.pushToTalk)], "letting go of ⌥ sends")
            Check.equal(m.flagsChanged([], at: 2.1), [])
            var optionFirst = ShortcutMatcher(bindings: defaults)
            _ = optionFirst.flagsChanged([.option], at: 0)
            Check.equal(optionFirst.flagsChanged([.option, .control], at: 0.05), [.began(.pushToTalk)], "either order works")
            _ = m.flagsChanged([.control, .option], at: 5)
            Check.equal(m.keyDown(0, at: 5.1).events, [.cancelled(.pushToTalk)], "⌃⌥A cancels")
            Check.equal(m.flagsChanged([], at: 5.2), [], "nothing more after cancel")
            var fnOnly = ShortcutMatcher(bindings: defaults)
            Check.equal(fnOnly.flagsChanged([.fn], at: 0), [], "fn alone doesn't talk")
            Check.equal(fnOnly.flagsChanged([], at: 2), [])
            var option = ShortcutMatcher(bindings: defaults)
            Check.equal(option.flagsChanged([.option], at: 0), [], "⌥ alone doesn't talk")
            Check.equal(option.flagsChanged([.option, .command], at: 0.05), [], "⌥⌘ doesn't talk")
        }

        Check.group("Shortcuts: double-tap control (text mode)") {
            var m = ShortcutMatcher(bindings: defaults)
            _ = m.flagsChanged([.control], at: 0); _ = m.flagsChanged([], at: 0.1)
            _ = m.flagsChanged([.control], at: 0.3)
            Check.equal(m.flagsChanged([], at: 0.4), [.triggered(.textMode)])
            var slow = ShortcutMatcher(bindings: defaults)
            _ = slow.flagsChanged([.control], at: 0); _ = slow.flagsChanged([], at: 0.1)
            _ = slow.flagsChanged([.control], at: 0.6)
            Check.equal(slow.flagsChanged([], at: 0.7), [], "taps too far apart")
            var typing = ShortcutMatcher(bindings: defaults)
            _ = typing.flagsChanged([.control], at: 0); _ = typing.keyDown(0, at: 0.05); _ = typing.flagsChanged([], at: 0.1)
            _ = typing.flagsChanged([.control], at: 0.2)
            Check.equal(typing.flagsChanged([], at: 0.3), [], "⌃A then ⌃ isn't a double tap")
        }

        Check.group("Shortcuts: ⌃fn hold vs ⌃fn ⌃fn") {
            var m = ShortcutMatcher(bindings: defaults)
            _ = m.flagsChanged([.control], at: 0)
            Check.equal(m.flagsChanged([.control, .fn], at: 0.02), [], "waits: could be a double tap")
            Check.expect(m.needsTick)
            Check.equal(m.tick(at: 0.2), [])
            Check.equal(m.tick(at: 0.33), [.began(.dictate)], "held 0.3 s → dictate")
            Check.equal(m.flagsChanged([.control], at: 3), [.ended(.dictate)])
            _ = m.flagsChanged([], at: 3.05)

            var d = ShortcutMatcher(bindings: defaults)
            _ = d.flagsChanged([.control], at: 10); _ = d.flagsChanged([.control, .fn], at: 10.01)
            _ = d.flagsChanged([.control], at: 10.1); _ = d.flagsChanged([], at: 10.12)
            _ = d.flagsChanged([.control], at: 10.25); _ = d.flagsChanged([.control, .fn], at: 10.26)
            _ = d.flagsChanged([.control], at: 10.33)
            Check.equal(d.flagsChanged([], at: 10.35), [.triggered(.handsFreeDictation)])

            var fnFirst = ShortcutMatcher(bindings: defaults)
            Check.equal(fnFirst.flagsChanged([.fn], at: 0), [], "fn alone does nothing")
            Check.equal(fnFirst.flagsChanged([.fn, .control], at: 0.05), [], "⌃fn waits: could be a double tap")
            Check.equal(fnFirst.tick(at: 0.4), [.began(.dictate)])
        }

        Check.group("Shortcuts: rebinding, combos, conflicts") {
            var custom = ShortcutBinding.defaults
            custom[0] = ShortcutBinding(.pushToTalk, KeyChord([.option]), .hold)
            custom.append(ShortcutBinding(.textMode, KeyChord([.command, .shift], keyCode: 49), .press))
            custom.remove(at: 1)
            var m = ShortcutMatcher(bindings: custom)
            Check.equal(m.flagsChanged([.option], at: 0), [.began(.pushToTalk)])
            _ = m.flagsChanged([], at: 1)
            _ = m.flagsChanged([.command, .shift], at: 2)
            let press = m.keyDown(49, at: 2.1)
            Check.equal(press.events, [.triggered(.textMode)])
            Check.expect(press.swallow, "combo key is swallowed")
            Check.equal(m.keyDown(0, at: 3).swallow, false, "other keys pass through")

            let clash = ShortcutBinding(.textMode, KeyChord([.control, .option]), .hold)
            Check.equal(ShortcutBinding.conflict(for: clash, in: defaults), .pushToTalk)
            Check.equal(ShortcutBinding.conflict(for: defaults[1], in: defaults), nil, "own binding isn't a conflict")
            Check.expect(!ShortcutBinding(.textMode, KeyChord([]), .hold).isValid, "empty hold is invalid")
            Check.equal(ShortcutBinding.normalized([]).map(\.action), ShortcutAction.allCases, "missing → defaults")
        }

        Check.group("Shortcuts: recorder") {
            var r = ShortcutRecorderLogic()
            _ = r.flagsChanged([.option], at: 0)
            Check.equal(r.flagsChanged([], at: 0.5), .recorded(KeyChord([.option]), .hold), "long press → hold")
            var d = ShortcutRecorderLogic()
            _ = d.flagsChanged([.control], at: 0); _ = d.flagsChanged([], at: 0.1)
            _ = d.flagsChanged([.control], at: 0.3)
            Check.equal(d.flagsChanged([], at: 0.4), .recorded(KeyChord([.control]), .doubleTap))
            var single = ShortcutRecorderLogic()
            _ = single.flagsChanged([.fn], at: 0); _ = single.flagsChanged([], at: 0.1)
            Check.equal(single.tick(at: 0.3), .waiting)
            Check.equal(single.tick(at: 0.5), .recorded(KeyChord([.fn]), .hold), "one short tap → hold")
            var combo = ShortcutRecorderLogic()
            _ = combo.flagsChanged([.command], at: 0)
            Check.equal(combo.keyDown(49), .recorded(KeyChord([.command], keyCode: 49), .press))
        }

        Check.group("Shortcuts: key caps") {
            Check.equal(KeyCapLabels.caps(for: KeyChord([.fn]), gesture: .hold), ["fn"])
            Check.equal(KeyCapLabels.caps(for: KeyChord([.control]), gesture: .doubleTap), ["^ control", "^ control"])
            Check.equal(KeyCapLabels.caps(for: KeyChord([.fn, .control]), gesture: .doubleTap),
                        ["^ control", "fn", "^ control", "fn"], "ref 07 order")
            Check.equal(KeyCapLabels.caps(for: KeyChord([.command], keyCode: 49), gesture: .press), ["⌘ command", "space"])
            Check.equal(KeyCapLabels.holdHint(for: KeyChord([.fn])), "Fn")
        }

        Check.group("Settings: 004 fields") {
            let old = #"{"fastModel":"x"}"#.data(using: .utf8)!
            let s = try TolerantDecoder.decode(Settings.self, from: old, defaults: Settings())
            Check.equal(s.shortcuts, ShortcutBinding.defaults, "older file gets default shortcuts")
            Check.equal(s.showInScreenRecordings, true)
            Check.expect(!s.profileName.isEmpty)
        }
    }
}
