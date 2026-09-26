import SwiftUI
import MyClickyCore

/// Settings → Dictation (ref 06): auto-detect, English/Spanish cards (Spanish region menu), and custom words.
struct DictationPage: View {
    @Environment(AppModel.self) private var model
    @StateObject private var newWord = Box("")

    static let spanishRegions: [(String, String)] = [
        ("es-MX", "México"), ("es-ES", "España"), ("es-US", "EE. UU."), ("es-CO", "Colombia"), ("es-AR", "Argentina"),
        ("es-CL", "Chile"), ("es-PE", "Perú"),
    ]

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            PageHeader(title: "Dictation", subtitle: SettingsPage.dictation.subtitle)
            SectionLabel("Language")
            SettingsCard {
                SettingsRow(title: "Auto-detect language", subtitle: "MyClicky figures out the language as you speak.") {
                    Toggle("", isOn: $model.settings.dictationAutoDetect).toggleStyle(.glossy).labelsHidden()
                }
                CardDivider()
                HStack(spacing: 14) {
                    languageCard("English", native: "English", code: "en")
                    languageCard("Spanish", native: "Español", code: "es")
                }
                .padding(Theme.rowPadding)
                Text(model.settings.dictationAutoDetect
                     ? "Both languages are listened for. The checked one wins when it's a close call."
                     : "Everything is transcribed in the checked language.")
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 18).padding(.bottom, 14)
            }

            SectionLabel("Words").padding(.top, 10)
            SettingsCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Names and terms MyClicky should always spell your way.").font(Theme.rowSubtitle)
                        .foregroundStyle(Theme.textSecondary)
                    FlowChips(words: model.settings.customWords) { word in
                        model.settings.customWords.removeAll { $0 == word }
                    }
                    HStack {
                        TextField("Add a word, e.g. Anthropic", text: $newWord.value).darkField().onSubmit(add)
                        Button("Add", action: add).buttonStyle(.pill(.secondary))
                    }
                }
                .padding(Theme.rowPadding)
            }
        }
    }

    private func add() {
        model.settings.customWords = CustomWords.normalized(model.settings.customWords + [newWord.value])
        newWord.value = ""
    }

    private func languageCard(_ title: String, native: String, code: String) -> some View {
        let checked = model.settings.dictationLanguage == code
        let included = model.settings.dictationAutoDetect || checked
        return SelectableCard(isSelected: checked, dimmed: !included, action: { model.settings.dictationLanguage = code }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text(native).font(.system(size: 15)).foregroundStyle(Theme.textSecondary)
                if code == "es" {
                    Menu(Self.spanishRegions.first { $0.0 == model.settings.spanishLocale }?.1 ?? model.settings.spanishLocale) {
                        ForEach(Self.spanishRegions, id: \.0) { region in
                            Button(region.1) { model.settings.spanishLocale = region.0 }
                        }
                    }
                    .menuStyle(.button)
                    .buttonStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.lavender)
                    .fixedSize()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .frame(height: 96)
    }
}

/// Removable word chips that wrap onto new lines.
struct FlowChips: View {
    let words: [String]
    let onRemove: (String) -> Void

    var body: some View {
        if words.isEmpty {
            Text("No words yet.").font(.system(size: 14)).foregroundStyle(Theme.textTertiary)
        } else {
            WrapLayout(spacing: 8) {
                ForEach(words, id: \.self) { word in
                    HStack(spacing: 6) {
                        Text(word).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.textPrimary)
                        Button { onRemove(word) } label: { Image(systemName: "xmark").font(.system(size: 10, weight: .bold)) }
                            .buttonStyle(.plain).foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.keycap, in: Capsule(style: .continuous))
                }
            }
        }
    }
}

/// Minimal wrapping layout for chips.
struct WrapLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 600
        var x: CGFloat = 0, y: CGFloat = 0, row: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { x = 0; y += row + spacing; row = 0 }
            x += size.width + spacing
            row = max(row, size.height)
        }
        return CGSize(width: width, height: y + row)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, row: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += row + spacing; row = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            row = max(row, size.height)
        }
    }
}
