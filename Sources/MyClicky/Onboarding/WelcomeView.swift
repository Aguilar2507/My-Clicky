import SwiftUI
import MyClickyCore

/// The tour's frame: mascot, the current step, progress dots, Back / Skip / Continue (contracts/ui-welcome.md).
struct WelcomeView: View {
    @Environment(AppModel.self) private var model
    let onClose: () -> Void
    @StateObject private var canContinue = Box(true)

    var body: some View {
        let tour = model.settings.tour
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    MascotBlob(color: Color(hex: 0xE8A090), glow: true).frame(width: 96, height: 70).padding(.top, 34)
                    step(tour.step)
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.never)
            footer(tour)
        }
        .frame(width: 720, height: 600)
        .background(Theme.windowBackground)
        .preferredColorScheme(.dark)
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
                Button("Back") { model.settings.tour = TourFlow.back(tour) }.buttonStyle(.plain).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 7) {
                ForEach(0..<progress.total, id: \.self) { i in
                    Circle().fill(i == progress.index ? Theme.lavender : Color(hex: 0x3A3A3C)).frame(width: 7, height: 7)
                }
            }
            Spacer()
            if TourFlow.canSkip(tour.step) {
                Button("Skip") { advance(completing: false) }.buttonStyle(.plain).foregroundStyle(Theme.textSecondary)
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
        .background(Color.black.opacity(0.25))
    }

    private func advance(completing: Bool) {
        canContinue.value = true
        model.settings.tour = TourFlow.next(model.settings.tour, completing: completing)
    }
}

/// Big title + subtitle used by each step.
struct StepTitle: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.system(size: 26, weight: .bold)).foregroundStyle(Theme.textPrimary).multilineTextAlignment(.center)
            Text(subtitle).font(.system(size: 15)).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
