import SwiftUI
import WidgetKit

#if canImport(ActivityKit)
import ActivityKit

struct ReminderLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReminderActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Label("备忘提醒", systemImage: "bell.fill")
                    .font(.headline)

                Text(context.state.content)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)

                Text(context.state.targetTime, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .activityBackgroundTint(.cyan.opacity(0.18))
            .activitySystemActionForegroundColor(.cyan)
            .widgetURL(URL(string: "memoreminder://reminder/\(context.attributes.reminderID)"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.cyan)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.content)
                        .font(.headline)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.targetTime, style: .time)
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                Text(context.state.targetTime, style: .time)
                    .font(.caption2)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.cyan)
            }
            .widgetURL(URL(string: "memoreminder://reminder/\(context.attributes.reminderID)"))
        }
    }
}

@main
struct MemoReminderWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReminderLiveActivityWidget()
    }
}
#endif

