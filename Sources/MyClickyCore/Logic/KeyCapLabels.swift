import Foundation

/// Key cap texts as shown on the Shortcuts page ("^ control", "fn").
public enum KeyCapLabels {
    public static func label(_ modifier: Modifier) -> String {
        switch modifier {
        case .control: "^ control"
        case .option: "⌥ option"
        case .shift: "⇧ shift"
        case .command: "⌘ command"
        case .fn: "fn"
        }
    }

    /// Key caps for a shortcut. More than four caps ("⌃ ⌥ ⇧ ⌘ 3") use symbols only, so the row's title keeps its room.
    public static func caps(for chord: KeyChord, gesture: Gesture) -> [String] {
        let count = (chord.modifiers.count + (chord.keyCode == nil ? 0 : 1)) * (gesture == .doubleTap ? 2 : 1)
        var caps = chord.modifiers.sorted().map(count > 4 ? symbol : label)
        if let code = chord.keyCode { caps.append(keyName(code)) }
        return gesture == .doubleTap ? caps + caps : caps
    }

    public static func symbol(_ modifier: Modifier) -> String {
        switch modifier {
        case .control: "⌃"
        case .option: "⌥"
        case .shift: "⇧"
        case .command: "⌘"
        case .fn: "fn"
        }
    }

    /// Short description for inline text ("Hold fn", "Hold ⌥ Option").
    public static func holdHint(for chord: KeyChord) -> String {
        let names = chord.modifiers.sorted().map { m -> String in
            switch m {
            case .control: "⌃ Control"
            case .option: "⌥ Option"
            case .shift: "⇧ Shift"
            case .command: "⌘ Command"
            case .fn: "Fn"
            }
        }
        return names.joined(separator: " + ")
    }

    public static func keyName(_ code: UInt16) -> String {
        let names: [UInt16: String] = [
            0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J", 40: "K", 37: "L",
            46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W", 7: "X",
            16: "Y", 6: "Z", 29: "0", 18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9",
            49: "space", 36: "return", 48: "tab", 51: "delete", 53: "esc", 123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10",
            103: "F11", 111: "F12", 27: "-", 24: "=", 33: "[", 30: "]", 41: ";", 39: "'", 43: ",", 47: ".", 44: "/",
            42: "\\", 50: "`",
        ]
        return names[code] ?? "key \(code)"
    }
}
