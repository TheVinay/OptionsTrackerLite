import SwiftUI

enum ClientDetailSection: String, CaseIterable, Identifiable {
    case trades = "Trades"
    case calendar = "Calendar"
    case analytics = "Analytics"
    case tools = "Tools"

    var id: String { rawValue }
}

struct ClientDetailView: View {
    @Binding var profile: ClientProfile

    @State private var selectedSection: ClientDetailSection = .trades
    @State private var showNewTrade = false

    // For ticker suggestions in NewTradeView
    private var recentTickers: [String] {
        Array(Set(profile.trades.map { $0.ticker })).sorted()
    }

    // Sorted trades for list
    private var sortedTrades: [Trade] {
        profile.trades.sorted { $0.tradeDate > $1.tradeDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker

            switch selectedSection {
            case .trades:
                tradesSection
            case .calendar:
                // Calendar for this single client
                ClientCalendarView(profile: profile)
            case .analytics:
                comingSoonView(
                    title: "Analytics",
                    message: "Client-level analytics, equity curves, and expectancy will appear here."
                )
            case .tools:
                comingSoonView(
                    title: "Tools",
                    message: "Rolling helpers and simulators will live in this tab later."
                )
            }
        }
        .navigationTitle(profile.name)
        .toolbar {
            if selectedSection == .trades {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewTrade = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("New Trade")
                }
            }
        }
        .sheet(isPresented: $showNewTrade) {
            NavigationStack {
                NewTradeView(
                    profile: $profile,
                    recentTickers: recentTickers,
                    onSave: { newTrade in
                        profile.trades.append(newTrade)
                    }
                )
            }
        }
    }

    // MARK: - UI pieces

    private var sectionPicker: some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(ClientDetailSection.allCases) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    private var tradesSection: some View {
        Group {
            if sortedTrades.isEmpty {
                ContentUnavailableView(
                    "No trades yet",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Add your first options trade for this client using the + button.")
                )
            } else {
                List {
                    ForEach(sortedTrades) { trade in
                        NavigationLink {
                            TradeDetailView(trade: trade, clientName: profile.name)
                        } label: {
                            TradeRowView(trade: trade)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func comingSoonView(title: String, message: String) -> some View {
        VStack {
            Spacer()
            ContentUnavailableView(
                "\(title) – coming soon",
                systemImage: "hourglass",
                description: Text(message)
            )
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ClientDetailView(
            profile: .constant(ClientProfile.demoProfiles().first!)
        )
    }
}
