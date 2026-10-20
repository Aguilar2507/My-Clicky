import AppKit
import CoreGraphics
import Intents
import MyClickyCore

/// Notices calls, screen sharing and Focus so MyClicky stays quiet (spec 007 US4, research R6). Best-effort:
/// macOS has no single public API for these; the menu bar icon's right-click menu can force quiet on or off for an hour.
@MainActor
final class QuietMonitor {
    let model: AppModel
    private var timer: Timer?
    private(set) var focusDetection = "unknown"

    init(model: AppModel) {
        self.model = model
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        requestFocusAccess()
        refresh()
    }

    func refresh() {
        var reasons = Set<QuietPolicy.Reason>()
        // A call: another app is using the microphone while MyClicky isn't listening. While MyClicky listens it can't
        // tell whose the microphone use is, so it keeps what it knew: clearing it let answers speak during calls.
        if model.talkState == .listening || model.isDictating {
            if model.quietReasons.contains(.call) { reasons.insert(.call) }
        } else if let mic = AudioDevices.defaultInput, AudioDevices.isRunningSomewhere(mic) {
            reasons.insert(.call)
        }
        if Self.screenSharingVisible() { reasons.insert(.screenSharing) }
        if Self.focusIsOn() { reasons.insert(.focus) }
        if model.quietReasons != reasons {
            Log.events.notice("quiet reasons=\(reasons.map { "\($0)" }.sorted().joined(separator: ","), privacy: .public)")
            model.quietReasons = reasons
        }
    }

    /// Known screen-sharing UI (window names need Screen Recording permission, which MyClicky already has).
    static func screenSharingVisible() -> Bool {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return false }
        let signals: [(owner: String, name: String)] = [
            ("zoom.us", "share"), ("Microsoft Teams", "sharing"), ("Slack", "screen share"), ("Webex", "sharing"),
            ("FaceTime", "sharing"), ("Screen Sharing", ""), ("", "is sharing your screen"), ("", "sharing indicator"),
        ]
        for window in windows {
            let owner = (window[kCGWindowOwnerName as String] as? String ?? "").lowercased()
            let name = (window[kCGWindowName as String] as? String ?? "").lowercased()
            for signal in signals {
                let ownerOK = signal.owner.isEmpty || owner.contains(signal.owner.lowercased())
                let nameOK = signal.name.isEmpty ? !signal.owner.isEmpty && owner == signal.owner.lowercased() : name.contains(signal.name)
                if ownerOK && nameOK { return true }
            }
        }
        return false
    }

    /// Focus / Do Not Disturb via INFocusStatusCenter. Needs authorization; may be unavailable to ad-hoc signed apps.
    static func focusIsOn() -> Bool {
        guard INFocusStatusCenter.default.authorizationStatus == .authorized else { return false }
        return INFocusStatusCenter.default.focusStatus.isFocused ?? false
    }

    private func requestFocusAccess() {
        INFocusStatusCenter.default.requestAuthorization { [weak self] status in
            let text: String
            switch status {
            case .authorized: text = "authorized"
            case .denied: text = "denied"
            case .restricted: text = "restricted (not available to this app)"
            default: text = "not determined"
            }
            Task { @MainActor in self?.focusDetection = text }
        }
    }
}

/// A small clickable "▶ Play answer" chip next to the cursor, for answers that arrived while MyClicky was quiet.
@MainActor
final class QuietPlayChip: NSObject {
    private var panel: NSPanel?
    private var hideWork: DispatchWorkItem?

    func show(near point: CGPoint, action: @escaping () -> Void) {
        close()
        let size = CGSize(width: 150, height: 32)
        let panel = NSPanel(contentRect: CGRect(x: point.x + 16, y: point.y - 90, width: size.width, height: size.height),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let button = NSButton(title: "🔇  Play answer", target: self, action: #selector(play))
        button.bezelStyle = .rounded
        button.frame = CGRect(origin: .zero, size: size)
        panel.contentView = button
        panel.orderFrontRegardless()
        self.panel = panel
        self.action = action
        let work = DispatchWorkItem { [weak self] in self?.close() }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: work)
    }

    private var action: (() -> Void)?

    @objc private func play() {
        action?()
        close()
    }

    func close() {
        hideWork?.cancel()
        panel?.orderOut(nil)
        panel = nil
    }
}
