import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// Shared ActivityKit contract used by both the app target and widget target.
///
/// Keep this type small: every field here must be serializable and available to
/// the extension process, so it should contain only what the Dynamic Island and
/// Lock Screen UI need to render.
struct ReminderActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var content: String
        var targetTime: Date
        var notifyTime: Date
    }

    var reminderID: String
}
#endif
