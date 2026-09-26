import AVFoundation
import AudioToolbox
import NaturalLanguage
import Speech
import MyClickyCore

/// Speech-to-text with Apple's on-device recognizer (free, private). Used by push-to-talk, dictation and the composer.
/// With auto-detect on it runs an English and a Spanish recognizer on the same audio and keeps the better result
/// (spec 008, research R2), then applies the user's custom words.
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

    private let engine = AVAudioEngine()
    private var sessions: [Session] = []
    private var languages = Languages(locales: ["en-US"], preferred: "en", words: [])
    private var finishContinuation: CheckedContinuation<String, Never>?
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
    func start(_ settings: Settings) throws {
        try start(languages: .from(settings), deviceUID: settings.microphoneUID)
    }

    func start(languages: Languages, deviceUID: String) throws {
        cancel()
        self.languages = languages
        missingOnDeviceLanguages = []
        for identifier in languages.locales {
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier)), recognizer.isAvailable else { continue }
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.addsPunctuation = true
            request.contextualStrings = languages.words
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true // audio never leaves the Mac
            } else {
                missingOnDeviceLanguages.append(identifier)
            }
            let session = Session(languageCode: String(identifier.prefix(2)), request: request)
            session.task = recognizer.recognitionTask(with: request, resultHandler: makeResultHandler(for: session))
            sessions.append(session)
        }
        guard !sessions.isEmpty else {
            throw SpeechError.unavailable("Speech recognition isn't available for \(languages.locales.joined(separator: ", ")).")
        }

        Self.selectInput(deviceUID, on: engine)
        let requests = sessions.map(\.request)
        Self.installTap(on: engine.inputNode, feeding: requests) { [weak self] level in
            Task { @MainActor in self?.onLevel?(level) }
        }
        engine.prepare()
        try engine.start()
    }

    /// Stops recording and returns the best final transcript (custom words applied).
    func stop() async -> String {
        guard !sessions.isEmpty else { return "" }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        sessions.forEach { $0.request.endAudio() }
        if sessions.allSatisfy(\.isFinal) { return cleanup() }
        return await withCheckedContinuation { continuation in
            finishContinuation = continuation
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(2)) // safety net if no final result arrives
                self?.finish()
            }
        }
    }

    func cancel() {
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        sessions.forEach { $0.task?.cancel() }
        sessions = []
        if let continuation = finishContinuation {
            finishContinuation = nil
            continuation.resume(returning: "")
        }
    }

    private func finish() {
        guard let continuation = finishContinuation else { return }
        finishContinuation = nil
        continuation.resume(returning: cleanup())
    }

    private func cleanup() -> String {
        let results = sessions.map { RecognitionResult(languageCode: $0.languageCode, text: $0.text, segmentConfidences: $0.confidences) }
        sessions.forEach { $0.task?.cancel() }
        sessions = []
        let best = LanguagePicker.pick(results, default: languages.preferred, tieBreak: Self.guessLanguage)
        return CustomWords.apply(languages.words, to: best?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

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
                                               level: @escaping @Sendable (Float) -> Void) {
        let format = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            requests.forEach { $0.append(buffer) }
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

    private nonisolated func makeResultHandler(for session: Session) -> @Sendable (SFSpeechRecognitionResult?, Error?) -> Void {
        { [weak self, weak session] result, error in
            let text = result?.bestTranscription.formattedString
            let confidences = result?.bestTranscription.segments.map(\.confidence) ?? []
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor in
                guard let self, let session else { return }
                if let text {
                    session.text = text
                    if isFinal { session.confidences = confidences }
                    self.onPartial?(self.livePartial)
                }
                if isFinal || failed { session.isFinal = true }
                if self.finishContinuation != nil, self.sessions.allSatisfy(\.isFinal) { self.finish() }
            }
        }
    }
}
