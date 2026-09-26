import SwiftUI
import MyClickyCore

/// Home sidebar (ref 02): logo, Search + "+", pinned Talk, Clickys, Apps chip, profile footer.
struct SidebarView: View {
    @Environment(AppModel.self) private var model
    @StateObject private var query = Box("")
    @StateObject private var showingAbout = Box(false)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MyClickyLogo().frame(width: 30, height: 30).padding(.leading, 20).padding(.top, 26).padding(.bottom, 26)
            HStack(spacing: 8) {
                SearchField(text: $query.value, placeholder: "Search")
                Button { model.select(model.createClicky()) } label: {
                    Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("New Clicky")
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 16)

            ScrollView {
                LazyVStack(spacing: 2) {
                    let rows = results
                    if rows.isEmpty {
                        Text("No chats match “\(query.value)”").font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
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

            AppsChip(integrations: model.integrations).padding(.horizontal, 12).padding(.vertical, 12)
            Rectangle().fill(Color(hex: 0x333333)).frame(height: 1).padding(.horizontal, 12)
            ProfileFooter(onAbout: { showingAbout.value = true })
        }
        .overlay {
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
            Image(systemName: "magnifyingglass").font(.system(size: 15)).foregroundStyle(Theme.textSecondary)
            TextField(placeholder, text: $text).textFieldStyle(.plain).font(.system(size: 16)).foregroundStyle(Theme.textPrimary)
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textTertiary) }
                    .buttonStyle(.plain)
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

    /// Spend ring (spec 011) — nil until that feature exists.
    static var spendRing: ((AppModel) -> AnyView)?

    var body: some View {
        HStack(spacing: 10) {
            InitialAvatar(name: model.settings.profileName, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.settings.profileName).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(model.thisMonth.formattedCost) this month").font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                    if let ring = Self.spendRing { ring(model) }
                }
            }
            Spacer(minLength: 4)
            Button(action: onAbout) { Image(systemName: "info.circle") }.help("About MyClicky")
            Button { model.openSettings() } label: { Image(systemName: "gearshape.fill") }.help("Settings")
        }
        .font(.system(size: 19))
        .foregroundStyle(Theme.icon)
        .buttonStyle(.plain)
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
                MyClickyLogo().frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("MyClicky").font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.textPrimary)
                    Text("Version \(AppInfo.versionString)").font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                }
            }
            Text("Your own screen-aware Mac assistant. Answers on your Anthropic API key, agents on your Claude plan.")
                .font(.system(size: 14)).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("What's new") { showingChangelog.value = true }.buttonStyle(.pill(.secondary, compact: true))
                Spacer()
                Button("Done", action: onDone).buttonStyle(.pill(.primary, compact: true))
            }
        }
        .overlay { if showingChangelog.value { WhatsNewSheet { showingChangelog.value = false } } }
    }
}
