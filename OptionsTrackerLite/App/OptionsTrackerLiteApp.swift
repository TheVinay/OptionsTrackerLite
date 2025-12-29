import SwiftUI
import SwiftData

@main
struct OptionsTrackerLiteApp: App {
    @AppStorage("useDarkMode") private var useDarkMode = false
    @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        // Request notification permissions on first launch
        Task {
            await NotificationManager.shared.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(useDarkMode ? .dark : .light)
                .tint(Color(.systemBlue))   // ✅ blue accent like TSLA screenshots
                //.tint(.purple)   // ✅ purple accent similar to workout app
        }
        .modelContainer(for: [ClientProfile.self, Trade.self, TradeNote.self])
    }
}
