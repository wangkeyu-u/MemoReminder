import Foundation

struct Reminder: Identifiable, Codable, Equatable {
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
    var targetTime: Date
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
