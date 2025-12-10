import SwiftUI

enum ClientDetailSection: String, CaseIterable, Identifiable {
    case trades = "Trades"
    case calendar = "Calendar"
    case analytics = "Analytics"
    case tools = "Tools"

    var id: String { rawValue }
}

enum ClientTradeSortKey: String, CaseIterable {
    case entryDate = "Entry Date"
    case expiryDate = "Expiry Date"
    case ticker = "Ticker"
    case pnl = "P&L"
}

enum ClientStatusFilter: String, CaseIterable {
    case all = "All Statuses"
    case open = "Open"
    case closed = "Closed"
    case rolled = "Rolled"
}

struct ClientDetailView: View {
    @Binding var profile: ClientProfile

    @State private var selectedSection: ClientDetailSection = .trades
    @State private var showNewTrade = false

    // Sort / filter state
    @State private var sortKey: ClientTradeSortKey = .entryDate
    @State private var sortAscending: Bool = false
    @State private var statusFilter: ClientStatusFilter = .all
    @State private var strategyFilter: OptionType? = nil

    // MARK: - Derived data

    private var recentTickers: [String] {
        Array(Set(profile.trades.map { $0.ticker })).sorted()
    }

    private var filteredTrades: [Trade] {
        var trades = profile.trades

        // Status filter
        switch statusFilter {
        case .all:
            break
        case .open:
            trades = trades.filter { !$0.isClosed }
        case .closed:
            trades = trades.filter { $0.isClosed }
        case .rolled:
            // For now, treat "Rolled" as a tag-based filter
            trades = trades.filter {
                $0.tags.contains { $0.localizedCaseInsensitiveContains("roll") }
            }
        }

        // Strategy filter
        if let strategy = strategyFilter {
            trades = trades.filter { $0.type == strategy }
        }

        // Sorting
        trades.sort { lhs, rhs in
            let comparison: Bool
            switch sortKey {
            case .entryDate:
                comparison = lhs.tradeDate < rhs.tradeDate
            case .expiryDate:
                comparison = lhs.expirationDate < rhs.expirationDate
            case .ticker:
                comparison = lhs.ticker.localizedCompare(rhs.ticker) == .orderedAscending
            case .pnl:
                let l = lhs.realizedPL ?? 0
                let r = rhs.realizedPL ?? 0
                comparison = l < r
            }
            return sortAscending ? comparison : !comparison
        }

        return trades
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker

            switch selectedSection {
            case .trades:
                tradesSection
            case .calendar:
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
                // IMPORTANT: we no longer pass `profile:` into NewTradeView.
                NewTradeView(
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
        VStack(spacing: 0) {
            sortFilterRow

            if filteredTrades.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No trades yet",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Add your first options trade for this client using the + button.")
                )
                Spacer()
            } else {
                List {
                    ForEach(filteredTrades) { trade in
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

    // The three “chip” menus (Sort / Status / Strategy) like in your screenshots
    private var sortFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Sort menu
                Menu {
                    ForEach(ClientTradeSortKey.allCases, id: \.self) { key in
                        Button {
                            sortKey = key
                        } label: {
                            if key == sortKey {
                                Label(key.rawValue, systemImage: "checkmark")
                            } else {
                                Text(key.rawValue)
                            }
                        }
                    }

                    Divider()

                    Button(sortAscending ? "Descending" : "Ascending") {
                        sortAscending.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down.circle")
                        Text("Sort: \(sortKey.rawValue)")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }

                // Status menu
                Menu {
                    ForEach(ClientStatusFilter.allCases, id: \.self) { status in
                        Button {
                            statusFilter = status
                        } label: {
                            if status == statusFilter {
                                Label(status.rawValue, systemImage: "checkmark")
                            } else {
                                Text(status.rawValue)
                            }
                        }
                    }
                } label: {
                    Text("Status")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }

                // Strategy menu
                Menu {
                    Button("All Strategies") {
                        strategyFilter = nil
                    }

                    ForEach(OptionType.allCases) { opt in
                        Button {
                            strategyFilter = opt
                        } label: {
                            if strategyFilter == opt {
                                Label(opt.rawValue, systemImage: "checkmark")
                            } else {
                                Text(opt.rawValue)
                            }
                        }
                    }
                } label: {
                    Text("Strategy")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func comingSoonView(title: String, message: String) -> some View {
        VStack {
            Spacer()
            ContentUnavailableView(
                "\(title) coming soon",
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
