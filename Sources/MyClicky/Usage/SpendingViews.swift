import SwiftUI
import Charts
import MyClickyCore

/// Small ring next to the footer spend (ref 02's usage ring): fills toward the monthly budget.
struct SpendRing: View {
    let fraction: Double
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Circle().stroke(Theme.track, lineWidth: 2.5)
            Circle().trim(from: 0, to: max(0.001, fraction))
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }

    private var color: Color {
        fraction >= 1 ? Theme.red : fraction >= BudgetPolicy.warnFraction ? Theme.orange : Theme.accent
    }
}

extension AppModel {
    var budgetFraction: Double {
        BudgetPolicy.fraction(spent: thisMonth.costUSD, budget: settings.monthlyBudgetUSD,
                              topUp: settings.budgetTopUps[UsageMonth.key(for: Date())] ?? 0)
    }
}

/// Spending sheet (contracts/ui-spending.md): total, splits, 6-month chart, credit projection, disclaimer.
struct SpendingSheet: View {
    @Environment(AppModel.self) private var model
    let onDone: () -> Void
    @StateObject private var creditText = Box("")

    var body: some View {
        _ = model.usageRevision
        let month = model.thisMonth
        let history = model.usageStore.history(months: 6)
        return ModalCard(width: 620, onDismiss: onDone) {
            HStack {
                Text("Spending").font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Button(action: onDone) { Image(systemName: "xmark") }.buttonStyle(.plain).foregroundStyle(Theme.icon)
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(month.formattedCost).font(.system(size: 34, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Text("\(month.questions) questions in \(Date().formatted(.dateTime.month(.wide)))")
                    .font(.system(size: 15)).foregroundStyle(Theme.textSecondary)
                Spacer()
                if model.settings.monthlyBudgetUSD > 0 {
                    SpendRing(fraction: model.budgetFraction, size: 26)
                    Text("of \(UsageMonth.format(model.settings.monthlyBudgetUSD + (model.settings.budgetTopUps[UsageMonth.key(for: Date())] ?? 0)))")
                        .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                }
            }
            HStack(alignment: .top, spacing: 12) {
                split("By model", month.byModel.map { (Self.modelName($0.key), $0.value) })
                split("By kind", month.byKind.map { (Self.kindName($0.key), $0.value) })
            }
            SectionLabel("Last 6 months")
            Chart(history, id: \.key) { item in
                BarMark(x: .value("Month", Self.monthLabel(item.key)), y: .value("USD", item.month.costUSD))
                    .foregroundStyle(Theme.accentGradient)
                    .cornerRadius(4)
            }
            .chartYAxis { AxisMarks { AxisValueLabel().foregroundStyle(Theme.textSecondary); AxisGridLine().foregroundStyle(Theme.hairline) } }
            .chartXAxis { AxisMarks { AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
            .frame(height: 120)
            creditCard
            Text("Estimated at list prices. Your Anthropic Console bill is the final word.")
                .font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
        }
        .onAppear { creditText.value = model.settings.creditUSD.map { String(format: "%.2f", $0) } ?? "" }
    }

    private func split(_ title: String, _ rows: [(String, Double)]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textSecondary)
            if rows.isEmpty {
                Text("No paid requests yet.").font(.system(size: 13)).foregroundStyle(Theme.textTertiary)
            }
            ForEach(rows.sorted { $0.1 > $1.1 }, id: \.0) { row in
                HStack {
                    Text(row.0).font(.system(size: 13)).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(UsageMonth.format(row.1)).font(.system(size: 13, design: .monospaced)).foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var creditCard: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 8) {
            Text("Credit").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textSecondary)
            HStack(spacing: 10) {
                Text("$").foregroundStyle(Theme.textSecondary)
                TextField("20.00", text: $creditText.value).darkField().frame(width: 100)
                    .onSubmit(saveCredit)
                Text("bought on").foregroundStyle(Theme.textSecondary).font(.system(size: 13))
                DatePicker("", selection: Binding(get: { model.settings.creditSince ?? Date() },
                                                  set: { model.settings.creditSince = $0 }), displayedComponents: .date)
                    .labelsHidden().frame(width: 120)
                Button("Save", action: saveCredit).buttonStyle(.pill(.secondary, compact: true))
            }
            if let credit = model.settings.creditUSD {
                let projection = CreditProjection(credit: credit, since: model.settings.creditSince ?? Date(),
                                                  daily: model.usageStore.dailySpend())
                Text(projectionText(projection)).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func saveCredit() {
        let value = Double(creditText.value.replacingOccurrences(of: ",", with: "."))
        model.settings.creditUSD = value.flatMap { $0 > 0 ? $0 : nil }
        if model.settings.creditSince == nil { model.settings.creditSince = Date() }
    }

    private func projectionText(_ p: CreditProjection) -> String {
        let left = "≈ \(UsageMonth.format(p.remaining)) left"
        guard let date = p.runsOutOn else { return left + " · No recent spending" }
        return left + " · At this pace, your credit lasts until about \(date.formatted(.dateTime.month(.abbreviated).day()))."
    }

    static func modelName(_ id: String) -> String {
        if id.contains("haiku") { return "Haiku" }
        if id.contains("sonnet") { return "Sonnet" }
        if id.contains("opus") { return "Opus" }
        return id
    }

    static func kindName(_ kind: String) -> String {
        switch kind {
        case "answer": "Answers"
        case "memory": "Memory"
        case "naming": "Naming Clickys"
        case "interview": "Welcome interview"
        default: kind.capitalized
        }
    }

    static func monthLabel(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2, let m = Int(parts[1]), (1...12).contains(m) else { return key }
        return Calendar.current.shortMonthSymbols[m - 1]
    }
}

/// Settings → General → SPENDING (spec 011 US2).
struct SpendingSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let enabled = Binding(get: { model.settings.monthlyBudgetUSD > 0 },
                              set: { model.settings.monthlyBudgetUSD = $0 ? max(1, Settings().monthlyBudgetUSD) : 0 })
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Spending").padding(.top, 10)
            SettingsCard {
                SettingsRow(title: "Monthly budget", subtitle: "Pause paid requests when this month reaches it.") {
                    HStack(spacing: 12) {
                        if enabled.wrappedValue {
                            Stepper(value: $model.settings.monthlyBudgetUSD, in: 1...100, step: 1) {
                                Text(String(format: "$%.0f", model.settings.monthlyBudgetUSD))
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced)).foregroundStyle(Theme.textPrimary)
                            }
                        }
                        Toggle("", isOn: enabled).toggleStyle(.glossy).labelsHidden()
                    }
                }
                CardDivider()
                Button { model.showingSpending = true } label: {
                    SettingsRow(title: "This month", subtitle: "\(model.thisMonth.formattedCost) · \(model.thisMonth.questions) questions") {
                        HStack(spacing: 8) {
                            SpendRing(fraction: model.budgetFraction, size: 20)
                            Image(systemName: "chevron.right").foregroundStyle(Theme.icon)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
