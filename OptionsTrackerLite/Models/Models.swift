import Foundation

import SwiftUI
import SwiftData

// MARK: - Option types

enum OptionType: String, CaseIterable, Identifiable, Hashable, Codable {
    case call = "Call"
    case put = "Put"
    case coveredCall = "Covered Call"
    case cashSecuredPut = "Cash-Secured Put"

    var id: String { rawValue }
}

// MARK: - Trade notes (for detail view timeline, optional)

@Model
final class TradeNote {
    var id: UUID
    var date: Date
    var text: String
    
    var trade: Trade?

    init(id: UUID = UUID(), date: Date = Date(), text: String) {
        self.id = id
        self.date = date
        self.text = text
    }
}

// Hashable conformance for backwards compatibility
extension TradeNote: Hashable {
    static func == (lhs: TradeNote, rhs: TradeNote) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Trade model

@Model
final class Trade {
    var id: UUID
    var ticker: String
    var typeRawValue: String
    var tradeDate: Date
    var expirationDate: Date
    var premium: Double
    var quantity: Int
    var totalPremium: Double
    var strike: Double?
    var underlyingPriceAtEntry: Double?
    var currentStockPrice: Double?
    var isClosed: Bool
    var realizedPL: Double?
    var simulated: Bool
    var sendNotifications: Bool
    var stopLossPercent: Double?
    var targetPercent: Double?
    var tags: [String]
    var entryCriteria: String?
    var exitCriteria: String?
    
    // NEW: Commission tracking
    var commissionOpen: Double?
    var commissionClose: Double?
    
    @Relationship(deleteRule: .cascade, inverse: \TradeNote.trade)
    var notes: [TradeNote]
    
    var profile: ClientProfile?
    
    // Computed property for type
    var type: OptionType {
        get { OptionType(rawValue: typeRawValue) ?? .call }
        set { typeRawValue = newValue.rawValue }
    }
    
    // NEW: Total commission
    var totalCommission: Double {
        (commissionOpen ?? 0) + (commissionClose ?? 0)
    }
    
