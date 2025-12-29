import SwiftUI

struct LearnView: View {
    var body: some View {
        List {
            // How It Works - Expandable
            Section {
                ExpandableSection(title: "How It Works", icon: "info.circle.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("OptionsTracker Lite helps financial advisors and traders manage multiple client portfolios efficiently.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HowItWorksRow(
                            icon: "person.2.fill",
                            title: "Create Client Profiles",
                            detail: "Add clients from the Portfolios tab. Track their contact info, notes, and preferred strategies."
                        )
                        
                        HowItWorksRow(
                            icon: "plus.circle.fill",
                            title: "Add Trades",
                            detail: "Tap + to add options trades. Enter ticker, strategy type, dates, premium, and strike price."
                        )
                        
                        HowItWorksRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Track Performance",
                            detail: "View open/closed trades, realized P&L, and expiration calendars. Filter by status, strategy, or ticker."
                        )
                        
                        HowItWorksRow(
                            icon: "bell.fill",
                            title: "Get Reminders",
                            detail: "Enable notifications in Settings to receive alerts before options expire (customizable 1-7 days)."
                        )
                        
                        HowItWorksRow(
                            icon: "square.and.arrow.up",
                            title: "Export Data",
                            detail: "Go to Settings → Export to save all data as CSV, JSON, or summary text for reporting."
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Color Coding - Expandable
            Section {
                ExpandableSection(title: "Color Coding Guide", icon: "paintpalette.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        ColorCodeRow(
                            color: .green,
                            title: "Green",
                            detail: "Positive values: Profitable trades, gains, positive P&L"
                        )
                        
                        ColorCodeRow(
                            color: .red,
                            title: "Red",
                            detail: "Negative values: Losing trades, losses, negative P&L"
                        )
                        
                        ColorCodeRow(
                            color: .orange,
                            title: "Orange",
                            detail: "Warnings: Validation errors, disabled features, or expiring soon"
                        )
                        
                        ColorCodeRow(
                            color: .blue,
                            title: "Blue",
                            detail: "Actions & highlights: Interactive elements, accent color, selected filters"
                        )
                        
                        ColorCodeRow(
                            color: .secondary,
                            title: "Gray",
                            detail: "Secondary info: Optional fields, metadata, inactive elements"
                        )
                    }
                }
                
                Text("Colors help you quickly identify trade status, profitability, and important information at a glance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            
            // Option Types - Expandable
            Section {
                ExpandableSection(title: "Option Types", icon: "book.closed.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        LearnRow(
                            title: "Call Options",
                            detail: "Right to buy 100 shares at a set strike price before expiration. Used for bullish bets or as part of spreads."
                        )
                        LearnRow(
                            title: "Put Options",
                            detail: "Right to sell 100 shares at a set strike price before expiration. Used for bearish bets or hedging long stock."
                        )
                        LearnRow(
                            title: "Covered Calls",
                            detail: "Sell call options against shares you already own. Generates income with limited upside, generally lower risk than naked calls."
                        )
                        LearnRow(
                            title: "Cash-Secured Puts",
                            detail: "Sell puts while holding enough cash to buy the shares if assigned. Often seen as one of the lower-risk ways to enter positions in quality stocks."
                        )
                    }
                }
            }

            // Risk Ranking - Expandable
            Section {
                ExpandableSection(title: "Risk Ranking", icon: "exclamationmark.triangle.fill") {
                    Text("1. Cash-Secured Puts\n2. Covered Calls\n3. Risk-defined spreads (verticals, iron condors)\n4. Naked calls/puts, straddles, and strangles")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Good Habits - Expandable
            Section {
                ExpandableSection(title: "Good Trading Habits", icon: "checkmark.seal.fill") {
                    Text("""
                    • Trade only with clear entry criteria.
                    • Always know max loss and risk per trade.
                    • Define exit rules before entry.
                    • Journal emotions and mistakes.
                    • Keep position sizing consistent.
                    • Review monthly P&L and expectancy, not single trades.
                    """)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            
            // Key Formulas - Expandable
            Section {
                ExpandableSection(title: "Key Formulas", icon: "function") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Premium Calculation")
                            .font(.headline)
                        Text("Total Premium = Premium per Contract × 100 × Quantity")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("Example:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Premium: $2.50 per contract\nQuantity: 5 contracts\nTotal: $2.50 × 100 × 5 = $1,250")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Common Terms - Expandable
            Section {
                ExpandableSection(title: "Common Terms", icon: "text.book.closed.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DTE (Days to Expiration)")
                            .font(.headline)
                        Text("Days remaining until the option expires. Shorter DTE means higher urgency.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("P&L (Profit & Loss)")
                            .font(.headline)
                        Text("Realized P&L shows actual gains/losses from closed trades. Open trades show unrealized P&L.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Learn")
    }
}

struct HowItWorksRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ColorCodeRow: View {
    let color: Color
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct LearnRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

