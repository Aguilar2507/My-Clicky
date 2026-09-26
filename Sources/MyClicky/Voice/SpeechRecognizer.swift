import AVFoundation
import Speech

/// Push-to-talk speech-to-text using Apple's on-device recognizer (free, private).
@MainActor
final class SpeechRecognizer {
    enum SpeechError: LocalizedError {
        case unavailable(String)
        var errorDescription: String? {
            switch self { case .unavailable(let why): return why }
        }
    }

    private let engine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var transcript = ""
    private var isFinished = false
    private var finishContinuation: CheckedContinuation<String, Never>?
    /// Microphone level 0…1 while recording (drives the companion's listening pulse, spec 006).
    var onLevel: ((Float) -> Void)?

    static func requestPermissions() async -> Bool {
        let speechOK = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        let micOK = await AVCaptureDevice.requestAccess(for: .audio)
        return speechOK && micOK
    }

    func start(locale: Locale) throws {
        cancel()
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw SpeechError.unavailable("Speech recognition isn't available for \(locale.identifier).")
        }
        self.recognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true // audio never leaves the Mac
        }
        self.request = request
        transcript = ""
        isFinished = false

        Self.installTap(on: engine.inputNode, feeding: request) { [weak self] level in
            Task { @MainActor in self?.onLevel?(level) }
        }
        engine.prepare()
        try engine.start()

        task = recognizer.recognitionTask(with: request, resultHandler: makeResultHandler())
    }

    /// Stops recording and returns the final transcript.
    func stop() async -> String {
        guard request != nil else { return transcript }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        if isFinished { return cleanup() }
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
        task?.cancel()
        _ = cleanup()
    }

    private func finish() {
        isFinished = true
        guard let continuation = finishContinuation else { return }
        finishContinuation = nil
        continuation.resume(returning: cleanup())
    }

    private func cleanup() -> String {
        task = nil
        request = nil
        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Built outside the main actor: these callbacks run on audio / recognizer threads.
    private nonisolated static func installTap(on node: AVAudioInputNode, feeding request: SFSpeechAudioBufferRecognitionRequest,
                                               level: @escaping @Sendable (Float) -> Void) {
        let format = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
            level(Self.level(of: buffer))
        }
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

    private nonisolated func makeResultHandler() -> @Sendable (SFSpeechRecognitionResult?, Error?) -> Void {
        { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let done = (result?.isFinal ?? false) || error != nil
            Task { @MainActor in
                guard let self else { return }
                if let text { self.transcript = text }
                if done { self.finish() }
            }
        }
    }
}
