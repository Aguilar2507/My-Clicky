import AVFoundation
import MyClickyCore

/// Text-to-speech with the built-in macOS voices (free, on-device).
@MainActor
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var onFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    var isSpeaking: Bool { synthesizer.isSpeaking }

    func speak(_ text: String, settings: Settings) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.voice(for: settings)
        utterance.rate = settings.speechRate
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }

    /// Uses the configured voice, otherwise the highest-quality installed voice for the speech language.
    /// Tip: download a Premium/Enhanced voice in System Settings → Accessibility → Spoken Content.
    static func voice(for settings: Settings) -> AVSpeechSynthesisVoice? {
        if !settings.voiceIdentifier.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: settings.voiceIdentifier) {
            return voice
        }
        let language = settings.locale.language.languageCode?.identifier ?? "en"
        let region = settings.locale.region?.identifier
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.hasPrefix(language) && !$0.voiceTraits.contains(.isNoveltyVoice)
        }
        return candidates.max { rank($0, region) < rank($1, region) }
            ?? AVSpeechSynthesisVoice(language: settings.locale.identifier)
    }

    private static func rank(_ voice: AVSpeechSynthesisVoice, _ region: String?) -> Int {
        var score = voice.quality.rawValue * 10 // premium > enhanced > default
        if let region, voice.language.hasSuffix(region) { score += 1 }
        return score
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.onFinish?() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.onFinish?() }
    }
}
