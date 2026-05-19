import SwiftUI

struct ReminderRow: View {
    let reminder: Reminder
    let select: () -> Void
    let edit: () -> Void
    let complete: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 10) {
                Text(reminder.content)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(reminder.targetTime.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    Text(reminder.leadTimeTitle)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if reminder.isOverdue {
                    Label("已过目标时间", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }

            VStack(spacing: 8) {
                Button(action: edit) {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.bold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(.teal)

                Button(action: complete) {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(.green)

                Button(role: .destructive, action: delete) {
                    Image(systemName: "trash")
                        .font(.caption.weight(.bold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
            }
        }
        .padding(14)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(reminder.isOverdue ? Color.red : Color.teal)
                .frame(width: 4)
                .clipShape(.rect(cornerRadius: 2))
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
    }

    private var statusIcon: some View {
        Image(systemName: reminder.isOverdue ? "exclamationmark" : "bell.fill")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(reminder.isOverdue ? .red : .teal)
            .frame(width: 34, height: 34)
            .background(
                (reminder.isOverdue ? Color.red : Color.teal).opacity(0.12),
                in: Circle()
            )
    }
}

#Preview {
    ReminderRow(
        reminder: Reminder(
            content: "明天买一个笔记本电脑",
            targetTime: Date().addingTimeInterval(3600),
            notifyTime: Date().addingTimeInterval(1800)
        ),
        select: {},
        edit: {},
        complete: {},
        delete: {}
    )
    .padding()
}
