import Foundation
import MyClickyCore

/// Checks for spec 009 (agents).
enum AgentChecks {
    static func run() {
        Check.group("Agent stream events") {
            let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("specs/009-agents/samples/stream.documented.jsonl")
            let lines = (try String(contentsOf: url, encoding: .utf8)).split(separator: "\n").map(String.init)
            let events = lines.flatMap(AgentEventParser.parse(line:))
            Check.equal(events.first, .initialized(sessionID: "4f1c2a9e-0000-4000-8000-000000000001"))
            Check.equal(events[1], .text("I'll look up today's AI news first."))
            Check.equal(events[2], .toolUse(id: "toolu_01", name: "WebSearch", input: ["query": "AI news today"]))
            Check.equal(events[3], .toolResult(id: "toolu_01", isError: false, summary: "1. Model release…"))
            Check.equal(events[5], .toolResult(id: "toolu_02", isError: false, summary: "File created"), "array content")
            Check.equal(events.last, .result(subtype: "success", text: "Done. The summary is in ai-news.md.", turns: 4,
                                             sessionID: "4f1c2a9e-0000-4000-8000-000000000001", isError: false))
            let real = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("specs/009-agents/samples/stream.real.jsonl")
            let realEvents = (try String(contentsOf: real, encoding: .utf8)).split(separator: "\n").map(String.init)
                .flatMap(AgentEventParser.parse(line:))
            let session = "fde0873e-dc36-425f-b509-f1d6a4b812b8"
            Check.equal(realEvents.count, 5, "real run (2.1.283): rate_limit_event, thinking_tokens and thinking blocks ignored")
            Check.equal(realEvents.first, .initialized(sessionID: session))
            Check.equal(realEvents[1], .toolUse(id: "toolu_01JAUaPeAyqgPJ8Yv3ZkSZAg", name: "Bash",
                                                input: ["command": "echo hello", "description": "Print hello"]))
            Check.equal(realEvents[2], .toolResult(id: "toolu_01JAUaPeAyqgPJ8Yv3ZkSZAg", isError: false, summary: "hello"))
            Check.equal(realEvents[3], .text("done"))
            Check.equal(realEvents.last, .result(subtype: "success", text: "done", turns: 2, sessionID: session, isError: false))
            Check.equal(AgentEventParser.parse(line: #"{"type":"stream_event","event":{}}"#), [], "unknown types ignored")
            Check.equal(AgentEventParser.parse(line: #"{"type":"assist"#), [], "partial line ignored")
            Check.equal(AgentEventParser.parse(line: #"{"type":"result","subtype":"error_max_turns","is_error":true,"num_turns":40}"#),
                        [.result(subtype: "error_max_turns", text: "", turns: 40, sessionID: nil, isError: true)])
        }

        Check.group("Permission descriptions") {
            let ls = PermissionDescriber.describe(tool: "Bash", input: ["command": "ls ~/Desktop"])
            Check.equal(ls.text, "Run a command")
            Check.equal(ls.detail, "ls ~/Desktop")
            Check.equal(ls.rule, "Bash(ls:*)")
            Check.expect(!ls.sensitive)
            for command in ["rm -rf build", "cd x && rm file", "git push origin main", "sudo reboot",
                            "curl -X POST https://x", "osascript -e 'tell app \"Mail\" to send'", "defaults write com.apple.x y 1"] {
                Check.expect(PermissionDescriber.describe(tool: "Bash", input: ["command": command]).sensitive, command)
            }
            Check.expect(!PermissionDescriber.isSensitive(command: "echo remove the item"), "words aren't commands")
            let click = PermissionDescriber.describe(tool: "mcp__myclicky__click", input: ["x": "10", "y": "20"])
            Check.equal(click.text, "Click on your screen")
            Check.expect(click.isComputerUse)
            let gh = PermissionDescriber.describe(tool: "mcp__myclicky-github__create_issue", input: ["title": "Bug"])
            Check.expect(gh.text.hasPrefix("Use Github"), gh.text)
            Check.expect(gh.sensitive, "creating things in connected apps is sensitive")
            Check.expect(PermissionDescriber.isPreApproved(ls, rules: ["Bash(ls:*)"]))
            let rm = PermissionDescriber.describe(tool: "Bash", input: ["command": "rm a"])
            Check.expect(!PermissionDescriber.isPreApproved(rm, rules: ["Bash(rm:*)"]), "sensitive never pre-approved")
            Check.equal(PermissionDescriber.stepSummary(tool: "WebSearch", input: ["query": "ai news"]), "Searching the web: ai news")
            Check.equal(PermissionDescriber.stepSummary(tool: "Write", input: ["file_path": "/a/b/report.md"]), "Writing report.md")
        }

        Check.group("Run queue + step cap") {
            var q = RunQueue()
            let ids = (0..<5).map { _ in UUID() }
            Check.equal(ids.prefix(3).map { q.request($0) }, [true, true, true])
            Check.equal(q.request(ids[3]), false, "4th waits")
            Check.equal(q.request(ids[4]), false)
            Check.equal(q.finish(ids[1]), ids[3], "FIFO")
            Check.equal(q.running.count, 3)
            Check.equal(q.finish(ids[4]), nil, "cancelling a waiting run starts nothing")
            Check.equal(RunQueue.stepLimit(autoApprove: false), 40)
            Check.equal(RunQueue.stepLimit(autoApprove: true), 150)
        }

        Check.group("MCP protocol") {
            let call = MCPProtocol.parse(line: #"{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"click","arguments":{"x":1}}}"#)
            Check.equal(call?.method, "tools/call")
            Check.equal(call?.id as? Int, 7)
            let note = MCPProtocol.parse(line: #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#)
            Check.expect(note != nil && note?.id == nil, "notifications have no id")
            let reply = MCPProtocol.result(id: 7, ["ok": true])
            Check.expect(reply.contains(#""id":7"#) && reply.contains(#""jsonrpc":"2.0""#))
            Check.equal(Set(MCPProtocol.tools.compactMap { $0["name"] as? String }),
                        ["approve", "screenshot", "click", "type", "key", "scroll", "move"])
            let request = BridgeRequest(id: "1", chatID: "c", tool: "click", input: ["x": .number(10), "label": .string("ok")])
            let decoded = try JSONFile.decoder.decode(BridgeRequest.self, from: JSONFile.encode(request))
            Check.equal(decoded, request, "bridge request round trip")
            Check.equal(JSONValue(any: ["a": [1, "b", true]]).any as? [String: [Any]] != nil, true)
        }

        Check.group("Bridge round trip (MyClickyComputer ⇄ socket)") {
            // Real processes: start the socket server, run the bridge like Claude Code would, send an MCP tools/call.
            let base = Check.tempPaths()
            let socketPath = "/tmp/myclicky-check-\(ProcessInfo.processInfo.processIdentifier).sock" // sun_path is short
            let server = BridgeSocketServer(path: socketPath) { request in
                BridgeResponse(id: request.id, ok: true,
                               content: [.text("got \(request.tool) for \(request.chatID) x=\(request.input["x"]?.double ?? -1)")])
            }
            try server.start()
            defer { server.stop() }
            let perms = (try? FileManager.default.attributesOfItem(atPath: socketPath)[.posixPermissions] as? Int) ?? 0
            Check.equal(perms, 0o600, "socket is private to this user")

            let bridge = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().appendingPathComponent("MyClickyComputer")
            guard FileManager.default.isExecutableFile(atPath: bridge.path) else {
                Check.expect(false, "build MyClickyComputer first (swift build)")
                return
            }
            let process = Process()
            process.executableURL = bridge
            process.arguments = ["--chat", "chat-1", "--socket", socketPath]
            let input = Pipe(), output = Pipe()
            process.standardInput = input
            process.standardOutput = output
            try process.run()
            let call = #"{"jsonrpc":"2.0","id":9,"method":"tools/call","params":{"name":"click","arguments":{"x":12}}}"#
            input.fileHandleForWriting.write(Data((call + "\n").utf8))
            try input.fileHandleForWriting.close()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let reply = String(decoding: data, as: UTF8.self)
            Check.expect(reply.contains("got click for chat-1 x=12.0"), "reply came back through the socket: \(reply.prefix(160))")
            Check.expect(reply.contains(#""isError":false"#))
            _ = base
        }

        Check.group("Suggestions") {
            let now = Date()
            let parsed = SuggestionParser.parse(#"Here: [{"text":"Draft the weekly update","clicky":"Build Lab"},{"text":"Check new roles","clicky":null},{"text":" "},{"text":"a"},{"text":"b"}]"#, now: now)
            Check.equal(parsed.map(\.text), ["Draft the weekly update", "Check new roles", "a"], "max 3, blanks dropped")
            Check.equal(parsed.first?.clickyTitle, "Build Lab")
            Check.equal(SuggestionParser.parse("nothing"), [])
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC")!
            let six = cal.date(from: DateComponents(year: 2026, month: 9, day: 25, hour: 6))!
            let eight = cal.date(from: DateComponents(year: 2026, month: 9, day: 25, hour: 8))!
            Check.expect(!SuggestionParser.isDue(last: nil, now: six, calendar: cal), "not before 7")
            Check.expect(SuggestionParser.isDue(last: nil, now: eight, calendar: cal))
            Check.expect(!SuggestionParser.isDue(last: eight.addingTimeInterval(-3600), now: eight, calendar: cal), "20 h spacing")
            Check.equal(SuggestionParser.current(parsed, now: now.addingTimeInterval(86_400 * 2)), [], "expire after the day")
        }

        Check.group("Chat file: 009 fields") {
            let old = #"{"id":"\#(UUID().uuidString)","messages":[{"role":"assistant","text":"hi"}]}"#
            let chat = try JSONFile.decoder.decode(Chat.self, from: old.data(using: .utf8)!)
            Check.equal(chat.messages.first?.kind, .text)
            Check.equal(chat.alwaysAllowed, [])
            var step = Message(role: .system, text: "Searching the web")
            step.kind = .step
            var c2 = Chat(kind: .clicky, title: "x")
            c2.append(Message(role: .assistant, text: "answer"))
            c2.append(step)
            Check.equal(c2.preview, "answer", "steps don't become the preview")
        }
    }
}
