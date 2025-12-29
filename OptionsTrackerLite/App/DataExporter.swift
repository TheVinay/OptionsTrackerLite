import Foundation
import UIKit
import SwiftUI

struct DataExporter {
    
    // MARK: - CSV Export
    
    static func exportToCSV(profiles: [ClientProfile]) -> String {
        var csv = "Client,Ticker,Type,Entry Date,Expiry Date,Premium,Quantity,Total Premium,Strike,Entry Price,Current Price,Status,P&L,Simulated,Tags\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for profile in profiles {
            for trade in profile.trades {
                let row = [
                    escapeCSV(profile.name),
                    escapeCSV(trade.ticker),
                    escapeCSV(trade.type.rawValue),
                    dateFormatter.string(from: trade.tradeDate),
                    dateFormatter.string(from: trade.expirationDate),
                    String(format: "%.2f", trade.premium),
                    String(trade.quantity),
                    String(format: "%.2f", trade.totalPremium),
                    trade.strike.map { String(format: "%.2f", $0) } ?? "",
                    trade.underlyingPriceAtEntry.map { String(format: "%.2f", $0) } ?? "",
                    trade.currentStockPrice.map { String(format: "%.2f", $0) } ?? "",
                    trade.isClosed ? "Closed" : "Open",
                    trade.realizedPL.map { String(format: "%.2f", $0) } ?? "",
                    trade.simulated ? "Yes" : "No",
                    escapeCSV(trade.tags.joined(separator: "; "))
                ].joined(separator: ",")
                
                csv += row + "\n"
            }
        }
        
        return csv
    }
    
    private static func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
    
    // MARK: - JSON Export
    
    static func exportToJSON(profiles: [ClientProfile]) throws -> Data {
        struct ExportProfile: Codable {
            let id: String
            let name: String
            let email: String?
            let phone: String?
            let trades: [ExportTrade]
        }
        
        struct ExportTrade: Codable {
            let id: String
            let ticker: String
            let type: String
            let tradeDate: String
            let expirationDate: String
            let premium: Double
            let quantity: Int
            let totalPremium: Double
            let strike: Double?
            let isClosed: Bool
            let realizedPL: Double?
            let tags: [String]
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        let exportData = profiles.map { profile in
            ExportProfile(
                id: profile.id.uuidString,
                name: profile.name,
                email: profile.email,
                phone: profile.phone,
                trades: profile.trades.map { trade in
                    ExportTrade(
                        id: trade.id.uuidString,
                        ticker: trade.ticker,
                        type: trade.type.rawValue,
                        tradeDate: dateFormatter.string(from: trade.tradeDate),
                        expirationDate: dateFormatter.string(from: trade.expirationDate),
                        premium: trade.premium,
                        quantity: trade.quantity,
                        totalPremium: trade.totalPremium,
                        strike: trade.strike,
                        isClosed: trade.isClosed,
                        realizedPL: trade.realizedPL,
                        tags: trade.tags
                    )
                }
            )
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportData)
    }
    
    // MARK: - Summary Text Export
    
    static func exportSummaryText(profiles: [ClientProfile]) -> String {
        var text = "OptionsTracker Lite - Portfolio Summary\n"
        text += "Generated: \(Date().formatted(date: .long, time: .shortened))\n"
        text += String(repeating: "=", count: 50) + "\n\n"
        
        let totalTrades = profiles.flatMap { $0.trades }.count
        let totalOpen = profiles.flatMap { $0.trades }.filter { !$0.isClosed }.count
        let totalClosed = profiles.flatMap { $0.trades }.filter { $0.isClosed }.count
        let totalPL = profiles.flatMap { $0.trades }.compactMap { $0.realizedPL }.reduce(0, +)
        
        text += "OVERALL SUMMARY\n"
        text += "Total Clients: \(profiles.count)\n"
        text += "Total Trades: \(totalTrades)\n"
        text += "Open Positions: \(totalOpen)\n"
        text += "Closed Positions: \(totalClosed)\n"
        text += String(format: "Total Realized P&L: $%.2f\n\n", totalPL)
        
        for profile in profiles {
            text += "\n" + String(repeating: "-", count: 50) + "\n"
            text += "CLIENT: \(profile.name)\n"
            if let email = profile.email {
                text += "Email: \(email)\n"
            }
            text += "Open Trades: \(profile.openCount)\n"
            text += "Closed Trades: \(profile.closedCount)\n"
            text += String(format: "Realized P&L: $%.2f\n", profile.realizedPL)
            
            if !profile.trades.isEmpty {
                text += "\nTRADES:\n"
                for trade in profile.trades.sorted(by: { $0.tradeDate > $1.tradeDate }) {
                    text += "  • \(trade.ticker) \(trade.type.rawValue) - "
                    text += "\(trade.isClosed ? "Closed" : "Open")"
                    if let pl = trade.realizedPL {
                        text += String(format: " (P&L: $%.2f)", pl)
                    }
                    text += "\n"
                }
            }
        }
        
        text += "\n" + String(repeating: "=", count: 50) + "\n"
        text += "End of Report\n"
        
        return text
    }
}

// MARK: - Share Sheet for UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
