import Foundation

/// Main-actor state container for all reminders.
///
/// The store owns local persistence and validation, while system side effects
/// such as scheduling/cancelling notifications are handled by
/// `NotificationScheduler`. This keeps data mutations predictable and makes it
/// easier to keep `UserDefaults` and pending notifications in sync.
@MainActor
final class ReminderStore: ObservableObject {
    @Published private(set) var reminders: [Reminder] = []
    @Published var selectedReminderID: UUID?

    private let storageKey = "memoReminder.reminders.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Read Models

    var activeReminders: [Reminder] {
        reminders
            .filter { $0.status == .pending || $0.status == .notified }
            .sorted { $0.targetTime < $1.targetTime }
    }

    var completedReminders: [Reminder] {
        reminders
            .filter { $0.status == .completed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var todayReminders: [Reminder] {
        activeReminders.filter { Calendar.current.isDateInToday($0.targetTime) }
    }

    var upcomingReminders: [Reminder] {
        activeReminders.filter { Calendar.current.isDateInToday($0.targetTime) == false }
    }

    var overdueCount: Int {
        activeReminders.filter(\.isOverdue).count
    }

    var selectedReminder: Reminder? {
        guard let selectedReminderID else {
            return nil
        }

        return reminders.first { $0.id == selectedReminderID }
    }

    // MARK: - Persistence

    func load() async {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            reminders = []
            return
        }

        do {
            reminders = try decoder.decode([Reminder].self, from: data)
        } catch {
            reminders = []
        }
    }

    // MARK: - Mutations

    /// Creates a reminder and returns the exact saved model so the caller can
    /// schedule a local notification using the same UUID.
    func add(content: String, targetTime: Date, leadTimeMinutes: Int) throws -> Reminder {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedContent.isEmpty == false else {
            throw ReminderValidationError.emptyContent
        }

        guard targetTime > Date() else {
            throw ReminderValidationError.invalidTime
        }

        let notifyTime = Self.notificationTime(for: targetTime, leadTimeMinutes: leadTimeMinutes)
        let reminder = Reminder(
            content: trimmedContent,
            targetTime: targetTime,
            notifyTime: notifyTime,
            leadTimeMinutes: leadTimeMinutes
        )
        reminders.insert(reminder, at: 0)
        save()
        return reminder
    }

    func markCompleted(_ reminder: Reminder) {
        update(reminder.id) { item in
            item.status = .completed
        }
    }

    func edit(_ reminder: Reminder, content: String, targetTime: Date, leadTimeMinutes: Int) throws -> Reminder {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedContent.isEmpty == false else {
            throw ReminderValidationError.emptyContent
        }

        guard targetTime > Date() else {
            throw ReminderValidationError.invalidTime
        }

        var editedReminder = reminder
        editedReminder.content = trimmedContent
        editedReminder.targetTime = targetTime
        editedReminder.notifyTime = Self.notificationTime(for: targetTime, leadTimeMinutes: leadTimeMinutes)
        editedReminder.leadTimeMinutes = leadTimeMinutes
        editedReminder.status = .pending
        editedReminder.updatedAt = Date()

        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else {
            return editedReminder
        }

        reminders[index] = editedReminder
        save()
        return editedReminder
    }

    /// Snoozing intentionally changes both the target time and notification
    /// time. The notification is scheduled a few seconds from now so the user
    /// gets a predictable follow-up after choosing "稍后 10 分钟".
    func snooze(_ reminder: Reminder, minutes: Int = 10) -> Reminder? {
        let newTargetTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        var updatedReminder: Reminder?

        update(reminder.id) { item in
            item.targetTime = newTargetTime
            item.notifyTime = Date().addingTimeInterval(3)
            item.leadTimeMinutes = 0
            item.status = .pending
            updatedReminder = item
        }

        return updatedReminder
    }

    func markNotified(id: UUID) {
        update(id) { item in
            if item.status == .pending {
                item.status = .notified
            }
        }
    }

    func reminder(id: UUID) -> Reminder? {
        reminders.first { $0.id == id }
    }

    func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        if selectedReminderID == reminder.id {
            selectedReminderID = nil
        }
        save()
    }

    func select(_ reminder: Reminder) {
        selectedReminderID = reminder.id
    }

    func clearSelection() {
        selectedReminderID = nil
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "memoreminder",
              url.host == "reminder",
              let id = UUID(uuidString: url.lastPathComponent) else {
            return
        }

        selectedReminderID = id
        markNotified(id: id)
    }

    /// Centralized update path so every mutation refreshes `updatedAt` and is
    /// immediately persisted.
    private func update(_ id: UUID, mutate: (inout Reminder) -> Void) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else {
            return
        }

        mutate(&reminders[index])
        reminders[index].updatedAt = Date()
        save()
    }

    /// Calculates the notification fire date from the user's target time. If
    /// the lead time would put the notification in the past, it is clamped to a
    /// near-future value so `UNUserNotificationCenter` can still schedule it.
    private static func notificationTime(for targetTime: Date, leadTimeMinutes: Int) -> Date {
        let preferredTime = targetTime.addingTimeInterval(TimeInterval(-leadTimeMinutes * 60))
        return max(preferredTime, Date().addingTimeInterval(3))
    }

    private func save() {
        do {
            let data = try encoder.encode(reminders)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to save reminders: \(error)")
        }
    }
}

enum ReminderValidationError: LocalizedError {
    case emptyContent
    case invalidTime

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "请输入提醒内容"
        case .invalidTime:
            return "请选择未来的提醒时间"
        }
    }
}
