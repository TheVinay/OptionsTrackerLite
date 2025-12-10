import SwiftUI

enum AllTradesSection: String, CaseIterable, Identifiable {
    case trades = "Trades"
    case calendar = "Calendar"
    case analytics = "Analytics"
    case tools = "Tools"

    var id: String { rawValue }
}

struct AllTradesView: View {
    @Binding var profiles: [ClientProfile]

    @State private var selectedSection: AllTradesSection = .trades

    // Filters
    @State private var selectedClientID: UUID? = nil       // nil = All clients
    @State private var selectedType: OptionType? = nil     // nil = All types

    // Sort (by trade date)
    @State private var sortAscending: Bool = false         // false = newest first

    // MARK: - Derived data

    private var allTrades: [Trade] {
        profiles.flatMap(\.trades)
    }

    /// Trades after filters + sort are applied
    private var filteredTrades: [Trade] {
        var result = allTrades

        // Filter by client
        if let id = selectedClientID {
            result = result.filter { trade in
                profiles.contains { profile in
                    profile.id == id &&
                    profile.trades.contains(where: { $0.id == trade.id })
                }
            }
        }

        // Filter by type
        if let t = selectedType {
            result = result.filter { $0.type == t }
        }

        // Sort by trade date
        result.sort { lhs, rhs in
            sortAscending ? (lhs.tradeDate < rhs.tradeDate)
                          : (lhs.tradeDate > rhs.tradeDate)
        }

        return result
    }

    private var totalRealizedPL: Double {
        filteredTrades.compactMap { $0.realizedPL }.reduce(0, +)
    }

    private var distinctClientCount: Int {
        let ids: Set<UUID> = Set(
            filteredTrades.compactMap { trade in
                profiles.first(where: { $0.trades.contains(where: { $0.id == trade.id }) })?.id
            }
        )
        return ids.count
    }

    // MARK: - Body

    var body: some View {
        VStack {
            Picker("Section", selection: $selectedSection) {
                ForEach(AllTradesSection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding([.top, .horizontal])

            switch selectedSection {
            case .trades:
                tradesSection
            case .calendar:
                comingSoonView(
                    title: "Calendar",
                    message: "A global expiration calendar for all clients will appear here. For now, this is a placeholder."
                )
            case .analytics:
                comingSoonView(
                    title: "Analytics",
                    message: "All-clients analytics, equity curves, and strategy metrics will be added here later."
                )
            case .tools:
                comingSoonView(
                    title: "Tools",
                    message: "Portfolio-level tools and simulators will live here in a future version."
                )
            }
        }
        .navigationTitle("All Trades")
    }

    // MARK: - Trades section

    private var tradesSection: some View {
        VStack(spacing: 8) {

            // Filter / sort chips (like your screenshots)
            chipsRow
                .padding(.horizontal)
                .padding(.bottom, 4)

            summaryCard

            if filteredTrades.isEmpty {
                ContentUnavailableView(
                    "No trades match filters",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Try changing the client or type filters to see more trades.")
                )
            } else {
                List {
                    ForEach(filteredTrades) { trade in
                        let clientName = profiles.first(where: { profile in
                            profile.trades.contains(where: { $0.id == trade.id })
                        })?.name

                        NavigationLink {
                            TradeDetailView(trade: trade, clientName: clientName)
                        } label: {
                            TradeRowView(trade: trade)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Chips row

    private var chipsRow: some View {
        HStack(spacing: 12) {

            // Client filter
            Menu {
                Button("All Clients") {
                    selectedClientID = nil
                }

                ForEach(profiles) { profile in
                    Button(profile.name) {
                        selectedClientID = profile.id
                    }
                }
            } label: {
                chipLabel(
                    text: selectedClientID.flatMap { id in
                        profiles.first(where: { $0.id == id })?.name
                    } ?? "All Clients",
                    isActive: selectedClientID != nil
                )
            }

            // Type filter
            Menu {
                Button("All Types") {
                    selectedType = nil
                }
                ForEach(OptionType.allCases) { type in
                    Button(type.rawValue) {
                        selectedType = type
                    }
                }
            } label: {
                chipLabel(
                    text: selectedType?.rawValue ?? "Type",
                    isActive: selectedType != nil
                )
            }

            // Sort direction
            Button {
                sortAscending.toggle()
            } label: {
                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private func chipLabel(text: String, isActive: Bool) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(isActive ? Color.blue : Color.blue)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SUMMARY")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Clients:")
                    Spacer()
                    Text("\(distinctClientCount)")
                }
                HStack {
                    Text("Total Trades:")
                    Spacer()
                    Text("\(filteredTrades.count)")
                }
                HStack {
                    Text("Realized P&L:")
                    Spacer()
                    Text(totalRealizedPL, format: .currency(code: "USD"))
                        .foregroundColor(totalRealizedPL >= 0 ? .green : .red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    // MARK: - Coming soon helper

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
