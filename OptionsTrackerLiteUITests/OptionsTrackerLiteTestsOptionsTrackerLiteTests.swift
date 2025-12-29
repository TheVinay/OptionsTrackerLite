import XCTest
@testable import OptionsTrackerLite

// MARK: - Trade Model Tests

class TradeTests: XCTestCase {
    
    func testTotalPremiumCalculation() {
        // Given
        let trade = Trade(
            ticker: "AAPL",
            type: .coveredCall,
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: 2.50,
            quantity: 5
        )
        
        // Then
        XCTAssertEqual(trade.totalPremium, 1250.0, "Total premium should be 2.50 * 100 * 5")
    }
    
    func testTradeStatusText() {
        // Given
        var trade = Trade(
            ticker: "TSLA",
            type: .call,
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: 1.0,
            quantity: 1
        )
        
        // When open
        XCTAssertEqual(trade.statusText, "Open")
        
        // When closed
        trade.isClosed = true
        XCTAssertEqual(trade.statusText, "Closed")
    }
    
    func testWinLossDetection() {
        // Given
        var trade = Trade(
            ticker: "AAPL",
            type: .put,
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: 1.0,
            quantity: 1
        )
        
        // When profitable
        trade.realizedPL = 150
        XCTAssertTrue(trade.isWinning, "Trade with positive P&L should be winning")
        
        // When losing
        trade.realizedPL = -50
        XCTAssertFalse(trade.isWinning, "Trade with negative P&L should be losing")
        
        // When break-even
        trade.realizedPL = 0
        XCTAssertTrue(trade.isWinning, "Break-even should count as winning")
    }
    
    func testOptionTypeConversion() {
        // Given
        let trade = Trade(
            ticker: "MSFT",
            type: .cashSecuredPut,
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: 3.0,
            quantity: 2
        )
        
        // Then
        XCTAssertEqual(trade.type, .cashSecuredPut)
        XCTAssertEqual(trade.typeRawValue, "Cash-Secured Put")
    }
}

// MARK: - Trade Validator Tests

class TradeValidatorTests: XCTestCase {
    
    func testValidTradePassesValidation() {
        // Given
        let errors = TradeValidator.validate(
            ticker: "AAPL",
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: 2.50,
            quantity: 5,
            strike: 150.0
        )
        
        // Then
        XCTAssertTrue(errors.isEmpty, "Valid trade should have no validation errors")
    }
    
    func testEmptyTickerFailsValidation() {
        // Given
        let errors = TradeValidator.validate(
            ticker: "",
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: 2.50,
            quantity: 5,
            strike: nil
        )
        
        // Then
        XCTAssertFalse(errors.isEmpty, "Empty ticker should fail validation")
        XCTAssertTrue(errors.contains { $0.message.contains("Ticker") })
    }
    
    func testInvalidExpirationDateFailsValidation() {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let errors = TradeValidator.validate(
            ticker: "AAPL",
            tradeDate: today,
            expirationDate: yesterday,
            premium: 2.50,
            quantity: 5,
            strike: nil
        )
        
        // Then
        XCTAssertFalse(errors.isEmpty, "Expiration before trade date should fail")
        XCTAssertTrue(errors.contains { $0.message.contains("after trade date") })
    }
    
    func testNegativePremiumFailsValidation() {
        // Given
        let errors = TradeValidator.validate(
            ticker: "AAPL",
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: -1.0,
            quantity: 5,
            strike: nil
        )
        
        // Then
        XCTAssertFalse(errors.isEmpty, "Negative premium should fail validation")
        XCTAssertTrue(errors.contains { $0.message.contains("Premium") })
    }
    
    func testZeroQuantityFailsValidation() {
        // Given
        let errors = TradeValidator.validate(
            ticker: "AAPL",
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: 2.50,
            quantity: 0,
            strike: nil
        )
        
        // Then
        XCTAssertFalse(errors.isEmpty, "Zero quantity should fail validation")
        XCTAssertTrue(errors.contains { $0.message.contains("Quantity") })
    }
    
    func testBasicValidityCheck() {
        // Valid cases
        XCTAssertTrue(TradeValidator.isBasicallyValid(ticker: "AAPL", premium: 2.50, quantity: 5))
        
        // Invalid cases
        XCTAssertFalse(TradeValidator.isBasicallyValid(ticker: "", premium: 2.50, quantity: 5))
        XCTAssertFalse(TradeValidator.isBasicallyValid(ticker: "AAPL", premium: -1.0, quantity: 5))
        XCTAssertFalse(TradeValidator.isBasicallyValid(ticker: "AAPL", premium: 2.50, quantity: 0))
    }
}

// MARK: - Client Profile Tests

class ClientProfileTests: XCTestCase {
    
    func testTradeCountCalculations() {
        // Given
        let openTrade = Trade(
            ticker: "AAPL",
            type: .call,
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: 2.0,
            quantity: 1,
            isClosed: false
        )
        
        let closedTrade = Trade(
            ticker: "TSLA",
            type: .put,
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: 3.0,
            quantity: 1,
            isClosed: true,
            realizedPL: 100.0
        )
        
        let profile = ClientProfile(
            name: "Test Client",
            trades: [openTrade, closedTrade]
        )
        
        // Then
        XCTAssertEqual(profile.openCount, 1, "Should have 1 open trade")
        XCTAssertEqual(profile.closedCount, 1, "Should have 1 closed trade")
        XCTAssertEqual(profile.realizedPL, 100.0, "Realized P&L should be 100")
    }
    
    func testDisplayInitialsGeneration() {
        // Given & Then
        let profile1 = ClientProfile(name: "John Doe")
        XCTAssertEqual(profile1.displayInitials, "JD")
        
        let profile2 = ClientProfile(name: "Alice")
        XCTAssertEqual(profile2.displayInitials, "A")
        
        let profile3 = ClientProfile(name: "Bob Smith Johnson")
        XCTAssertEqual(profile3.displayInitials, "BS")
    }
}

// MARK: - Data Export Tests

class DataExportTests: XCTestCase {
    
    func testCSVExportContainsHeader() {
        // Given
        let profiles: [ClientProfile] = []
        
        // When
        let csv = DataExporter.exportToCSV(profiles: profiles)
        
        // Then
        XCTAssertTrue(csv.contains("Client"), "CSV should contain Client header")
        XCTAssertTrue(csv.contains("Ticker"), "CSV should contain Ticker header")
        XCTAssertTrue(csv.contains("Type"), "CSV should contain Type header")
        XCTAssertTrue(csv.contains("P&L"), "CSV should contain P&L header")
    }
    
    func testSummaryTextIncludesTotals() {
        // Given
        let trade = Trade(
            ticker: "AAPL",
            type: .coveredCall,
            tradeDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            premium: 2.0,
            quantity: 1,
            isClosed: true,
            realizedPL: 200.0
        )
        
        let profile = ClientProfile(name: "Test Client", trades: [trade])
        
        // When
        let summary = DataExporter.exportSummaryText(profiles: [profile])
        
        // Then
        XCTAssertTrue(summary.contains("OptionsTracker Lite"), "Summary should contain app name")
        XCTAssertTrue(summary.contains("Total Clients"), "Summary should contain total clients")
        XCTAssertTrue(summary.contains("Test Client"), "Summary should contain client name")
    }
}
