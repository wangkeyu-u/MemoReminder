import SwiftUI

struct ReminderDetailView: View {
    let reminder: Reminder
    let onSnooze: () -> Void
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.14))
                    .frame(width: 76, height: 76)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.teal)
            }

            VStack(spacing: 10) {
                Text("提醒你")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(reminder.content)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 7) {
                    Label(reminder.targetTime.formatted(date: .complete, time: .shortened), systemImage: "clock")
                    Label(reminder.leadTimeTitle, systemImage: "timer")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    onSnooze()
                    dismiss()
                } label: {
                    Label("稍后", systemImage: "gobackward.10")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    onComplete()
                    dismiss()
                } label: {
                    Label("完成", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.teal)
            }

            Button("关闭") {
                dismiss()
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(28)
    }
}

#Preview {
    ReminderDetailView(
        reminder: Reminder(
            content: "明天买一个笔记本电脑",
            targetTime: Date().addingTimeInterval(3600),
            notifyTime: Date().addingTimeInterval(1800)
        ),
        onSnooze: {},
        onComplete: {}
    )
}

