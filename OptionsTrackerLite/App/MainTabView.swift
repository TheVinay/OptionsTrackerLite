import SwiftUI

struct MainTabView: View {
    @State private var profiles: [ClientProfile] = ClientProfile.demoProfiles()

    var body: some View {
        TabView {
            // Profile / Home
            NavigationStack {
                RootView(profiles: $profiles)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }

            // Portfolios
            NavigationStack {
                PortfoliosView(profiles: $profiles)
            }
            .tabItem {
                Label("Portfolios", systemImage: "person.3")
            }

            // All Trades
            NavigationStack {
                AllTradesView(profiles: $profiles)
            }
            .tabItem {
                Label("All Trades", systemImage: "rectangle.stack")
            }

            // Learn
            NavigationStack {
                LearnView()
            }
            .tabItem {
                Label("Learn", systemImage: "book.closed")
            }
        }
    }
}

#Preview {
    MainTabView()
}
