import Foundation
import MyClickyCore

/// Checks for spec 005 (Clickys and chats).
enum ChatChecks {
    static func run() {
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        let research = ChatRouter.ClickyRef(id: UUID(), title: "Research Buddy", lastAgentUseAt: now.addingTimeInterval(-3600))
        let scout = ChatRouter.ClickyRef(id: UUID(), title: "Role Scout", lastAgentUseAt: now.addingTimeInterval(-300))

        Check.group("Chat routing") {
            Check.equal(ChatRouter.route("what's on my screen?", clickys: [research], now: now), .talk("what's on my screen?"))
            Check.equal(ChatRouter.route("agenda for today", clickys: [], now: now), .talk("agenda for today"), "agenda ≠ agent")
            Check.equal(ChatRouter.route("agent, ask Research Buddy to add sources", clickys: [research, scout], now: now),
                        .clicky(research.id, "add sources"), "named Clicky wins")
            Check.equal(ChatRouter.route("agente, pídele a role scout que busque remoto", clickys: [research, scout], now: now),
                        .clicky(scout.id, "busque remoto"), "Spanish, accents and case ignored")
            Check.equal(ChatRouter.route("agent, also check remote roles", clickys: [research, scout], now: now),
                        .clicky(scout.id, "also check remote roles"), "continues the Clicky used 5 min ago")
            Check.equal(ChatRouter.route("agent, draft a summary", clickys: [research], now: now),
                        .newClicky("draft a summary"), "1 hour ago is too old → new Clicky")
        }

        Check.group("Context window + memory folding") {
            var chat = Chat(kind: .talk, title: "Talk")
            func exchange(_ i: Int) {
                chat.append(Message(role: .user, text: "q\(i)"))
                chat.append(Message(role: .assistant, text: "a\(i)"))
            }
            (1...5).forEach(exchange)
            var w = ContextWindow(chat: chat)
            Check.equal(w.recent.count, 5)
            Check.equal(w.toFold.count, 0, "nothing to fold under the threshold")
            (6...13).forEach(exchange)
            w = ContextWindow(chat: chat)
            Check.equal(w.recent.map(\.user.text), ["q8", "q9", "q10", "q11", "q12", "q13"], "last 6 exchanges")
            Check.equal(w.toFold.map(\.user.text), (1...7).map { "q\($0)" }, "13 unsummarized → fold all but the last 6")
            chat.summarizedThroughID = w.toFold.last?.assistant.id
            chat.memorySummary = "project Orion"
            w = ContextWindow(chat: chat)
            Check.equal(w.toFold.count, 0, "after folding, 6 remain")
            Check.equal(w.summary, "project Orion")
        }

        Check.group("Relative time + greeting") {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC")!
            let locale = Locale(identifier: "en_US")
            let today = cal.date(from: DateComponents(year: 2026, month: 9, day: 25, hour: 20))!
            let noon = cal.date(from: DateComponents(year: 2026, month: 9, day: 25, hour: 12, minute: 29))!
            Check.expect(RelativeTime.format(noon, now: today, calendar: cal, locale: locale).hasPrefix("12:29"), "today → time")
            let tuesday = cal.date(from: DateComponents(year: 2026, month: 9, day: 22, hour: 9))!
            Check.equal(RelativeTime.format(tuesday, now: today, calendar: cal, locale: locale), "Tuesday")
            let old = cal.date(from: DateComponents(year: 2026, month: 9, day: 3))!
            Check.equal(RelativeTime.format(old, now: today, calendar: cal, locale: locale), "Sep 3")
            Check.equal(Greeting.title(name: "Jose", hour: 9), "Morning, Jose.")
            Check.equal(Greeting.title(name: "Jose", hour: 15), "Afternoon, Jose.")
            Check.equal(Greeting.title(name: "Jose", hour: 20), "Evening, Jose.")
            Check.equal(Greeting.title(name: "Jose", hour: 2), "Evening, Jose.")
            Check.equal(Greeting.hint(for: ShortcutBinding.defaults[0]), "Hold Fn and tell me what to take off your plate.")
            Check.equal(Greeting.hint(for: ShortcutBinding(.pushToTalk, KeyChord([.option]), .hold)),
                        "Hold ⌥ Option and tell me what to take off your plate.")
        }

        Check.group("Search") {
            var chat = Chat(kind: .clicky, title: "Research Buddy")
            chat.append(Message(role: .user, text: "Two-page SpaceX competitor summary please"))
            chat.append(Message(role: .assistant, text: "Here's the canción you asked for."))
            Check.expect(SearchIndex.search("spacex", in: chat) != nil, "case-insensitive")
            Check.expect(SearchIndex.search("cancion", in: chat)?.snippet.contains("canción") == true, "accent-insensitive, original shown")
            Check.expect(SearchIndex.search("buddy", in: chat) != nil, "title match")
            Check.equal(SearchIndex.search("orion", in: chat), nil)
        }

        Check.group("Clicky naming") {
            let parsed = NamingParser.parse(#"Sure! {"name": "Role Scout", "color": "lilac"}"#)
            Check.equal(parsed?.name, "Role Scout")
            Check.equal(parsed?.color, .lilac)
            Check.expect(NamingParser.parse("no json") == nil)
            Check.expect(NamingParser.parse(#"{"name": "A very long name for a helper"}"#) == nil, "more than 3 words rejected")
            Check.equal(NamingParser.parse(#"{"name":"Shippy","color":"neon"}"#)?.color, nil, "unknown color ignored")
            Check.equal(NamingParser.unique("Role Scout", existing: ["role scout"]), "Role Scout 2")
            Check.equal(NamingParser.unique("Role Scout", existing: ["Role Scout", "Role Scout 2"]), "Role Scout 3")
            Check.equal(NamingParser.fallbackName(existing: ["New Clicky"]), "New Clicky 2")
            Check.equal(AvatarColor.next(avoiding: [.peach, .sky]), .butter)
        }

        Check.group("Chat file: 005 fields") {
            let old = #"{"id":"\#(UUID().uuidString)","title":"Old"}"#
            let chat = try JSONFile.decoder.decode(Chat.self, from: old.data(using: .utf8)!)
            Check.equal(chat.avatarColor, .sky)
            Check.equal(chat.isUnread, false)
            Check.equal(chat.agentSessionID, nil)
        }
    }
}
