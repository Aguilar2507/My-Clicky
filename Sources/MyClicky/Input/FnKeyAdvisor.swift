import AppKit
import MyClickyCore

/// macOS can open the emoji picker or dictation when 🌐/fn is pressed; that fights with fn shortcuts (research R2).
enum FnKeyAdvisor {
    /// 0 = Do Nothing, 1 = Change Input Source, 2 = Show Emoji & Symbols, 3 = Start Dictation.
    static var fnUsageType: Int {
        (CFPreferencesCopyAppValue("AppleFnUsageType" as CFString, "com.apple.HIToolbox" as CFString) as? NSNumber)?.intValue ?? 1
    }

    static func needsWarning(bindings: [ShortcutBinding]) -> Bool {
        bindings.contains { $0.chord.modifiers.contains(.fn) } && fnUsageType != 0
    }

    static var currentActionName: String {
        switch fnUsageType {
        case 0: "Do Nothing"
        case 2: "Show Emoji & Symbols"
        case 3: "Start Dictation"
        default: "Change Input Source"
        }
    }

    static func openKeyboardSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!)
    }
}
