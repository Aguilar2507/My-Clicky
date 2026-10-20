import SwiftUI
import MyClickyCore

/// Settings profile card (refs 03–10): initial, name, and this month's API spend where HeyClicky shows "FREE".
struct ProfileCard: View {
    @Environment(AppModel.self) private var model
    var onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                InitialAvatar(name: model.settings.profileName, size: 34)
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.settings.profileName).textStyle(.headline)
                        .foregroundStyle(Theme.textPrimary).lineLimit(1)
                    Text(spendBadge)
                        .textStyle(.label.weight(.bold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Theme.track, in: Capsule(style: .continuous))
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .hoverHighlight(radius: 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .help("Edit your name")
    }

    private var spendBadge: String {
        let month = Date().formatted(.dateTime.month(.abbreviated)).uppercased()
        return "\(model.thisMonth.formattedCost) · \(month)"
    }
}

struct InitialAvatar: View {
    let name: String
    var size: CGFloat = 40
    var body: some View {
        Text(String(name.first ?? "?").uppercased())
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .frame(width: size, height: size)
            .background(Theme.track, in: Circle())
    }
}

/// Edit the name used in greetings.
struct ProfileEditor: View {
    @Environment(AppModel.self) private var model
    @StateObject private var name = Box("")
    let onDone: () -> Void

    var body: some View {
        ModalCard(width: 420, onDismiss: onDone) {
            Text("Your name").textStyle(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
            Text("MyClicky uses it to greet you.").textStyle(.callout).foregroundStyle(Theme.textSecondary)
            TextField("Name", text: $name.value).darkField().onSubmit(save)
            HStack {
                Spacer()
                Button("Cancel", action: onDone).buttonStyle(.pill(.dark))
                Button("Save", action: save).buttonStyle(.pill(.primary))
            }
        }
        .onAppear { name.value = model.settings.profileName }
    }

    private func save() {
        let trimmed = name.value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { model.settings.profileName = trimmed }
        onDone()
    }
}
