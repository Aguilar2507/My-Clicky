import os

/// MyClicky's diagnostic log (no personal data: no keys, speech or screen content).
/// Read it with: log show --last 30m --predicate 'subsystem == "com.myclicky.app"'
enum Log {
    static let shortcuts = Logger(subsystem: "com.myclicky.app", category: "shortcuts")
}
