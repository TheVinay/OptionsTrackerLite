import SwiftUI
import SwiftData

/// Root "Profile" tab – your home screen.
/// Shows your personal summary and a quick link into Portfolios.
struct RootView: View {
    @Query private var profiles: [ClientProfile]
    @AppStorage("advisorName") private var advisorName = "Vinay Viswambharan"

    // MARK: - Aggregated stats

    private var totalClients: Int {
        profiles.count
    }

    private var totalOpenTrades: Int {
        profiles.reduce(0) { $0 + $1.openCount }
    }

    private var totalClosedTrades: Int {
        profiles.reduce(0) { $0 + $1.closedCount }
    }

    private var totalRealizedPL: Double {
        profiles.reduce(0) { $0 + $1.realizedPL }
    }

    var body: some View {
        List {
            headerSection
            profileSummaryCard
            portfoliosLinkSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("OptionsTracker Lite")
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Profile")
                    .font(.largeTitle.bold())

                Text("Your personal home screen. Track your trading performance and manage client portfolios.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var profileSummaryCard: some View {
        Section {
            HStack(alignment: .center, spacing: 16) {
                // Simple avatar placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Text(advisorInitials)
                        .font(.title2.bold())
                        .foregroundColor(.accentColor)
                }
                .shadow(color: .accentColor.opacity(0.2), radius: 8, x: 0, y: 4)
                .accessibilityLabel("Profile avatar")
                .accessibilityValue(advisorInitials)

                VStack(alignment: .leading, spacing: 4) {
                    Text(advisorName)
                        .font(.headline)

                    Text("Options Portfolio Manager")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        metricChip(title: "Clients", value: "\(totalClients)")
                        metricChip(title: "Open", value: "\(totalOpenTrades)")
                        metricChip(
                            title: "Realized P&L",
                            value: totalRealizedPL,
                            isPL: true
                        )
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 6)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Profile summary: \(advisorName), \(totalClients) clients, \(totalOpenTrades) open trades, realized profit and loss \(totalRealizedPL, format: .currency(code: "USD"))")
        }
    }
    
    private var advisorInitials: String {
        let parts = advisorName
            .split(separator: " ")
            .map { String($0.prefix(1)) }
        return parts.prefix(2).joined().uppercased()
    }

    private func metricChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private func metricChip(title: String, value: Double, isPL: Bool) -> some View {
        let color: Color = value >= 0 ? .green : .red
        return VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value, format: .currency(code: "USD"))
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private var portfoliosLinkSection: some View {
        Section {
            NavigationLink {
                PortfoliosView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Portfolios")
                            .font(.headline)
                        Text("View and manage all client accounts")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 6)
            }
            .accessibilityLabel("Portfolios")
            .accessibilityHint("View and manage all client portfolios. Double tap to open.")
        }
    }
}

#Preview {
    NavigationStack {
        RootView()
            .modelContainer(for: [ClientProfile.self, Trade.self, TradeNote.self])
    }
}
