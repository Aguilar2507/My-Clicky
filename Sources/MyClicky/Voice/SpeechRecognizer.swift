import AVFoundation
import AudioToolbox
import NaturalLanguage
import Speech
import MyClickyCore

/// Speech-to-text with Apple's on-device recognizer (free, private). Used by push-to-talk, dictation and the composer.
/// With auto-detect on, the preferred language listens live and the other one reads a copy of the same audio once you
/// stop; the better result wins (spec 008, research R2), then the user's custom words apply. macOS runs one recognition
/// at a time: starting a second live one cancels the first (kAFAssistantErrorDomain 1110), so they can't run together.
@MainActor
final class SpeechRecognizer {
    enum SpeechError: LocalizedError {
        case unavailable(String)
        var errorDescription: String? {
            switch self { case .unavailable(let why): return why }
        }
    }

    /// What to listen for, from settings.
    struct Languages {
        var locales: [String]
        var preferred: String
        var words: [String]
        /// Phrases to expect that aren't custom words (not rewritten in the transcript).
        var hints: [String] = []

        @MainActor
        static func from(_ settings: Settings) -> Languages {
            Languages(locales: LanguagePicker.locales(autoDetect: settings.dictationAutoDetect,
                                                      language: settings.dictationLanguage,
                                                      spanishLocale: settings.spanishLocale),
                      preferred: settings.dictationLanguage,
                      words: settings.customWords)
        }
    }

    private final class Session {
        let languageCode: String
        let request: SFSpeechAudioBufferRecognitionRequest
        var task: SFSpeechRecognitionTask?
        var text = ""
        var confidences: [Float] = []
        var isFinal = false
        init(languageCode: String, request: SFSpeechAudioBufferRecognitionRequest) {
            self.languageCode = languageCode
            self.request = request
        }
    }

    /// A copy of the recorded audio that every language reads once you stop (filled on the audio thread).
    private final class AudioStore: @unchecked Sendable {
        private let lock = NSLock()
        private var buffers: [AVAudioPCMBuffer] = []
        private var frames: Double = 0
        private var full = false
        static let maxSeconds = 150.0 // ~29 MB; longer recordings (hands-free) keep the live transcript

        func append(_ buffer: AVAudioPCMBuffer) {
            guard let source = buffer.floatChannelData, buffer.frameLength > 0,
                  let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength),
                  let target = copy.floatChannelData else { return }
            copy.frameLength = buffer.frameLength
            for channel in 0..<Int(buffer.format.channelCount) {
                target[channel].update(from: source[channel], count: Int(buffer.frameLength))
            }
            lock.lock(); defer { lock.unlock() }
            guard frames < Self.maxSeconds * buffer.format.sampleRate else { full = true; return }
            buffers.append(copy)
            frames += Double(buffer.frameLength)
        }

