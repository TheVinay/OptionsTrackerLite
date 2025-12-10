import SwiftUI

// Simple per-client expiration calendar.
// Shows a month grid with risk-colored dots for days that have expirations.
// Tap a day to see trades expiring on that date.

struct ClientCalendarView: View {
    let profile: ClientProfile

    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var selectedDayTrades: [Trade] = []
    @State private var showDaySheet = false

    private let calendar = Calendar.current

    // MARK: - Computed helpers

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth)
    }

    /// All trades for this client.
    private var trades: [Trade] {
        profile.trades
    }

    /// Map of "day" (startOfDay) -> trades expiring that day.
    private var expirationsByDay: [Date: [Trade]] {
        var dict: [Date: [Trade]] = [:]
        for trade in trades {
            let key = calendar.startOfDay(for: trade.expirationDate)
            dict[key, default: []].append(trade)
        }
        return dict
    }

    /// All dates to show in the grid for the current month, including leading/trailing days.
    private var monthGridDays: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let firstWeekdayIndex = (firstWeekday - calendar.firstWeekday + 7) % 7
        let leadingDays = firstWeekdayIndex
        let totalDays = leadingDays + range.count
        let rows = Int(ceil(Double(totalDays) / 7.0))

        guard let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: firstOfMonth) else {
            return []
        }

        return (0..<(rows * 7)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: gridStart)
        }
    }

    private func isInDisplayedMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    /// Risk status for a single trade based on days to expiry (same thresholds as TradeDetailView).
    private enum SimpleRiskStatus {
        case safe
        case watch
        case critical
    }

    private func riskStatus(for trade: Trade) -> SimpleRiskStatus {
        let daysToExpiry = calendar.dateComponents([.day], from: Date(), to: trade.expirationDate).day ?? 0
        if daysToExpiry <= 7 {
            return .critical
        } else if daysToExpiry <= 14 {
            return .watch
        } else {
            return .safe
        }
    }

    /// Combine statuses for a given day: red wins over yellow, yellow over green.
    private func riskColor(for trades: [Trade]) -> Color {
        var hasCritical = false
        var hasWatch = false

        for trade in trades {
            switch riskStatus(for: trade) {
            case .critical: hasCritical = true
            case .watch: hasWatch = true
            case .safe: break
            }
        }

        if hasCritical {
            return Color(.systemRed)
        } else if hasWatch {
            return Color(.systemYellow)
        } else {
            return Color(.systemGreen)
        }
    }

    private func trades(on date: Date) -> [Trade] {
        let key = calendar.startOfDay(for: date)
        return expirationsByDay[key] ?? []
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            weekDayHeader
            monthGrid
            upcomingSummary
        }
        .sheet(isPresented: $showDaySheet) {
            DayDetailSheet(
                date: selectedDate,
                trades: selectedDayTrades,
                clientName: profile.name
            )
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(monthTitle)
                .font(.headline)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }

    private var weekDayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols   // Sun Mon Tue...
        return HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }

    private var monthGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(monthGridDays, id: \.self) { date in
                let dayNumber = calendar.component(.day, from: date)
                let inMonth = isInDisplayedMonth(date)
                let dayTrades = trades(on: date)

                Button {
                    if !dayTrades.isEmpty {
                        selectedDate = date
                        selectedDayTrades = dayTrades
                        showDaySheet = true
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text("\(dayNumber)")
                            .font(.subheadline)
                            .foregroundColor(inMonth ? .primary : .secondary.opacity(0.4))

                        if !dayTrades.isEmpty {
                            Circle()
                                .fill(riskColor(for: dayTrades))
                                .frame(width: 8, height: 8)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private var upcomingSummary: some View {
        let today = calendar.startOfDay(for: Date())
        let sevenDaysOut = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let thirtyDaysOut = calendar.date(byAdding: .day, value: 30, to: today) ?? today

        let next7 = trades.filter {
            let d = calendar.startOfDay(for: $0.expirationDate)
            return d >= today && d <= sevenDaysOut
        }

        let next30 = trades.filter {
            let d = calendar.startOfDay(for: $0.expirationDate)
            return d >= today && d <= thirtyDaysOut
        }

        return VStack(alignment: .leading, spacing: 6) {
            Text("Upcoming")
                .font(.headline)
                .padding(.horizontal)

            HStack {
                Text("This week")
                Spacer()
                Text("\(next7.count) expirations")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .padding(.horizontal)

            HStack {
                Text("Next 30 days")
                Spacer()
                Text("\(next30.count) expirations")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .padding(.horizontal)
        }
        .padding(.top)
    }

    // MARK: - Helpers

    private func changeMonth(by offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

// MARK: - Day detail sheet (per client)

private struct DayDetailSheet: View {
    let date: Date
    let trades: [Trade]
    let clientName: String

    private let calendar = Calendar.current
    @Environment(\.dismiss) private var dismiss

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                if trades.isEmpty {
                    ContentUnavailableView(
                        "No expirations",
                        systemImage: "calendar",
                        description: Text("There are no positions expiring on this date.")
                    )
                } else {
                    ForEach(trades) { trade in
                        NavigationLink {
                            TradeDetailView(trade: trade, clientName: clientName)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(trade.ticker) \(trade.type.rawValue)")
                                    .font(.headline)

                                Text("Expiry: \(trade.expirationDate, format: .dateTime.month().day().year())")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let realized = trade.realizedPL, trade.isClosed {
                                    Text("Realized P&L: \(realized, format: .currency(code: "USD"))")
                                        .font(.subheadline)
                                        .foregroundColor(realized >= 0 ? .green : .red)
                                } else {
                                    Text(trade.isClosed ? "Closed" : "Open")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
