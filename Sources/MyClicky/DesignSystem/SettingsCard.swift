import SwiftUI

/// Uppercase, letter-spaced section label ("BEHAVIOR").
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .textStyle(.label)
            .foregroundStyle(Theme.sectionLabel)
            .padding(.leading, 8)
            .padding(.bottom, 2)
    }
}

/// Rounded card that stacks rows; put `CardDivider()` between rows.
struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 1))
    }
}

struct CardDivider: View {
    var body: some View {
        Rectangle().fill(Theme.cardBorder).frame(height: 1).padding(.leading, 18)
    }
}

/// A title + optional subtitle on the left and any control on the right.
struct SettingsRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).textStyle(.headline).foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle).textStyle(.callout).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            trailing.fixedSize() // controls never wrap; the text column gives way instead
        }
        .padding(Theme.rowPadding)
    }
}

extension SettingsRow where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// Page header used by every settings page: big title + gray subtitle.
struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).textStyle(.largeTitle).foregroundStyle(Theme.textPrimary)
            Text(subtitle).textStyle(.body).foregroundStyle(Theme.textSecondary)
        }
        .padding(.bottom, 12)
    }
}
