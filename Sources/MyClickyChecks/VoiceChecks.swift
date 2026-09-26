import Foundation
import MyClickyCore

/// Checks for spec 007 (voice talk): streaming events, sentence splitting, voices, speed, quiet mode, migration.
enum VoiceChecks {
    static func run() {
        Check.group("Streaming events (SSE)") {
            let p = SSEParser()
            Check.equal(p.parse(line: #"data: {"type":"message_start","message":{"usage":{"input_tokens":1500,"cache_read_input_tokens":20}}}"#),
                        .start(inputTokens: 1500, cacheReadTokens: 20, cacheWriteTokens: 0))
            Check.equal(p.parse(line: #"data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hi"}}"#),
                        .textDelta("Hi"))
            Check.equal(p.parse(line: #"data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":42}}"#),
                        .stop(reason: "end_turn", outputTokens: 42))
            Check.equal(p.parse(line: #"data: {"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}"#),
                        .error(type: "overloaded_error", message: "Overloaded"))
            Check.equal(p.parse(line: #"data: {"type": "ping"}"#), .ping)
            Check.equal(p.parse(line: "event: content_block_delta"), nil, "event lines are ignored")
            Check.equal(p.parse(line: #"data: {"type":"content_block_delta","delta":{"type":"thinking_delta","thinking":"x"}}"#), nil,
                        "non-text deltas ignored")
            Check.equal(p.parse(line: #"data: {"type":"message_stop"}"#), nil)
            Check.equal(p.parse(line: "data: {broken"), nil)
        }

        Check.group("Sentence splitting") {
            var s = SentenceSplitter()
            Check.equal(s.append("Hello there. How are"), ["Hello there."])
            Check.equal(s.append(" you? I'm fine"), ["How are you?"])
            Check.equal(s.finish(), "I'm fine")

            var abbrev = SentenceSplitter()
            Check.equal(abbrev.append("Use a tool, e.g. the Export menu. Then save. "), ["Use a tool, e.g. the Export menu.", "Then save."])
            var numbers = SentenceSplitter()
            Check.equal(numbers.append("It costs 3.5 dollars in v2.1 of the app. Done. "), ["It costs 3.5 dollars in v2.1 of the app.", "Done."])
            var spanish = SentenceSplitter()
            Check.equal(spanish.append("¿Qué es esto? ¡Sí! El Sr. Pérez llega, p. ej. mañana. "),
                        ["¿Qué es esto?", "¡Sí!", "El Sr. Pérez llega, p. ej. mañana."])
            var waiting = SentenceSplitter()
            Check.equal(waiting.append("Wait for it."), [], "a final dot needs what follows first")
            Check.equal(waiting.append(".. "), ["Wait for it..."], "ellipsis kept together")
            var quote = SentenceSplitter()
            Check.equal(quote.append("She said \"hi.\" Then left. "), ["She said \"hi.\"", "Then left."])
            var early = SentenceSplitter()
            let long = "When you open the export panel on the right side of the window, choose PDF"
            Check.equal(early.append(long + " and save"), ["When you open the export panel on the right side of the window,"],
                        "first chunk flushes early at a comma")
            var lines = SentenceSplitter()
            Check.equal(lines.append("Step one\nStep two"), ["Step one"])
        }

        Check.group("Voices + speed") {
            let voices = [
                VoiceRanking.VoiceInfo(identifier: "a", name: "Samantha", language: "en-US", quality: 1),
                VoiceRanking.VoiceInfo(identifier: "b", name: "Zoe", language: "en-US", quality: 3),
                VoiceRanking.VoiceInfo(identifier: "c", name: "Ava", language: "en-GB", quality: 3),
                VoiceRanking.VoiceInfo(identifier: "d", name: "Paulina", language: "es-MX", quality: 2),
            ]
            Check.equal(VoiceRanking.ranked(voices, language: "en", preferredRegion: "US").map(\.identifier), ["b", "c", "a"])
            Check.equal(VoiceRanking.ranked(voices, language: "es").map(\.identifier), ["d"])
            Check.equal(VoiceRanking.rate(for: 1), 0.52)
            Check.equal(VoiceRanking.rate(for: 1.5), 0.62)
            Check.equal(VoiceRanking.speed(forRate: 0.52), 1)
            Check.equal(VoiceRanking.speed(forRate: 0.6), 1.5)
            Check.equal(VoiceRanking.language(ofIdentifier: "com.apple.voice.premium.es-MX.Paulina"), "es")
            Check.equal(VoiceRanking.language(ofIdentifier: "nonsense"), nil)
            Check.equal(VoiceRanking.descriptor(for: voices[1]), "Premium · US")
            // The voices actually installed on this Mac (2026-09-25): robotic Eloquence voices must not win.
            let installed = [
                VoiceRanking.VoiceInfo(identifier: "com.apple.eloquence.en-US.Eddy", name: "Eddy", language: "en-US", quality: 1),
                VoiceRanking.VoiceInfo(identifier: "com.apple.speech.synthesis.voice.Fred", name: "Fred", language: "en-US", quality: 1),
                VoiceRanking.VoiceInfo(identifier: "com.apple.voice.super-compact.en-US.Samantha", name: "Samantha", language: "en-US", quality: 1),
                VoiceRanking.VoiceInfo(identifier: "com.apple.voice.compact.en-US.Samantha", name: "Samantha", language: "en-US", quality: 1),
                VoiceRanking.VoiceInfo(identifier: "com.apple.siri.natural.Nora", name: "Voice 4", language: "en-US", quality: 2),
            ]
            Check.equal(VoiceRanking.ranked(installed, language: "en", preferredRegion: "US").map(\.identifier),
                        ["com.apple.siri.natural.Nora", "com.apple.voice.compact.en-US.Samantha",
                         "com.apple.eloquence.en-US.Eddy", "com.apple.speech.synthesis.voice.Fred"],
                        "natural first, one Samantha, robotic last")
            Check.equal(VoiceRanking.descriptor(for: installed[0]), "Robotic · US")
        }

        Check.group("Quiet mode") {
            let now = Date()
            Check.expect(!QuietPolicy.isQuiet(reasons: [], override: .init()))
            Check.expect(QuietPolicy.isQuiet(reasons: [.call], override: .init()))
            Check.expect(!QuietPolicy.isQuiet(reasons: [.call], override: .init(mode: .off, until: now.addingTimeInterval(3600)), now: now))
            Check.expect(QuietPolicy.isQuiet(reasons: [], override: .init(mode: .on, until: now.addingTimeInterval(60)), now: now))
            Check.expect(!QuietPolicy.isQuiet(reasons: [], override: .init(mode: .on, until: now.addingTimeInterval(-1)), now: now),
                         "expired override → automatic")
        }

        Check.group("Settings migration v2 → v3") {
            var s = Settings()
            s.version = 2
            s.speechRate = 0.6
            s.voiceIdentifier = "com.apple.voice.premium.es-MX.Paulina"
            SettingsMigrations.upgrade(&s)
            Check.equal(s.version, Settings.currentVersion)
            Check.equal(s.speechSpeed, 1.5)
            Check.equal(s.voiceByLanguage, ["es": "com.apple.voice.premium.es-MX.Paulina"])
            var fresh = Settings()
            SettingsMigrations.upgrade(&fresh)
            Check.equal(fresh.speechSpeed, 1, "defaults unchanged")
        }
    }
}
