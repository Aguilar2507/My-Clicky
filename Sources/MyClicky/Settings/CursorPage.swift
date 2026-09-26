import SwiftUI
import MyClickyCore

/// Settings → Cursor (ref 08): four colors and "Dock cursor".
struct CursorPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            PageHeader(title: "Cursor", subtitle: SettingsPage.cursor.subtitle)
            SectionLabel("Color")
            HStack(spacing: 14) {
                ForEach(CursorColor.allCases, id: \.self) { color in
                    SelectableCard(isSelected: model.settings.cursorColor == color,
                                   action: { model.settings.cursorColor = color }) {
                        CompanionTriangle(color: Color(hex: color.hex))
                            .frame(width: 30, height: 30)
                            .shadow(color: Color(hex: color.hex).opacity(0.55), radius: 14)
                    }
                    .frame(width: 118, height: 118)
                    .accessibilityLabel(color.rawValue.capitalized)
                }
            }
            SectionLabel("Visibility").padding(.top, 10)
            SettingsCard {
                SettingsRow(title: "Dock cursor", subtitle: "Docking hides the cursor and stops it from following you.") {
                    Toggle("", isOn: $model.settings.cursorDocked).toggleStyle(.glossy).labelsHidden()
                }
            }
        }
    }
}
