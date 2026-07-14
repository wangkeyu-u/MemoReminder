# MemoReminder

> 一款轻量级 iOS 备忘提醒 App —— 快速记录、定时震动提醒、灵动岛速览。
>
> A lightweight iOS memo reminder app — quick capture, timed haptic alerts, and Dynamic Island glance.

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)](https://developer.apple.com/ios/)
[![Language](https://img.shields.io/badge/language-SwiftUI-orange)](https://developer.apple.com/swiftui/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## 简介 / Overview

MemoReminder 解决一个极简需求：**记一件事，到点提醒你**。不需要复杂日历，不需要注册账号，打开即用。

MemoReminder solves one simple need: **jot down a task, get reminded on time.** No complex calendars, no account registration — just open and use.

- 创建提醒 → 选择时间 → 系统在到点前 30 分钟震动通知
- 支持灵动岛的 iPhone 上，提醒触发后灵动岛展示入口，点击速览内容
- 通知快捷操作直接「完成」或「稍后 10 分钟」
- Create a reminder → pick a time → the system nudges you 30 min before
- On Dynamic-Island iPhones, an alert appears in the island; tap to glance at the memo
- Notification quick actions: "Done" or "Snooze 10 min"

**典型场景 / Typical use cases：** 明天买东西 · 下午打电话 · 半小时后取快递 · 晚上提交作业

---

## 核心功能 / Key Features

| 功能 / Feature | 说明 / Description |
|---|---|
| 快速创建 / Quick capture | 输入内容 + 选时间，一步保存 / Type text + pick time, one-tap save |
| 提前提醒 / Advance alert | 到点前 30 分钟震动 + 系统通知 / Haptic + system notification 30 min before |
| 灵动岛速览 / Dynamic Island glance | 点击灵动岛入口弹出小窗查看提醒内容 / Tap the island to peek at the memo |
| 通知快捷操作 / Notification actions | 直接在通知上「完成」或「稍后 10 分钟」 / "Done" or "Snooze 10 min" right from the notification |
| 分组与搜索 / Group & search | 今天 / 之后分组，按内容搜索 / Grouped by Today / Later, searchable by text |
| 状态管理 / Status tracking | 未提醒 · 已提醒 · 已完成 · 已取消 / Pending · Reminded · Done · Cancelled |
| 本地持久化 / Local persistence | 所有数据存本地，无需联网 / All data on-device, no network required |

---

## 技术栈 / Tech Stack

- **SwiftUI** — 全部界面构建 / All UI
- **UserNotifications** — 本地通知调度与快捷操作 / Local notification scheduling & quick actions
- **ActivityKit + WidgetKit** — 灵动岛与锁屏活动展示 / Dynamic Island & lock-screen Live Activity
- **UserDefaults / SwiftData** — 本地数据持久化 / On-device persistence
- **MVVM** — Store 模式集中管理状态与通知一致性 / Store pattern for state-notification consistency

---

## 工程结构 / Project Structure

```
MemoReminder/
├── MemoReminderApp/            # App 入口 + 全局 Store & Scheduler / App entry + global state
├── MemoReminderWidgets/        # 灵动岛 & 锁屏 Widget Extension / Dynamic Island & lock widget
├── Shared/                     # 跨 target 共享模型 / Shared models across targets
├── Scripts/                    # 辅助脚本 / Helper scripts
├── iOS备忘提醒App需求文档.md     # 产品需求文档 / Product requirements doc
└── APP_STORE_RELEASE.md        # App Store 发布指南 / App Store release guide
```

核心模块 / Core modules：

- **`Reminder`** — 领域模型，用 `UUID` 串起本地数据、通知请求、Live Activity / Domain model, UUID links data ↔ notifications ↔ Live Activity
- **`ReminderStore`** — 主线程状态容器：校验、增删改查、分组、持久化 / Main-thread state container
- **`NotificationScheduler`** — 通知适配层：权限、调度、快捷操作 / Notification adapter: permission, scheduling, actions
- **`LiveActivityManager`** — ActivityKit 接入层 / ActivityKit integration

---

## 关键设计 / Key Design Decisions

<details>
<summary>数据与通知一致性 / Data-Notification Consistency</summary>

创建、编辑、删除、完成、稍后提醒时，都会**同步更新本地数据和系统通知**，避免出现"列表里没了但通知还会响"的状态不一致。编辑提醒时先取消旧 pending notification，再用同一 UUID 重新调度。

All mutations (create / edit / delete / complete / snooze) **synchronously update both local data and system notifications**, preventing "deleted from list but notification still fires" inconsistencies. Editing cancels the old pending notification first, then re-schedules with the same UUID.

</details>

<details>
<summary>灵动岛 vs 本地通知 / Dynamic Island vs Local Notification</summary>

灵动岛不能由普通 App 随意显示，需要 ActivityKit + Widget Extension 的 Live Activity。第一版以**本地通知作为稳定触达通道**，灵动岛作为增强展示入口持续迭代。

Dynamic Island requires ActivityKit + Widget Extension Live Activities. v1 uses **local notifications as the stable delivery channel**, with Dynamic Island as an enhancement layer.

</details>

---

## 运行 / How to Run

### 环境要求 / Prerequisites

- Xcode 16+
- iOS 17+（真机测试通知、震动、Live Activity / real device for notifications, haptics, Live Activity）

### 步骤 / Steps

1. 克隆仓库 / Clone:
   ```bash
   git clone https://github.com/wangkeyu-u/MemoReminder.git
   cd MemoReminder
   ```
2. 用 Xcode 打开 `MemoReminder/MemoReminder.xcodeproj`
3. 选择 iPhone 模拟器或真机 / Select an iPhone simulator or real device
4. `⌘R` 运行 / Run

> ⚠️ 如果直接双击运行 `MemoReminder.app` 构建产物会报错——这是 iOS App，不是 macOS App。请在 Xcode 中选择模拟器或真机后运行。
>
> ⚠️ Double-clicking the built `.app` will error — this is an iOS app, not macOS. Run from Xcode with a simulator or device selected.

---

## 路线图 / Roadmap

- [ ] 自定义提前提醒时间（当前固定 30 分钟）/ Custom advance time (currently fixed at 30 min)
- [ ] iCloud 同步 / iCloud sync
- [ ] Siri 快捷指令创建提醒 / Siri shortcut integration
- [ ] iPad 适配 / iPad support

---

## 许可证 / License

MIT

---

<p align="center">
  <sub>记一件事 · 到点提醒你 / Jot it down · Get reminded on time</sub>
</p>
