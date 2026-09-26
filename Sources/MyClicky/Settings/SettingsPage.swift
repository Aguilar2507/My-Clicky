import Foundation

/// Settings pages (refs 03–10). A page appears in the sidebar only once its feature is built.
enum SettingsPage: String, CaseIterable, Identifiable {
    case general, voice, microphone, dictation, shortcuts, cursor, agents, integrations

    var id: String { rawValue }

    enum Group { case none, myclicky, work }

    var group: Group {
        switch self {
        case .general: .none
        case .voice, .microphone, .dictation, .shortcuts, .cursor: .myclicky
        case .agents, .integrations: .work
        }
    }

    var title: String {
        switch self {
        case .general: "General"
        case .voice: "Voice"
        case .microphone: "Microphone"
        case .dictation: "Dictation"
        case .shortcuts: "Shortcuts"
        case .cursor: "Cursor"
        case .agents: "Agents"
        case .integrations: "Integrations"
        }
    }

    var subtitle: String {
        switch self {
        case .general: "How MyClicky behaves on your Mac."
        case .voice: "The voice MyClicky answers in, and how fast it talks."
        case .microphone: "Which microphone MyClicky listens through."
        case .dictation: "Languages and the words MyClicky should spell right."
        case .shortcuts: "The keys that summon MyClicky."
        case .cursor: "The MyClicky cursor that lives on your screen."
        case .agents: "Where agents work and how much rope they get."
        case .integrations: "Apps your agents can reach into."
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .voice: "waveform"
        case .microphone: "mic.fill"
        case .dictation: "character.cursor.ibeam"
        case .shortcuts: "command"
        case .cursor: "cursorarrow"
        case .agents: "circle.grid.2x2.fill"
        case .integrations: "puzzlepiece.extension.fill"
        }
    }

    /// Pages whose feature has been built. Each feature adds its page here (specs 006–010).
    static var available: Set<SettingsPage> = [.general, .voice, .microphone, .shortcuts, .cursor]

    var isAvailable: Bool { Self.available.contains(self) }
}
