import SwiftUI

struct NewTradeView: View {
    let recentTickers: [String]
    let onSave: (Trade) -> Void

    // SETTINGS & DEFAULTS
    @AppStorage("defaultQuantity") private var defaultQuantity = 1
    @AppStorage("defaultStrategy") private var defaultStrategy = "Covered Call"
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("notificationDaysBefore") private var notificationDaysBefore = 3
    
    // BASIC
    @State private var ticker: String = ""
    @State private var type: OptionType = .coveredCall
    @State private var tradeDate: Date = .now
    @State private var expirationDate: Date = Calendar.current.date(
        byAdding: .day,
        value: 30,
        to: .now
    ) ?? .now

    // ADVANCED
    @State private var strikePrice: Double?
    @State private var quantity: Int = 1
    @State private var contractPrice: Double?
    @State private var stopLossPercent: Double?
    @State private var targetPercent: Double?
    @State private var stockEntryPrice: Double?
    @State private var stockCurrentPrice: Double?
    @State private var sendNotifications: Bool = true

    // UI STATE
    @State private var filteredStocks: [StockInfo] = []
    @State private var showTickerSuggestions: Bool = false
    @State private var validationErrors: [TradeValidator.ValidationError] = []
    @State private var showValidationAlert = false
    @State private var isSearchingAPI: Bool = false
    @State private var isFetchingPrice: Bool = false
    @State private var showAutoFillToast: Bool = false
    @State private var autoFilledFields: Set<String> = []

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case ticker, strike, quantity, contractPrice
    }

    var body: some View {
        ZStack {
            Form {
                basicSection
                advancedSection
                notificationSection
                
                if !validationErrors.isEmpty {
                    validationErrorSection
                }

                saveSection
            }
            .navigationTitle("New Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel and discard trade")
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                quantity = defaultQuantity
                if let defaultType = OptionType(rawValue: defaultStrategy) {
                    type = defaultType
                }
                sendNotifications = enableNotifications
            }
            .alert("Validation Errors", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationErrors.map { $0.message }.joined(separator: "\n"))
            }
            
            // Auto-fill toast notification
            if showAutoFillToast {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Auto-filled from live market data")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 10)
                    .padding(.bottom, 80)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Sections

    private var basicSection: some View {
        Section {
            // Ticker with suggestions
            VStack(alignment: .leading, spacing: 8) {
                TextField("Ticker Symbol", text: $ticker, prompt: Text("e.g., AAPL, TSLA"))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .ticker)
                    .onChange(of: ticker) { _, newValue in
                        updateTickerSuggestions(for: newValue)
                        validateFields()
                    }
                    .accessibilityLabel("Ticker symbol")
                    .accessibilityHint("Enter stock ticker like AAPL or TSLA")

                if showTickerSuggestions {
                    VStack(alignment: .leading, spacing: 8) {
                        // Show loading indicator when searching API
                        if isSearchingAPI {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        
                        if !filteredStocks.isEmpty {
                            ForEach(filteredStocks) { stock in
                                Button {
                                    ticker = stock.ticker
                                    showTickerSuggestions = false
                                    
                                    // Auto-fill stock data
                                    Task {
                                        await fetchStockDataAndAutoFill(ticker: stock.ticker)
                                    }
                                    
                                    focusedField = .strike
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(stock.ticker)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text(stock.companyName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.forward.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Select \(stock.ticker), \(stock.companyName)")
                            }
                        }
                        
                        // Show "Use anyway" option if ticker is typed but not found and not searching
                        if !ticker.isEmpty && filteredStocks.isEmpty && !isSearchingAPI {
                            Button {
                                showTickerSuggestions = false
                                focusedField = .strike
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Use \"\(ticker.uppercased())\"")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("Not found, but you can use it")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.green.opacity(0.3), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Use \(ticker.uppercased()) anyway")
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Stock suggestions")
                }
            }

            Picker("Strategy Type", selection: $type) {
                ForEach(OptionType.allCases) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }
            .accessibilityLabel("Strategy type picker")

            DatePicker("Trade Date", selection: $tradeDate, displayedComponents: .date)
                .onChange(of: tradeDate) { _, _ in
                    validateFields()
                }
                .accessibilityLabel("Trade date")

            DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                .onChange(of: expirationDate) { _, _ in
                    validateFields()
                }
                .accessibilityLabel("Expiration date")
            
            // DTE (Days to Expiration) indicator
            if expirationDate > tradeDate {
                let days = Calendar.current.dateComponents([.day], from: tradeDate, to: expirationDate).day ?? 0
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("\(days) days until expiration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("\(days) days until expiration")
            }
        } header: {
            Label("Basic Information", systemImage: "doc.text")
        }
    }

    private var advancedSection: some View {
        Section {
            HStack {
                Text("Strike Price")
                Spacer()
                
                if isFetchingPrice {
                    ProgressView()
                        .controlSize(.small)
                }
                
                TextField("Required", value: $strikePrice, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .strike)
                    .foregroundStyle(autoFilledFields.contains("strike") ? .blue : .primary)
                    .fontWeight(autoFilledFields.contains("strike") ? .semibold : .regular)
                    .onChange(of: strikePrice) { _, _ in
                        autoFilledFields.remove("strike")
                        validateFields()
                    }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Strike price")

            Stepper("Quantity: \(quantity) contract\(quantity == 1 ? "" : "s")", value: $quantity, in: 1...1000)
                .onChange(of: quantity) { _, _ in
                    validateFields()
                }
                .accessibilityLabel("Quantity: \(quantity) contracts")
                .accessibilityHint("Number of option contracts")

            HStack {
                Text("Premium per Contract")
                Spacer()
                TextField("Required", value: $contractPrice, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .contractPrice)
                    .onChange(of: contractPrice) { _, _ in
                        validateFields()
                    }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Premium per contract")
            
            // Total Premium Calculator
            if let premium = contractPrice {
                let total = premium * 100.0 * Double(quantity)
                HStack {
                    Label("Total Premium", systemImage: "dollarsign.circle.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Text(total, format: .currency(code: "USD"))
                        .font(.headline)
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total premium: \(total, format: .currency(code: "USD"))")
            }

            Divider()

            HStack {
                Text("Stock Entry Price")
                Spacer()
                TextField("Optional", value: $stockEntryPrice, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Current Stock Price")
                Spacer()
                TextField("Optional", value: $stockCurrentPrice, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Text("Stop Loss %")
                Spacer()
                TextField("Optional", value: $stopLossPercent, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Target Profit %")
                Spacer()
                TextField("Optional", value: $targetPercent, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("Trade Details", systemImage: "chart.line.uptrend.xyaxis")
        } footer: {
            Text("Premium is the price per contract. Total = Premium × 100 × Quantity")
                .font(.caption)
        }
    }
    
    private var notificationSection: some View {
        Section {
            Toggle(isOn: $sendNotifications) {
                Label("Send Expiration Reminder", systemImage: "bell.fill")
            }
            .disabled(!enableNotifications)
            .accessibilityLabel("Send expiration reminder toggle")
            
            if sendNotifications && enableNotifications {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Reminder \(notificationDaysBefore) day\(notificationDaysBefore == 1 ? "" : "s") before expiration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if !enableNotifications {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("Notifications are disabled in Settings")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        } header: {
            Label("Notifications", systemImage: "bell.badge")
        }
    }
    
    private var validationErrorSection: some View {
        Section {
            ForEach(validationErrors) { error in
                Label {
                    Text(error.message)
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        } header: {
            Text("Please Fix These Issues")
                .foregroundStyle(.orange)
        }
    }
    
    private var saveSection: some View {
        Section {
            Button {
                handleSave()
            } label: {
                HStack {
                    Spacer()
                    Label("Save Trade", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                    Spacer()
                }
            }
            .disabled(!canSave)
            .listRowBackground(canSave ? Color.accentColor : Color.gray.opacity(0.3))
            .foregroundStyle(canSave ? .white : .secondary)
            .accessibilityLabel("Save trade")
            .accessibilityHint(canSave ? "Tap to save this trade" : "Complete required fields to enable")
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        TradeValidator.isBasicallyValid(
            ticker: ticker,
            premium: contractPrice,
            quantity: quantity
        ) && strikePrice != nil && validationErrors.isEmpty
    }
    
    private func validateFields() {
        validationErrors = TradeValidator.validate(
            ticker: ticker,
            tradeDate: tradeDate,
            expirationDate: expirationDate,
            premium: contractPrice,
            quantity: quantity,
            strike: strikePrice
        )
    }

    private func updateTickerSuggestions(for text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces).uppercased()
        
        guard !trimmed.isEmpty else {
            filteredStocks = []
            showTickerSuggestions = false
            isSearchingAPI = false
            return
        }
        
        // Search in local database first
        let databaseResults = StockDatabase.search(query: trimmed)
        
        // Also check recent tickers
        let recentMatches = recentTickers
            .filter { $0.localizedCaseInsensitiveContains(trimmed) }
            .compactMap { ticker in
                StockDatabase.info(for: ticker) ?? StockInfo(ticker: ticker, companyName: "Recent Trade")
            }
        
        // Combine: recent tickers first, then database results
        var combined = recentMatches
        for stock in databaseResults {
            if !combined.contains(where: { $0.ticker == stock.ticker }) {
                combined.append(stock)
            }
        }
        
        filteredStocks = Array(combined.prefix(8))
        showTickerSuggestions = !trimmed.isEmpty
        
        // If no local results and query looks like a ticker (2-5 chars), search Yahoo Finance
        if filteredStocks.isEmpty && trimmed.count >= 2 && trimmed.count <= 5 {
            searchYahooFinance(query: trimmed)
        } else {
            isSearchingAPI = false
        }
    }
    
    private func searchYahooFinance(query: String) {
        isSearchingAPI = true
        
        Task {
            do {
                let results = try await YahooFinanceAPI.shared.searchStocks(query: query)
                
                await MainActor.run {
                    // Only update if the query hasn't changed
                    if ticker.uppercased().trimmingCharacters(in: .whitespaces) == query {
                        filteredStocks = results
                        isSearchingAPI = false
                    }
                }
            } catch {
                print("Yahoo Finance search error: \(error.localizedDescription)")
                await MainActor.run {
                    isSearchingAPI = false
                }
            }
        }
    }
    
    // MARK: - Auto-Fill Stock Data
    
    private func fetchStockDataAndAutoFill(ticker: String) async {
        do {
            let quote = try await YahooFinanceAPI.shared.getQuote(ticker: ticker)
            
            await MainActor.run {
                // Auto-fill current stock price
                if let price = quote.price {
                    stockCurrentPrice = price
                    
                    // For covered calls, also set entry price
                    if type == .coveredCall {
                        if stockEntryPrice == nil {
                            stockEntryPrice = price
                        }
                    }
                    
                    // Suggest strike prices based on strategy
                    suggestStrikePrice(currentPrice: price, strategy: type)
                }
            }
        } catch {
            print("Failed to fetch stock data: \(error.localizedDescription)")
        }
    }
    
    private func suggestStrikePrice(currentPrice: Double, strategy: OptionType) {
        guard strikePrice == nil else { return } // Don't overwrite if user already entered
        
        switch strategy {
        case .coveredCall, .call:
            // Suggest strike 5% above current price (moderate)
            let suggestedStrike = (currentPrice * 1.05).rounded(toPlaces: 2)
            strikePrice = suggestedStrike
            
        case .cashSecuredPut, .put:
            // Suggest strike 5% below current price (moderate)
            let suggestedStrike = (currentPrice * 0.95).rounded(toPlaces: 2)
            strikePrice = suggestedStrike
        }
    }
}

// MARK: - Helper Extensions

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension NewTradeView {
    private func handleSave() {
        // Final validation
        validateFields()
        
        guard validationErrors.isEmpty else {
            showValidationAlert = true
            return
        }
        
        guard let contractPrice = contractPrice,
              let strike = strikePrice else { 
            return 
        }

        let trade = Trade(
            ticker: ticker.uppercased().trimmingCharacters(in: .whitespaces),
            type: type,
            tradeDate: tradeDate,
            expirationDate: expirationDate,
            premium: contractPrice,
            quantity: quantity,
            strike: strike,
            underlyingPriceAtEntry: stockEntryPrice,
            currentStockPrice: stockCurrentPrice,
            sendNotifications: sendNotifications,
            stopLossPercent: stopLossPercent,
            targetPercent: targetPercent
        )

        onSave(trade)
        
        // Schedule notification if enabled
        if sendNotifications && enableNotifications {
            Task {
                await NotificationManager.shared.scheduleExpirationNotification(
                    for: trade,
                    daysBeforeExpiry: notificationDaysBefore
                )
            }
        }
        
        dismiss()
    }
}

#Preview {
    NavigationStack {
        NewTradeView(
            recentTickers: ["AAPL", "TSLA", "NVDA", "SPY", "QQQ", "MSFT", "GOOGL", "AMZN"],
            onSave: { trade in
                print("Saved: \(trade.ticker) \(trade.type.rawValue)")
            }
        )
    }
}
