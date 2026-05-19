# App Store 发布清单

## 当前工程状态

- App 名称：备忘提醒
- Bundle ID：`com.wangkeyu.memoreminder`
- Widget Extension Bundle ID：`com.wangkeyu.memoreminder.widgets`
- 版本号：`1.0`
- Build：`1`
- 最低系统：iOS 17.0
- 支持设备：iPhone、iPad
- 已包含 App Icon、Accent Color、Launch Screen 配置、Privacy Manifest。
- 已声明不使用非豁免加密：`ITSAppUsesNonExemptEncryption = false`
- 已声明 UserDefaults Required Reason API：`NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1`

## 上传前必须由你在 Xcode 完成

1. 打开 `MemoReminder.xcodeproj`。
2. 在 `MemoReminder` target 的 Signing & Capabilities 里选择你的 Apple Developer Team。
3. 如果 `com.wangkeyu.memoreminder` 已被占用，改成你账号下唯一的 Bundle ID。
4. 同步修改 `MemoReminderWidgetsExtension` 的 Bundle ID，保持主 App 前缀一致。
5. 确认 Widget Extension 已随主 App embed。
6. 真机测试通知权限、本地通知、通知快捷操作、Live Activity / 灵动岛。
7. Product > Archive。
8. Organizer > Distribute App > App Store Connect > Upload。

## App Store Connect 信息草稿

### 名称

备忘提醒

### 副标题

快速记录，准时提醒

### 关键词

备忘录,提醒,待办,日程,清单,通知,效率,时间管理

### 描述

备忘提醒是一款轻量、清晰的 iPhone 提醒工具。你可以快速写下需要处理的事情，选择目标时间，并设置提前多久提醒。到达提醒时间时，App 会通过系统通知提醒你；支持的设备还可以通过 Live Activity 和灵动岛展示提醒入口。

主要功能：

- 快速创建提醒
- 选择目标时间
- 支持提前 5 分钟、15 分钟、30 分钟、1 小时提醒
- 今天与未来提醒分组展示
- 搜索提醒内容
- 编辑、完成、删除提醒
- 稍后 10 分钟再次提醒
- 通知快捷操作
- 支持 Live Activity / 灵动岛入口

所有提醒内容都保存在本机，第一版不需要登录账号，也不会上传你的提醒内容。

### 隐私摘要

- 不收集用户数据。
- 不进行跨 App 或跨网站追踪。
- 提醒内容仅保存在设备本地。
- 使用通知权限仅用于按时提醒用户。

### 审核备注

本 App 是本地备忘提醒工具。用户创建提醒后，App 使用本地通知在设定时间提醒用户；通知中的“完成”和“稍后 10 分钟”动作用于直接处理提醒。Live Activity / 灵动岛用于展示正在进行的提醒状态。

## 建议测试用例

1. 第一次打开 App，请求通知权限。
2. 创建 1 条 3 分钟后的提醒，确认通知触发。
3. 在通知上点击“稍后 10 分钟”，确认提醒被重新安排。
4. 在通知上点击“完成”，确认提醒移动到最近完成。
5. 创建、编辑、删除提醒，确认列表状态和通知状态同步。
6. 在支持灵动岛的真机上测试 Live Activity 展示与点击跳转。

