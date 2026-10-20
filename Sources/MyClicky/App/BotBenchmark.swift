import AppKit
import SwiftUI

/// `MyClicky --bench-bot`: shows the greeting-size animated bot in a small window for 8 seconds, then prints the CPU
/// time the process used, so changes to the bot's rendering can be measured (spec 016).
@MainActor
enum BotBenchmark {
    static func run() -> Never {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let window = NSWindow(contentRect: NSRect(x: 60, y: 60, width: 220, height: 220),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.title = "Bot benchmark"
        window.contentView = NSHostingView(rootView: LivelyBot(sparkles: true).frame(width: 112, height: 112)
            .frame(width: 220, height: 220).background(Theme.contentBackground))
        window.orderFrontRegardless()
        RunLoop.current.run(until: Date().addingTimeInterval(1)) // warm up
        let start = cpuSeconds(), wall = Date()
        RunLoop.current.run(until: Date().addingTimeInterval(8))
        let used = cpuSeconds() - start, elapsed = Date().timeIntervalSince(wall)
        print(String(format: "Bot: %.1f%% of one core (%.2f s CPU in %.1f s)", used / elapsed * 100, used, elapsed))
        exit(0)
    }

    static func demoAgentBot() -> Never {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let bot = AgentBotPresenter()
        func report(_ label: String) {
            let frames = NSApp.windows.filter(\.isVisible).map { "\(Int($0.frame.minX)),\(Int($0.frame.minY)) \(Int($0.frame.width))×\(Int($0.frame.height))" }
            print(label, bot.isOut ? "out" : "away", frames)
        }
        print("pointer", NSEvent.mouseLocation)
        bot.summon()
        report("t=0.0")
        for t in [0.25, 0.6, 1.5] {
            RunLoop.current.run(until: Date().addingTimeInterval(t == 0.25 ? 0.25 : t == 0.6 ? 0.35 : 0.9))
            report("t=\(t)")
        }
        var gone = false
        bot.dismiss(nod: true) { gone = true }
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        report("leaving")
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        report(gone ? "gone" : "still out")
        exit(0)
    }

    private static func cpuSeconds() -> Double {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        func seconds(_ t: timeval) -> Double { Double(t.tv_sec) + Double(t.tv_usec) / 1_000_000 }
        return seconds(usage.ru_utime) + seconds(usage.ru_stime)
    }
}
