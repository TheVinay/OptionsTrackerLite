import SwiftUI

struct TradeDetailView: View {
    let trade: Trade
    let clientName: String?

    @State private var showAdvancedRisk = false

    // MARK: - Simple risk + timing metrics (local only)

    private var daysToExpiry: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day],
                                       from: Date(),
                                       to: trade.expirationDate).day ?? 0
    }

    private var daysInTrade: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day],
                                       from: trade.tradeDate,
                                       to: Date()).day ?? 0
    }

    /// For now, treat `premium` as the total credit (max potential profit for simple credit trades).
    private var maxPotentialProfit: Double {
        trade.premium
    }

    private var tradeDirectionDescription: String {
        maxPotentialProfit >= 0 ? "Credit trade (income)" : "Debit trade"
    }

    private enum SimpleRiskStatus: String {
        case safe = "Safe"
        case watch = "Watch"
        case critical = "Critical"
    }

    private var simpleRiskStatus: SimpleRiskStatus {
        // Phase 1: DTE-only rule; we’ll refine later with ITM/OTM + distance to strike.
        if daysToExpiry <= 7 {
            return .critical
        } else if daysToExpiry <= 14 {
            return .watch
        } else {
            return .safe
        }
    }

    private var riskStatusColor: Color {
        switch simpleRiskStatus {
        case .safe:     return Color(.systemGreen)
        case .watch:    return Color(.systemYellow)
        case .critical: return Color(.systemRed)
        }
    }

    private var riskStatusDescription: String {
        switch simpleRiskStatus {
        case .critical:
            return "Expires soon. Consider adjusting, rolling, or closing."
        case .watch:
            return "Approaching expiry. Keep an eye on this position."
        case .safe:
            return "Plenty of time to expiry based on current dates."
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                riskSummarySection
                basicDetailsSection
                notesHintSection
                copyButtonSection
            }
            .padding()
        }
        .navigationTitle("\(trade.ticker) \(trade.type.rawValue)")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let clientName {
                Text(clientName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(trade.ticker)
                .font(.largeTitle)
                .bold()

            Text(trade.type.rawValue)
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                // Status pill
                Text(trade.isClosed ? "Closed" : "Open")
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(trade.isClosed
                                  ? Color(.systemGreen).opacity(0.15)
                                  : Color(.systemBlue).opacity(0.15))
                    )
                    .foregroundColor(trade.isClosed ? .green : .blue)

                // Realized P&L, if available
                if let realized = trade.realizedPL {
                    Text("Realized P&L \(realized, format: .currency(code: "USD"))")
                        .font(.subheadline)
                        .foregroundColor(realized >= 0 ? .green : .red)
                }
            }
        }
    }

    // MARK: - Risk summary card

    private var riskSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("Risk & Timing")
                    .font(.headline)

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(riskStatusColor)
                        .frame(width: 10, height: 10)
                    Text(simpleRiskStatus.rawValue)
                        .font(.subheadline)
                        .foregroundColor(riskStatusColor)
                }
            }

            Text(riskStatusDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            // Collapsible advanced details
            DisclosureGroup(isExpanded: $showAdvancedRisk) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Days in trade")
                        Spacer()
                        Text("\(max(daysInTrade, 0)) days")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Days to expiry")
                        Spacer()
                        Text("\(max(daysToExpiry, 0)) days")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Entry premium (total)")
                        Spacer()
                        Text(maxPotentialProfit, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Quantity (contracts)")
                        Spacer()
                        Text("\(trade.quantity)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Trade type")
                        Spacer()
                        Text(tradeDirectionDescription)
                            .foregroundStyle(.secondary)
                    }

                    // TODO: Phase 2
                    // - Unrealized P&L (needs live price)
                    // - % return on margin
                    // - Annualized % return
                    // - Greeks, POP, etc.
                }
                .font(.subheadline)
            } label: {
                Text(showAdvancedRisk ? "Hide advanced" : "Show advanced")
                    .font(.subheadline)
                    .foregroundColor(Color(.systemBlue))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Basic details card

    private var basicDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Trade date")
                    Spacer()
                    Text(trade.tradeDate, format: .dateTime.month(.abbreviated).day().year())
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Expiration")
                    Spacer()
                    Text(trade.expirationDate, format: .dateTime.month(.abbreviated).day().year())
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Contracts")
                    Spacer()
                    Text("\(trade.quantity)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Premium (total)")
                    Spacer()
                    Text(trade.premium, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05),
                            radius: 4, x: 0, y: 2)
            )
        }
    }

    // MARK: - Notes hint (placeholder for future journaling)

    private var notesHintSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes & Journaling")
                .font(.headline)

            Text("In a future version you can log entry rationale, psychology, and post-trade reflection here to build better habits.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Copy button

    private var copyButtonSection: some View {
        Button {
            UIPasteboard.general.string = shareSummaryText()
        } label: {
            HStack {
                Image(systemName: "doc.on.doc")
                Text("Copy Trade to Clipboard")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(.systemBlue))
        .padding(.top, 8)
    }

    private func shareSummaryText() -> String {
        var lines: [String] = []

        if let clientName {
            lines.append("Client: \(clientName)")
        }
        lines.append("Ticker: \(trade.ticker)")
        lines.append("Type: \(trade.type.rawValue)")
        lines.append("Trade date: \(formattedDate(trade.tradeDate))")
        lines.append("Expiration: \(formattedDate(trade.expirationDate))")
        lines.append("Contracts: \(trade.quantity)")
        lines.append("Premium (total): \(trade.premium)")

        if let realized = trade.realizedPL {
            lines.append("Realized P&L: \(realized)")
        }
        lines.append("Status: \(trade.isClosed ? "Closed" : "Open")")
        lines.append("Days to expiry: \(daysToExpiry)")

        return lines.joined(separator: "\n")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
