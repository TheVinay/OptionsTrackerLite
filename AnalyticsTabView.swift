import SwiftUI

// ---------------------------------------------
// Internal structs for analytics
// ---------------------------------------------

private struct TradeStats {
    var wins: Int = 0
    var losses: Int = 0
    var totalPL: Double = 0

    var total: Int { wins + losses }

    var winRate: Double {
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total)
    }

    var winRateLabel: String {
        total == 0 ? "–" : String(format: "%.0f%%", winRate * 100)
    }
}

private struct TickerStrategyKey: Hashable {
    let ticker: String
    let type: OptionType
}

private struct DayKey: Hashable {
    let index: Int
    let label: String
}

// ---------------------------------------------
// MAIN VIEW
// ---------------------------------------------

struct AnalyticsTabView: View {

    let profiles: [ClientProfile]

    // MARK: - Filters
    enum TimeFilter: String, CaseIterable, Identifiable {
        case last7 = "1W"
        case last30 = "30D"
        case last90 = "90D"
        case ytd = "YTD"
        case last365 = "1Y"
        case max = "Max"
        var id: String { rawValue }
    }

    @State private var selectedFilter: TimeFilter = .max

    enum SectionFilter: String, CaseIterable, Identifiable {
        case tickerStrategy = "By Ticker & Strategy"
        case strategy = "By Strategy"
        case weekday = "By Day of Week"

        var id: String { rawValue }
    }

    @State private var sectionFilter: SectionFilter = .tickerStrategy
    @State private var sectionExpanded: Bool = true

    // MARK: - Derived sets

    private var allTrades: [Trade] {
        profiles.flatMap(\.trades)
    }

    private var closed: [Trade] {
        allTrades.filter { $0.isClosed && $0.realizedPL != nil }
    }

    // ---------------------------------------------
    // FILTERED TRADES
    // ---------------------------------------------

    private var filteredClosed: [Trade] {
        let cal = Calendar.current
        let now = Date()

        func daysAgo(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now) ?? now }
        func startOfYear() -> Date {
            let comps = cal.dateComponents([.year], from: now)
            return cal.date(from: comps) ?? now
        }

