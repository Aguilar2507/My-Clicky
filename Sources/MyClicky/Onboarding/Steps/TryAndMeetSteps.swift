import SwiftUI
import MyClickyCore

/// Hands-on practice: each action ticks off when MyClicky sees you do it (spec 012 US2).
struct HandsOnStep: View {
    @Environment(AppModel.self) private var model
    @StateObject private var practice = Box("")

    var body: some View {
        VStack(spacing: 16) {
            StepTitle(title: "Try it", subtitle: "Do each one — they tick off by themselves. Skip any you like.")
            SettingsCard {
                ForEach(Array(AppEvent.allCases.enumerated()), id: \.element) { index, event in
                    if index > 0 { CardDivider() }
                    HStack(spacing: 14) {
                        Image(systemName: model.seenEvents.contains(event) ? "checkmark.circle.fill" : "circle")
                            .font(.icon(20))
                            .foregroundStyle(model.seenEvents.contains(event) ? Theme.green : Theme.textTertiary)
                        Text(event.title).textStyle(.callout).foregroundStyle(Theme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 18).padding(.vertical, 12)
                }
            }
            TextField("Practice box: click here, then hold control + fn and speak", text: $practice.value, axis: .vertical)
                .lineLimit(2...3).darkField()
        }
    }
}

/// Three questions → three Clickys made for you (Claude Code first, then Haiku, then starters).
struct InterviewStep: View {
    @Environment(AppModel.self) private var model
    let canContinue: Box<Bool>
    @StateObject private var answers = Box(["", "", ""])
    @StateObject private var index = Box(0)
    @StateObject private var creating = Box(false)
    @StateObject private var created = Box<[String]>([])
    @StateObject private var note = Box<String?>(nil)
    @StateObject private var dictation = ComposerDictation()

    static let questions = ["What do you do?", "What eats your time each week?", "Which apps do you live in?"]

    var body: some View {
        VStack(spacing: 18) {
            if !created.value.isEmpty {
                StepTitle(title: "Meet your agents", subtitle: note.value ?? "They're in your sidebar, ready for tasks.")
                HStack(spacing: 18) {
                    ForEach(model.clickys.filter { created.value.contains($0.title) }) { chat in
                        VStack(spacing: 8) {
                            ChatAvatar(chat: chat, size: 60)
                            Text(chat.title).textStyle(.callout.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                            Text(chat.purpose).textStyle(.caption).foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center).lineLimit(3)
                        }
                        .frame(width: 180)
                    }
                }
            } else if creating.value {
                StepTitle(title: "Creating your agents…", subtitle: "Picking names, colors and jobs from your answers.")
                ProgressView()
            } else {
                StepTitle(title: Self.questions[index.value], subtitle: "Question \(index.value + 1) of 3 — type or tap the mic.")
                HStack(alignment: .bottom, spacing: 10) {
                    TextField("Your answer", text: $answers.value[index.value], axis: .vertical).lineLimit(2...4).darkField()
                    Button {
                        dictation.toggle { answers.value[index.value] += (answers.value[index.value].isEmpty ? "" : " ") + $0 }
                    } label: {
                        Image(systemName: dictation.isListening ? "waveform.circle.fill" : "mic.circle.fill").font(.icon(30))
                            .foregroundStyle(dictation.isListening ? Theme.red : Theme.accent)
                    }
                    .buttonStyle(.pressable)
                }
                .frame(maxWidth: 520)
                HStack {
                    if index.value > 0 { Button("Previous") { index.value -= 1 }.buttonStyle(.pill(.dark, compact: true)) }
                    Spacer()
                    Button(index.value < 2 ? "Next question" : "Create my agents") {
                        if index.value < 2 { index.value += 1 } else { Task { await create() } }
                    }
                    .buttonStyle(.pill(.primary, compact: true))
                }
                .frame(maxWidth: 520)
            }
        }
        .onAppear { canContinue.value = !created.value.isEmpty }
    }

    private func create() async {
        creating.value = true
        defer { creating.value = false }
        let prompt = """
        Create 3 helpers ("Clickys") for this person from their answers. Reply with JSON only:
        {"clickys": [{"name": "1-3 words, playful but clear", "color": "peach|sky|butter|lilac|pink|mint|coral|slate",
        "purpose": "one paragraph that works as the helper's standing instructions"}]}
        What they do: \(answers.value[0])
        What eats their time: \(answers.value[1])
        Apps they use: \(answers.value[2])
        """
        var reply = ""
        if let claude = ClaudeCodeLocator.find(model.settings) { // their Claude plan: no API cost
            let output = await ClaudeCodeLocator.run(claude, ["-p", prompt, "--output-format", "json", "--max-turns", "1"])
            reply = ((try? JSONSerialization.jsonObject(with: Data(output.utf8))) as? [String: Any])?["result"] as? String ?? ""
        }
        if reply.isEmpty, let key = Keychain.apiKey(), PaidRequestGate.allow(model),
           let answer = try? await ClaudeClient().complete(system: "You design helpful assistant personas.", user: prompt,
                                                           model: model.settings.fastModel, maxTokens: 700, apiKey: key) {
            PaidRequestGate.record(model, answer.usage, kind: .interview)
            reply = answer.text
        }
        let result = InterviewParser.parse(reply, existing: model.chats.map(\.title))
        var names: [String] = []
        for clicky in result.clickys {
            let id = model.createClicky(purpose: clicky.purpose)
            model.updateChat(id) {
                $0.title = clicky.name
                $0.avatarColor = clicky.color
            }
            names.append(clicky.name)
        }
        if result.usedFallback { note.value = "I couldn't reach Claude, so here are three starters. Rename them anytime." }
        created.value = names
        canContinue.value = true
    }
}

struct DoneStep: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 18) {
            StepTitle(title: "You're all set, \(model.settings.profileName).", subtitle: "Three things to remember:")
            VStack(alignment: .leading, spacing: 12) {
                tip("menubar.rectangle", "Click the bot in the menu bar or press option + space to open your chats and settings.")
                tip("mic.fill", "Hold control + option and ask about anything on your screen.")
                tip("person.3.fill", "Say “Jarvis agent…” (or click +) to give an agent a task.")
            }
            .padding(20)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func tip(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(Theme.accent).frame(width: 22)
            Text(text).textStyle(.callout).foregroundStyle(Theme.textPrimary)
        }
    }
}
