import SwiftUI
import MyClickyCore

/// The tour's frame: mascot, the current step, progress dots, Back / Skip / Continue (contracts/ui-welcome.md).
struct WelcomeView: View {
    @Environment(AppModel.self) private var model
    let onClose: () -> Void
    @StateObject private var canContinue = Box(true)
    /// Which way the last step change went, set before the change so the leaving step slides the right way.
    @StateObject private var forward = Box(true)

    var body: some View {
        let tour = model.settings.tour
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    LivelyBot().frame(width: 92, height: 92).padding(.top, 30)
                    // Steps slide in the direction of travel; going back retraces the path (spec 014, skill §7).
                    ZStack {
                        step(tour.step)
                            .id(tour.step)
                            .transition(.slide(forward: forward.value))
                    }
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.never)
            .scrollEdgeFade(top: 0, bottom: 16)
            footer(tour)
        }
        .frame(width: 720, height: 600)
        .background(Theme.windowBackground) // grouped gray so the step cards stand out (spec 015)
        .environment(\.controlActiveState, .key)
    }

    @ViewBuilder
    private func step(_ step: TourState.Step) -> some View {
        switch step {
        case .intro: IntroStep()
        case .name: NameStep()
        case .permissions: PermissionsStep()
        case .apiKey: APIKeyStep(canContinue: canContinue)
        case .claudeCode: ClaudeCodeStep()
        case .handsOn: HandsOnStep()
        case .interview: InterviewStep(canContinue: canContinue)
        case .done: DoneStep()
        }
    }

    private func footer(_ tour: TourState) -> some View {
        let progress = TourFlow.progress(tour)
        return HStack {
            if tour.step != .intro && tour.step != .done {
                Button("Back") { go(forward: false) { TourFlow.back(tour) } }
                    .buttonStyle(.pressable).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 7) {
                ForEach(0..<progress.total, id: \.self) { i in
                    Capsule().fill(i == progress.index ? Theme.accent : Theme.track)
                        .frame(width: i == progress.index ? 18 : 7, height: 7)
                }
            }
            .animation(Motion.standard, value: progress.index)
            Spacer()
            if TourFlow.canSkip(tour.step) {
                Button("Skip") { advance(completing: false) }.buttonStyle(.pressable).foregroundStyle(Theme.textSecondary)
                    .padding(.trailing, 12)
            }
            Button(tour.step == .done ? "Start using MyClicky" : "Continue") {
                if tour.step == .done { onClose() } else { advance(completing: true) }
            }
            .buttonStyle(.pill(.primary))
            .disabled(!canContinue.value && (tour.step == .apiKey || tour.step == .interview))
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 18)
        .background(Theme.sidebarBackground)
    }

    private func advance(completing: Bool) {
        canContinue.value = true
        go(forward: true) { TourFlow.next(model.settings.tour, completing: completing) }
    }

    /// Point the transition first, then change the step on the next turn of the run loop.
    private func go(forward isForward: Bool, to next: @escaping () -> TourState) {
        forward.value = isForward
        DispatchQueue.main.async {
            Motion.withAnimation { model.settings.tour = next() }
        }
    }
}

/// Big title + subtitle used by each step.
struct StepTitle: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 8) {
            Text(title).textStyle(.title1).foregroundStyle(Theme.textPrimary).multilineTextAlignment(.center)
            Text(subtitle).textStyle(.callout).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
