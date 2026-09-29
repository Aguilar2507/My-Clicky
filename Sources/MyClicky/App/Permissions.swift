import AppKit
import AVFoundation
import Speech
import ApplicationServices

/// The five permissions MyClicky needs, with live status and the System Settings page for each.
enum Permission: String, CaseIterable, Identifiable {
    case microphone, speechRecognition, screenRecording, accessibility, inputMonitoring

    var id: String { rawValue }

    var title: String {
        switch self {
        case .microphone: "Microphone"
        case .speechRecognition: "Speech Recognition"
        case .screenRecording: "Screen Recording"
        case .accessibility: Self.accessibilityName
        case .inputMonitoring: "Input Monitoring"
        }
    }

    /// macOS 27 renamed Privacy & Security → Accessibility to "Device Control and Data Access".
    static var accessibilityName: String {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 ? "Device Control and Data Access" : "Accessibility"
    }

    var why: String {
        switch self {
        case .microphone: "Hear you while you hold the talk key."
        case .speechRecognition: "Turn your voice into text on this Mac."
        case .screenRecording: "See your screen when you ask something."
        case .accessibility: "Point, type and use your shortcuts in any app."
        case .inputMonitoring: "Notice your shortcut keys in other apps."
        }
    }

    var isGranted: Bool {
        switch self {
        case .microphone: AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        case .speechRecognition: SFSpeechRecognizer.authorizationStatus() == .authorized
        case .screenRecording: CGPreflightScreenCaptureAccess()
        case .accessibility: AXIsProcessTrusted()
        case .inputMonitoring: CGPreflightListenEventAccess()
        }
    }

    private var pane: String {
        switch self {
        case .microphone: "Privacy_Microphone"
        case .speechRecognition: "Privacy_SpeechRecognition"
        case .screenRecording: "Privacy_ScreenCapture"
        case .accessibility: "Privacy_Accessibility"
        case .inputMonitoring: "Privacy_ListenEvent"
        }
    }

    /// Asks macOS (shows the system prompt when possible), then opens the right System Settings page.
    func request() {
        switch self {
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        case .speechRecognition:
            SFSpeechRecognizer.requestAuthorization { _ in }
        case .screenRecording:
            CGRequestScreenCaptureAccess()
        case .accessibility:
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        case .inputMonitoring:
            CGRequestListenEventAccess()
        }
        openSettings()
    }

    func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }
}
