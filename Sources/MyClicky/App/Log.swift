import os

/// MyClicky's diagnostic log (no personal data: no keys, speech or screen content).
/// Read it with: log show --last 30m --predicate 'subsystem == "com.myclicky.app"'
enum Log {
    static let shortcuts = Logger(subsystem: "com.myclicky.app", category: "shortcuts")
    /// What happened, never what was said: talk, voice, pointing, dictation, agents, alerts, budget, window.
    /// End-to-end checks (`scripts/e2e/`) read these lines.
    static let events = Logger(subsystem: "com.myclicky.app", category: "events")
}
