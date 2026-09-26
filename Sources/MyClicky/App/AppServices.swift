import AppKit

/// Long-lived services that views sometimes need to reach (set up by AppDelegate; nil in snapshots).
@MainActor
final class AppServices {
    static var shared: AppServices?

    let shortcuts: ShortcutCenter
    let notch: NotchController

    init(shortcuts: ShortcutCenter, notch: NotchController) {
        self.shortcuts = shortcuts
        self.notch = notch
    }
}

/// Where the app content is: home (chats) or a settings page.
enum HomeRoute: Equatable {
    case home
    case settings(SettingsPage)
}
