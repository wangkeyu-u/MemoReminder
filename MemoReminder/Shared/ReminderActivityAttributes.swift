import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct ReminderActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var content: String
        var targetTime: Date
        var notifyTime: Date
    }

    var reminderID: String
}
#endif

