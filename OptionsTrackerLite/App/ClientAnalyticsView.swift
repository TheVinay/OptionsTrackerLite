import SwiftUI
import Charts

// MARK: - Client Analytics View

struct ClientAnalyticsView: View {
    @Bindable var profile: ClientProfile
    
    @State private var selectedTimeframe: Timeframe = .all
    @State private var showingDetailedStats = false
    
    enum Timeframe: String, CaseIterable, Identifiable {
        case week = "1W"
        case month = "1M"
        case quarter = "3M"
        case year = "1Y"
        case all = "All"
        
        var id: String { rawValue }
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            case .all: return nil
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredTrades: [Trade] {
        let closedTrades = profile.trades.filter { $0.isClosed && $0.realizedPL != nil }
        
        guard let days = selectedTimeframe.days else { return closedTrades }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return closedTrades.filter { $0.tradeDate >= cutoffDate }
    }
    
    private var stats: PerformanceStats {
        calculateStats(from: filteredTrades)
    }
    
    private var equityCurveData: [EquityPoint] {
        calculateEquityCurve(from: filteredTrades)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Timeframe Picker
                timeframePicker
                
                if filteredTrades.isEmpty {
                    emptyStateView
                } else {
                    // Performance Overview Cards
                    performanceOverviewSection
                    
                    // Equity Curve
                    equityCurveSection
                    
                    // Strategy Breakdown
                    strategyBreakdownSection
                    
                    // Win Rate Chart
                    winRateSection
                    
                    // Monthly Calendar Heatmap
                    monthlyHeatmapSection
                    
                    // Risk Metrics
                    riskMetricsSection
                    
                    // Best & Worst Trades
                    topTradesSection
                    
                    // Time Analysis
                    timeAnalysisSection
                }
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var timeframePicker: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Closed Trades")
                .font(.headline)
            
            Text("Close some trades to see analytics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var performanceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Overview")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Total P&L",
                    value: stats.totalPL.formatted(.currency(code: "USD")),
                    icon: "dollarsign.circle.fill",
                    color: stats.totalPL >= 0 ? .green : .red
                )
                
                StatCard(
                    title: "Win Rate",
                    value: stats.winRatePercentage,
                    icon: "percent",
                    color: .blue
                )
                
                StatCard(
                    title: "Avg Win",
                    value: stats.avgWin.formatted(.currency(code: "USD")),
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Avg Loss",
                    value: stats.avgLoss.formatted(.currency(code: "USD")),
                    icon: "arrow.down.circle.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Total Trades",
                    value: "\(stats.totalTrades)",
                    icon: "chart.bar",
                    color: .orange
                )
                
                StatCard(
                    title: "Expectancy",
                    value: stats.expectancy.formatted(.currency(code: "USD")),
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var equityCurveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Equity Curve")
                    .font(.headline)
                
                HelpButton(
                    title: "What is Equity Curve?",
                    message: "Shows your cumulative profit/loss over time. An upward trend indicates profitable trading."
                )
                
                Spacer()
            }
            
