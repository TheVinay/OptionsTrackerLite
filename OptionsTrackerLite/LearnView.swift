import SwiftUI

struct LearnView: View {
    var body: some View {
        List {
            Section("Option Types") {
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

            Section("Risk Ranking (from lowest to highest)") {
                Text("1. Cash-Secured Puts\n2. Covered Calls\n3. Risk-defined spreads (verticals, iron condors)\n4. Naked calls/puts, straddles, and strangles")
                    .font(.subheadline)
            }

            Section("Good Habits") {
                Text("""
                • Trade only with clear entry criteria.
                • Always know max loss and risk per trade.
                • Define exit rules before entry.
                • Journal emotions and mistakes.
                • Keep position sizing consistent.
                • Review monthly P&L and expectancy, not single trades.
                """)
                .font(.subheadline)
            }
        }
        .navigationTitle("Learn")
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
