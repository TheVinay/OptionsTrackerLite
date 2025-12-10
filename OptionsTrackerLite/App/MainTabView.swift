import SwiftUI

struct MainTabView: View {
    @State private var profiles: [ClientProfile] = ClientProfile.demoProfiles()

    var body: some View {
        TabView {

            // Profile tab
            NavigationStack {
                RootView(profiles: $profiles)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }

            // Portfolios tab
            NavigationStack {
                PortfoliosView(profiles: $profiles)
            }
            .tabItem {
                Label("Portfolios", systemImage: "person.3")
            }

            // All Trades tab
            NavigationStack {
                AllTradesView(profiles: $profiles)
            }
            .tabItem {
                Label("All Trades", systemImage: "rectangle.stack")
            }

            // NEW Analytics tab
            NavigationStack {
                AnalyticsTabView(profiles: profiles)
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.bar.doc.horizontal")
            }

            // Learn tab
            NavigationStack {
                LearnView()
            }
            .tabItem {
                Label("Learn", systemImage: "book.closed")
            }
        }
    }
}
