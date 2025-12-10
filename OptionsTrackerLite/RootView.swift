import SwiftUI

/// Root "Profile" tab – your home screen.
/// Shows your personal summary and a quick link into Portfolios.
struct RootView: View {
    @Binding var profiles: [ClientProfile]

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

                Text("Your personal home screen. Later we can add your own stats, habits, and shortcuts here.")
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
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Text("VV") // you can swap to your initials / image later
                        .font(.title2.bold())
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Vinay Viswambharan")
                        .font(.headline)

                    Text("Options advisor & portfolio manager")
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
        }
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
                // Reuse the same Portfolios screen as the Portfolios tab
                PortfoliosView(profiles: $profiles)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Portfolios")
                        .font(.headline)
                    Text("View and manage all client accounts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RootView(profiles: .constant(ClientProfile.demoProfiles()))
    }
}
