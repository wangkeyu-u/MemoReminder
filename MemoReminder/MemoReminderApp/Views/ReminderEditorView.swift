import SwiftUI

struct ReminderEditorView: View {
    let reminder: Reminder
    let leadTimeOptions: [Int]
    let save: (Reminder, String, Date, Int) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var content: String
    @State private var targetTime: Date
    @State private var leadTimeMinutes: Int
    @State private var errorMessage: String?

    init(
        reminder: Reminder,
        leadTimeOptions: [Int],
        save: @escaping (Reminder, String, Date, Int) throws -> Void
    ) {
        self.reminder = reminder
        self.leadTimeOptions = leadTimeOptions
        self.save = save
        _content = State(initialValue: reminder.content)
        _targetTime = State(initialValue: max(reminder.targetTime, Date().addingTimeInterval(60)))
        _leadTimeMinutes = State(initialValue: reminder.leadTimeMinutes == 0 ? 5 : reminder.leadTimeMinutes)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                TextField("提醒内容", text: $content, axis: .vertical)
                    .font(.body)
                    .lineLimit(4, reservesSpace: true)
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                DatePicker("目标时间", selection: $targetTime, in: Date()...)

                VStack(alignment: .leading, spacing: 10) {
                    Text("提前多久提醒")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(leadTimeOptions, id: \.self) { minutes in
                            Button {
                                leadTimeMinutes = minutes
                            } label: {
                                Text(minutes == 60 ? "1 小时" : "\(minutes) 分钟")
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundStyle(leadTimeMinutes == minutes ? .white : .primary)
                                    .background(
                                        leadTimeMinutes == minutes ? Color.teal : Color(.secondarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("编辑提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        do {
                            try save(reminder, content, targetTime, leadTimeMinutes)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ReminderEditorView(
        reminder: Reminder(
            content: "明天买一个笔记本电脑",
            targetTime: Date().addingTimeInterval(3600),
            notifyTime: Date().addingTimeInterval(1800)
        ),
        leadTimeOptions: [5, 15, 30, 60],
        save: { _, _, _, _ in }
    )
}

