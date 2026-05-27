import SwiftUI
import UIKit

/// Main composition view for the app.
///
/// `ContentView` intentionally coordinates user actions across `ReminderStore`
/// and `NotificationScheduler`: the store changes app data, while the scheduler
/// mirrors those changes into iOS notification/Live Activity state.
struct ContentView: View {
    @EnvironmentObject private var store: ReminderStore
    @EnvironmentObject private var notificationScheduler: NotificationScheduler

    @State private var content = ""
    @State private var targetTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var leadTimeMinutes = 30
    @State private var errorMessage: String?
    @State private var toastMessage: String?
    @State private var searchText = ""
    @State private var editingReminder: Reminder?

    private let leadTimeOptions = [5, 15, 30, 60]

    // MARK: - Filtered Sections

    private var filteredTodayReminders: [Reminder] {
        filter(store.todayReminders)
    }

    private var filteredUpcomingReminders: [Reminder] {
        filter(store.upcomingReminders)
    }

    private var filteredCompletedReminders: [Reminder] {
        Array(filter(store.completedReminders).prefix(5))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.98, blue: 0.98),
                        Color(red: 0.99, green: 0.97, blue: 0.93),
                        Color(red: 0.96, green: 0.96, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        DashboardHeader(
                            activeCount: store.activeReminders.count,
                            todayCount: store.todayReminders.count,
                            overdueCount: store.overdueCount
                        )

                        PermissionBanner(
                            authorizationStatus: notificationScheduler.authorizationStatus,
                            requestPermission: {
                                Task {
                                    await notificationScheduler.requestAuthorizationIfNeeded()
                                }
                            },
                            openSettings: openSettings
                        )

                        ReminderComposerCard(
                            content: $content,
                            targetTime: $targetTime,
                            leadTimeMinutes: $leadTimeMinutes,
                            leadTimeOptions: leadTimeOptions,
                            errorMessage: errorMessage,
                            save: saveReminder
                        )

                        SearchField(text: $searchText)

                        ReminderSection(
                            title: "今天",
                            subtitle: "当天要处理的事",
                            reminders: filteredTodayReminders,
                            emptyTitle: "今天没有提醒",
                            select: store.select,
                            edit: startEditing,
                            complete: complete,
                            delete: delete
                        )

                        ReminderSection(
                            title: "之后",
                            subtitle: "未来安排",
                            reminders: filteredUpcomingReminders,
                            emptyTitle: "后续提醒会在这里排队",
                            select: store.select,
                            edit: startEditing,
                            complete: complete,
                            delete: delete
                        )

                        if searchText.isEmpty == false || filteredCompletedReminders.isEmpty == false {
                            ReminderSection(
                                title: "最近完成",
                                subtitle: "已处理的提醒",
                                reminders: filteredCompletedReminders,
                                emptyTitle: "还没有完成记录",
                                select: store.select,
                                edit: startEditing,
                                complete: complete,
                                delete: delete
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 36)
                }

                if let toastMessage {
                    Text(toastMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("备忘提醒")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: selectedReminderBinding) { reminder in
                ReminderDetailView(
                    reminder: reminder,
                    onSnooze: {
                        snooze(reminder)
                    },
                    onComplete: {
                        complete(reminder)
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingReminder) { reminder in
                ReminderEditorView(
                    reminder: reminder,
                    leadTimeOptions: leadTimeOptions,
                    save: editReminder
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Bindings

    /// Converts the store's selected reminder ID into a sheet-friendly binding.
    /// This lets deep links and row taps share the same detail presentation path.
    private var selectedReminderBinding: Binding<Reminder?> {
        Binding(
            get: { store.selectedReminder },
            set: { value in
                if value == nil {
                    store.clearSelection()
                }
            }
        )
    }

    // MARK: - User Actions

    private func saveReminder() {
        errorMessage = nil

        do {
            let reminder = try store.add(
                content: content,
                targetTime: targetTime,
                leadTimeMinutes: leadTimeMinutes
            )

            Task {
                do {
                    // Persist first, then schedule with the saved model so the
                    // notification identifier matches the stored UUID.
                    try await notificationScheduler.schedule(reminder: reminder)
                    content = ""
                    targetTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                    leadTimeMinutes = 30
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showToast("提醒已保存")
                } catch {
                    errorMessage = "通知创建失败，请检查通知权限"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startEditing(_ reminder: Reminder) {
        // The edit sheet and detail sheet are separate presentations; clearing
        // the selection prevents both from competing for presentation.
        store.clearSelection()
        editingReminder = reminder
    }

    private func editReminder(_ reminder: Reminder, content: String, targetTime: Date, leadTimeMinutes: Int) throws {
        let editedReminder = try store.edit(
            reminder,
            content: content,
            targetTime: targetTime,
            leadTimeMinutes: leadTimeMinutes
        )

        Task {
            // Cancel the old request before scheduling the edited reminder to
            // prevent duplicate notifications after a time/content change.
            await notificationScheduler.cancel(reminder: reminder)
            try? await notificationScheduler.schedule(reminder: editedReminder)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showToast("提醒已更新")
        }
    }

    private func delete(_ reminder: Reminder) {
        Task {
            // System notification state is external to the app's local array, so
            // it must be explicitly cancelled before removing the model.
            await notificationScheduler.cancel(reminder: reminder)
            store.delete(reminder)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            showToast("提醒已删除")
        }
    }

    private func complete(_ reminder: Reminder) {
        Task {
            await notificationScheduler.cancel(reminder: reminder)
            store.markCompleted(reminder)
            store.clearSelection()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showToast("已标记完成")
        }
    }

    private func snooze(_ reminder: Reminder) {
        Task {
            await notificationScheduler.cancel(reminder: reminder)

            guard let updatedReminder = store.snooze(reminder, minutes: 10) else {
                return
            }

            try? await notificationScheduler.schedule(reminder: updatedReminder)
            store.clearSelection()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showToast("10 分钟后再次提醒")
        }
    }

    private func filter(_ reminders: [Reminder]) -> [Reminder] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard query.isEmpty == false else {
            return reminders
        }

        return reminders.filter { reminder in
            reminder.content.localizedCaseInsensitiveContains(query)
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            toastMessage = message
        }

        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeOut(duration: 0.2)) {
                toastMessage = nil
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url)
    }
}

#Preview {
    ContentView()
        .environmentObject(ReminderStore())
        .environmentObject(NotificationScheduler())
}