    // NEW: Net P&L after commissions
    var netPL: Double? {
        guard let realizedPL = realizedPL else { return nil }
        return realizedPL - totalCommission
    }

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
        notes: [TradeNote] = [],
        commissionOpen: Double? = nil,
        commissionClose: Double? = nil
    ) {
        self.id = id
        self.ticker = ticker
        self.typeRawValue = type.rawValue
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
        self.commissionOpen = commissionOpen
        self.commissionClose = commissionClose
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

// Hashable conformance for backwards compatibility
extension Trade: Hashable {
    static func == (lhs: Trade, rhs: Trade) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Client profile

@Model
final class ClientProfile {
    var id: UUID
    var name: String
    var email: String?
    var phone: String?
    var address: String?
    var notes: String?
    var createdAt: Date
    var lastModified: Date
    var interestedTypesRaw: [String]
    
    @Relationship(deleteRule: .cascade, inverse: \Trade.profile)
    var trades: [Trade]
    
    var interestedTypes: Set<OptionType> {
        get { Set(interestedTypesRaw.compactMap { OptionType(rawValue: $0) }) }
        set { interestedTypesRaw = Array(newValue.map { $0.rawValue }) }
    }

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
        self.interestedTypesRaw = Array(interestedTypes.map { $0.rawValue })
        self.trades = trades
    }
}

// MARK: - Helper stats for list screens

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

// MARK: - Demo data for previews + analytics heatmap

extension ClientProfile {
    static func demoProfiles() -> [ClientProfile] {
        let calendar = Calendar.current
        let today = Date()

        func daysFromToday(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: days, to: today) ?? today
        }

        // Helper to create a closed trade
        func closedTrade(
            ticker: String,
            type: OptionType,
            daysAgo: Int,
            dte: Int,
            premium: Double,
            quantity: Int,
            strike: Double,
            entryPrice: Double,
            currentPrice: Double,
            realizedPL: Double
        ) -> Trade {
            Trade(
                ticker: ticker,
                type: type,
                tradeDate: daysFromToday(-daysAgo),
                expirationDate: daysFromToday(dte),
                premium: premium,
                quantity: quantity,
                strike: strike,
                underlyingPriceAtEntry: entryPrice,
                currentStockPrice: currentPrice,
                isClosed: true,
                realizedPL: realizedPL,
                simulated: false,
                sendNotifications: true,
                stopLossPercent: 50,
                targetPercent: 100,
                tags: [type.rawValue]
            )
        }

        // Helper to create an open trade
        func openTrade(
            ticker: String,
            type: OptionType,
            daysAgo: Int,
            dte: Int,
            premium: Double,
            quantity: Int,
            strike: Double,
            entryPrice: Double,
            currentPrice: Double
        ) -> Trade {
            Trade(
                ticker: ticker,
                type: type,
                tradeDate: daysFromToday(-daysAgo),
                expirationDate: daysFromToday(dte),
                premium: premium,
                quantity: quantity,
                strike: strike,
                underlyingPriceAtEntry: entryPrice,
                currentStockPrice: currentPrice,
                isClosed: false,
                realizedPL: nil,
                simulated: false,
                sendNotifications: true,
                stopLossPercent: 50,
                targetPercent: 100,
                tags: [type.rawValue]
            )
        }

        // MARK: - NVDA cluster (strong PUTs, weak CALLs)

        // NVDA PUTs: mostly winners
        let nvdaPut1 = closedTrade(
            ticker: "NVDA", type: .put,
            daysAgo: 15, dte: 5,
            premium: 3.2, quantity: 1,
            strike: 120, entryPrice: 128, currentPrice: 115,
            realizedPL: 220
        )
        let nvdaPut2 = closedTrade(
            ticker: "NVDA", type: .put,
            daysAgo: 20, dte: 10,
            premium: 2.8, quantity: 1,
            strike: 125, entryPrice: 130, currentPrice: 118,
            realizedPL: 180
        )
        let nvdaPut3 = closedTrade(
            ticker: "NVDA", type: .put,
            daysAgo: 32, dte: 2,
            premium: 3.5, quantity: 2,
            strike: 115, entryPrice: 123, currentPrice: 112,
            realizedPL: 420
        )
        let nvdaPut4 = closedTrade(
            ticker: "NVDA", type: .put,
            daysAgo: 7, dte: 14,
            premium: 2.1, quantity: 1,
            strike: 130, entryPrice: 133, currentPrice: 129,
            realizedPL: 90
        )
        let nvdaPutLoss = closedTrade(
            ticker: "NVDA", type: .put,
            daysAgo: 40, dte: 1,
            premium: 2.9, quantity: 1,
            strike: 118, entryPrice: 120, currentPrice: 130,
            realizedPL: -210
        )

        // NVDA CALLs: more losers than winners
        let nvdaCallLoss1 = closedTrade(
            ticker: "NVDA", type: .call,
            daysAgo: 10, dte: 3,
            premium: 2.0, quantity: 1,
            strike: 140, entryPrice: 135, currentPrice: 128,
            realizedPL: -160
        )
        let nvdaCallLoss2 = closedTrade(
            ticker: "NVDA", type: .call,
            daysAgo: 18, dte: 4,
            premium: 2.4, quantity: 1,
            strike: 145, entryPrice: 139, currentPrice: 132,
            realizedPL: -190
        )
        let nvdaCallLoss3 = closedTrade(
            ticker: "NVDA", type: .call,
            daysAgo: 27, dte: 2,
            premium: 3.0, quantity: 1,
            strike: 150, entryPrice: 142, currentPrice: 136,
            realizedPL: -220
        )
        let nvdaCallWin = closedTrade(
            ticker: "NVDA", type: .call,
            daysAgo: 35, dte: 5,
            premium: 1.8, quantity: 1,
            strike: 135, entryPrice: 132, currentPrice: 140,
            realizedPL: 160
        )

        // MARK: - TSLA CSP cluster (mostly winners)

        let tslaCsp1 = closedTrade(
            ticker: "TSLA", type: .cashSecuredPut,
            daysAgo: 14, dte: 7,
            premium: 2.5, quantity: 1,
            strike: 190, entryPrice: 197, currentPrice: 192,
            realizedPL: 180
        )
        let tslaCsp2 = closedTrade(
            ticker: "TSLA", type: .cashSecuredPut,
            daysAgo: 25, dte: 10,
            premium: 3.1, quantity: 1,
            strike: 185, entryPrice: 194, currentPrice: 188,
            realizedPL: 230
        )
        let tslaCsp3 = closedTrade(
            ticker: "TSLA", type: .cashSecuredPut,
            daysAgo: 5, dte: 20,
            premium: 2.0, quantity: 1,
            strike: 200, entryPrice: 205, currentPrice: 203,
            realizedPL: 90
        )
        let tslaCspLoss = closedTrade(
            ticker: "TSLA", type: .cashSecuredPut,
            daysAgo: 30, dte: 1,
            premium: 3.0, quantity: 1,
            strike: 180, entryPrice: 188, currentPrice: 170,
            realizedPL: -260
        )

        // MARK: - AAPL CALLs (mixed)

        let aaplCall1 = closedTrade(
            ticker: "AAPL", type: .call,
            daysAgo: 12, dte: 6,
            premium: 1.2, quantity: 1,
            strike: 190, entryPrice: 188, currentPrice: 194,
            realizedPL: 110
        )
        let aaplCall2 = closedTrade(
            ticker: "AAPL", type: .call,
            daysAgo: 22, dte: 3,
            premium: 1.5, quantity: 1,
            strike: 195, entryPrice: 191, currentPrice: 189,
            realizedPL: -130
        )
        let aaplCall3 = closedTrade(
            ticker: "AAPL", type: .call,
            daysAgo: 8, dte: 9,
            premium: 1.8, quantity: 1,
            strike: 192, entryPrice: 190, currentPrice: 191,
            realizedPL: 40
        )

        // MARK: - AMD PUTs (very mixed)

        let amdPut1 = closedTrade(
            ticker: "AMD", type: .put,
            daysAgo: 16, dte: 8,
            premium: 2.2, quantity: 1,
            strike: 110, entryPrice: 116, currentPrice: 109,
            realizedPL: 150
        )
        let amdPut2 = closedTrade(
            ticker: "AMD", type: .put,
            daysAgo: 28, dte: 4,
            premium: 2.0, quantity: 1,
            strike: 108, entryPrice: 112, currentPrice: 115,
            realizedPL: -170
        )

        // MARK: - Some open trades (ignored by heatmap, visible elsewhere)

        let openNvdaPut = openTrade(
            ticker: "NVDA", type: .put,
            daysAgo: 3, dte: 21,
            premium: 2.7, quantity: 1,
            strike: 125, entryPrice: 130, currentPrice: 127
        )

        let openTslaCc = openTrade(
            ticker: "TSLA", type: .coveredCall,
            daysAgo: 4, dte: 18,
            premium: 1.9, quantity: 1,
            strike: 210, entryPrice: 202, currentPrice: 207
        )

        // MARK: - Build client profiles

        let johnDoe = ClientProfile(
            name: "John Doe",
            email: "john.doe@example.com",
            phone: "555-0101",
            address: nil,
            notes: "Conservative investor, prefers covered calls and cash-secured puts.",
            createdAt: daysFromToday(-90),
            lastModified: daysFromToday(-1),
            interestedTypes: [.coveredCall, .cashSecuredPut],
            trades: [
                closedTrade(
                    ticker: "AAPL",
                    type: .coveredCall,
                    daysAgo: 30,
                    dte: 5,
                    premium: 2.50,
                    quantity: 5,
                    strike: 180,
                    entryPrice: 175,
                    currentPrice: 178,
                    realizedPL: 1250
                ),
                openTrade(
                    ticker: "MSFT",
                    type: .cashSecuredPut,
                    daysAgo: 10,
                    dte: 20,
                    premium: 3.20,
                    quantity: 3,
                    strike: 400,
                    entryPrice: 410,
                    currentPrice: 408
                ),
                closedTrade(
                    ticker: "TSLA",
                    type: .coveredCall,
                    daysAgo: 45,
                    dte: 2,
                    premium: 4.50,
                    quantity: 2,
                    strike: 250,
                    entryPrice: 240,
                    currentPrice: 245,
                    realizedPL: 900
                )
            ]
        )

        let maryJane = ClientProfile(
            name: "Mary Jane",
            email: "mary.jane@example.com",
            phone: "555-0202",
            address: nil,
            notes: "Aggressive trader, focuses on tech stocks and short-term plays.",
            createdAt: daysFromToday(-120),
            lastModified: daysFromToday(-3),
            interestedTypes: [.call, .put],
            trades: [
                closedTrade(
                    ticker: "NVDA",
                    type: .call,
                    daysAgo: 15,
                    dte: 3,
                    premium: 5.00,
                    quantity: 4,
                    strike: 500,
                    entryPrice: 480,
                    currentPrice: 510,
                    realizedPL: 2000
                ),
                closedTrade(
                    ticker: "AMD",
                    type: .put,
                    daysAgo: 25,
                    dte: 1,
                    premium: 3.80,
                    quantity: 3,
                    strike: 140,
                    entryPrice: 145,
                    currentPrice: 138,
                    realizedPL: -450
                ),
                openTrade(
                    ticker: "GOOGL",
                    type: .call,
                    daysAgo: 5,
                    dte: 25,
                    premium: 4.20,
                    quantity: 2,
                    strike: 150,
                    entryPrice: 145,
                    currentPrice: 148
                )
            ]
        )

        let joshPosh = ClientProfile(
            name: "Josh Posh",
            email: "josh.posh@example.com",
            phone: "555-0303",
            address: nil,
            notes: "Balanced approach, mixes income and growth strategies.",
            createdAt: daysFromToday(-60),
            lastModified: daysFromToday(-2),
            interestedTypes: [.coveredCall, .call, .cashSecuredPut],
            trades: [
                closedTrade(
                    ticker: "SPY",
                    type: .cashSecuredPut,
                    daysAgo: 20,
                    dte: 7,
                    premium: 2.10,
                    quantity: 10,
                    strike: 450,
                    entryPrice: 455,
                    currentPrice: 452,
                    realizedPL: 2100
                ),
                openTrade(
                    ticker: "QQQ",
                    type: .coveredCall,
                    daysAgo: 12,
                    dte: 18,
                    premium: 3.50,
                    quantity: 5,
                    strike: 400,
                    entryPrice: 390,
                    currentPrice: 395
                ),
                closedTrade(
                    ticker: "AMZN",
                    type: .call,
                    daysAgo: 35,
                    dte: 4,
                    premium: 6.50,
                    quantity: 1,
                    strike: 175,
                    entryPrice: 170,
                    currentPrice: 180,
                    realizedPL: 650
                )
            ]
        )

        return [johnDoe, maryJane, joshPosh]
    }
}
