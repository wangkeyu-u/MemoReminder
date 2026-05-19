import SwiftUI
import UserNotifications

struct PermissionBanner: View {
    let authorizationStatus: UNAuthorizationStatus
    let requestPermission: () -> Void
    let openSettings: () -> Void

    var body: some View {
        switch authorizationStatus {
        case .denied:
            banner(
                title: "通知权限已关闭",
                message: "开启后才能准时震动并弹出提醒。",
                icon: "bell.slash.fill",
                tint: .red,
                actionTitle: "去设置",
                action: openSettings
            )
        case .notDetermined:
            banner(
                title: "开启通知提醒",
                message: "保存提醒前先允许通知，App 才能在时间到达前提醒你。",
                icon: "bell.badge.fill",
                tint: .teal,
                actionTitle: "允许通知",
                action: requestPermission
            )
        default:
            EmptyView()
        }
    }

    private func banner(
        title: String,
        message: String,
        icon: String,
        tint: Color,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(actionTitle, action: action)
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
        }
        .padding(14)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

