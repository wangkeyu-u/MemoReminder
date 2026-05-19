import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

enum LiveActivityManager {
    static func startActivity(for reminder: Reminder) async {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = ReminderActivityAttributes(reminderID: reminder.id.uuidString)
        let state = ReminderActivityAttributes.ContentState(
            content: reminder.content,
            targetTime: reminder.targetTime,
            notifyTime: reminder.notifyTime
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: reminder.targetTime),
                pushType: nil
            )
        } catch {
            assertionFailure("Failed to start Live Activity: \(error)")
        }
        #endif
    }

    static func endActivity(for reminderID: UUID) async {
        #if canImport(ActivityKit)
        for activity in Activity<ReminderActivityAttributes>.activities
            where activity.attributes.reminderID == reminderID.uuidString {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        #endif
    }
}

