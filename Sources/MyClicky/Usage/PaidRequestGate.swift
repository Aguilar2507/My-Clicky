import AppKit
import MyClickyCore

/// Every paid API request goes through here (spec 011 research R1): the monthly budget is checked before sending,
/// and the cost is recorded (by model, kind and day) after. Agents never come here: they use the Claude plan.
@MainActor
enum PaidRequestGate {
    /// Shown once a month at 80% (percent, budget).
    static var onWarn: (Int, Double) -> Void = { _, _ in }
    /// Shown when a request is blocked (resets on).
    static var onBlock: (Date) -> Void = { _ in }

    static func decision(_ model: AppModel) -> BudgetPolicy.Decision {
        let month = UsageMonth.key(for: Date())
        return BudgetPolicy.decision(spent: model.thisMonth.costUSD, budget: model.settings.monthlyBudgetUSD,
                                     topUp: model.settings.budgetTopUps[month] ?? 0,
                                     warnedMonth: model.settings.budgetWarnedMonth, month: month)
    }

    /// For requests you asked for (answers, the welcome interview): shows the 80% / 100% notices.
    static func allow(_ model: AppModel) -> Bool {
        switch decision(model) {
        case .allow:
            return true
        case .warn(let percent):
            model.settings.budgetWarnedMonth = UsageMonth.key(for: Date())
            Log.events.notice("budget warn percent=\(percent, privacy: .public)")
            onWarn(percent, model.settings.monthlyBudgetUSD)
            return true
        case .block(let resetsOn):
            Log.events.notice("budget blocked")
            onBlock(resetsOn)
            return false
        }
    }

    /// For background requests (memory summaries, naming): silently skipped when the budget is reached.
    static func allowsBackground(_ model: AppModel) -> Bool {
        if case .block = decision(model) { return false }
        return true
    }

    static func record(_ model: AppModel, _ usage: TokenUsage, kind: UsageMonth.Kind) {
        model.usageStore.record(usage, kind: kind)
        model.usageRevision += 1
    }

    /// "Allow $2 more this month".
    static func topUp(_ model: AppModel) {
        let month = UsageMonth.key(for: Date())
        model.settings.budgetTopUps[month, default: 0] += BudgetPolicy.topUpStep
        Log.events.notice("budget topped up")
    }
}

/// A clickable chip beside the cursor: "Allow $2 more this month" (the bubble itself is click-through).
@MainActor
final class TopUpChip: NSObject {
    private var panel: NSPanel?
    private var action: (() -> Void)?

    func show(action: @escaping () -> Void) {
        close()
        self.action = action
        let mouse = NSEvent.mouseLocation
        let size = CGSize(width: 230, height: 32)
        let panel = NSPanel(contentRect: CGRect(x: mouse.x + 16, y: mouse.y - 96, width: size.width, height: size.height),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let button = NSButton(title: "Allow $2 more this month", target: self, action: #selector(tapped))
        button.bezelStyle = .rounded
        button.frame = CGRect(origin: .zero, size: size)
        panel.contentView = button
        panel.orderFrontRegardless()
        self.panel = panel
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in self?.close() }
    }

    @objc private func tapped() {
        action?()
        close()
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }
}
