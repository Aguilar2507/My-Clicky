import SwiftUI
import MyClickyCore

/// Home sidebar (ref 02): window buttons (spec 015), Search + "+", pinned Talk, Clickys, Apps chip, profile footer.
struct SidebarView: View {
    @Environment(AppModel.self) private var model
    @StateObject private var query = Box("")
    @StateObject private var showingAbout = Box(false)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SidebarHeader().padding(.bottom, 16)
            HStack(spacing: 8) {
                SearchField(text: $query.value, placeholder: "Search")
                Button { model.select(model.createClicky()) } label: {
                    Image(systemName: "plus").font(.icon(17, .semibold)).foregroundStyle(Theme.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .hoverHighlight(radius: 12)
                }
                .buttonStyle(.pressable)
                .help("New agent")
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 16)

            ScrollView {
                LazyVStack(spacing: 2) {
                    let rows = results
                    if rows.isEmpty {
                        Text("No chats match “\(query.value)”").textStyle(.subheadline).foregroundStyle(Theme.textSecondary)
                            .padding(.top, 20)
                    }
                    ForEach(rows, id: \.chat.id) { row in
                        ChatRow(chat: row.chat, snippet: row.snippet, isSelected: model.selectedChatID == row.chat.id,
                                isWorking: model.workingChatIDs.contains(row.chat.id)) {
                            model.select(row.chat.id)
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
            .scrollIndicators(.never)
            .scrollEdgeFade(top: 10, bottom: 24) // no hard lines where the list meets the chrome (spec 014)

            AppsChip(integrations: model.integrations).padding(.horizontal, 12).padding(.vertical, 12)
            ProfileFooter(onAbout: { showingAbout.value = true })
        }
        .modalOverlay(showingAbout.value) {
            if showingAbout.value { AboutSheet { showingAbout.value = false } }
        }
    }

    private var results: [(chat: Chat, snippet: String?)] {
        let ordered = [model.talkChatIfExists].compactMap { $0 } + model.clickys // Talk pinned first
        let q = query.value.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return ordered.map { ($0, nil) } }
        return ordered.compactMap { chat in SearchIndex.search(q, in: chat).map { (chat, $0.snippet) } }
    }
}

/// Rounded dark search field with a magnifier (ref 02).
struct SearchField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.icon(15)).foregroundStyle(Theme.textSecondary)
            TextField(placeholder, text: $text).textFieldStyle(.plain).textStyle(.body).foregroundStyle(Theme.textPrimary)
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textTertiary) }
                    .buttonStyle(.pressable)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Footer (ref 02): initial, name, spend this month (+ ring from spec 011), ⓘ and ⚙.
struct ProfileFooter: View {
    @Environment(AppModel.self) private var model
    var onAbout: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            InitialAvatar(name: model.settings.profileName, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                // "$0.42 · Sep": this month's API spend (tap for the Spending sheet)
                Text(model.settings.profileName).textStyle(.headline).foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Button { model.showingSpending = true } label: {
                    HStack(spacing: 6) {
                        if model.settings.monthlyBudgetUSD > 0 { SpendRing(fraction: model.budgetFraction, size: 13) }
                        Text("\(model.thisMonth.formattedCost) · \(Date().formatted(.dateTime.month(.abbreviated)))")
                            .textStyle(.footnote).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    }
                }
                .buttonStyle(.pressable)
                .help("Spending")
            }
            Spacer(minLength: 4)
            Button(action: onAbout) { Image(systemName: "info.circle") }.help("About MyClicky")
            Button { model.openSettings() } label: { Image(systemName: "gearshape.fill") }.help("Settings")
        }
        .font(.icon(19))
        .foregroundStyle(Theme.icon)
        .buttonStyle(.pressable)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }
}

/// ⓘ: logo, version and What's new.
struct AboutSheet: View {
    let onDone: () -> Void
    @StateObject private var showingChangelog = Box(false)

    var body: some View {
        ModalCard(width: 380, onDismiss: onDone) {
            HStack(spacing: 14) {
                AppLogo().frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text("MyClicky").textStyle(.title2.weight(.bold)).foregroundStyle(Theme.textPrimary)
                    Text("Version \(AppInfo.versionString)").textStyle(.subheadline).foregroundStyle(Theme.textSecondary)
                }
            }
            Text("Your own screen-aware Mac assistant. Answers on your Anthropic API key, agents on your Claude plan.")
                .textStyle(.subheadline).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("What's new") { showingChangelog.value = true }.buttonStyle(.pill(.secondary, compact: true))
                Spacer()
                Button("Done", action: onDone).buttonStyle(.pill(.primary, compact: true))
            }
        }
        .modalOverlay(showingChangelog.value) { if showingChangelog.value { WhatsNewSheet { showingChangelog.value = false } } }
    }
}
