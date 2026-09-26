import Foundation
import MyClickyCore

/// Checks for spec 008 (dictation).
enum DictationChecks {
    static func run() {
        Check.group("Dictation: language pick") {
            let en = RecognitionResult(languageCode: "en", text: "Hello team", segmentConfidences: [0.9, 0.8])
            let es = RecognitionResult(languageCode: "es", text: "Hola tim", segmentConfidences: [0.4, 0.5])
            Check.equal(LanguagePicker.pick([en, es], default: "es")?.languageCode, "en", "clearly more confident wins")
            let enClose = RecognitionResult(languageCode: "en", text: "Hola equipo", segmentConfidences: [0.62])
            let esClose = RecognitionResult(languageCode: "es", text: "Hola equipo", segmentConfidences: [0.60])
            Check.equal(LanguagePicker.pick([enClose, esClose], default: "en", tieBreak: { _ in "es" })?.languageCode, "es",
                        "close call → the text's language decides")
            Check.equal(LanguagePicker.pick([enClose, esClose], default: "es")?.languageCode, "es", "no tie-break → default")
            let empty = RecognitionResult(languageCode: "es", text: " ", segmentConfidences: [])
            Check.equal(LanguagePicker.pick([en, empty], default: "es")?.languageCode, "en", "empty results ignored")
            Check.equal(LanguagePicker.pick([], default: "en"), nil)
            Check.equal(LanguagePicker.locales(autoDetect: true, language: "en", spanishLocale: "es-MX"), ["en-US", "es-MX"])
            Check.equal(LanguagePicker.locales(autoDetect: false, language: "es", spanishLocale: "es-ES"), ["es-ES"])
        }

        Check.group("Dictation: custom words") {
            let words = ["Anthropic", "MyClicky", "Jose"]
            Check.equal(CustomWords.apply(words, to: "ask anthropic about myclicky"), "ask Anthropic about MyClicky")
            Check.equal(CustomWords.apply(words, to: "anthropical stays"), "anthropical stays", "whole words only")
            Check.equal(CustomWords.apply(["José"], to: "hola jose y JOSÉ"), "hola jose y José", "exact spelling for exact word")
            Check.equal(CustomWords.apply(["C++"], to: "I like c++."), "I like C++.", "special characters are literal")
            Check.equal(CustomWords.normalized([" Jose ", "jose", "", "Orion"]), ["Jose", "Orion"])
        }

        Check.group("Dictation: spacing") {
            Check.expect(SpacingRule.needsLeadingSpace(before: "world", previousCharacter: "o"))
            Check.expect(!SpacingRule.needsLeadingSpace(before: "world", previousCharacter: " "))
            Check.expect(!SpacingRule.needsLeadingSpace(before: ", then", previousCharacter: "o"), "leading punctuation")
            Check.expect(!SpacingRule.needsLeadingSpace(before: "hola", previousCharacter: "¿"))
            Check.expect(!SpacingRule.needsLeadingSpace(before: "Hi", previousCharacter: nil), "start of field")
            Check.expect(SpacingRule.needsLeadingSpace(before: "Next", previousCharacter: "."))
        }

        Check.group("Settings migration v3 → v4") {
            var s = Settings()
            s.version = 3
            s.speechLocale = "es-ES"
            SettingsMigrations.upgrade(&s)
            Check.equal(s.version, 4)
            Check.equal(s.dictationLanguage, "es")
            Check.equal(s.spanishLocale, "es-ES")
            var english = Settings()
            english.version = 3
            english.speechLocale = "en-GB"
            SettingsMigrations.upgrade(&english)
            Check.equal(english.dictationLanguage, "en")
            Check.expect(Settings.defaultSpanishLocale.hasPrefix("es-"))
        }
    }
}
