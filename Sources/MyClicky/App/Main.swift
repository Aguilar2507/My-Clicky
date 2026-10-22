import AppKit

@main
@MainActor
enum Main {
    static let delegate = AppDelegate()

    static func main() {
        // Developer tool: `MyClicky --snapshot <screen> <out.png>` renders a screen to an image and exits.
        if let index = CommandLine.arguments.firstIndex(of: "--snapshot") {
            let args = Array(CommandLine.arguments.dropFirst(index + 1))
            exit(Snapshot.run(screen: args.first ?? "", output: args.dropFirst().first ?? "snapshot.png") ? 0 : 1)
        }
        // Developer tool: `MyClicky --bench-bot` shows the animated bot for 8 s and prints the CPU it used (spec 016).
        if CommandLine.arguments.contains("--bench-bot") { BotBenchmark.run() }
        // Developer tool: `MyClicky --demo-agent-bot` summons the agent bot, then sends it away, printing its frames.
        if CommandLine.arguments.contains("--demo-agent-bot") { BotBenchmark.demoAgentBot() }
        // Developer tool: `--hold-mic <seconds>` keeps the microphone busy like a call (quiet-mode checks).
        if let index = CommandLine.arguments.firstIndex(of: "--hold-mic") {
            MicHolder.run(seconds: Double(CommandLine.arguments.dropFirst(index + 1).first ?? "") ?? 20)
        }
        // Developer tool: `--screenshot <out.png>` saves every display and exits (end-to-end checks, scripts/e2e/).
        if let index = CommandLine.arguments.firstIndex(of: "--screenshot") {
            ScreenshotTool.run(output: CommandLine.arguments.dropFirst(index + 1).first ?? "/tmp/myclicky-screen.png")
        }
        // A write to a closed pipe or socket (an agent that exited, its bridge) returns an error instead of killing us.
        signal(SIGPIPE, SIG_IGN)
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // the "Show in Dock" setting turns on the Dock icon at launch (spec 019)
        app.run()
    }
}
