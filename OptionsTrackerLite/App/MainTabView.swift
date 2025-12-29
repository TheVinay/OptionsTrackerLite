import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query private var profiles: [ClientProfile]
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    var body: some View {
        TabView {

            // Profile tab
            NavigationStack {
                RootView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }

            // Portfolios tab
            NavigationStack {
                PortfoliosView()
            }
            .tabItem {
                Label("Portfolios", systemImage: "person.3")
            }

            // All Trades tab
            NavigationStack {
                AllTradesView()
            }
            .tabItem {
                Label("All Trades", systemImage: "rectangle.stack")
            }

            // Analytics tab
            NavigationStack {
                AnalyticsTabView(profiles: Array(profiles))
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
            
            // Settings tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showOnboarding = true
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
    }
}
#Preview {
    MainTabView()
        .modelContainer(for: [ClientProfile.self, Trade.self, TradeNote.self])
}

