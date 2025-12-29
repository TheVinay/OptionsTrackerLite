import Foundation

struct TradeValidator {
    
    struct ValidationError: Identifiable {
        let id = UUID()
        let message: String
    }
    
    /// Validates a trade and returns array of errors (empty if valid)
    static func validate(
        ticker: String,
        tradeDate: Date,
        expirationDate: Date,
        premium: Double?,
        quantity: Int,
        strike: Double?
    ) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Ticker validation
        let trimmedTicker = ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTicker.isEmpty {
            errors.append(ValidationError(message: "Ticker symbol is required"))
        } else if trimmedTicker.count > 10 {
            errors.append(ValidationError(message: "Ticker symbol is too long"))
        }
        
        // Date validation
        if expirationDate <= tradeDate {
            errors.append(ValidationError(message: "Expiration date must be after trade date"))
        }
        
        // Check if dates are reasonable (not too far in past/future)
        let calendar = Calendar.current
        if let yearAgo = calendar.date(byAdding: .year, value: -5, to: Date()),
           tradeDate < yearAgo {
            errors.append(ValidationError(message: "Trade date seems too far in the past"))
        }
        
        if let fiveYearsAhead = calendar.date(byAdding: .year, value: 5, to: Date()),
           expirationDate > fiveYearsAhead {
            errors.append(ValidationError(message: "Expiration date seems too far in the future"))
        }
        
        // Premium validation
        if let premium = premium {
            if premium <= 0 {
                errors.append(ValidationError(message: "Premium must be greater than 0"))
            } else if premium > 10000 {
                errors.append(ValidationError(message: "Premium seems unusually high"))
            }
        }
        
        // Quantity validation
        if quantity <= 0 {
            errors.append(ValidationError(message: "Quantity must be at least 1"))
        } else if quantity > 1000 {
            errors.append(ValidationError(message: "Quantity seems unusually high (max 1000)"))
        }
        
        // Strike validation
        if let strike = strike {
            if strike <= 0 {
                errors.append(ValidationError(message: "Strike price must be greater than 0"))
            } else if strike > 100000 {
                errors.append(ValidationError(message: "Strike price seems unusually high"))
            }
        }
        
        return errors
    }
    
    /// Quick check if basic fields are valid (for enabling/disabling save button)
    static func isBasicallyValid(ticker: String, premium: Double?, quantity: Int) -> Bool {
        let trimmedTicker = ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTicker.isEmpty else { return false }
        
        if let premium = premium, premium <= 0 { return false }
        if quantity <= 0 { return false }
        
        return true
    }
}
