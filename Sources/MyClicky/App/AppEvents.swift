import Foundation

/// Things the hands-on tour watches for (spec 012 US2). Features call `AppModel.emit(_:)`.
enum AppEvent: String, CaseIterable, Hashable {
    case notchExpanded, talkAnswered, pointed, textModeSent, dictationInserted

    var title: String {
        switch self {
        case .notchExpanded: "Hover the notch to open MyClicky"
        case .talkAnswered: "Hold fn and ask “what's on my screen?”"
        case .pointed: "Ask “where is the Apple menu?” and watch it point"
        case .textModeSent: "Double-tap control and type a question"
        case .dictationInserted: "Hold control + fn and dictate into the box below"
        }
    }
}

extension AppModel {
    func emit(_ event: AppEvent) {
        if !seenEvents.contains(event) { seenEvents.insert(event) }
    }
}
