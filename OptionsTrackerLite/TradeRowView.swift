import SwiftUI

struct TradeRowView: View {
    let trade: Trade

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Top line: Ticker + type + status pill
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(trade.ticker) \(trade.type.rawValue)")
                        .font(.headline)

                    if let strike = trade.strike {
                        Text("Strike \(strike.formatted(.number.precision(.fractionLength(0...2))))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                statusPill
            }

            // Dates
            HStack(spacing: 16) {
                Text("Entry: \(trade.tradeDate, format: Date.FormatStyle().month().day().year())")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Expiry: \(trade.expirationDate, format: Date.FormatStyle().month().day().year())")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Realized P&L (if any)
            if let pl = trade.realizedPL {
                Text("Realized P&L: \(pl, format: .currency(code: "USD"))")
                    .font(.subheadline)
                    .foregroundColor(pl >= 0 ? .green : .red)
            } else {
                Text("Realized P&L: —")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var statusPill: some View {
        Text(trade.isClosed ? "Closed" : "Open")
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(trade.isClosed
                          ? Color(.systemGreen).opacity(0.15)
                          : Color(.systemBlue).opacity(0.12))
            )
            .foregroundColor(trade.isClosed ? .green : .blue)
    }
}

#Preview {
    // quick preview using demo data from Models.swift
    let demo = ClientProfile.demoProfiles().first!.trades.first!
    TradeRowView(trade: demo)
        .padding()
}
