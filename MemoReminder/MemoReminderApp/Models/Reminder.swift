import Foundation

/// Domain model for one memo reminder.
///
/// The `id` is intentionally used as the stable bridge between app state,
/// pending local notifications, deep links, and Live Activities. Keeping that
/// identifier stable is what lets edit/delete/complete operations update the
/// matching system objects instead of creating duplicates.
struct Reminder: Identifiable, Codable, Equatable {
    /// User-visible lifecycle state. Notification delivery changes a reminder
    /// to `notified`, while explicit user actions move it to a terminal state.
    enum Status: String, Codable, CaseIterable {
        case pending
        case notified
        case completed
        case cancelled

        var title: String {
            switch self {
            case .pending:
                return "未提醒"
            case .notified:
                return "已提醒"
            case .completed:
                return "已完成"
            case .cancelled:
                return "已取消"
            }
        }
    }

    let id: UUID
    var content: String
    /// The actual time the user cares about, for example "buy a laptop at 7 PM".
    var targetTime: Date
    /// The time the system notification should fire. This can be earlier than
    /// `targetTime` when the user selects a lead time.
    var notifyTime: Date
    var leadTimeMinutes: Int
    var status: Status
    let createdAt: Date
    var updatedAt: Date

    var isOverdue: Bool {
        status != .completed && targetTime < Date()
    }

    var leadTimeTitle: String {
        switch leadTimeMinutes {
        case 5:
            return "提前 5 分钟"
        case 15:
            return "提前 15 分钟"
        case 30:
            return "提前 30 分钟"
        case 60:
            return "提前 1 小时"
        default:
            return "提前 \(leadTimeMinutes) 分钟"
        }
    }

    init(
        id: UUID = UUID(),
        content: String,
        targetTime: Date,
        notifyTime: Date,
        leadTimeMinutes: Int = 30,
        status: Status = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.targetTime = targetTime
        self.notifyTime = notifyTime
        self.leadTimeMinutes = leadTimeMinutes
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case targetTime
        case notifyTime
        case leadTimeMinutes
        case status
        case createdAt
        case updatedAt
    }

    /// Custom decoding keeps older locally saved reminders readable if new
    /// fields are added later. `leadTimeMinutes` defaults to 30 for data saved
    /// by earlier app versions.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        targetTime = try container.decode(Date.self, forKey: .targetTime)
        notifyTime = try container.decode(Date.self, forKey: .notifyTime)
        leadTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .leadTimeMinutes) ?? 30
        status = try container.decode(Status.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
