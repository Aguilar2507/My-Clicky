import Foundation

/// Things the hands-on tour watches for (spec 012 US2). Features call `AppModel.emit(_:)`.
enum AppEvent: String, CaseIterable, Hashable {
    /// Raw value kept from spec 012 (the notch home) so saved tour progress still matches.
    case appOpened = "notchExpanded"
    case talkAnswered, pointed, textModeSent, dictationInserted

    var title: String {
        switch self {
        case .appOpened: "Press option + space to open MyClicky"
        case .talkAnswered: "Hold control + option and say “Jarvis, what's on my screen?”"
        case .pointed: "Ask “where is the Apple menu?” and watch it point"
        case .textModeSent: "Double-tap control and type a question"
        case .dictationInserted: "Hold control + fn and dictate into the box below"
        }
    }
}

extension AppModel {
    func emit(_ event: AppEvent) {
        Log.events.notice("event \(event.rawValue, privacy: .public)")
        if !seenEvents.contains(event) { seenEvents.insert(event) }
    }
}
