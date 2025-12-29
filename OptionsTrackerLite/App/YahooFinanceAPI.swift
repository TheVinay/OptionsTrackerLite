import Foundation

// MARK: - Yahoo Finance API Service

actor YahooFinanceAPI {
    
    // Singleton
    static let shared = YahooFinanceAPI()
    
    private init() {}
    
    // MARK: - Search for stocks
    
    /// Search for stocks by ticker or company name
    /// - Parameter query: Search query (ticker or company name)
    /// - Returns: Array of stock results
    func searchStocks(query: String) async throws -> [StockInfo] {
        guard !query.isEmpty else { return [] }
        
        // Yahoo Finance search endpoint
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://query2.finance.yahoo.com/v1/finance/search?q=\(encodedQuery)&quotesCount=8&newsCount=0"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 5.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(YahooSearchResponse.self, from: data)
        
        // Convert to StockInfo
        return result.quotes.compactMap { quote in
            // Only return equities and ETFs
            guard ["EQUITY", "ETF", "MUTUALFUND"].contains(quote.quoteType) else {
                return nil
            }
            
            return StockInfo(
                ticker: quote.symbol,
                companyName: quote.longname ?? quote.shortname ?? quote.symbol
            )
        }
    }
    
    // MARK: - Get quote for a specific ticker
    
    /// Get current price and info for a ticker
    /// - Parameter ticker: Stock ticker symbol
    /// - Returns: Stock quote information
    func getQuote(ticker: String) async throws -> StockQuote {
        let encodedTicker = ticker.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ticker
        let urlString = "https://query2.finance.yahoo.com/v7/finance/quote?symbols=\(encodedTicker)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 5.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(YahooQuoteResponse.self, from: data)
        
        guard let quoteData = result.quoteResponse.result.first else {
            throw APIError.noData
        }
        
        return StockQuote(
            ticker: quoteData.symbol,
            companyName: quoteData.longName ?? quoteData.shortName ?? quoteData.symbol,
            price: quoteData.regularMarketPrice,
            change: quoteData.regularMarketChange,
            changePercent: quoteData.regularMarketChangePercent
        )
    }
}

// MARK: - Models

struct StockQuote {
    let ticker: String
    let companyName: String
    let price: Double?
    let change: Double?
    let changePercent: Double?
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .noData: return "No data returned"
        case .decodingError: return "Failed to decode response"
        }
    }
}

// MARK: - Yahoo API Response Models

private struct YahooSearchResponse: Codable {
    let quotes: [YahooQuote]
}

private struct YahooQuote: Codable {
    let symbol: String
    let shortname: String?
    let longname: String?
    let quoteType: String
    let exchange: String?
}

private struct YahooQuoteResponse: Codable {
    let quoteResponse: QuoteResponseData
}

private struct QuoteResponseData: Codable {
    let result: [QuoteResult]
}

private struct QuoteResult: Codable {
    let symbol: String
    let shortName: String?
    let longName: String?
    let regularMarketPrice: Double?
    let regularMarketChange: Double?
    let regularMarketChangePercent: Double?
}
