# MemoReminder

一款 iOS 备忘提醒 App 的 MVP 源码骨架。

## 面试版定位

这是三个项目里的主项目，面试时优先讲它。推荐主线：

> 我独立做了一个 iOS 备忘提醒 App，用 SwiftUI 完成提醒创建、编辑、分组和搜索，使用 UserNotifications 做本地通知调度，并支持通知快捷操作里的完成和稍后 10 分钟。项目重点不是页面堆砌，而是维护提醒数据和系统 pending notification 的一致性：创建、修改、删除、完成、稍后提醒时，都要同步更新本地状态和通知中心。

面试官追问时优先展开这 4 个点：

- `Reminder` 模型里用 `UUID` 作为提醒和通知的稳定关联 ID。
- `NotificationScheduler` 先取消旧通知再添加新通知，避免修改提醒后重复触发。
- `UNNotificationCategory` + `UNNotificationAction` 支持“完成”和“稍后 10 分钟”。
- ActivityKit / Widget Extension 作为提醒状态展示入口，本地通知仍是稳定触达通道。

## 工程结构

- `MemoReminderApp`：App 入口，负责创建全局 `ReminderStore` 和 `NotificationScheduler`，并处理 deep link。
- `Reminder`：核心领域模型，用一个稳定 `UUID` 串起本地数据、通知请求、Live Activity 和跳转链接。
- `ReminderStore`：主线程状态容器，负责提醒的校验、增删改查、分组和本地持久化。
- `NotificationScheduler`：系统通知适配层，负责权限、通知调度、通知快捷操作和前台展示。
- `LiveActivityManager` + `ReminderLiveActivityWidget`：ActivityKit/WidgetKit 接入层，负责灵动岛和锁屏活动展示。
- `Views`：SwiftUI 展示层，组件只接收数据和 action closure，业务状态集中由 Store 和 Scheduler 维护。

## 关键工程设计

- 创建、编辑、删除、完成、稍后提醒都会同步更新本地数据和系统通知，避免出现“列表里没有了但通知还会响”的状态不一致。
- 编辑提醒时先取消旧的 pending notification，再用同一个 reminder UUID 重新调度，避免重复通知。
- Store 的 mutation 方法返回保存后的 `Reminder`，调用方可以直接用同一份数据去调度通知和 Live Activity。
- ActivityKit 作为增强展示入口，本地通知仍作为第一版的稳定触达通道。

## 当前已实现

- 创建提醒
- 选择目标时间
- 可选提前 5 分钟、15 分钟、30 分钟、1 小时触发本地通知
- 本地保存提醒列表
- 今天 / 之后分组
- 待提醒、今天、逾期统计
- 搜索提醒内容
- 编辑已创建的提醒
- 标记完成
- 删除提醒并取消对应通知
- 稍后 10 分钟再次提醒
- 通知快捷操作：完成、稍后 10 分钟
- 点击通知跳转提醒详情
- ActivityKit / 灵动岛接入入口与 Widget Extension 示例代码
- App Store 隐私清单
- App Icon 和发布资源

## 建议开发环境

- Xcode 16 或更新版本
- iOS 17 或更新版本
- 真机测试通知、震动、Live Activity 和灵动岛

## 重要说明

灵动岛不能由普通 App 随意显示，需要通过 ActivityKit + Widget Extension 的 Live Activity 实现。当前项目已经放入相关代码结构，但仍需要在 Xcode 中创建 App target 和 Widget Extension target 后，把对应源码加入 target，并开启 Live Activities capability。

如果不接入远程推送或后台任务，App 无法保证在完全退出时于未来某个时间点自动启动 Live Activity。第一版应以本地通知作为稳定提醒通道，灵动岛作为增强入口继续迭代。

发布前请阅读 `APP_STORE_RELEASE.md`。最终上传 App Store Connect 需要你在 Xcode 中选择自己的 Apple Developer Team，并确认 Bundle ID 在你的开发者账号下可用。

## 打开方式

直接用 Xcode 打开：

```bash
open MemoReminder.xcodeproj
```

如果看到 “Your Mac does not support this application. Try reinstalling or downloading the version for your system.”，通常是因为直接双击运行了 iOS 构建产物 `MemoReminder.app`。这个项目当前是 iOS App，不是 macOS App。请在 Xcode 左上角选择 iPhone 模拟器或真机后运行。

如果命令行提示 `xcodebuild requires Xcode, but active developer directory ... is a command line tools instance`，先安装完整 Xcode，然后执行：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

如需重新生成工程文件：

```bash
ruby Scripts/generate_xcode_project.rb
```

命令行构建建议把产物输出到 `/tmp`，避免 macOS Documents 目录的扩展属性影响 codesign：

```bash
xcodebuild \
  -project MemoReminder.xcodeproj \
  -target MemoReminder \
  -sdk iphonesimulator26.5 \
  -configuration Debug \
  SYMROOT=/tmp/MemoReminderBuild \
  OBJROOT=/tmp/MemoReminderBuild/Obj \
  DSTROOT=/tmp/MemoReminderBuild/Dst \
  build
```
