import SwiftUI
import AVFoundation

/// Settings → Microphone (ref 05): input device list and a live level test.
struct MicrophonePage: View {
    @Environment(AppModel.self) private var model
    @StateObject private var tester = MicTester()
    @StateObject private var devices = Box(AudioDevices.inputs())

    var body: some View {
        let selectedUID = model.settings.microphoneUID
        let missing = !selectedUID.isEmpty && !devices.value.contains { $0.uid == selectedUID }
        VStack(alignment: .leading, spacing: 14) {
            PageHeader(title: "Microphone", subtitle: SettingsPage.microphone.subtitle)
            SectionLabel("Input device")
            SettingsCard {
                row("System Default", selected: selectedUID.isEmpty || missing) { model.settings.microphoneUID = "" }
                ForEach(devices.value) { device in
                    CardDivider()
                    row(device.name, selected: device.uid == selectedUID) { model.settings.microphoneUID = device.uid }
                }
            }
            if missing {
                Text("Your chosen microphone is disconnected — using System Default.").textStyle(.footnote)
                    .foregroundStyle(Theme.orange).padding(.leading, 8)
            }
            SectionLabel("Test").padding(.top, 10)
            SettingsCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 18) {
                        Button(tester.isRunning ? "Stop test" : "Test microphone") {
                            tester.isRunning ? tester.stop() : tester.start(uid: model.settings.microphoneUID)
                        }
                        .buttonStyle(.pill(.secondary))
                        LevelMeter(level: tester.level)
                    }
                    Text("Tap to test selected input").textStyle(.footnote).foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.rowPadding)
            }
            Text("Speak normally — the bars should move as MyClicky hears you.").textStyle(.footnote)
                .foregroundStyle(Theme.textSecondary).padding(.leading, 8)
        }
        .onAppear { AudioDevices.onChange { devices.value = AudioDevices.inputs() } }
        .onDisappear { tester.stop() }
    }

    private func row(_ name: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                RadioMark(isOn: selected)
                Text(name).textStyle(.headline).foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(Theme.rowPadding)
            .hoverHighlight(radius: Theme.cardRadius)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressableRow)
    }
}

/// 16 rounded bars that light up with the input level.
struct LevelMeter: View {
    let level: Float

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<16, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Float(i) / 16 < level ? AnyShapeStyle(Theme.accentFill) : AnyShapeStyle(Theme.track))
                    .frame(width: 8, height: 26)
            }
        }
        .animation(Motion.quick, value: level) // tracks the voice continuously (spec 014)
    }
}

/// Listens to the chosen microphone for up to 10 s and publishes its level.
@MainActor
final class MicTester: ObservableObject {
    @Published private(set) var level: Float = 0
    @Published private(set) var isRunning = false
    private var engine: AVAudioEngine?
    private var stopWork: DispatchWorkItem?

    func start(uid: String) {
        stop()
        let engine = AVAudioEngine()
        SpeechRecognizer.selectInput(uid, on: engine)
        let format = engine.inputNode.outputFormat(forBus: 0)
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            let level = SpeechRecognizer.level(of: buffer)
            Task { @MainActor in self?.level = level }
        }
        do {
            try engine.start()
            self.engine = engine
            isRunning = true
            AppModel.shared.isDictating = true // not a call
            let work = DispatchWorkItem { [weak self] in self?.stop() }
            stopWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: work)
        } catch {
            isRunning = false
        }
    }

    func stop() {
        stopWork?.cancel()
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        isRunning = false
        level = 0
        AppModel.shared.isDictating = false
    }
}
