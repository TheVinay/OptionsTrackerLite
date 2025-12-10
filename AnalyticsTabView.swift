import SwiftUI

/// Simple summary of wins / losses / P&L
private struct TradeStats {
    var wins: Int = 0
    var losses: Int = 0
    var totalPL: Double = 0

    var total: Int { wins + losses }

    var winRate: Double {
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total)
    }

    var winRatePercentText: String {
        guard total > 0 else { return "–" }
        let pct = winRate * 100
        return String(format: "%.0f%%", pct)
    }
}

/// Key for “by ticker & strategy” heatmap
private struct TickerStrategyKey: Hashable {
    let ticker: String
    let type: OptionType
}

struct AnalyticsTabView: View {

    let profiles: [ClientProfile]

    // MARK: - Derived collections

    private var allTrades: [Trade] {
        profiles.flatMap(\.trades)
    }

    /// For performance analytics we usually care about closed trades with realized P&L.
    private var closedTradesWithPL: [Trade] {
        allTrades.filter { $0.isClosed && $0.realizedPL != nil }
    }

    // MARK: - Grouped stats

    /// Heatmap: By (ticker, strategy)
    private var statsByTickerAndStrategy: [(TickerStrategyKey, TradeStats)] {
        var dict: [TickerStrategyKey: TradeStats] = [:]

        for trade in closedTradesWithPL {
            guard let pl = trade.realizedPL else { continue }
            let key = TickerStrategyKey(ticker: trade.ticker, type: trade.type)

            var stats = dict[key] ?? TradeStats()
            if pl >= 0 {
                stats.wins += 1
            } else {
                stats.losses += 1
            }
            stats.totalPL += pl
            dict[key] = stats
        }

        // Sorted by ticker then by strategy name
        return dict.sorted { lhs, rhs in
            if lhs.key.ticker == rhs.key.ticker {
                return lhs.key.type.rawValue < rhs.key.type.rawValue
            }
            return lhs.key.ticker < rhs.key.ticker
        }
    }

    /// Heatmap: By strategy only (aggregating across tickers)
    private var statsByStrategy: [(OptionType, TradeStats)] {
        var dict: [OptionType: TradeStats] = [:]

        for trade in closedTradesWithPL {
            guard let pl = trade.realizedPL else { continue }
            var stats = dict[trade.type] ?? TradeStats()
            if pl >= 0 {
                stats.wins += 1
            } else {
                stats.losses += 1
            }
            stats.totalPL += pl
            dict[trade.type] = stats
        }

        return dict.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    /// Heatmap: By day-of-week of entry
    private struct DayKey: Hashable {
        let index: Int       // 1...7 from Calendar
        let label: String    // "Mon", "Tue", ...
    }

    private var statsByWeekday: [(DayKey, TradeStats)] {
        let calendar = Calendar.current
        var dict: [Int: TradeStats] = [:]

        for trade in closedTradesWithPL {
            guard let pl = trade.realizedPL else { continue }
            let weekday = calendar.component(.weekday, from: trade.tradeDate) // 1=Sunday...

            var stats = dict[weekday] ?? TradeStats()
            if pl >= 0 {
                stats.wins += 1
            } else {
                stats.losses += 1
            }
            stats.totalPL += pl
            dict[weekday] = stats
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        let weekdaySymbols = formatter.shortWeekdaySymbols ?? ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

        return dict
            .sorted { $0.key < $1.key }
            .map { (weekdayIndex, stats) in
                // Calendar weekday is 1-based; DateFormatter arrays are 0-based
                let label = weekdaySymbols[(weekdayIndex - 1 + weekdaySymbols.count) % weekdaySymbols.count]
                let key = DayKey(index: weekdayIndex, label: label)
                return (key, stats)
            }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSummaryCard
                tickerStrategyHeatmapCard
                strategyHeatmapCard
                weekdayHeatmapCard
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Cards

    private var headerSummaryCard: some View {
        let total = closedTradesWithPL.count
        let wins = closedTradesWithPL.filter { ($0.realizedPL ?? 0) >= 0 }.count
        let losses = total - wins
        let totalPL = closedTradesWithPL.compactMap(\.realizedPL).reduce(0, +)
        let winRate = total > 0 ? Double(wins) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 8) {
            Text("Trade Performance Heatmap")
                .font(.title3.bold())

            Text("These views help answer questions like “My PUTs on NVDA are 80% winners, but my CALLs lose 40%.”")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Closed trades")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(total)")
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Win rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f%%", winRate * 100))
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Realized P&L")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalPL, format: .currency(code: "USD"))
                        .font(.headline)
                        .foregroundColor(totalPL >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    /// Card: By ticker + strategy
    private var tickerStrategyHeatmapCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Ticker & Strategy")
                .font(.headline)

            if statsByTickerAndStrategy.isEmpty {
                Text("No closed trades yet. As you close trades, this view will show performance by ticker and strategy.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(statsByTickerAndStrategy, id: \.0) { key, stats in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(key.ticker) – \(key.type.rawValue)")
                                    .font(.subheadline)
                                Text("\(stats.wins) wins / \(stats.losses) losses")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(stats.winRatePercentText)
                                    .font(.subheadline.bold())
                                Text(stats.totalPL, format: .currency(code: "USD"))
                                    .font(.caption)
                                    .foregroundColor(stats.totalPL >= 0 ? .green : .red)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(heatmapColor(for: stats.winRate))
                            )
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    /// Card: By strategy only
    private var strategyHeatmapCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Strategy")
                .font(.headline)

            if statsByStrategy.isEmpty {
                Text("Once you have more closed trades, you’ll see how PUTs vs CALLs vs CSPs perform overall.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(statsByStrategy, id: \.0) { type, stats in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.rawValue)
                                    .font(.subheadline)
                                Text("\(stats.wins) wins / \(stats.losses) losses")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(stats.winRatePercentText)
                                    .font(.subheadline.bold())
                                Text(stats.totalPL, format: .currency(code: "USD"))
                                    .font(.caption)
                                    .foregroundColor(stats.totalPL >= 0 ? .green : .red)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(heatmapColor(for: stats.winRate))
                            )
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    /// Card: By day of week
    private var weekdayHeatmapCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Day of Week (Entry)")
                .font(.headline)

            if statsByWeekday.isEmpty {
                Text("When you log more trades, this will show which days of the week you tend to perform best.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(statsByWeekday, id: \.0) { key, stats in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key.label)
                                    .font(.subheadline)
                                Text("\(stats.wins) wins / \(stats.losses) losses")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(stats.winRatePercentText)
                                    .font(.subheadline.bold())
                                Text(stats.totalPL, format: .currency(code: "USD"))
                                    .font(.caption)
                                    .foregroundColor(stats.totalPL >= 0 ? .green : .red)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(heatmapColor(for: stats.winRate))
                            )
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Helpers

    private func heatmapColor(for winRate: Double) -> Color {
        switch winRate {
        case 0.7...:
            return Color.green.opacity(0.18)
        case 0.5...:
            return Color.yellow.opacity(0.18)
        case 0.001...:
            return Color.red.opacity(0.18)
        default:
            return Color.gray.opacity(0.12)
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsTabView(profiles: ClientProfile.demoProfiles())
    }
}
