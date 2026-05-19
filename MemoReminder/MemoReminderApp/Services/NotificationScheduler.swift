import Foundation
import UserNotifications

enum ReminderNotificationAction {
    static let complete = "REMINDER_COMPLETE"
    static let snooze = "REMINDER_SNOOZE"
    static let category = "REMINDER_ACTIONS"
}

@MainActor
final class NotificationScheduler: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private weak var store: ReminderStore?

    func configure(store: ReminderStore) {
        self.store = store
        UNUserNotificationCenter.current().delegate = self
        configureNotificationActions()
    }

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus

        guard settings.authorizationStatus == .notDetermined else {
            return
        }

        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            authorizationStatus = await center.notificationSettings().authorizationStatus
        } catch {
            authorizationStatus = .denied
        }
    }

    func schedule(reminder: Reminder) async throws {
        let content = UNMutableNotificationContent()
        content.title = "备忘提醒"
        content.body = reminder.content
        content.sound = .default
        content.categoryIdentifier = ReminderNotificationAction.category
        content.userInfo = ["reminderID": reminder.id.uuidString]

        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminder.notifyTime
        )
        dateComponents.calendar = Calendar.current

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: reminder.id),
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier(for: reminder.id)]
        )
        try await UNUserNotificationCenter.current().add(request)
        await LiveActivityManager.startActivity(for: reminder)
    }

    func cancel(reminder: Reminder) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier(for: reminder.id)]
        )
        await LiveActivityManager.endActivity(for: reminder.id)
    }

    private func notificationIdentifier(for id: UUID) -> String {
        "reminder-\(id.uuidString)"
    }

    private func configureNotificationActions() {
        let completeAction = UNNotificationAction(
            identifier: ReminderNotificationAction.complete,
            title: "完成",
            options: []
        )
        let snoozeAction = UNNotificationAction(
            identifier: ReminderNotificationAction.snooze,
            title: "稍后 10 分钟",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: ReminderNotificationAction.category,
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

extension NotificationScheduler: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let reminderID = response.notification.request.content.userInfo["reminderID"] as? String else {
            return
        }

        await MainActor.run {
            if let id = UUID(uuidString: reminderID) {
                switch response.actionIdentifier {
                case ReminderNotificationAction.complete:
                    if let reminder = store?.reminder(id: id) {
                        store?.markCompleted(reminder)
                        Task {
                            await LiveActivityManager.endActivity(for: reminder.id)
                        }
                    }
                case ReminderNotificationAction.snooze:
                    if let reminder = store?.reminder(id: id),
                       let updatedReminder = store?.snooze(reminder, minutes: 10) {
                        Task {
                            await LiveActivityManager.endActivity(for: reminder.id)
                            try? await self.schedule(reminder: updatedReminder)
                        }
                    }
                default:
                    store?.selectedReminderID = id
                    store?.markNotified(id: id)
                }
            }
        }
    }
}
