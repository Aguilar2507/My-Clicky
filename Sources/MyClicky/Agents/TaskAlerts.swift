import AppKit
import UserNotifications

/// Project rule (spec 018 US3): every task end tells you. This part is the macOS notification: one per task end,
/// shown even while MyClicky is in front, and clicking it opens that Clicky's chat. Permission is asked the first
/// time a task ends. Nothing leaves the Mac.
@MainActor
final class TaskAlerts: NSObject, UNUserNotificationCenterDelegate {
    static let shared = TaskAlerts()
    /// Opens a chat (set by AppDelegate).
    var openChat: (UUID) -> Void = { _ in }
    private var asked = false

    func post(chatID: UUID, title: String, body: String) {
        Log.events.notice("notification posted chat=\(chatID.uuidString.prefix(8), privacy: .public)")
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let send = {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.threadIdentifier = chatID.uuidString
            content.userInfo = ["chatID": chatID.uuidString]
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
        if asked {
            send()
            return
        }
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            Task { @MainActor in
                self?.asked = true
                if granted { send() }
            }
        }
    }

    // Show the banner even when MyClicky is the active app.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    // Clicking it opens the chat.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = (response.notification.request.content.userInfo["chatID"] as? String).flatMap(UUID.init(uuidString:))
        Task { @MainActor in
            if let id { TaskAlerts.shared.openChat(id) }
        }
        completionHandler()
    }
}
