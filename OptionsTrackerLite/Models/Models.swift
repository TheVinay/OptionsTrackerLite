import Foundation

// MARK: - Option types

enum OptionType: String, CaseIterable, Identifiable {
    case call = "Call"
    case put = "Put"
    case coveredCall = "Covered Call"
    case cashSecuredPut = "Cash-Secured Put"

    var id: String { rawValue }
}

// MARK: - Trade notes (for detail view timeline, optional)

struct TradeNote: Identifiable, Hashable {
    let id: UUID
    var date: Date
    var text: String

    init(id: UUID = UUID(), date: Date = Date(), text: String) {
        self.id = id
        self.date = date
        self.text = text
    }
}

// MARK: - Trade model

struct Trade: Identifiable, Hashable {
    let id: UUID

    var ticker: String
    var type: OptionType

    var tradeDate: Date
    var expirationDate: Date

    /// Entry price per contract
    var premium: Double

    /// Number of contracts
    var quantity: Int

    /// Total premium in dollars (premium * 100 * quantity)
    var totalPremium: Double

    /// Strike price, if applicable
    var strike: Double?

    /// Stock price at entry (used for CSP / CC / calls / puts)
    var underlyingPriceAtEntry: Double?

    /// For future use; some UIs may compute mark-to-market with this.
    var currentStockPrice: Double?

    /// Whether this position is closed
    var isClosed: Bool

    /// Realized P&L in dollars (optional until closed)
    var realizedPL: Double?

    /// If this is just a simulation / idea
    var simulated: Bool

    /// Whether to send alerts for this trade
    var sendNotifications: Bool

    /// Optional rule-of-thumb risk management fields
    var stopLossPercent: Double?
    var targetPercent: Double?

    /// Light-weight tagging
    var tags: [String]

    /// Simple entry/exit criteria text (used in detail view)
    var entryCriteria: String?
    var exitCriteria: String?

    /// Notes timeline
    var notes: [TradeNote]

    // MARK: - Initializer expected by NewTradeView

    init(
        id: UUID = UUID(),
        ticker: String,
        type: OptionType,
        tradeDate: Date,
        expirationDate: Date,
        premium: Double,
        quantity: Int,
        totalPremium: Double? = nil,
        strike: Double? = nil,
        underlyingPriceAtEntry: Double? = nil,
        currentStockPrice: Double? = nil,
        isClosed: Bool = false,
        realizedPL: Double? = nil,
        simulated: Bool = false,
        sendNotifications: Bool = true,
        stopLossPercent: Double? = nil,
        targetPercent: Double? = nil,
        tags: [String] = [],
        entryCriteria: String? = nil,
        exitCriteria: String? = nil,
        notes: [TradeNote] = []
    ) {
        self.id = id
        self.ticker = ticker
        self.type = type
        self.tradeDate = tradeDate
        self.expirationDate = expirationDate
        self.premium = premium
        self.quantity = quantity
        self.totalPremium = totalPremium ?? premium * 100 * Double(quantity)
        self.strike = strike
        self.underlyingPriceAtEntry = underlyingPriceAtEntry
        self.currentStockPrice = currentStockPrice
        self.isClosed = isClosed
        self.realizedPL = realizedPL
        self.simulated = simulated
        self.sendNotifications = sendNotifications
        self.stopLossPercent = stopLossPercent
        self.targetPercent = targetPercent
        self.tags = tags
        self.entryCriteria = entryCriteria
        self.exitCriteria = exitCriteria
        self.notes = notes
    }
}

// Convenience computed properties used in row / detail views
extension Trade {
    var statusText: String {
        isClosed ? "Closed" : "Open"
    }

    var statusColorName: String {
        isClosed ? "StatusClosed" : "StatusOpen"
    }

    var isWinning: Bool {
        (realizedPL ?? 0) >= 0
    }
}

// MARK: - Client profile

struct ClientProfile: Identifiable {
    let id: UUID

    var name: String
    var email: String?
    var phone: String?
    var address: String?
    var notes: String?

    var createdAt: Date
    var lastModified: Date

    /// What types of strategies this client is interested in
    var interestedTypes: Set<OptionType>

