import AppKit

/// Shows or hides the Dock icon from the "Show in Dock" setting (spec 003 US5).
@MainActor
enum DockPolicy {
    static func apply(showInDock: Bool) {
        let policy: NSApplication.ActivationPolicy = showInDock ? .regular : .accessory
        if NSApp.activationPolicy() != policy { NSApp.setActivationPolicy(policy) }
    }
}

/// Keeps MyClicky's windows out of screen recordings when "Show in screen recordings" is off (spec 004).
@MainActor
enum WindowSharing {
    static func apply(to window: NSWindow, model: AppModel) {
        window.sharingType = model.settings.showInScreenRecordingsValue ? .readOnly : .none
    }
}

extension Settings {
    /// Until spec 004 adds the setting, MyClicky is visible in recordings (HeyClicky's default).
    var showInScreenRecordingsValue: Bool { true }
}