        switch selectedFilter {
        case .last7:  return closed.filter { $0.tradeDate >= daysAgo(7) }
        case .last30: return closed.filter { $0.tradeDate >= daysAgo(30) }
        case .last90: return closed.filter { $0.tradeDate >= daysAgo(90) }
        case .ytd:    return closed.filter { $0.tradeDate >= startOfYear() }
        case .last365:return closed.filter { $0.tradeDate >= daysAgo(365) }
        case .max:    return closed
        }
    }

    // ---------------------------------------------
    // GROUPED ANALYTICS
    // ---------------------------------------------

    private var statsByTickerStrategy: [(TickerStrategyKey, TradeStats)] {
        var dict: [TickerStrategyKey: TradeStats] = [:]

        for t in filteredClosed {
            guard let pl = t.realizedPL else { continue }
            let key = TickerStrategyKey(ticker: t.ticker, type: t.type)
            var st = dict[key] ?? TradeStats()
            if pl >= 0 { st.wins += 1 } else { st.losses += 1 }
            st.totalPL += pl
            dict[key] = st
        }

        return dict.sorted { $0.key.ticker < $1.key.ticker }
    }

    private var statsByStrategy: [(OptionType, TradeStats)] {
        var dict: [OptionType: TradeStats] = [:]

        for t in filteredClosed {
            guard let pl = t.realizedPL else { continue }
            var st = dict[t.type] ?? TradeStats()
            if pl >= 0 { st.wins += 1 } else { st.losses += 1 }
            st.totalPL += pl
            dict[t.type] = st
        }

        return dict.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    private var statsByWeekday: [(DayKey, TradeStats)] {
        var dict: [Int: TradeStats] = [:]
        let cal = Calendar.current

        for t in filteredClosed {
            guard let pl = t.realizedPL else { continue }
            let wd = cal.component(.weekday, from: t.tradeDate)

            var st = dict[wd] ?? TradeStats()
            if pl >= 0 { st.wins += 1 } else { st.losses += 1 }
            st.totalPL += pl
            dict[wd] = st
        }

        let fmt = DateFormatter()
        let labels = fmt.shortWeekdaySymbols ?? ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

        return dict.keys.sorted().map { wd in
            let label = labels[(wd - 1 + labels.count) % labels.count]
            return (DayKey(index: wd, label: label), dict[wd]!)
        }
    }

    // ---------------------------------------------
    // MAIN BODY
    // ---------------------------------------------

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                filterBar
                headerSummaryCard
                sectionPickerCard
                analyticsSection
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // ---------------------------------------------
    // FILTER BAR
    // ---------------------------------------------

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TimeFilter.allCases) { f in
                    Text(f.rawValue)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(f == selectedFilter ? Color.blue.opacity(0.2) : Color(.systemGray6))
                        )
                        .foregroundColor(f == selectedFilter ? .blue : .primary)
                        .onTapGesture { selectedFilter = f }
                }
            }
        }
    }

    // ---------------------------------------------
    // HEADER SUMMARY
    // ---------------------------------------------

    private var headerSummaryCard: some View {
        let total = filteredClosed.count
        let wins = filteredClosed.filter { ($0.realizedPL ?? 0) >= 0 }.count
        let _ = total - wins  // losses count (not currently displayed)
        let totalPL = filteredClosed.compactMap(\.realizedPL).reduce(0, +)
        let winRate = total == 0 ? 0 : Double(wins)/Double(total)

        return VStack(alignment: .leading, spacing: 8) {

            Text("Performance Summary")
                .font(.title3.bold())

            Divider()

            HStack {
                summaryBox(title: "Closed", value: "\(total)")
                summaryBox(title: "Win Rate", value: String(format:"%.0f%%", winRate*100))
                summaryBox(title: "P&L",
                           value: totalPL.formatted(.currency(code:"USD")),
                           color: totalPL >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
    }

    private func summaryBox(title: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
    }

    // ---------------------------------------------
    // SECTION PICKER
    // ---------------------------------------------

    private var sectionPickerCard: some View {
        VStack(spacing: 8) {

            Menu {
                ForEach(SectionFilter.allCases) { s in
                    Button(s.rawValue) { sectionFilter = s }
                }
            } label: {
                HStack {
                    Text(sectionFilter.rawValue)
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }

    // ---------------------------------------------
    // ANALYTICS SECTION
    // ---------------------------------------------

    @ViewBuilder
    private var analyticsSection: some View {
        switch sectionFilter {
        case .tickerStrategy:
            heatmapCard(title: "By Ticker & Strategy", rows: statsByTickerStrategy.map {
                ("\($0.ticker) – \($0.type.rawValue)", $1)
            })

        case .strategy:
            heatmapCard(title: "By Strategy", rows: statsByStrategy.map {
                ($0.rawValue, $1)
            })

        case .weekday:
            heatmapCard(title: "By Day of Week", rows: statsByWeekday.map {
                ($0.label, $1)
            })
        }
    }

    // ---------------------------------------------
    // REUSABLE HEATMAP
    // ---------------------------------------------

    private func heatmapCard(title: String, rows: [(String, TradeStats)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)

            if rows.isEmpty {
                Text("Not enough data yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(rows, id: \.0) { label, stats in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(label).font(.subheadline)
                                Text("\(stats.wins) wins / \(stats.losses) losses")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text(stats.winRateLabel)
                                    .bold()
                                Text(stats.totalPL,
                                     format: .currency(code:"USD"))
                                .foregroundColor(stats.totalPL >= 0 ? .green : .red)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(heatColor(for: stats.winRate)))
                        }
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 4))
    }

    private func heatColor(for rate: Double) -> Color {
        switch rate {
        case 0.7...:   return .green.opacity(0.18)
        case 0.5...:   return .yellow.opacity(0.18)
        case 0.01...:  return .red.opacity(0.18)
        default:       return .gray.opacity(0.12)
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsTabView(profiles: ClientProfile.demoProfiles())
    }
}
