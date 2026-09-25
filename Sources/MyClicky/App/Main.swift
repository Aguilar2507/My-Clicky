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
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // menu bar only, no Dock icon
        app.run()
    }
}
