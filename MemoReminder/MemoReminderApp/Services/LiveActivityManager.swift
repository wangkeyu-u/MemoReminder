import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

/// Optional ActivityKit bridge used by the app target.
///
/// Local notifications remain the reliable reminder channel. Live Activities
/// are treated as a richer glanceable surface when the device and user settings
/// allow it, so all ActivityKit calls are guarded by availability checks.
enum LiveActivityManager {
    /// Starts a Live Activity for the reminder. The Widget Extension renders
    /// this state on the Lock Screen and Dynamic Island.
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

    /// Ends any activity that was created for the matching reminder UUID.
    static func endActivity(for reminderID: UUID) async {
        #if canImport(ActivityKit)
        for activity in Activity<ReminderActivityAttributes>.activities
            where activity.attributes.reminderID == reminderID.uuidString {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        #endif
    }
}
