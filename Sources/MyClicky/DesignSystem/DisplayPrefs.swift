import AppKit
import Observation

/// The Mac's display accessibility settings, live (spec 014 US5). Theme tokens and motions read these, and
/// Observation re-renders every view that did when you flip a switch in System Settings. No restart needed.
@Observable
final class DisplayPrefs {
    static let shared = DisplayPrefs()

    private(set) var reduceMotion = false
    private(set) var reduceTransparency = false
    private(set) var increaseContrast = false
    /// Snapshot renders can't draw live blur, so they use the solid surfaces.
    var forceSolid = false

    /// Glass surfaces become opaque navy.
    var solidSurfaces: Bool { reduceTransparency || forceSolid }

    private init() {
        refresh()
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.refresh() }
    }

    private func refresh() {
        let workspace = NSWorkspace.shared
        if reduceMotion != workspace.accessibilityDisplayShouldReduceMotion {
            reduceMotion = workspace.accessibilityDisplayShouldReduceMotion
        }
        if reduceTransparency != workspace.accessibilityDisplayShouldReduceTransparency {
            reduceTransparency = workspace.accessibilityDisplayShouldReduceTransparency
        }
        if increaseContrast != workspace.accessibilityDisplayShouldIncreaseContrast {
            increaseContrast = workspace.accessibilityDisplayShouldIncreaseContrast
        }
    }
}
