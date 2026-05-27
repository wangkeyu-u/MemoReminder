import SwiftUI

/// Section renderer for grouped reminders.
///
/// Grouping is computed by `ReminderStore`/`ContentView`; this view focuses on
/// consistent layout, empty states, and forwarding row actions.
struct ReminderSection: View {
    let title: String
    let subtitle: String
    let reminders: [Reminder]
    let emptyTitle: String
    let select: (Reminder) -> Void
    let edit: (Reminder) -> Void
    let complete: (Reminder) -> Void
    let delete: (Reminder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.bold))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(reminders.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground), in: Capsule())
            }

            if reminders.isEmpty {
                EmptyReminderPanel(title: emptyTitle)
            } else {
                VStack(spacing: 10) {
                    ForEach(reminders) { reminder in
                        ReminderRow(
                            reminder: reminder,
                            select: {
                                select(reminder)
                            },
                            edit: {
                                edit(reminder)
                            },
                            complete: {
                                complete(reminder)
                            },
                            delete: {
                                delete(reminder)
                            }
                        )
                    }
                }
            }
        }
    }
}

private struct EmptyReminderPanel: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.title3)
                .foregroundStyle(.green)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
