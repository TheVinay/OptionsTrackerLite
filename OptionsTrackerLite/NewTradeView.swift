import SwiftUI

struct NewTradeView: View {

    // We don't actually need the profile yet, so we drop it.
    // The parent passes a closure to append the new Trade.
    let recentTickers: [String]
    let onSave: (Trade) -> Void

    // BASIC
    @State private var ticker: String = ""
    @State private var filteredTickers: [String] = []
    @State private var showTickerSuggestions = false

    @State private var selectedType: OptionType = .coveredCall
    @State private var tradeDate: Date = .now
    @State private var expirationDate: Date = .now.addingTimeInterval(86400 * 30)

    // ADVANCED – stored as text for easier editing
    @State private var strikeText: String = ""
    @State private var quantityText: String = "1"
    @State private var premiumText: String = ""

    @State private var stockEntryPriceText: String = ""
    @State private var stockCurrentPriceText: String = ""

    @State private var stopLossPercentText: String = ""
    @State private var targetPercentText: String = ""

    @Environment(\.dismiss) private var dismiss

    // MARK: - Parsed values

    private var quantityValue: Int {
        Int(quantityText) ?? 0
    }

    private var premiumValue: Double {
        Double(premiumText) ?? 0
    }

    private var strikeValue: Double? {
        Double(strikeText)
    }

    private var stockEntryPriceValue: Double? {
        Double(stockEntryPriceText)
    }

    private var stockCurrentPriceValue: Double? {
        Double(stockCurrentPriceText)
    }

    private var stopLossPercentValue: Double? {
        Double(stopLossPercentText)
    }

    private var targetPercentValue: Double? {
        Double(targetPercentText)
    }

    /// Only for Covered Calls: visible derived total premium
    private var coveredCallTotalPremium: Double {
        premiumValue * 100.0 * Double(max(quantityValue, 0))
    }

    private var canSave: Bool {
        !ticker.trimmingCharacters(in: .whitespaces).isEmpty &&
        premiumValue > 0 &&
        quantityValue > 0
    }

    var body: some View {
        Form {
            basicSection
            advancedSection
        }
        .navigationTitle("New Trade")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveTrade() }
                    .disabled(!canSave)
            }
        }
        .onChange(of: ticker) { newValue in
            updateTickerSuggestions(for: newValue)
        }
    }

    // MARK: - Sections

    private var basicSection: some View {
        Section("Basic") {
            tickerRow
            typeRow

            DatePicker("Trade date", selection: $tradeDate, displayedComponents: .date)
            DatePicker("Expiration", selection: $expirationDate, displayedComponents: .date)

            // ONLY Covered Call: show visible derived total premium
            if selectedType == .coveredCall {
                HStack {
                    Text("Total premium")
                    Spacer()
                    Text(coveredCallTotalPremium, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var advancedSection: some View {
        Section("Advanced") {
            // These fields exist for ALL 3 types
            TextField("Strike price", text: $strikeText)
                .keyboardType(.decimalPad)

            TextField("Quantity (contracts)", text: $quantityText)
                .keyboardType(.numberPad)

            TextField("Contract price (per contract)", text: $premiumText)
                .keyboardType(.decimalPad)

            // Stock prices – shared for Covered Call / Call / Put
            TextField("Stock price at entry", text: $stockEntryPriceText)
                .keyboardType(.decimalPad)

            TextField("Current stock price", text: $stockCurrentPriceText)
                .keyboardType(.decimalPad)

            // Extra risk fields for all (you’ll add logic later)
            Text("Risk management")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            HStack {
                TextField("Stop loss %", text: $stopLossPercentText)
                    .keyboardType(.decimalPad)

                TextField("Target %", text: $targetPercentText)
                    .keyboardType(.decimalPad)
            }
        }
    }

    // MARK: - Subviews

    private var tickerRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ticker")
            TextField("Eg. NVDA", text: $ticker)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()

            if showTickerSuggestions && !filteredTickers.isEmpty {
                // Lightweight dropdown-like suggestions, similar to Stocks app
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredTickers.prefix(5), id: \.self) { suggestion in
                        Button {
                            ticker = suggestion.uppercased()
                            showTickerSuggestions = false
                        } label: {
                            HStack {
                                Text(suggestion.uppercased())
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
                .padding(.top, 4)
            }
        }
    }

    private var typeRow: some View {
        HStack {
            Text("Type")
            Spacer()
            Menu {
                ForEach(OptionType.allCases) { option in
                    Button(option.rawValue) {
                        selectedType = option
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedType.rawValue)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
            }
        }
    }

    // MARK: - Logic

    private func updateTickerSuggestions(for text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            filteredTickers = []
            showTickerSuggestions = false
            return
        }

        let upper = trimmed.uppercased()
        filteredTickers = recentTickers
            .filter { $0.uppercased().hasPrefix(upper) }
            .sorted()

        showTickerSuggestions = !filteredTickers.isEmpty
    }

    private func saveTrade() {
        let cleanTicker = ticker.trimmingCharacters(in: .whitespaces).uppercased()
        guard !cleanTicker.isEmpty, premiumValue > 0, quantityValue > 0 else { return }

        let newTrade = Trade(
            ticker: cleanTicker,
            type: selectedType,
            tradeDate: tradeDate,
            expirationDate: expirationDate,
            premium: premiumValue,
            quantity: quantityValue,
            // totalPremium left nil → Trade initializer will compute premium * 100 * quantity for you
            strike: strikeValue,
            underlyingPriceAtEntry: stockEntryPriceValue,
            currentStockPrice: stockCurrentPriceValue,
            isClosed: false,
            realizedPL: nil,
            simulated: false,
            sendNotifications: true,
            stopLossPercent: stopLossPercentValue,
            targetPercent: targetPercentValue
        )

        onSave(newTrade)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        NewTradeView(
            recentTickers: ["AAPL", "TSLA", "NVDA", "SPY"],
            onSave: { _ in }
        )
    }
}