        var all: [AVAudioPCMBuffer] { lock.lock(); defer { lock.unlock() }; return buffers }
        /// True when the recording outgrew the cap (the copy is missing its end).
        var isCapped: Bool { lock.lock(); defer { lock.unlock() }; return full }
    }

    private let engine = AVAudioEngine()
    private var sessions: [Session] = []
    private var languages = Languages(locales: ["en-US"], preferred: "en", words: [])
    private var finishContinuation: CheckedContinuation<Void, Never>?
    private var passContinuation: CheckedContinuation<Void, Never>?
    private var recorded: AudioStore?
    /// Bumped by every start/cancel, so a stop that was interrupted returns nothing.
    private var generation = 0
    /// Microphone level 0…1 while recording (drives the companion's listening pulse, spec 006).
    var onLevel: ((Float) -> Void)?
    /// Live transcript while recording (hands-free dictation shows it in the bubble).
    var onPartial: ((String) -> Void)?
    /// Set when a language's on-device model is missing and recognition may use Apple's servers.
    private(set) var missingOnDeviceLanguages: [String] = []

    var isRecording: Bool { engine.isRunning }

    static func requestPermissions() async -> Bool {
        let speechOK = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        let micOK = await AVCaptureDevice.requestAccess(for: .audio)
        return speechOK && micOK
    }

    /// Starts listening with the language settings (auto-detect, language, custom words) and microphone.
    /// `expecting` adds phrases the recognizers should listen for (Talk passes the wake words, spec 020).
    func start(_ settings: Settings, expecting: [String] = []) throws {
        var languages = Languages.from(settings)
        languages.hints = expecting
        try start(languages: languages, deviceUID: settings.microphoneUID)
    }

    func start(languages: Languages, deviceUID: String) throws {
        cancel()
        self.languages = languages
        lastLanguage = nil
        missingOnDeviceLanguages = []
        // The first available language listens live (live text, wake words); every language reads the recording at the end.
        for identifier in languages.locales where sessions.isEmpty {
            guard let (recognizer, session) = makeSession(identifier) else { continue }
            session.task = recognizer.recognitionTask(with: session.request, resultHandler: makeResultHandler(for: session, live: true))
            sessions.append(session)
        }
        guard !sessions.isEmpty else {
            throw SpeechError.unavailable("Speech recognition isn't available for \(languages.locales.joined(separator: ", ")).")
        }
        recorded = AudioStore()

        Self.selectInput(deviceUID, on: engine)
        Self.installTap(on: engine.inputNode, feeding: sessions.map(\.request), recording: recorded) { [weak self] level in
            Task { @MainActor in self?.onLevel?(level) }
        }
        engine.prepare()
        try engine.start()
    }

    private func makeSession(_ identifier: String) -> (SFSpeechRecognizer, Session)? {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier)), recognizer.isAvailable else { return nil }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.contextualStrings = languages.words + languages.hints
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true // audio never leaves the Mac
        } else if !missingOnDeviceLanguages.contains(identifier) {
            missingOnDeviceLanguages.append(identifier)
        }
        return (recognizer, Session(languageCode: String(identifier.prefix(2)), request: request))
    }

    /// Stops recording and returns the best final transcript (custom words applied).
    func stop() async -> String {
        guard !sessions.isEmpty else { return "" }
        let run = generation
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        sessions.forEach { $0.request.endAudio() }
        if !sessions.allSatisfy(\.isFinal) {
            await withCheckedContinuation { continuation in
                finishContinuation = continuation
                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(2)) // safety net if no final result arrives
                    self?.finish()
                }
            }
        }
        // Every language reads the whole recording, one at a time. The live transcript can drop what came before a
        // pause (a 20 s hands-free dictation kept 67 of ~150 characters); a pass over the recording keeps it all.
        let store = recorded
        recorded = nil
        let audio = store?.all ?? []
        if let store, !store.isCapped, !audio.isEmpty {
            let live = sessions
            var passes: [Session] = []
            for identifier in languages.locales where run == generation {
                guard let (recognizer, session) = makeSession(identifier) else { continue }
                session.request.shouldReportPartialResults = false
                audio.forEach(session.request.append)
                session.request.endAudio()
                sessions.append(session) // so cancel() stops it too
                passes.append(session)
                await withCheckedContinuation { continuation in
                    passContinuation = continuation
                    session.task = recognizer.recognitionTask(with: session.request,
                                                              resultHandler: makeResultHandler(for: session, live: false))
                    Task { @MainActor [weak self] in
                        try? await Task.sleep(for: .seconds(3)) // safety net
                        self?.finishPass()
                    }
                }
            }
            // A language whose pass heard nothing keeps its live transcript.
            let heard = passes.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
            let liveFallback = live.filter { session in !heard.contains { $0.languageCode == session.languageCode } }
            if run == generation { sessions = heard + liveFallback }
        }
        guard run == generation else { return "" }
        return cleanup()
    }

    func cancel() {
        generation += 1
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        sessions.forEach { $0.task?.cancel() }
        sessions = []
        recorded = nil
        finish()
        finishPass()
    }

    private func finish() {
        guard let continuation = finishContinuation else { return }
        finishContinuation = nil
        continuation.resume()
    }

    private func finishPass() {
        guard let continuation = passContinuation else { return }
        passContinuation = nil
        continuation.resume()
    }

    private func cleanup() -> String {
        let results = sessions.map { RecognitionResult(languageCode: $0.languageCode, text: $0.text, segmentConfidences: $0.confidences) }
        sessions.forEach { $0.task?.cancel() }
        sessions = []
        let best = LanguagePicker.pick(results, default: languages.preferred, tieBreak: Self.guessLanguage)
        lastLanguage = best?.languageCode
        for r in results {
            Log.events.notice("heard \(r.languageCode, privacy: .public) chars=\(r.text.count, privacy: .public) conf=\(String(format: "%.2f", r.meanConfidence), privacy: .public) reads=\(Self.guessLanguage(r.text) ?? "?", privacy: .public)")
        }
        return CustomWords.apply(languages.words, to: best?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    /// "en" or "es": the language the last finished transcript was recognized in (spec 020).
    private(set) var lastLanguage: String?

    /// Every language's live transcript (the wake words may show up in either first).
    var partials: [String] { sessions.map(\.text) }

    /// The live transcript: the preferred language's partial result (or the longest).
    private var livePartial: String {
        let preferred = sessions.first { $0.languageCode == languages.preferred }?.text ?? ""
        return preferred.isEmpty ? (sessions.map(\.text).max { $0.count < $1.count } ?? "") : preferred
    }

    nonisolated static func guessLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [.english, .spanish]
        recognizer.processString(text)
        switch recognizer.dominantLanguage {
        case .english?: return "en"
        case .spanish?: return "es"
        default: return nil
        }
    }

    // Built outside the main actor: these callbacks run on audio / recognizer threads.
    private nonisolated static func installTap(on node: AVAudioInputNode, feeding requests: [SFSpeechAudioBufferRecognitionRequest],
                                               recording: AudioStore?, level: @escaping @Sendable (Float) -> Void) {
        let format = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            requests.forEach { $0.append(buffer) }
            recording?.append(buffer)
            level(Self.level(of: buffer))
        }
    }

    /// Points the engine's input at a specific microphone; falls back to the system default if it's gone.
    static func selectInput(_ uid: String, on engine: AVAudioEngine) {
        guard !uid.isEmpty, var id = AudioDevices.deviceID(forUID: uid), let unit = engine.inputNode.audioUnit else { return }
        AudioUnitSetProperty(unit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &id,
                             UInt32(MemoryLayout<AudioDeviceID>.size))
    }

    /// RMS of a buffer mapped from -50…0 dB to 0…1.
    nonisolated static func level(of buffer: AVAudioPCMBuffer) -> Float {
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<Int(buffer.frameLength) { sum += samples[i] * samples[i] }
        let rms = (sum / Float(buffer.frameLength)).squareRoot()
        let db = 20 * log10(max(rms, 0.000_01))
        return min(1, max(0, (db + 50) / 50))
    }

    private nonisolated func makeResultHandler(for session: Session, live: Bool) -> @Sendable (SFSpeechRecognitionResult?, Error?) -> Void {
        { [weak self, weak session] result, error in
            let text = result?.bestTranscription.formattedString
            let confidences = result?.bestTranscription.segments.map(\.confidence) ?? []
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            let errorInfo = (error as NSError?).map { "\($0.domain) \($0.code)" }
            Task { @MainActor in
                guard let self, let session else { return }
                if let errorInfo {
                    Log.events.notice("recognizer \(session.languageCode, privacy: .public) error \(errorInfo, privacy: .public)")
                }
                if let text {
                    session.text = text
                    if isFinal { session.confidences = confidences }
                    if live { self.onPartial?(self.livePartial) }
                }
                if isFinal || failed { session.isFinal = true }
                if !live {
                    if session.isFinal { self.finishPass() }
                } else if self.finishContinuation != nil, self.sessions.allSatisfy(\.isFinal) {
                    self.finish()
                }
            }
        }
    }
}
