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
    @State private var showActiveOnly = true

    private var allTrades: [Trade] {
        profiles.flatMap(\.trades)
    }

    private var filteredTrades: [Trade] {
        let base = allTrades.sorted { $0.tradeDate > $1.tradeDate }
        return showActiveOnly ? base.filter { !$0.isClosed } : base
    }

    private var totalRealizedPL: Double {
        allTrades.compactMap { $0.realizedPL }.reduce(0, +)
    }

    var body: some View {
        VStack {
            Picker("Section", selection: $selectedSection) {
                ForEach(AllTradesSection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding([.top, .horizontal])

            contentForSelectedSection
        }
        .navigationTitle("All Trades")
    }

    // MARK: - Section switcher

    @ViewBuilder
    private var contentForSelectedSection: some View {
        switch selectedSection {
        case .trades:
            tradesSection
        case .calendar:
            calendarSection
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

    // MARK: - Trades section

    @ViewBuilder
    private var tradesSection: some View {
        VStack(spacing: 8) {
            summaryCard

            Toggle(isOn: $showActiveOnly) {
                Text(showActiveOnly ? "Showing Active Only" : "Showing All")
            }
            .padding(.horizontal)
            .padding(.bottom, 4)

            if filteredTrades.isEmpty {
                ContentUnavailableView(
                    "No trades yet",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Once you log trades in any portfolio, they will appear here.")
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

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SUMMARY")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Clients:")
                    Spacer()
                    Text("\(profiles.count)")
                }
                HStack {
                    Text("Total Trades:")
                    Spacer()
                    Text("\(allTrades.count)")
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

    // MARK: - Calendar section (global)

    private var calendarSection: some View {
        ScrollView {
            AllTradesCalendarView(profiles: profiles)
                .padding(.top)
        }
    }

    // MARK: - Coming soon

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

// MARK: - Global calendar view (all clients)

private struct CalendarEvent {
    let trade: Trade
    let clientName: String
}

private struct AllTradesCalendarView: View {
    let profiles: [ClientProfile]

    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var selectedEvents: [CalendarEvent] = []
    @State private var showDaySheet = false

    private let calendar = Calendar.current

    // All events: each trade plus its client name.
    private var events: [CalendarEvent] {
        profiles.flatMap { profile in
            profile.trades.map { trade in
                CalendarEvent(trade: trade, clientName: profile.name)
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var expirationsByDay: [Date: [CalendarEvent]] {
        var dict: [Date: [CalendarEvent]] = [:]
        for event in events {
            let key = calendar.startOfDay(for: event.trade.expirationDate)
            dict[key, default: []].append(event)
        }
        return dict
    }

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

    private func riskColor(for events: [CalendarEvent]) -> Color {
        var hasCritical = false
        var hasWatch = false

        for event in events {
            switch riskStatus(for: event.trade) {
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

    private func events(on date: Date) -> [CalendarEvent] {
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
            GlobalDayDetailSheet(
                date: selectedDate,
                events: selectedEvents
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
        let symbols = calendar.shortWeekdaySymbols
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
                let dayEvents = events(on: date)

                Button {
                    if !dayEvents.isEmpty {
                        selectedDate = date
                        selectedEvents = dayEvents
                        showDaySheet = true
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text("\(dayNumber)")
                            .font(.subheadline)
                            .foregroundColor(inMonth ? .primary : .secondary.opacity(0.4))

                        if !dayEvents.isEmpty {
                            Circle()
                                .fill(riskColor(for: dayEvents))
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

        let next7 = events.filter {
            let d = calendar.startOfDay(for: $0.trade.expirationDate)
            return d >= today && d <= sevenDaysOut
        }

        let next30 = events.filter {
            let d = calendar.startOfDay(for: $0.trade.expirationDate)
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

// MARK: - Global day sheet (all clients)

private struct GlobalDayDetailSheet: View {
    let date: Date
    let events: [CalendarEvent]

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
                if events.isEmpty {
                    ContentUnavailableView(
                        "No expirations",
                        systemImage: "calendar",
                        description: Text("There are no positions expiring on this date.")
                    )
                } else {
                    ForEach(events.indices, id: \.self) { index in
                        let event = events[index]
                        NavigationLink {
                            TradeDetailView(trade: event.trade, clientName: event.clientName)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.clientName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("\(event.trade.ticker) \(event.trade.type.rawValue)")
                                    .font(.headline)

                                Text("Expiry: \(event.trade.expirationDate, format: .dateTime.month().day().year())")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let realized = event.trade.realizedPL, event.trade.isClosed {
                                    Text("Realized P&L: \(realized, format: .currency(code: "USD"))")
                                        .font(.subheadline)
                                        .foregroundColor(realized >= 0 ? .green : .red)
                                } else {
                                    Text(event.trade.isClosed ? "Closed" : "Open")
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
