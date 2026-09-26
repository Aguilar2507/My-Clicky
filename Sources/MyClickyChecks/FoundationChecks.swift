import Foundation
import MyClickyCore

/// Checks for spec 002 (app foundation): routing, point tags, pricing, settings, migration, usage and chats.
enum FoundationChecks {
    static func run() {
        Check.group("Router (pointing model routing)") {
            let cases: [(String, Bool)] = [
                ("¿Cómo estás?", false), ("Resume esto como una lista", false), ("¿Cómo hago para exportar?", true),
                ("¿Dónde está el botón de guardar?", true), ("I have an appointment at 5", false),
                ("I'm disappointed", false), ("Where is the export button?", true), ("How do I rename this?", true),
                ("What does this error mean?", false), ("Point to the settings", true),
                ("¿Cómo se llama esta canción?", false), ("Dale clic aquí", true),
            ]
            for (text, expected) in cases { Check.equal(Router.wantsPointing(text), expected, text) }
        }

        Check.group("Router (agent prefix)") {
            Check.equal(Router.agentTask("agent, organize my Downloads"), "organize my Downloads")
            Check.equal(Router.agentTask("Agente, crea un recordatorio"), "crea un recordatorio")
            Check.equal(Router.agentTask("hey agent do it"), "do it")
            Check.equal(Router.agentTask("agenda for today"), nil, "agenda is not agent")
            Check.equal(Router.agentTask("agent"), nil, "empty task")
        }

        Check.group("Point tags (v0.1 format)") {
            let parsed = ScreenTags.parse("Click Export. [POINT:120,45:Export button:screen 2]")
            Check.equal(parsed.text, "Click Export.")
            Check.equal(parsed.point, .point(x: 120, y: 45, label: "Export button", screen: 2))
            let plain = ScreenTags.parse("No pointing here.")
            Check.equal(plain.text, "No pointing here.")
            Check.equal(plain.point, nil)
            Check.equal(ScreenTags.parse("[point: 1.5 , 2 ]").point?.screen, 1, "default screen")
        }

        Check.group("Pricing") {
            Check.near(TokenUsage(model: "claude-haiku-4-5", inputTokens: 1_000_000).costUSD, 1)
            Check.near(TokenUsage(model: "claude-haiku-4-5", outputTokens: 1_000_000).costUSD, 5)
            Check.near(TokenUsage(model: "claude-sonnet-5", inputTokens: 1_000, outputTokens: 100).costUSD, 0.003)
            Check.near(TokenUsage(model: "claude-opus-5-5", inputTokens: 1_000_000).costUSD, 4, "5-5 before 5")
            Check.near(TokenUsage(model: "claude-haiku-4-5", cacheWriteTokens: 1_000_000, cacheReadTokens: 1_000_000).costUSD, 1.35)
            Check.near(TokenUsage(model: "unknown", inputTokens: 1_000_000).costUSD, 3, "fallback price")
        }

        Check.group("Settings (tolerant decoding)") {
            let partial = #"{"fastModel":"custom-model","speechRate":"oops","unknownKey":42}"#.data(using: .utf8)!
            let s = try TolerantDecoder.decode(Settings.self, from: partial, defaults: Settings())
            Check.equal(s.fastModel, "custom-model", "kept value")
            Check.equal(s.speechRate, Settings().speechRate, "bad value falls back to default")
            Check.equal(s.pointingModel, Settings().pointingModel, "missing key uses default")
            let roundTrip = try TolerantDecoder.decode(Settings.self, from: JSONFile.encode(s), defaults: Settings())
            Check.equal(roundTrip, s, "round trip")
        }

        Check.group("Settings store + v0.1 migration") {
            let paths = AppPaths(base: Check.tempPaths())
            let legacy = """
            {"agentAllowedTools":["Read"],"agentWorkingDirectory":"~/Work","claudePath":"/x/claude","fastModel":"f",
             "maxHistoryTurns":4,"pointingModel":"p","speechLocale":"es-ES","speechRate":0.6,"voiceIdentifier":"v"}
            """
            try JSONFile.write(legacy.data(using: .utf8)!, to: paths.legacyConfig)
            let store = SettingsStore(paths: paths, debounce: 0.05)
            let s = store.load()
            Check.equal(s.agentAllowedTools, ["Read"])
            Check.equal(s.agentWorkingDirectory, "~/Work")
            Check.equal(s.claudePath, "/x/claude")
            Check.equal(s.fastModel, "f")
            Check.equal(s.maxHistoryTurns, 4)
            Check.equal(s.pointingModel, "p")
            Check.equal(s.speechLocale, "es-ES")
            Check.equal(s.speechRate, 0.6)
            Check.equal(s.voiceIdentifier, "v")
            Check.equal(s.version, Settings.currentVersion)
            let fm = FileManager.default
            Check.expect(fm.fileExists(atPath: paths.settings.path), "settings.json written")
            Check.expect(fm.fileExists(atPath: paths.legacyBackup.path), "backup kept")
            Check.expect(!fm.fileExists(atPath: paths.legacyConfig.path), "config.json moved")
            Check.equal(LegacyConfigMigration.run(paths: paths), nil, "second run is a no-op")

            var changed = s
            changed.fastModel = "changed"
            store.save(changed)
            store.flush()
            Check.equal(SettingsStore(paths: paths).load().fastModel, "changed", "flush writes pending save")

            try JSONFile.write("not json".data(using: .utf8)!, to: paths.settings)
            Check.equal(SettingsStore(paths: paths).load(), Settings(), "damaged settings → defaults")
            Check.expect(fm.fileExists(atPath: paths.settings.path + ".damaged"), "damaged file set aside")
        }

        Check.group("Usage store") {
            let paths = AppPaths(base: Check.tempPaths())
            try JSONFile.write(#"{"2026-08":{"questions":3,"costUSD":0.5}}"#.data(using: .utf8)!, to: paths.usage)
            let store = UsageStore(paths: paths)
            let aug = DateComponents(calendar: .current, year: 2026, month: 8, day: 10).date!
            Check.equal(store.month(containing: aug), UsageMonth(questions: 3, costUSD: 0.5), "v0.1 file reads")
            store.record(TokenUsage(model: "claude-haiku-4-5", inputTokens: 1_000_000), now: aug)
            store.record(TokenUsage(model: "claude-haiku-4-5", inputTokens: 1_000_000), countsAsQuestion: false, now: aug)
            Check.equal(store.month(containing: aug).questions, 4)
            Check.near(store.month(containing: aug).costUSD, 2.5)
            Check.equal(UsageMonth.format(0.0421), "$0.042")
            Check.equal(UsageMonth.format(12.5), "$12.50")
        }

        Check.group("Dates (exact milliseconds)") {
            for ms in [0.0, 0.001, 0.829, 0.9995, 812072495.829765] {
                let date = Date(timeIntervalSinceReferenceDate: ms)
                let text = ISODate.string(from: date)
                Check.equal(ISODate.string(from: ISODate.date(from: text)!), text, "stable \(text)")
            }
            Check.equal(ISODate.string(from: ISODate.date(from: "2026-09-25T23:41:35Z")!), "2026-09-25T23:41:35.000Z",
                        "plain ISO dates still read")
            Check.equal(ISODate.date(from: "yesterday"), nil)
        }

        Check.group("Chat store") {
            let paths = AppPaths(base: Check.tempPaths())
            let store = ChatStore(paths: paths, debounce: 0.05)
            var talk = Chat.talk()
            talk.append(Message(role: .user, text: "hi", via: .voice, screensSeen: 2))
            talk.append(Message(role: .assistant, text: "hello"))
            store.saveNow(talk)
            var clicky = Chat(kind: .clicky, title: "Research Buddy")
            clicky.memorySummary = "likes Swift"
            store.save(clicky)
            store.flush()

            try JSONFile.write("{broken".data(using: .utf8)!, to: paths.chatFile(UUID()))
            let wrongID = Chat(kind: .clicky, title: "Mismatch")
            try JSONFile.write(wrongID, to: paths.chatFile(UUID()))

            let loaded = store.loadAll()
            Check.equal(loaded.chats.count, 2, "good chats load")
            Check.equal(loaded.setAside.count, 2, "damaged + mismatched set aside")
            // Dates are stored to the millisecond; a stable round trip means re-saving gives identical bytes.
            let reloaded = loaded.chats.first { $0.kind == .talk }
            Check.equal(reloaded.map { try? JSONFile.encode($0) }, try JSONFile.encode(talk), "round trip")
            Check.equal(reloaded?.messages.map(\.text), ["hi", "hello"])
            Check.equal(reloaded?.messages.first?.screensSeen, 2)
            Check.equal(loaded.chats.first { $0.kind == .clicky }?.memorySummary, "likes Swift")

            let old = #"{"id":"\#(UUID().uuidString)","messages":[{"role":"user","text":"x"}]}"#
            let decoded = try JSONFile.decoder.decode(Chat.self, from: old.data(using: .utf8)!)
            Check.equal(decoded.messages.first?.text, "x", "older chat files decode")

            store.delete(id: talk.id)
            Check.equal(store.loadAll().chats.count, 1, "delete removes the file")
            let raw = String(data: try Data(contentsOf: paths.chatFile(clicky.id)), encoding: .utf8) ?? ""
            Check.expect(!raw.contains("base64") && !raw.contains("image"), "no images stored")
        }
    }
}