    /// Trades for this client
    var trades: [Trade]

    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        interestedTypes: Set<OptionType> = [],
        trades: [Trade] = []
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.notes = notes
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.interestedTypes = interestedTypes
        self.trades = trades
    }
}

// Helper stats for list screens
extension ClientProfile {
    var openTrades: [Trade] { trades.filter { !$0.isClosed } }
    var closedTrades: [Trade] { trades.filter { $0.isClosed } }

    var openCount: Int { openTrades.count }
    var closedCount: Int { closedTrades.count }

    var realizedPL: Double {
        trades.compactMap { $0.realizedPL }.reduce(0, +)
    }

    var displayInitials: String {
        let parts = name
            .split(separator: " ")
            .map { String($0.prefix(1)) }
        return parts.prefix(2).joined()
    }
}

// MARK: - Demo data for previews

extension ClientProfile {
    static func demoProfiles() -> [ClientProfile] {
        let calendar = Calendar.current
        let today = Date()

        // Helper for dates
        func daysFromToday(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: days, to: today) ?? today
        }

        // Alice – one open covered call
        let aliceTrade = Trade(
            ticker: "AAPL",
            type: .coveredCall,
            tradeDate: daysFromToday(-3),
            expirationDate: daysFromToday(14),
            premium: 1.50,
            quantity: 1,
            strike: 210,
            underlyingPriceAtEntry: 198,
            isClosed: false,
            realizedPL: nil,
            sendNotifications: true,
            stopLossPercent: 50,
            targetPercent: 25,
            tags: ["CC"],
            entryCriteria: "Only sell calls when IVR > 30.",
            exitCriteria: "Close at 50% max profit.",
            notes: [
                TradeNote(text: "Sold call after strong run-up."),
                TradeNote(text: "Watching resistance near 210.")
            ]
        )

        // Bob – one closed CSP
        let bobTrade = Trade(
            ticker: "TSLA",
            type: .cashSecuredPut,
            tradeDate: daysFromToday(-10),
            expirationDate: daysFromToday(30),
            premium: 2.30,
            quantity: 1,
            strike: 190,
            underlyingPriceAtEntry: 205,
            isClosed: true,
            realizedPL: -230.0,
            sendNotifications: true,
            stopLossPercent: 200,
            targetPercent: 50,
            tags: ["CSP"],
            entryCriteria: "Only CSP when IVR > 40.",
            exitCriteria: "Roll if tested or 21 DTE.",
            notes: [
                TradeNote(text: "Aggressive CSP on TSLA; size small."),
                TradeNote(text: "Stock sold off hard; took loss.")
            ]
        )

        // GI Jane – example call
        let janeTrade = Trade(
            ticker: "NVDA",
            type: .call,
            tradeDate: daysFromToday(-1),
            expirationDate: daysFromToday(7),
            premium: 3.40,
            quantity: 2,
            strike: 550,
            underlyingPriceAtEntry: 548.17,
            isClosed: false,
            realizedPL: nil,
            sendNotifications: false,
            stopLossPercent: 50,
            targetPercent: 100,
            tags: ["Call"],
            entryCriteria: "Momentum breakout above 50-day MA.",
            exitCriteria: "Take profit at 100% or cut at 50% loss."
        )

        let alice = ClientProfile(
            name: "Alice",
            email: "alice@example.com",
            createdAt: daysFromToday(-60),
            lastModified: daysFromToday(-1),
            interestedTypes: [.coveredCall, .call],
            trades: [aliceTrade]
        )

        let bob = ClientProfile(
            name: "Bob",
            email: "bob@example.com",
            createdAt: daysFromToday(-90),
            lastModified: daysFromToday(-5),
            interestedTypes: [.cashSecuredPut, .put],
            trades: [bobTrade]
        )

        let giJane = ClientProfile(
            name: "GI Jane",
            email: "jane@example.com",
            createdAt: daysFromToday(-30),
            lastModified: daysFromToday(-1),
            interestedTypes: [.call, .put],
            trades: [janeTrade]
        )

        return [alice, bob, giJane]
    }
}
