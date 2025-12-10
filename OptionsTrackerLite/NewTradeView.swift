import SwiftUI

struct NewTradeView: View {

    // We no longer take `profile` here – the caller handles appending.
    let recentTickers: [String]
    let onSave: (Trade) -> Void

    // BASIC
    @State private var ticker: String = ""
    @State private var type: OptionType = .coveredCall
    @State private var tradeDate: Date = .now
    @State private var expirationDate: Date = Calendar.current.date(
        byAdding: .day,
        value: 30,
        to: .now
    ) ?? .now

    // ADVANCED – common across Call / Put / Covered Call / CSP
    @State private var strikePrice: Double?
    @State private var quantity: Int = 1
    @State private var contractPrice: Double?

    @State private var stopLossPercent: Double?
    @State private var targetPercent: Double?

    @State private var stockEntryPrice: Double?
    @State private var stockCurrentPrice: Double?

    // Ticker suggestions (simple “Stocks app–style” pill row)
    @State private var filteredTickers: [String] = []
    @State private var showTickerSuggestions: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            basicSection
            advancedSection

            Section {
                Button("Save Trade") {
                    handleSave()
                }
                .disabled(!canSave)
            }
        }
        .navigationTitle("New Trade")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var basicSection: some View {
        Section("Basic") {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Ticker", text: $ticker)
                    .autocapitalization(.allCharacters)
                    .onChange(of: ticker) { newValue in
                        updateTickerSuggestions(for: newValue)
                    }

                if showTickerSuggestions && !filteredTickers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(filteredTickers, id: \.self) { symbol in
                                Button(symbol) {
                                    ticker = symbol
                                    showTickerSuggestions = false
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }
                        .padding(.top, 2)
                    }
                }
            }

            Picker("Type", selection: $type) {
                ForEach(OptionType.allCases) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }

            DatePicker("Trade date", selection: $tradeDate, displayedComponents: .date)

            DatePicker("Expiration", selection: $expirationDate, displayedComponents: .date)
        }
    }

    private var advancedSection: some View {
        Section("Advanced (optional)") {
            TextField("Strike price", value: $strikePrice, format: .number)
                .keyboardType(.decimalPad)

            TextField("Quantity (contracts)", value: $quantity, format: .number)
                .keyboardType(.numberPad)

            TextField("Contract price", value: $contractPrice, format: .number)
                .keyboardType(.decimalPad)

            TextField("Stop loss %", value: $stopLossPercent, format: .number)
                .keyboardType(.decimalPad)

            TextField("Target %", value: $targetPercent, format: .number)
                .keyboardType(.decimalPad)

            TextField("Stock price at entry", value: $stockEntryPrice, format: .number)
                .keyboardType(.decimalPad)

            TextField("Current stock price", value: $stockCurrentPrice, format: .number)
                .keyboardType(.decimalPad)
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        !ticker.trimmingCharacters(in: .whitespaces).isEmpty &&
        contractPrice != nil &&
        strikePrice != nil
    }

    private func updateTickerSuggestions(for text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            filteredTickers = []
            showTickerSuggestions = false
            return
        }

        filteredTickers = recentTickers
            .filter { $0.localizedCaseInsensitiveContains(trimmed) }

        showTickerSuggestions = !filteredTickers.isEmpty
    }

    private func handleSave() {
        guard let contractPrice = contractPrice,
              let strike = strikePrice else { return }

        let premiumPerContract = contractPrice

        let trade = Trade(
            ticker: ticker.uppercased(),
            type: type,
            tradeDate: tradeDate,
            expirationDate: expirationDate,
            premium: premiumPerContract,
            quantity: quantity,
            strike: strike,
            underlyingPriceAtEntry: stockEntryPrice,
            currentStockPrice: stockCurrentPrice,
            stopLossPercent: stopLossPercent,
            targetPercent: targetPercent
        )

        onSave(trade)
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
