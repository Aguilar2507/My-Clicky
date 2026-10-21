import AppKit
import MyClickyCore

/// Dictation (spec 008): hold ⌃fn to dictate into any app, or double-tap ⌃fn for hands-free (double-tap again to
/// insert, Esc to cancel). Text is transcribed on the Mac and never sent anywhere or saved in chats.
@MainActor
final class DictationController {
    enum Mode { case hold, handsFree }

    let model: AppModel
    let companion: CompanionController
    private let speech = SpeechRecognizer()
    private(set) var mode: Mode?
    private var capWork: DispatchWorkItem?
    static let handsFreeLimit: TimeInterval = 10 * 60

    init(model: AppModel, companion: CompanionController) {
        self.model = model
        self.companion = companion
        speech.onLevel = { [weak companion] in companion?.setLevel($0) }
        speech.onPartial = { [weak self] text in
            guard let self, self.mode == .handsFree, !text.isEmpty else { return }
            self.companion.showBubble(text, style: .listening)
        }
    }

    var isActive: Bool { mode != nil }

    // MARK: Shortcut events

    func holdBegan() {
        guard mode == nil else { return }
        start(.hold)
    }

    func holdEnded() {
        guard mode == .hold else { return }
        finish(insert: true)
    }

    func holdCancelled() {
        guard mode == .hold else { return }
        finish(insert: false)
    }

    func toggleHandsFree() {
        if mode == .handsFree { finish(insert: true) } else if mode == nil { start(.handsFree) }
    }

    /// Esc during dictation cancels without inserting. Returns true if it handled the key.
    func escape() -> Bool {
        guard mode != nil else { return false }
        finish(insert: false)
        companion.showBubble("Dictation cancelled", style: .info, autoHide: 1.5)
        return true
    }

    // MARK: Flow

    private func start(_ mode: Mode) {
        if TextInserter.focusedElement().isSecure {
            Log.events.notice("dictation refusedSecure (before recording)")
            companion.showBubble("Can't dictate into password fields", style: .info, autoHide: 2.5)
            return
        }
        do {
            try speech.start(model.settings)
        } catch {
            companion.showBubble(error.localizedDescription, style: .info, autoHide: 4)
            return
        }
        self.mode = mode
        model.isDictating = true
        companion.setLook(.listening)
        companion.showBubble(mode == .hold ? "Dictating…" : "Hands-free · \(stopHint)", style: .listening)
        if let missing = speech.missingOnDeviceLanguages.first {
            companion.showBubble("Download \(missing) in System Settings → Keyboard → Dictation to keep dictation offline.",
                                 style: .info, autoHide: 4)
        }
        if mode == .handsFree {
            let work = DispatchWorkItem { [weak self] in
                guard let self, self.mode == .handsFree else { return }
                self.finish(insert: true, notice: "Stopped after 10 minutes")
            }
            capWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.handsFreeLimit, execute: work)
        }
    }

    private func finish(insert: Bool, notice: String? = nil) {
        capWork?.cancel()
        mode = nil
        model.isDictating = false
        companion.setLook(.idle)
        guard insert else {
            speech.cancel()
            companion.hideBubble()
            return
        }
        Task {
            let text = await speech.stop()
            guard !text.isEmpty else { companion.hideBubble(); return }
            let outcome = TextInserter.insert(text)
            Log.events.notice("dictation \("\(outcome)", privacy: .public) chars=\(text.count, privacy: .public) app=\(NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "?", privacy: .public)")
            switch outcome {
            case .inserted:
                model.emit(.dictationInserted)
                companion.hideBubble()
                if let notice { companion.showBubble(notice, style: .info, autoHide: 2) }
            case .copiedNoField:
                companion.showBubble("Copied — no text field was focused", style: .info, autoHide: 2.5)
            case .refusedSecure:
                companion.showBubble("Can't dictate into password fields", style: .info, autoHide: 2.5)
            }
        }
    }

    private var stopHint: String {
        let binding = ShortcutBinding.normalized(model.settings.shortcuts).first { $0.action == .handsFreeDictation }!
        return KeyCapLabels.caps(for: binding.chord, gesture: binding.gesture).joined(separator: " ") + " to stop"
    }
}
