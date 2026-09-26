import AppKit
import MyClickyCore

/// Owns the key tap and the matcher; turns keys into MyClicky actions. While the Shortcuts page records a new
/// shortcut, events go to the recorder instead.
@MainActor
final class ShortcutCenter {
    let model: AppModel
    var onEvent: (ShortcutMatcher.Event) -> Void = { _ in }

    private let tap = HotkeyTap()
    private var matcher: ShortcutMatcher
    private var ticker: Timer?
    private var recorder: ShortcutRecorderLogic?
    private var onRecorded: ((KeyChord, Gesture) -> Void)?
    /// Live modifiers while recording (for key caps).
    private(set) var recordingModifiers: Set<Modifier> = []
    var onRecordingChange: (Set<Modifier>) -> Void = { _ in }

    init(model: AppModel) {
        self.model = model
        matcher = ShortcutMatcher(bindings: ShortcutBinding.normalized(model.settings.shortcuts))
        tap.onFlags = { [weak self] mods in self?.flags(mods) }
        tap.onKeyDown = { [weak self] code in self?.key(code) ?? false }
        observeChanges({ model.settings.shortcuts }) { [weak self] bindings in
            self?.matcher.bindings = ShortcutBinding.normalized(bindings)
        }
    }

    var isListening: Bool { tap.isRunning }

    /// Starts listening. Returns false when Accessibility/Input Monitoring aren't granted yet.
    @discardableResult
    func start() -> Bool { tap.start() }

    // MARK: Recording

    func beginRecording(_ done: @escaping (KeyChord, Gesture) -> Void) {
        recorder = ShortcutRecorderLogic()
        onRecorded = done
        recordingModifiers = []
        startTicker()
    }

    func cancelRecording() {
        recorder = nil
        onRecorded = nil
        recordingModifiers = []
    }

    var isRecording: Bool { recorder != nil }

    // MARK: Events

    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    private func flags(_ mods: Set<Modifier>) {
        if recorder != nil {
            recordingModifiers = mods.isEmpty ? recordingModifiers : mods
            onRecordingChange(mods)
            finish(recorder!.flagsChanged(mods, at: now))
            return
        }
        matcher.flagsChanged(mods, at: now).forEach(onEvent)
        if matcher.needsTick { startTicker() }
    }

    private func key(_ code: UInt16) -> Bool {
        if recorder != nil {
            if code == 53 { cancelRecording(); onRecordingChange([]); return true } // Esc cancels
            finish(recorder!.keyDown(code))
            return true
        }
        let result = matcher.keyDown(code, at: now)
        result.events.forEach(onEvent)
        return result.swallow
    }

    private func finish(_ result: ShortcutRecorderLogic.Result) {
        guard case .recorded(let chord, let gesture) = result else { return }
        let done = onRecorded
        cancelRecording()
        done?(chord, gesture)
    }

    private func startTicker() {
        guard ticker == nil else { return }
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.recorder != nil {
                    self.finish(self.recorder!.tick(at: self.now))
                } else {
                    self.matcher.tick(at: self.now).forEach(self.onEvent)
                }
                if !self.matcher.needsTick && self.recorder == nil {
                    self.ticker?.invalidate()
                    self.ticker = nil
                }
            }
        }
    }
}
