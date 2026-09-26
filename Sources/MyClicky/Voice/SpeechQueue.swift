import AVFoundation
import NaturalLanguage
import MyClickyCore

/// Speaks answers sentence by sentence as they stream in (spec 007), each with the chosen voice for its language
/// (English or Spanish). Replaces v0.1's Speaker.
@MainActor
final class SpeechQueue: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    /// Called when a sentence starts being spoken (the bubble grows with it).
    var onSentenceStart: (String) -> Void = { _ in }
    /// Called once everything queued has been spoken and no more text is coming.
    var onFinish: () -> Void = {}

    private var pending = 0
    private var inputClosed = true
    private var generation = 0
    private var lastLanguage = "en"

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    var isSpeaking: Bool { synthesizer.isSpeaking || pending > 0 }

    /// Starts a new answer (more sentences will follow).
    func begin() {
        stopNow()
        inputClosed = false
    }

    func enqueue(_ sentence: String, settings: Settings) {
        let text = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let language = Self.language(of: text, fallback: lastLanguage)
        lastLanguage = language
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.voice(for: language, settings: settings)
        utterance.rate = VoiceRanking.rate(for: settings.speechSpeed)
        pending += 1
        synthesizer.speak(utterance)
    }

    /// No more sentences are coming for this answer.
    func close() {
        inputClosed = true
        if pending == 0 { onFinish() }
    }

    /// Speaks a complete text at once (announcements, errors).
    func speakAll(_ text: String, settings: Settings) {
        begin()
        var splitter = SentenceSplitter()
        splitter.append(text + " ").forEach { enqueue($0, settings: settings) }
        if let rest = splitter.finish() { enqueue(rest, settings: settings) }
        close()
    }

    /// Stops immediately (push-to-talk interrupts). Doesn't call onFinish.
    func stopNow() {
        generation += 1
        pending = 0
        inputClosed = true
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }

    // MARK: Voices

    /// "en" or "es" for a sentence; short sentences keep the previous language.
    static func language(of text: String, fallback: String) -> String {
        guard text.count >= 20 else { return fallback }
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [.english, .spanish]
        recognizer.processString(text)
        switch recognizer.dominantLanguage {
        case .spanish?: return "es"
        case .english?: return "en"
        default: return fallback
        }
    }

    static func installedVoices() -> [VoiceRanking.VoiceInfo] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { !$0.voiceTraits.contains(.isNoveltyVoice) }
            .map { VoiceRanking.VoiceInfo(identifier: $0.identifier, name: $0.name, language: $0.language,
                                          quality: $0.quality.rawValue) }
    }

    /// The chosen voice for a language, or the best installed one (Premium > Enhanced > default).
    static func voice(for language: String, settings: Settings) -> AVSpeechSynthesisVoice? {
        if let id = settings.voiceByLanguage[language], let voice = AVSpeechSynthesisVoice(identifier: id) { return voice }
        let region = Locale.current.region?.identifier
        if let best = VoiceRanking.ranked(installedVoices(), language: language, preferredRegion: region).first {
            return AVSpeechSynthesisVoice(identifier: best.identifier)
        }
        return AVSpeechSynthesisVoice(language: language == "es" ? "es-MX" : "en-US")
    }

    // MARK: AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let text = utterance.speechString
        Task { @MainActor in self.onSentenceStart(text) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.utteranceEnded() }
    }

    private func utteranceEnded() {
        guard pending > 0 else { return }
        pending -= 1
        if pending == 0 && inputClosed { onFinish() }
    }
}
