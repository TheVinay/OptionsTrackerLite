import SwiftUI

@main
struct OptionsTrackerLiteApp: App {
    @AppStorage("useDarkMode") private var useDarkMode = false

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(useDarkMode ? .dark : .light)
                .tint(Color(.systemBlue))   // ✅ blue accent like TSLA screenshots
                //.tint(.purple)   // ✅ purple accent similar to workout app
        }
    }
}
