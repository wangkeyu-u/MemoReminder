import SwiftUI

@main
struct MemoReminderApp: App {
    @StateObject private var store = ReminderStore()
    @StateObject private var notificationScheduler = NotificationScheduler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(notificationScheduler)
                .task {
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