            if equityCurveData.count >= 2 {
                Chart(equityCurveData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("P&L", point.cumulativePL)
                    )
                    .foregroundStyle(.blue.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("P&L", point.cumulativePL)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                Text("Need at least 2 trades to show equity curve")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var strategyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strategy Performance")
                .font(.headline)
            
            ForEach(stats.strategyStats.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { strategy, stratStats in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(strategy.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(stratStats.totalPL.formatted(.currency(code: "USD")))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(stratStats.totalPL >= 0 ? .green : .red)
                    }
                    
                    HStack(spacing: 16) {
                        Label("\(stratStats.wins)/\(stratStats.totalTrades)", systemImage: "chart.bar")
                        Label("\(stratStats.winRatePercentage)", systemImage: "percent")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    ProgressView(value: Double(stratStats.wins), total: Double(stratStats.totalTrades))
                        .tint(stratStats.totalPL >= 0 ? .green : .red)
                }
                .padding()
                .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private var winRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Win/Loss Distribution")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(stats.wins)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    Text("Wins")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(stats.losses)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                    Text("Losses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var monthlyHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Monthly Performance")
                    .font(.headline)
                
                HelpButton(
                    title: "Monthly Heatmap",
                    message: "Shows which months were most profitable. Darker green = more profit."
                )
            }
            
            let monthlyData = calculateMonthlyPerformance(from: filteredTrades)
            
            if !monthlyData.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(monthlyData, id: \.month) { data in
                        VStack(spacing: 4) {
                            Text(data.monthName)
                                .font(.caption2)
                                .fontWeight(.medium)
                            
                            Text(data.pl.formatted(.currency(code: "USD")))
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(data.color.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(data.color, lineWidth: 1)
                        }
                    }
                }
            } else {
                Text("No monthly data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var riskMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Risk Metrics")
                    .font(.headline)
                
                HelpButton(
                    title: "Risk Metrics",
                    message: "Max Drawdown: Largest peak-to-trough decline.\nProfit Factor: Gross profit / Gross loss."
                )
            }
            
            VStack(spacing: 12) {
                HStack {
                    Label("Max Drawdown", systemImage: "arrow.down.to.line")
                        .font(.subheadline)
                    Spacer()
                    Text(stats.maxDrawdown.formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
                
                Divider()
                
                HStack {
                    Label("Profit Factor", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.2f", stats.profitFactor))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(stats.profitFactor >= 1.5 ? .green : .orange)
                }
                
                Divider()
                
                HStack {
                    Label("Largest Win", systemImage: "trophy.fill")
                        .font(.subheadline)
                    Spacer()
                    Text(stats.largestWin.formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                
                Divider()
                
                HStack {
                    Label("Largest Loss", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                    Spacer()
                    Text(stats.largestLoss.formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var topTradesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Trades")
                .font(.headline)
            
            let sortedByPL = filteredTrades.sorted { ($0.realizedPL ?? 0) > ($1.realizedPL ?? 0) }
            let topWinners = Array(sortedByPL.prefix(3))
            let topLosers = Array(sortedByPL.suffix(3).reversed())
            
            if !topWinners.isEmpty {
                Text("Best Trades")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                
                ForEach(topWinners, id: \.id) { trade in
                    MiniTradeCard(trade: trade)
                }
            }
            
            if !topLosers.isEmpty {
                Text("Worst Trades")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
                
                ForEach(topLosers, id: \.id) { trade in
                    MiniTradeCard(trade: trade)
                }
            }
        }
    }
    
    private var timeAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Time Analysis")
                    .font(.headline)
                
                HelpButton(
                    title: "Time Analysis",
                    message: "Shows average holding period and days to expiration statistics."
                )
            }
            
            VStack(spacing: 12) {
                HStack {
                    Label("Avg Days Held", systemImage: "calendar")
                        .font(.subheadline)
                    Spacer()
                    Text("\(stats.avgDaysHeld)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                HStack {
                    Label("Avg DTE at Entry", systemImage: "clock")
                        .font(.subheadline)
                    Spacer()
                    Text("\(stats.avgDTE)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    // MARK: - Calculation Methods
    
    private func calculateStats(from trades: [Trade]) -> PerformanceStats {
        var stats = PerformanceStats()
        
        stats.totalTrades = trades.count
        
        var wins: [Double] = []
        var losses: [Double] = []
        var strategyBreakdown: [OptionType: StrategyStats] = [:]
        var daysHeld: [Int] = []
        var daysToExpiration: [Int] = []
        
        for trade in trades {
            guard let pl = trade.realizedPL else { continue }
            
            stats.totalPL += pl
            
            if pl > 0 {
                stats.wins += 1
                wins.append(pl)
                stats.largestWin = max(stats.largestWin, pl)
            } else {
                stats.losses += 1
                losses.append(abs(pl))
                stats.largestLoss = min(stats.largestLoss, pl)
            }
            
            // Strategy breakdown
            var stratStat = strategyBreakdown[trade.type] ?? StrategyStats()
            stratStat.totalTrades += 1
            stratStat.totalPL += pl
            if pl > 0 {
                stratStat.wins += 1
            }
            strategyBreakdown[trade.type] = stratStat
            
            // Time analysis
            let days = Calendar.current.dateComponents([.day], from: trade.tradeDate, to: Date()).day ?? 0
            daysHeld.append(days)
            
            let dte = Calendar.current.dateComponents([.day], from: trade.tradeDate, to: trade.expirationDate).day ?? 0
            daysToExpiration.append(dte)
        }
        
        stats.avgWin = wins.isEmpty ? 0 : wins.reduce(0, +) / Double(wins.count)
        stats.avgLoss = losses.isEmpty ? 0 : -losses.reduce(0, +) / Double(losses.count)
        
        // Expectancy
        if stats.totalTrades > 0 {
            let winRate = Double(stats.wins) / Double(stats.totalTrades)
            let lossRate = 1 - winRate
            stats.expectancy = (winRate * stats.avgWin) + (lossRate * stats.avgLoss)
        }
        
        // Profit factor
        let grossProfit = wins.reduce(0, +)
        let grossLoss = losses.reduce(0, +)
        stats.profitFactor = grossLoss > 0 ? grossProfit / grossLoss : 0
        
        // Max drawdown
        let sortedByDate = trades.sorted { $0.tradeDate < $1.tradeDate }
        var runningTotal: Double = 0
        var peak: Double = 0
        var maxDD: Double = 0
        
        for trade in sortedByDate {
            guard let pl = trade.realizedPL else { continue }
            runningTotal += pl
            peak = max(peak, runningTotal)
            let drawdown = peak - runningTotal
            maxDD = max(maxDD, drawdown)
        }
        stats.maxDrawdown = -maxDD
        
        stats.strategyStats = strategyBreakdown
        
        // Time stats
        stats.avgDaysHeld = daysHeld.isEmpty ? 0 : daysHeld.reduce(0, +) / daysHeld.count
        stats.avgDTE = daysToExpiration.isEmpty ? 0 : daysToExpiration.reduce(0, +) / daysToExpiration.count
        
        return stats
    }
    
    private func calculateEquityCurve(from trades: [Trade]) -> [EquityPoint] {
        let sorted = trades.sorted { $0.tradeDate < $1.tradeDate }
        var cumulative: Double = 0
        var points: [EquityPoint] = []
        
        for trade in sorted {
            guard let pl = trade.realizedPL else { continue }
            cumulative += pl
            points.append(EquityPoint(date: trade.tradeDate, cumulativePL: cumulative))
        }
        
        return points
    }
    
    private func calculateMonthlyPerformance(from trades: [Trade]) -> [MonthlyData] {
        let calendar = Calendar.current
        var monthlyPL: [String: Double] = [:]
        
        for trade in trades {
            guard let pl = trade.realizedPL else { continue }
            let components = calendar.dateComponents([.year, .month], from: trade.tradeDate)
            if let year = components.year, let month = components.month {
                let key = "\(year)-\(String(format: "%02d", month))"
                monthlyPL[key, default: 0] += pl
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        
        return monthlyPL.map { key, pl in
            let components = key.split(separator: "-")
            let monthName = components.count == 2 ? "\(components[1])/\(String(components[0].suffix(2)))" : key
            let color: Color = pl >= 0 ? .green : .red
            return MonthlyData(month: key, monthName: monthName, pl: pl, color: color)
        }.sorted { $0.month > $1.month }
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MiniTradeCard: View {
    let trade: Trade
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.ticker)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(trade.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text((trade.realizedPL ?? 0).formatted(.currency(code: "USD")))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle((trade.realizedPL ?? 0) >= 0 ? .green : .red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Data Structures

private struct PerformanceStats {
    var totalTrades = 0
    var wins = 0
    var losses = 0
    var totalPL: Double = 0
    var avgWin: Double = 0
    var avgLoss: Double = 0
    var expectancy: Double = 0
    var maxDrawdown: Double = 0
    var profitFactor: Double = 0
    var largestWin: Double = 0
    var largestLoss: Double = 0
    var avgDaysHeld = 0
    var avgDTE = 0
    var strategyStats: [OptionType: StrategyStats] = [:]
    
    var winRatePercentage: String {
        guard totalTrades > 0 else { return "0%" }
        let rate = Double(wins) / Double(totalTrades) * 100
        return String(format: "%.1f%%", rate)
    }
}

private struct StrategyStats {
    var totalTrades = 0
    var wins = 0
    var totalPL: Double = 0
    
    var winRatePercentage: String {
        guard totalTrades > 0 else { return "0%" }
        let rate = Double(wins) / Double(totalTrades) * 100
        return String(format: "%.0f%%", rate)
    }
}

private struct EquityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let cumulativePL: Double
}

private struct MonthlyData {
    let month: String
    let monthName: String
    let pl: Double
    let color: Color
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ClientAnalyticsView(profile: ClientProfile(name: "Demo"))
    }
}
