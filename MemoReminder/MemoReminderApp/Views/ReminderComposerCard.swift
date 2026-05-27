import SwiftUI

/// Presentational form for creating a reminder.
///
/// The card owns only temporary input bindings. Validation, persistence, and
/// notification scheduling stay in the parent coordinator view.
struct ReminderComposerCard: View {
    @Binding var content: String
    @Binding var targetTime: Date
    @Binding var leadTimeMinutes: Int

    let leadTimeOptions: [Int]
    let errorMessage: String?
    let save: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("新建提醒", systemImage: "square.and.pencil")
                    .font(.headline)

                Spacer()

                Text("提前提醒")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            TextField("例如：明天买一个笔记本电脑", text: $content, axis: .vertical)
                .font(.body)
                .lineLimit(3, reservesSpace: true)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            DatePicker("目标时间", selection: $targetTime, in: Date()...)
                .font(.subheadline.weight(.medium))

            VStack(alignment: .leading, spacing: 10) {
                Text("提前多久提醒")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(leadTimeOptions, id: \.self) { minutes in
                        LeadTimeButton(
                            minutes: minutes,
                            isSelected: leadTimeMinutes == minutes
                        ) {
                            leadTimeMinutes = minutes
                        }
                    }
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button(action: save) {
                Label("保存提醒", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.teal)
            .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(18)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 20, y: 10)
    }
}

/// Compact segmented-control style button for lead-time presets.
private struct LeadTimeButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    isSelected ? Color.teal : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    private var title: String {
        minutes == 60 ? "1 小时" : "\(minutes) 分钟"
    }
}
