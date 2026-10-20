import Foundation
import MyClickyCore

/// Checks for specs 018/020: "Jarvis" (Talk) and "Jarvis agent" (a Clicky task), matched by sound.
enum WakeWordChecks {
    static func run() {
        Check.group("Wake words: Jarvis agent → agent") {
            Check.equal(Router.agentTask("Jarvis agent, summarize my Downloads folder"), "summarize my Downloads folder")
            Check.equal(Router.agentTask("Hey Jarvis agent make a landing page"), "make a landing page")
            Check.equal(Router.agentTask("hey jarvis agent. Build a to-do app"), "Build a to-do app")
            Check.equal(Router.agentTask("Jarvis agente, crea una presentación"), "crea una presentación")
            Check.equal(Router.agentTask("Oye Jarvis agente, ordena mis archivos"), "ordena mis archivos")
            Check.equal(Router.agentTask("Jarvis, agent: write the report"), "write the report")
            Check.equal(Router.agentTask("agent, organize my Downloads"), "organize my Downloads", "old prefix still works")
            Check.equal(Router.agentTask("okay agent do it"), "do it")
        }

        Check.group("Wake words: the name heard many ways") {
            for heard in ["Jarvis", "Harvis", "Yarvis", "Jarbis", "Járvis", "Jervis", "Javis", "Charvis", "Arvis",
                          "Jarvi", "Harvey's", "Jarviss", "Llarvis", "Yarbis", "JARVIS"] {
                Check.equal(Router.agentTask("\(heard) agent write the report"), "write the report", heard)
            }
            Check.equal(Router.agentTask("Jar vis agent write the report"), "write the report", "split in two words")
            Check.equal(Router.agentTask("Har bis, agente, escribe el informe"), "escribe el informe")
            Check.equal(Router.talkQuestion("Oye Yarvis, ¿qué es esto?"), "¿qué es esto?")
        }

        Check.group("Wake words: Jarvis → Talk") {
            Check.equal(Router.agentTask("Jarvis, what is this button?"), nil)
            Check.equal(Router.talkQuestion("Jarvis, what is this button?"), "what is this button?")
            Check.equal(Router.talkQuestion("Hey Jarvis where is the export menu"), "where is the export menu")
            Check.equal(Router.talkQuestion("Oye Jarvis, ¿qué es esto?"), "¿qué es esto?")
            Check.equal(Router.talkQuestion("what is this?"), "what is this?", "no wake word")
            Check.equal(Router.talkQuestion("Jarvis"), "Jarvis", "nothing after it: keep the text")
            Check.equal(ChatRouter.route("Jarvis, what's this?", clickys: []), .talk("what's this?"))
        }

        Check.group("Wake words: look-alikes are not the name") {
            for sentence in ["harvest the data from this page", "Harris called me", "Charles said hi", "Travis is late",
                             "Davis Street", "service is down", "Paris in spring", "Avis rental car", "Elvis song",
                             "Clicky, what's this?", "agenda for today", "hey what's this", "jar of jam"] {
                Check.equal(Router.talkQuestion(sentence), sentence, sentence)
                Check.equal(Router.agentTask(sentence), nil, sentence)
            }
            Check.expect(!WakeWords.isAgentCall("Jarvisverse agent"), "whole words only")
        }

        Check.group("Wake words: live transcript") {
            Check.expect(WakeWords.isAgentCall("Hey Jarvis agent"), "bot shows before the task is said")
            Check.expect(WakeWords.isAgentCall("Yarvis agente"))
            Check.expect(!WakeWords.isAgentCall("Hey Jarvis"), "not yet: could still be Talk")
            Check.expect(!WakeWords.isAgentCall("agenda for today"), "agenda is not agent")
        }

        Check.group("Wake words: the name is spelled right in chats") {
            Check.equal(WakeWords.canonical("Harvis, what's this?"), "Jarvis, what's this?")
            Check.equal(WakeWords.canonical("Oye Yarvis agente, abre Notas"), "Oye Jarvis agente, abre Notas")
            Check.equal(WakeWords.canonical("jar vis agent do it"), "Jarvis agent do it")
            Check.equal(WakeWords.canonical("harvest the data"), "harvest the data")
        }

        Check.group("Reply language (spec 020)") {
            Check.equal(ReplyLanguage.resolve(spoken: "es", guessed: "en", previous: "en", fallback: "en"), "es",
                        "what the recognizer heard wins over a guess")
            Check.equal(ReplyLanguage.resolve(spoken: nil, guessed: "es", previous: "en", fallback: "en"), "es", "typed")
            Check.equal(ReplyLanguage.resolve(spoken: nil, guessed: nil, previous: "es", fallback: "en"), "es",
                        "too short to tell: keep the last language")
            Check.equal(ReplyLanguage.resolve(spoken: nil, guessed: nil, previous: nil, fallback: "es"), "es")
            Check.equal(ReplyLanguage.resolve(spoken: "fr", guessed: nil, previous: nil, fallback: "de"), "en")
            Check.expect(ReplyLanguage.instruction("es").contains("only in Spanish"))
            Check.expect(ReplyLanguage.instruction("en").contains("only in English"))
            Check.equal(ReplyLanguage.text(.finished("Build Lab"), "es"), "Build Lab terminó.")
            Check.equal(ReplyLanguage.text(.finished("Build Lab"), "en"), "Build Lab finished.")
        }
    }
}
