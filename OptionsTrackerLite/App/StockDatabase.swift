import Foundation

// MARK: - Stock Database

struct StockInfo: Identifiable, Hashable {
    let id = UUID()
    let ticker: String
    let companyName: String
    
    var displayText: String {
        "\(ticker) - \(companyName)"
    }
}

struct StockDatabase {
    
    // Popular stocks for quick searching
    static let popularStocks: [StockInfo] = [
        // FAANG + Tech Giants
        StockInfo(ticker: "AAPL", companyName: "Apple Inc."),
        StockInfo(ticker: "MSFT", companyName: "Microsoft Corporation"),
        StockInfo(ticker: "GOOGL", companyName: "Alphabet Inc. (Google)"),
        StockInfo(ticker: "AMZN", companyName: "Amazon.com Inc."),
        StockInfo(ticker: "META", companyName: "Meta Platforms (Facebook)"),
        StockInfo(ticker: "TSLA", companyName: "Tesla Inc."),
        StockInfo(ticker: "NVDA", companyName: "NVIDIA Corporation"),
        StockInfo(ticker: "AMD", companyName: "Advanced Micro Devices"),
        StockInfo(ticker: "INTC", companyName: "Intel Corporation"),
        StockInfo(ticker: "NFLX", companyName: "Netflix Inc."),
        
        // Other Tech
        StockInfo(ticker: "ORCL", companyName: "Oracle Corporation"),
        StockInfo(ticker: "CRM", companyName: "Salesforce Inc."),
        StockInfo(ticker: "ADBE", companyName: "Adobe Inc."),
        StockInfo(ticker: "CSCO", companyName: "Cisco Systems"),
        StockInfo(ticker: "AVGO", companyName: "Broadcom Inc."),
        StockInfo(ticker: "QCOM", companyName: "QUALCOMM Inc."),
        StockInfo(ticker: "TXN", companyName: "Texas Instruments"),
        StockInfo(ticker: "SNOW", companyName: "Snowflake Inc."),
        StockInfo(ticker: "PLTR", companyName: "Palantir Technologies"),
        StockInfo(ticker: "UBER", companyName: "Uber Technologies"),
        
        // Finance
        StockInfo(ticker: "JPM", companyName: "JPMorgan Chase & Co."),
        StockInfo(ticker: "BAC", companyName: "Bank of America"),
        StockInfo(ticker: "GS", companyName: "Goldman Sachs"),
        StockInfo(ticker: "MS", companyName: "Morgan Stanley"),
        StockInfo(ticker: "WFC", companyName: "Wells Fargo"),
        StockInfo(ticker: "V", companyName: "Visa Inc."),
        StockInfo(ticker: "MA", companyName: "Mastercard Inc."),
        StockInfo(ticker: "PYPL", companyName: "PayPal Holdings"),
        StockInfo(ticker: "SQ", companyName: "Block Inc. (Square)"),
        StockInfo(ticker: "COIN", companyName: "Coinbase Global"),
        
        // Retail & Consumer
        StockInfo(ticker: "WMT", companyName: "Walmart Inc."),
        StockInfo(ticker: "COST", companyName: "Costco Wholesale"),
        StockInfo(ticker: "TGT", companyName: "Target Corporation"),
        StockInfo(ticker: "HD", companyName: "Home Depot"),
        StockInfo(ticker: "LOW", companyName: "Lowe's Companies"),
        StockInfo(ticker: "NKE", companyName: "Nike Inc."),
        StockInfo(ticker: "SBUX", companyName: "Starbucks Corporation"),
        StockInfo(ticker: "MCD", companyName: "McDonald's Corporation"),
        StockInfo(ticker: "DIS", companyName: "Walt Disney Company"),
        
        // Auto & Transportation
        StockInfo(ticker: "F", companyName: "Ford Motor Company"),
        StockInfo(ticker: "GM", companyName: "General Motors"),
        StockInfo(ticker: "RIVN", companyName: "Rivian Automotive"),
        StockInfo(ticker: "LCID", companyName: "Lucid Group"),
        StockInfo(ticker: "DAL", companyName: "Delta Air Lines"),
        StockInfo(ticker: "UAL", companyName: "United Airlines"),
        StockInfo(ticker: "AAL", companyName: "American Airlines"),
        
        // Energy
        StockInfo(ticker: "XOM", companyName: "Exxon Mobil"),
        StockInfo(ticker: "CVX", companyName: "Chevron Corporation"),
        StockInfo(ticker: "COP", companyName: "ConocoPhillips"),
        StockInfo(ticker: "SLB", companyName: "Schlumberger"),
        
        // Healthcare & Pharma
        StockInfo(ticker: "JNJ", companyName: "Johnson & Johnson"),
        StockInfo(ticker: "UNH", companyName: "UnitedHealth Group"),
        StockInfo(ticker: "PFE", companyName: "Pfizer Inc."),
        StockInfo(ticker: "ABBV", companyName: "AbbVie Inc."),
        StockInfo(ticker: "TMO", companyName: "Thermo Fisher Scientific"),
        StockInfo(ticker: "ABT", companyName: "Abbott Laboratories"),
        StockInfo(ticker: "LLY", companyName: "Eli Lilly and Company"),
        StockInfo(ticker: "MRNA", companyName: "Moderna Inc."),
        
        // Communication
        StockInfo(ticker: "T", companyName: "AT&T Inc."),
        StockInfo(ticker: "VZ", companyName: "Verizon Communications"),
        StockInfo(ticker: "CMCSA", companyName: "Comcast Corporation"),
        StockInfo(ticker: "TMUS", companyName: "T-Mobile US"),
        
        // Semiconductors
        StockInfo(ticker: "TSM", companyName: "Taiwan Semiconductor"),
        StockInfo(ticker: "ASML", companyName: "ASML Holding"),
        StockInfo(ticker: "MU", companyName: "Micron Technology"),
        StockInfo(ticker: "AMAT", companyName: "Applied Materials"),
        StockInfo(ticker: "LRCX", companyName: "Lam Research"),
        
        // Entertainment & Media
        StockInfo(ticker: "SPOT", companyName: "Spotify Technology"),
        StockInfo(ticker: "ROKU", companyName: "Roku Inc."),
        StockInfo(ticker: "PARA", companyName: "Paramount Global"),
        
        // E-commerce & Delivery
        StockInfo(ticker: "SHOP", companyName: "Shopify Inc."),
        StockInfo(ticker: "EBAY", companyName: "eBay Inc."),
        StockInfo(ticker: "DASH", companyName: "DoorDash Inc."),
        
        // Aerospace & Defense
        StockInfo(ticker: "BA", companyName: "Boeing Company"),
        StockInfo(ticker: "LMT", companyName: "Lockheed Martin"),
        StockInfo(ticker: "RTX", companyName: "Raytheon Technologies"),
        StockInfo(ticker: "NOC", companyName: "Northrop Grumman"),
        
        // Industrial
        StockInfo(ticker: "CAT", companyName: "Caterpillar Inc."),
        StockInfo(ticker: "DE", companyName: "Deere & Company"),
        StockInfo(ticker: "GE", companyName: "General Electric"),
        
        // Real Estate & REITs
        StockInfo(ticker: "AMT", companyName: "American Tower Corp."),
        StockInfo(ticker: "PLD", companyName: "Prologis Inc."),
        StockInfo(ticker: "EQIX", companyName: "Equinix Inc."),
        
        // ETFs (Popular for options)
        StockInfo(ticker: "SPY", companyName: "SPDR S&P 500 ETF"),
        StockInfo(ticker: "QQQ", companyName: "Invesco QQQ ETF"),
        StockInfo(ticker: "IWM", companyName: "iShares Russell 2000"),
        StockInfo(ticker: "DIA", companyName: "SPDR Dow Jones Industrial"),
        StockInfo(ticker: "VOO", companyName: "Vanguard S&P 500 ETF"),
        StockInfo(ticker: "VTI", companyName: "Vanguard Total Stock Market"),
        StockInfo(ticker: "ARKK", companyName: "ARK Innovation ETF"),
        StockInfo(ticker: "TLT", companyName: "iShares 20+ Year Treasury"),
        StockInfo(ticker: "GLD", companyName: "SPDR Gold Shares"),
        StockInfo(ticker: "SLV", companyName: "iShares Silver Trust"),
        
        // Meme Stocks / Popular with Options
        StockInfo(ticker: "GME", companyName: "GameStop Corp."),
        StockInfo(ticker: "AMC", companyName: "AMC Entertainment"),
        StockInfo(ticker: "BB", companyName: "BlackBerry Limited"),
        StockInfo(ticker: "BBBY", companyName: "Bed Bath & Beyond"),
    ]
    
    /// Search stocks by ticker or company name
    /// - Parameter query: Search text
    /// - Returns: Array of matching stocks, sorted by relevance
    static func search(query: String) -> [StockInfo] {
        guard !query.isEmpty else { return [] }
        
        let lowercaseQuery = query.lowercased()
        
        // Exact ticker match first
        let exactMatches = popularStocks.filter { $0.ticker.lowercased() == lowercaseQuery }
        
        // Ticker starts with query
        let tickerMatches = popularStocks.filter {
            $0.ticker.lowercased().hasPrefix(lowercaseQuery) && !exactMatches.contains($0)
        }
        
        // Company name contains query
        let nameMatches = popularStocks.filter {
            $0.companyName.lowercased().contains(lowercaseQuery) && 
            !exactMatches.contains($0) && 
            !tickerMatches.contains($0)
        }
        
        // Combine and limit results
        return (exactMatches + tickerMatches + nameMatches).prefix(8).map { $0 }
    }
    
    /// Get stock info for a specific ticker
    static func info(for ticker: String) -> StockInfo? {
        popularStocks.first { $0.ticker.lowercased() == ticker.lowercased() }
    }
}
