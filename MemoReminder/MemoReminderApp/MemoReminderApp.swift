import SwiftUI

@main
struct MemoReminderApp: App {
    /// App-level dependencies are created once here and injected into SwiftUI.
    /// This keeps views lightweight and avoids creating multiple schedulers or
    /// stores during navigation.
    @StateObject private var store = ReminderStore()
    @StateObject private var notificationScheduler = NotificationScheduler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(notificationScheduler)
                .task {
                    // Startup order matters: ask for notification permission,
                    // load local reminders, then connect the notification
                    // delegate to the loaded store.
                    await notificationScheduler.requestAuthorizationIfNeeded()
                    await store.load()
                    notificationScheduler.configure(store: store)
                }
                .onOpenURL { url in
                    store.handleDeepLink(url)
                }
        }
    }
}
