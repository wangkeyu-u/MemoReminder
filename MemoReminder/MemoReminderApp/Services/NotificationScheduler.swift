import Foundation
import UserNotifications

/// String constants shared by scheduled notifications and notification actions.
enum ReminderNotificationAction {
    static let complete = "REMINDER_COMPLETE"
    static let snooze = "REMINDER_SNOOZE"
    static let category = "REMINDER_ACTIONS"
}

/// Thin adapter around `UNUserNotificationCenter`.
///
/// App state stays in `ReminderStore`; this type only translates reminders into
/// system notification requests and feeds notification actions back into the
/// store. The reminder UUID is reused as the notification identifier suffix so
/// editing or deleting a reminder can target the correct pending request.
@MainActor
final class NotificationScheduler: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private weak var store: ReminderStore?

    /// Called once during app startup after the store is created. Setting the
    /// delegate here lets the app react to taps and notification action buttons.
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

    /// Replaces any existing pending request for this reminder before adding a
    /// new one. This is important after edits because iOS does not deduplicate
    /// semantically equivalent notification requests for us.
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

    /// Cancels both the pending notification and the optional Live Activity
    /// representation for the same reminder.
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
    /// Keep notifications visible even while the app is foregrounded; otherwise
    /// a foreground reminder would be easy to miss during testing and real use.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    /// Notification delegate callbacks are not isolated to the main actor, but
    /// store mutations are. `MainActor.run` is the boundary that keeps SwiftUI
    /// state updates safe.
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
