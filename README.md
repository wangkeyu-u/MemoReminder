# MemoReminder

用 SwiftUI 编写的本地 iOS 提醒应用。支持创建、编辑、搜索、完成提醒，以及通知中的“完成”和“稍后 10 分钟”操作。

## 运行

需要 Xcode 16+，最低系统为 iOS 17。从仓库根目录打开：

```bash
open MemoReminder/MemoReminder.xcodeproj
```

选择 iPhone 模拟器或真机，按 `⌘R`。真机运行需要在 App 和 Widget Extension target 中选择自己的开发者 Team。通知、锁屏活动和灵动岛行为需要在目标设备上验证。

## 目录

```text
MemoReminder/
  MemoReminder.xcodeproj/       # App 与 Widget Extension targets
  MemoReminderApp/              # SwiftUI views、领域模型和服务
  MemoReminderWidgets/          # ActivityKit / WidgetKit 展示
  Shared/                      # 跨 target 的活动模型
  Scripts/                     # 工程生成和资源工具
```

## 状态与通知

`Reminder` 的稳定 UUID 连接本地数据、通知请求和 deep link。`ReminderStore` 集中管理校验、增删改查和 UserDefaults 持久化；`NotificationScheduler` 负责权限、调度和通知操作。

编辑时取消旧通知并用同一 UUID 调度；完成、删除和稍后提醒也更新对应通知。提前提醒时间可选 5、15、30 分钟或 1 小时。

`LiveActivityManager` 和 Widget Extension 提供锁屏活动及灵动岛入口。完全退出后，普通本地调度不能保证在未来时刻自动启动 Live Activity；定时提醒依靠系统本地通知。

## 开发

需要重新生成 Xcode 工程时，在内层工程目录执行：

```bash
cd MemoReminder
ruby Scripts/generate_xcode_project.rb
```

源码工程和资源都已入库，构建产物不应提交。
