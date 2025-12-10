import SwiftUI

struct NewTradeView: View {

    @Binding var profile: ClientProfile
    let recentTickers: [String]
    let onSave: (Trade) -> Void

    // Basic fields
    @State private var ticker: String = ""
    @State private var type: OptionType = .coveredCall
    @State private var tradeDate: Date = .now
    @State private var expirationDate: Date = .now.addingTimeInterval(86400 * 7)

    // Advanced
    @State private var strikePrice: Double?
    @State private var quantity: Int = 1
    @State private var premium: Double?

    @State private var stockEntryPrice: Double?
    @State private var stockCurrentPrice: Double?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Basic") {
                TextField("Ticker", text: $ticker)

                Picker("Type", selection: $type) {
                    ForEach(OptionType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }

                DatePicker("Trade date", selection: $tradeDate, displayedComponents: .date)

                DatePicker("Expiration", selection: $expirationDate, displayedComponents: .date)
            }

            Section("Advanced") {
                TextField("Strike Price", value: $strikePrice, format: .number)
                    .keyboardType(.decimalPad)

                TextField("Quantity (contracts)", value: $quantity, format: .number)
                    .keyboardType(.numberPad)

                TextField("Premium (per contract)", value: $premium, format: .number)
                    .keyboardType(.decimalPad)

                TextField("Stock price at entry", value: $stockEntryPrice, format: .number)
                    .keyboardType(.decimalPad)

                TextField("Current stock price", value: $stockCurrentPrice, format: .number)
                    .keyboardType(.decimalPad)
            }

            Button("Save Trade") {
                saveTrade()
            }
            .disabled(ticker.isEmpty || premium == nil)
        }
        .navigationTitle("New Trade")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveTrade() {

        let trade = Trade(
            ticker: ticker,
            type: type,
            tradeDate: tradeDate,
            expirationDate: expirationDate,
            premium: premium ?? 0,
            quantity: quantity,
            strike: strikePrice,
            underlyingPriceAtEntry: stockEntryPrice,
            currentStockPrice: stockCurrentPrice
        )

        onSave(trade)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        NewTradeView(
            profile: .constant(ClientProfile.demoProfiles().first!),
            recentTickers: ["AAPL", "TSLA"],
            onSave: { _ in }
        )
    }
}
