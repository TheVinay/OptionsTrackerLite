import SwiftUI
import Charts

// MARK: - Client Tools View

struct ClientToolsView: View {
    @Bindable var profile: ClientProfile
    
    @State private var selectedTool: ToolType = .breakEven
    
    enum ToolType: String, CaseIterable, Identifiable {
        case breakEven = "Break-Even"
        case positionSize = "Position Size"
        case incomeProjector = "Income"
        case assignmentRisk = "Assignment"
        case rollHelper = "Roll"
        case plVisualizer = "P/L Chart"
        case wheelTracker = "Wheel"
        case templates = "Templates"
        case portfolioHeat = "Heat"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .breakEven: return "chart.line.uptrend.xyaxis"
            case .positionSize: return "dollarsign.circle"
            case .incomeProjector: return "banknote"
            case .assignmentRisk: return "exclamationmark.triangle"
            case .rollHelper: return "arrow.triangle.2.circlepath"
            case .plVisualizer: return "chart.xyaxis.line"
            case .wheelTracker: return "arrow.clockwise.circle"
            case .templates: return "doc.on.doc"
            case .portfolioHeat: return "flame"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tool Picker - Horizontal Scrolling Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ToolType.allCases) { tool in
                        ToolPickerCard(
                            tool: tool,
                            isSelected: selectedTool == tool
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTool = tool
                            }
                        }
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Tool Content
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTool {
                    case .breakEven:
                        BreakEvenCalculator()
                    case .positionSize:
                        PositionSizeCalculator()
                    case .incomeProjector:
                        IncomeProjectorCalculator(profile: profile)
                    case .assignmentRisk:
                        AssignmentRiskCalculator()
                    case .rollHelper:
                        RollPositionHelper()
                    case .plVisualizer:
                        PLVisualizerTool()
                    case .wheelTracker:
                        WheelStrategyTracker(profile: profile)
                    case .templates:
                        TradeTemplates(profile: profile)
                    case .portfolioHeat:
                        PortfolioHeatMonitor(profile: profile)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Tools")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Tool Picker Card

private struct ToolPickerCard: View {
    let tool: ClientToolsView.ToolType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: tool.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Text(tool.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 85, height: 85)
            .background(
                isSelected ? 
                    AnyShapeStyle(.blue.gradient) : 
                    AnyShapeStyle(.quaternary.opacity(0.5))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            }
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Break-Even Calculator

struct BreakEvenCalculator: View {
    @State private var strategyType: OptionType = .coveredCall
    @State private var stockPrice: String = ""
    @State private var strikePrice: String = ""
    @State private var premiumReceived: String = ""
    @State private var contracts: String = "1"
    
    private var breakEvenPrice: Double? {
        guard let stock = Double(stockPrice),
              let premium = Double(premiumReceived) else { return nil }
        
        switch strategyType {
        case .coveredCall:
            // Break-even = Stock price - Premium received
            return stock - premium
        case .cashSecuredPut:
            // Break-even = Strike - Premium received
            guard let strike = Double(strikePrice) else { return nil }
            return strike - premium
        case .call, .put:
            // For buying options: Strike + Premium (calls) or Strike - Premium (puts)
            guard let strike = Double(strikePrice) else { return nil }
            if strategyType == .call {
                return strike + premium
            } else {
                return strike - premium
            }
        }
    }
    
    private var totalPremium: Double? {
        guard let premium = Double(premiumReceived),
              let qty = Double(contracts) else { return nil }
        return premium * 100 * qty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                Text("Break-Even Calculator")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HelpButton(
                    title: "Break-Even Price",
                    message: "The stock price at which you neither profit nor lose. For covered calls: Stock cost - Premium. For cash-secured puts: Strike - Premium."
                )
            }
            
            CalloutView(
                type: .info,
                message: "Calculate the exact price where your trade breaks even."
            )
            
            // Strategy Type Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy Type")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Picker("Strategy", selection: $strategyType) {
                    ForEach(OptionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Input Fields
            VStack(spacing: 16) {
                if strategyType == .coveredCall {
                    HintTextField(
                        title: "Stock Purchase Price",
                        hint: "50.00",
                        text: $stockPrice,
                        keyboardType: .decimalPad
                    )
                }
                
                if strategyType == .cashSecuredPut || strategyType == .call || strategyType == .put {
                    HintTextField(
                        title: "Strike Price",
                        hint: "50.00",
                        text: $strikePrice,
                        keyboardType: .decimalPad
                    )
                }
                
                HintTextField(
                    title: "Premium (per share)",
                    hint: "2.50",
                    text: $premiumReceived,
                    keyboardType: .decimalPad
                )
                
                HintTextField(
                    title: "Number of Contracts",
                    hint: "1",
                    text: $contracts,
                    keyboardType: .numberPad
                )
            }
            
            // Results
            if let breakEven = breakEvenPrice {
                VStack(spacing: 16) {
                    Divider()
                    
                    // Break-Even Price
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Break-Even Price")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(breakEven.formatted(.currency(code: "USD")))
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.blue)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    
                    // Total Premium
                    if let total = totalPremium {
                        HStack {
                            Label("Total Premium Collected", systemImage: "banknote")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(total.formatted(.currency(code: "USD")))
                                .font(.headline)
                                .foregroundStyle(.green)
                        }
                        .padding()
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    }
                    
                    // Formula Explanation
                    FormulaExplainer(
                        formulaName: "Break-Even Formula",
                        formula: strategyType == .coveredCall 
                            ? "Stock Price - Premium Received"
                            : "Strike Price - Premium Received",
                        example: strategyType == .coveredCall
                            ? "Stock at $50, sold call for $2: $50 - $2 = $48"
                            : "Strike $50, premium $2: $50 - $2 = $48"
                    )
                }
            }
        }
    }
}

// MARK: - Position Size Calculator

struct PositionSizeCalculator: View {
    @State private var accountSize: String = ""
    @State private var riskPercent: String = "2"
    @State private var stockPrice: String = ""
    @State private var strikePrice: String = ""
    @State private var strategyType: OptionType = .cashSecuredPut
    
    private var maxRiskAmount: Double? {
        guard let account = Double(accountSize),
              let risk = Double(riskPercent) else { return nil }
        return account * (risk / 100)
    }
    
    private var capitalRequired: Double? {
        switch strategyType {
        case .cashSecuredPut:
            guard let strike = Double(strikePrice) else { return nil }
            return strike * 100 // Per contract
        case .coveredCall:
            guard let stock = Double(stockPrice) else { return nil }
            return stock * 100 // Per 100 shares
        case .call, .put:
            return nil // For now
        }
    }
    
    private var recommendedContracts: Int? {
        guard let maxRisk = maxRiskAmount,
              let capital = capitalRequired,
              capital > 0 else { return nil }
        return Int(maxRisk / capital)
    }
    
    private var totalCapitalNeeded: Double? {
        guard let contracts = recommendedContracts,
              let capital = capitalRequired else { return nil }
        return Double(contracts) * capital
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "dollarsign.circle")
                    .font(.title2)
                    .foregroundStyle(.green)
                
                Text("Position Size Calculator")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HelpButton(
                    title: "Position Sizing",
                    message: "Calculate how many contracts you should trade based on your account size and risk tolerance. Never risk more than you can afford to lose!"
                )
            }
            
            CalloutView(
                type: .tip,
                message: "Professional traders typically risk 1-2% of their account per trade."
            )
            
            // Strategy Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy Type")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Picker("Strategy", selection: $strategyType) {
                    Text("Cash-Secured Put").tag(OptionType.cashSecuredPut)
                    Text("Covered Call").tag(OptionType.coveredCall)
                }
                .pickerStyle(.segmented)
            }
            
            // Input Fields
            VStack(spacing: 16) {
                HintTextField(
                    title: "Account Size",
                    hint: "10000",
                    text: $accountSize,
                    keyboardType: .decimalPad
                )
                
                HintTextField(
                    title: "Risk Percentage (%)",
                    hint: "2",
                    text: $riskPercent,
                    keyboardType: .decimalPad
                )
                
                if strategyType == .cashSecuredPut {
                    HintTextField(
                        title: "Strike Price",
                        hint: "50.00",
                        text: $strikePrice,
                        keyboardType: .decimalPad
                    )
                } else {
                    HintTextField(
                        title: "Stock Price",
                        hint: "50.00",
                        text: $stockPrice,
                        keyboardType: .decimalPad
                    )
                }
            }
            
            // Results
            if let maxRisk = maxRiskAmount {
                VStack(spacing: 16) {
                    Divider()
                    
                    // Max Risk Amount
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Max Risk Per Trade")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(maxRisk.formatted(.currency(code: "USD")))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    
                    // Recommended Contracts
                    if let contracts = recommendedContracts, contracts > 0 {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recommended Contracts")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text("\(contracts)")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(.green)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        
                        // Total Capital Required
                        if let totalCapital = totalCapitalNeeded {
                            HStack {
                                Label("Total Capital Required", systemImage: "banknote")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text(totalCapital.formatted(.currency(code: "USD")))
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                            }
                            .padding()
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Percentage of Account
                        if let account = Double(accountSize), account > 0, let totalCapital = totalCapitalNeeded {
                            let percentage = (totalCapital / account) * 100
                            
                            HStack {
                                Label("% of Account Used", systemImage: "chart.pie")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text(String(format: "%.1f%%", percentage))
                                    .font(.headline)
                                    .foregroundStyle(percentage > 50 ? .red : .green)
                            }
                            .padding()
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                            
                            if percentage > 50 {
                                CalloutView(
                                    type: .warning,
                                    message: "Warning: This position uses more than 50% of your account. Consider reducing position size or increasing account size."
                                )
                            }
                        }
                    } else if recommendedContracts == 0 {
                        CalloutView(
                            type: .warning,
                            message: "Your account size is too small for this strategy with your current risk tolerance. Consider a smaller position or increasing your account size."
                        )
                    }
                    
                    // Formula
                    FormulaExplainer(
                        formulaName: "Position Size Formula",
                        formula: "Max Risk = Account Size × Risk %\nContracts = Max Risk ÷ Capital per Contract",
                        example: "$10,000 account, 2% risk, $50 strike:\n$200 max risk ÷ $5,000 per contract = 0.04\nRound down = 0 contracts (too small)"
                    )
                }
            }
        }
    }
}

// MARK: - Income Projector Calculator

struct IncomeProjectorCalculator: View {
    @Bindable var profile: ClientProfile
    
    @State private var avgPremiumPerTrade: String = ""
    @State private var tradesPerMonth: String = "4"
    @State private var expectedWinRate: String = "75"
    
    private var monthlyIncome: (conservative: Double, moderate: Double, aggressive: Double)? {
        guard let premium = Double(avgPremiumPerTrade),
              let trades = Double(tradesPerMonth),
              let winRate = Double(expectedWinRate) else { return nil }
        
        let winRateDecimal = winRate / 100
        
        // Conservative: Win rate - 10%, premium - 20%
        let conservative = (premium * 0.8) * trades * max(0.1, winRateDecimal - 0.1)
        
        // Moderate: As entered
        let moderate = premium * trades * winRateDecimal
        
        // Aggressive: Win rate + 5%, premium + 10%
        let aggressive = (premium * 1.1) * trades * min(0.95, winRateDecimal + 0.05)
        
        return (conservative, moderate, aggressive)
    }
    
    // Calculate from profile's historical data
    private var historicalStats: (avgPremium: Double, winRate: Double)? {
        let closedTrades = profile.trades.filter { $0.isClosed }
        guard !closedTrades.isEmpty else { return nil }
        
        let wins = closedTrades.filter { ($0.realizedPL ?? 0) > 0 }.count
        let winRate = Double(wins) / Double(closedTrades.count) * 100
        
        let avgPremium = closedTrades.map { $0.totalPremium }.reduce(0, +) / Double(closedTrades.count)
        
        return (avgPremium, winRate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "banknote")
                    .font(.title2)
                    .foregroundStyle(.green)
                
                Text("Premium Income Projector")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HelpButton(
                    title: "Income Projection",
                    message: "Estimate your potential monthly and annual income from options trading based on your average premium and win rate."
                )
            }
            
            CalloutView(
                type: .tip,
                message: "Use conservative estimates for realistic goal-setting. Actual results may vary."
            )
            
            // Historical Stats (if available)
            if let stats = historicalStats {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Historical Stats")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Avg Premium")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(stats.avgPremium.formatted(.currency(code: "USD")))
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Win Rate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f%%", stats.winRate))
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        Button("Use These") {
                            avgPremiumPerTrade = String(format: "%.2f", stats.avgPremium)
                            expectedWinRate = String(format: "%.0f", stats.winRate)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding()
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            
            // Input Fields
            VStack(spacing: 16) {
                HintTextField(
                    title: "Avg Premium Per Trade",
                    hint: "150.00",
                    text: $avgPremiumPerTrade,
                    keyboardType: .decimalPad
                )
                
                HintTextField(
                    title: "Trades Per Month",
                    hint: "4",
                    text: $tradesPerMonth,
                    keyboardType: .numberPad
                )
                
                HintTextField(
                    title: "Expected Win Rate (%)",
                    hint: "75",
                    text: $expectedWinRate,
                    keyboardType: .numberPad
                )
            }
            
            // Results
            if let income = monthlyIncome {
                VStack(spacing: 16) {
                    Divider()
                    
                    Text("Monthly Projections")
                        .font(.headline)
                    
                    // Conservative
                    IncomeScenarioCard(
                        title: "Conservative",
                        monthly: income.conservative,
                        color: .orange,
                        description: "Lower premium, reduced win rate"
                    )
                    
                    // Moderate
                    IncomeScenarioCard(
                        title: "Moderate",
                        monthly: income.moderate,
                        color: .blue,
                        description: "As entered above"
                    )
                    
                    // Aggressive
                    IncomeScenarioCard(
                        title: "Aggressive",
                        monthly: income.aggressive,
                        color: .green,
                        description: "Higher premium, better win rate"
                    )
                    
                    // Annual Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Annual Projections")
                            .font(.headline)
                        
                        HStack {
                            Text("Conservative")
                                .font(.caption)
                            Spacer()
                            Text((income.conservative * 12).formatted(.currency(code: "USD")))
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Moderate")
                                .font(.caption)
                            Spacer()
                            Text((income.moderate * 12).formatted(.currency(code: "USD")))
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Aggressive")
                                .font(.caption)
                            Spacer()
                            Text((income.aggressive * 12).formatted(.currency(code: "USD")))
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    
                    CalloutView(
                        type: .info,
                        message: "Remember: Past performance does not guarantee future results. Always manage your risk."
                    )
                }
            }
        }
    }
}

private struct IncomeScenarioCard: View {
    let title: String
    let monthly: Double
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(monthly.formatted(.currency(code: "USD")))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - Assignment Risk Calculator

struct AssignmentRiskCalculator: View {
    @State private var strikePrice: String = ""
    @State private var currentStockPrice: String = ""
    @State private var daysToExpiration: String = ""
    @State private var optionType: OptionType = .cashSecuredPut
    @State private var hasDividendSoon: Bool = false
    
    private var isITM: Bool? {
        guard let strike = Double(strikePrice),
              let stock = Double(currentStockPrice) else { return nil }
        
        switch optionType {
        case .cashSecuredPut, .put:
            return stock < strike
        case .coveredCall, .call:
            return stock > strike
        }
    }
    
    private var riskLevel: (level: String, color: Color, action: String)? {
        guard let itm = isITM,
              let dte = Int(daysToExpiration) else { return nil }
        
        if itm {
            // In the money
            if dte <= 2 || hasDividendSoon {
                return ("HIGH", .red, "Consider closing or rolling immediately")
            } else if dte <= 7 {
                return ("MEDIUM-HIGH", .orange, "Monitor closely, consider rolling")
            } else {
                return ("MEDIUM", .yellow, "Watch this position")
            }
        } else {
            // Out of the money
            if dte <= 2 && hasDividendSoon {
                return ("MEDIUM", .yellow, "Low risk but dividend may cause early assignment")
            } else {
                return ("LOW", .green, "Assignment unlikely")
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text("Assignment Risk")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HelpButton(
                    title: "Assignment Risk",
                    message: "Calculate the risk of early assignment on your short options. ITM options near expiration have high assignment risk."
                )
            }
            
            CalloutView(
                type: .warning,
                message: "Early assignment can happen any time, but is most common when options are deep ITM and near expiration."
            )
            
            // Strategy Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Option Type")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Picker("Type", selection: $optionType) {
                    Text("Cash-Secured Put").tag(OptionType.cashSecuredPut)
                    Text("Covered Call").tag(OptionType.coveredCall)
                }
                .pickerStyle(.segmented)
            }
            
            // Input Fields
            VStack(spacing: 16) {
                HintTextField(
                    title: "Strike Price",
                    hint: "50.00",
                    text: $strikePrice,
                    keyboardType: .decimalPad
                )
                
                HintTextField(
                    title: "Current Stock Price",
                    hint: "48.50",
                    text: $currentStockPrice,
                    keyboardType: .decimalPad
                )
                
                HintTextField(
                    title: "Days to Expiration",
                    hint: "5",
                    text: $daysToExpiration,
                    keyboardType: .numberPad
                )
                
                Toggle(isOn: $hasDividendSoon) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dividend Before Expiration")
                            .font(.subheadline)
                        Text("Increases assignment risk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Results
            if let risk = riskLevel {
                VStack(spacing: 16) {
                    Divider()
                    
                    // Risk Level
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: risk.level == "HIGH" ? "exclamationmark.triangle.fill" : 
                                  risk.level.contains("MEDIUM") ? "exclamationmark.circle.fill" : 
                                  "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(risk.color)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Risk Level")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text(risk.level)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(risk.color)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(risk.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    
                    // Status
                    if let itm = isITM {
                        HStack {
                            Label(itm ? "In The Money" : "Out of The Money", 
                                  systemImage: itm ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(itm ? "Higher Risk" : "Lower Risk")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(itm ? .red : .green)
                        }
                        .padding()
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    }
                    
                    // Action Recommendation
                    CalloutView(
                        type: risk.level == "HIGH" ? .error : 
                              risk.level.contains("MEDIUM") ? .warning : .tip,
                        message: risk.action
                    )
                    
                    // Additional Info
                    if hasDividendSoon {
                        CalloutView(
                            type: .warning,
                            message: "⚠️ Dividend Alert: Covered calls are often assigned early before ex-dividend date so the buyer can collect the dividend."
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Roll Position Helper

struct RollPositionHelper: View {
    @State private var currentStrike: String = ""
    @State private var currentPremium: String = ""
    @State private var currentDTE: String = ""
    
    @State private var newStrike: String = ""
    @State private var newPremium: String = ""
    @State private var newDTE: String = ""
    
    @State private var strategyType: OptionType = .cashSecuredPut
    
    private var additionalCredit: Double? {
        guard let current = Double(currentPremium),
              let new = Double(newPremium) else { return nil }
        return new - current
    }
    
    private var totalCredit: Double? {
        guard let current = Double(currentPremium),
              let new = Double(newPremium) else { return nil }
        return current + new
    }
    
    private var daysExtended: Int? {
        guard let current = Int(currentDTE),
              let new = Int(newDTE) else { return nil }
        return new - current
    }
    
    private var newBreakEven: Double? {
        guard let strike = Double(newStrike),
              let total = totalCredit else { return nil }
        return strike - total
    }
    
    private var shouldRoll: Bool? {
        guard let credit = additionalCredit,
              let days = daysExtended else { return nil }
        
        // Simple heuristic: Worth rolling if you get meaningful credit and extend time
        return credit > 0 && days >= 7
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title2)
                    .foregroundStyle(.purple)
                
                Text("Roll Position Helper")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HelpButton(
                    title: "Rolling Positions",
                    message: "Rolling means closing your current position and opening a new one with a different strike or expiration. This calculator helps you decide if it's worth it."
                )
            }
            
            CalloutView(
                type: .tip,
                message: "Rolling is common when your position is challenged or you want to extend duration."
            )
            
            // Strategy Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy Type")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Picker("Strategy", selection: $strategyType) {
                    ForEach(OptionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Current Position
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Position")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    HintTextField(
                        title: "Strike",
                        hint: "50",
                        text: $currentStrike,
                        keyboardType: .decimalPad
                    )
                    
                    HintTextField(
                        title: "Premium",
                        hint: "2.00",
                        text: $currentPremium,
                        keyboardType: .decimalPad
                    )
                    
                    HintTextField(
                        title: "DTE",
                        hint: "3",
                        text: $currentDTE,
                        keyboardType: .numberPad
                    )
                }
            }
            .padding()
            .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            
            // Roll To (New Position)
            VStack(alignment: .leading, spacing: 12) {
                Text("Roll To (New Position)")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    HintTextField(
                        title: "Strike",
                        hint: "48",
                        text: $newStrike,
                        keyboardType: .decimalPad
                    )
                    
                    HintTextField(
                        title: "Premium",
                        hint: "2.75",
                        text: $newPremium,
                        keyboardType: .decimalPad
                    )
                    
                    HintTextField(
                        title: "DTE",
                        hint: "30",
                        text: $newDTE,
                        keyboardType: .numberPad
                    )
                }
            }
            .padding()
            .background(.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            
            // Results
            if let credit = additionalCredit {
                VStack(spacing: 16) {
                    Divider()
                    
                    // Additional Credit/Debit
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(credit >= 0 ? "Additional Credit" : "Additional Debit")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(abs(credit).formatted(.currency(code: "USD")))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(credit >= 0 ? .green : .red)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background((credit >= 0 ? Color.green : Color.red).opacity(0.1), 
                              in: RoundedRectangle(cornerRadius: 12))
                    
                    // Total Credit
                    if let total = totalCredit {
                        HStack {
                            Label("Total Credit", systemImage: "dollarsign.circle")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(total.formatted(.currency(code: "USD")))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    }
                    
                    // Days Extended
                    if let days = daysExtended {
                        HStack {
                            Label("Days Extended", systemImage: "calendar")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(days) days")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(days > 0 ? .blue : .orange)
                        }
                        .padding()
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    }
                    
                    // New Break-Even
                    if let breakEven = newBreakEven {
                        HStack {
                            Label("New Break-Even", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(breakEven.formatted(.currency(code: "USD")))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    }
                    
                    // Recommendation
                    if let should = shouldRoll {
                        CalloutView(
                            type: should ? .tip : .warning,
                            message: should 
                                ? "✅ Rolling looks favorable! You're collecting additional credit and extending time."
                                : "⚠️ Consider if this roll makes sense. You may not be collecting enough credit for the time extension."
                        )
                    }
                    
                    // Formula
                    FormulaExplainer(
                        formulaName: "Roll Calculation",
                        formula: "Additional Credit = New Premium - Current Premium\nTotal Credit = Current + New\nNew Break-Even = New Strike - Total Credit",
                        example: "Current: $50 strike, $2 premium\nRoll to: $48 strike, $2.75 premium\nAdditional: $0.75\nTotal: $2.75\nBreak-even: $45.25"
                    )
                }
            }
        }
    }
}

// MARK: - P/L Visualizer

struct PLVisualizerTool: View {
    @State private var strategyType: OptionType = .cashSecuredPut
    @State private var strikePrice: String = ""
    @State private var premium: String = ""
    @State private var stockPriceMin: String = ""
    @State private var stockPriceMax: String = ""
    
    private var chartData: [PLPoint] {
        guard let strike = Double(strikePrice),
              let prem = Double(premium),
              let minPrice = Double(stockPriceMin),
              let maxPrice = Double(stockPriceMax),
              minPrice < maxPrice else { return [] }
        
        var points: [PLPoint] = []
        let step = (maxPrice - minPrice) / 50
        
        for i in 0...50 {
            let stockPrice = minPrice + (step * Double(i))
            let pl = calculatePL(strategy: strategyType, strike: strike, premium: prem, stockPrice: stockPrice)
            points.append(PLPoint(stockPrice: stockPrice, profitLoss: pl))
        }
        
        return points
    }
    
    private func calculatePL(strategy: OptionType, strike: Double, premium: Double, stockPrice: Double) -> Double {
        let premiumTotal = premium * 100
        
        switch strategy {
        case .cashSecuredPut:
            if stockPrice < strike {
                // Assigned: bought stock at strike, current value is stockPrice
                return premiumTotal + ((stockPrice - strike) * 100)
            } else {
                // Not assigned: keep premium
                return premiumTotal
            }
            
        case .coveredCall:
            if stockPrice > strike {
                // Called away: sold at strike
                return premiumTotal + ((strike - stockPrice) * 100)
            } else {
                // Keep stock and premium
                return premiumTotal
            }
            
        case .put:
            // Long put: profit if stock below strike
            let intrinsicValue = max(0, strike - stockPrice)
            return (intrinsicValue - premium) * 100
            
        case .call:
            // Long call: profit if stock above strike
            let intrinsicValue = max(0, stockPrice - strike)
            return (intrinsicValue - premium) * 100
        }
    }
    
    private var breakEvenPrice: Double? {
        guard let strike = Double(strikePrice),
              let prem = Double(premium) else { return nil }
        
        switch strategyType {
        case .cashSecuredPut: return strike - prem
        case .coveredCall: return strike + prem
        case .put: return strike - prem
        case .call: return strike + prem
        }
    }
    
    private var maxProfit: Double? {
        guard let prem = Double(premium) else { return nil }
        
        switch strategyType {
        case .cashSecuredPut, .coveredCall:
            return prem * 100
        case .put, .call:
            return nil // Unlimited for long options
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                Text("P/L Visualizer")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HelpButton(
                    title: "P/L Chart",
                    message: "Visualize your profit/loss at different stock prices. Green = profit, Red = loss."
                )
            }
            
            CalloutView(
                type: .info,
                message: "See exactly how your trade performs at any stock price."
            )
            
            // Strategy Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy Type")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Picker("Strategy", selection: $strategyType) {
                    ForEach(OptionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Input Fields
            VStack(spacing: 16) {
                HintTextField(
                    title: "Strike Price",
                    hint: "50.00",
                    text: $strikePrice,
                    keyboardType: .decimalPad
                )
                
                HintTextField(
                    title: "Premium (per share)",
                    hint: "2.50",
                    text: $premium,
                    keyboardType: .decimalPad
                )
                
                HStack(spacing: 12) {
                    HintTextField(
                        title: "Chart Min Price",
                        hint: "40",
                        text: $stockPriceMin,
                        keyboardType: .decimalPad
                    )
                    
                    HintTextField(
                        title: "Chart Max Price",
                        hint: "60",
                        text: $stockPriceMax,
                        keyboardType: .decimalPad
                    )
                }
            }
            
            // Chart
            if !chartData.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    Text("Profit/Loss Chart")
                        .font(.headline)
                    
                    Chart(chartData) { point in
                        LineMark(
                            x: .value("Stock Price", point.stockPrice),
                            y: .value("P&L", point.profitLoss)
                        )
                        .foregroundStyle(point.profitLoss >= 0 ? .green : .red)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        // Zero line
                        RuleMark(y: .value("Break Even", 0))
                            .foregroundStyle(.gray)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        
                        // Break-even marker
                        if let breakEven = breakEvenPrice {
                            RuleMark(x: .value("Break Even", breakEven))
                                .foregroundStyle(.orange)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [3, 3]))
                        }
                    }
                    .frame(height: 250)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom)
                    }
                    
                    // Stats
                    VStack(spacing: 12) {
                        if let breakEven = breakEvenPrice {
                            HStack {
                                Label("Break-Even Price", systemImage: "equal.circle")
                                    .font(.subheadline)
                                Spacer()
                                Text(breakEven.formatted(.currency(code: "USD")))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.orange)
                            }
                            .padding()
                            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        }
                        
                        if let maxProfit = maxProfit {
                            HStack {
                                Label("Max Profit", systemImage: "arrow.up.circle")
                                    .font(.subheadline)
                                Spacer()
                                Text(maxProfit.formatted(.currency(code: "USD")))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                            }
                            .padding()
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
    }
}

private struct PLPoint: Identifiable {
    let id = UUID()
    let stockPrice: Double
    let profitLoss: Double
}

// MARK: - StatCard (reusable)

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Wheel Strategy Tracker

struct WheelStrategyTracker: View {
    @Bindable var profile: ClientProfile
    
    @State private var selectedTicker: String = ""
    
    private var wheelCycles: [WheelCycle] {
        analyzeWheelCycles(from: profile.trades)
    }
    
    private func analyzeWheelCycles(from trades: [Trade]) -> [WheelCycle] {
        var cycles: [WheelCycle] = []
        
        // Group by ticker
        let groupedByTicker = Dictionary(grouping: trades) { $0.ticker }
        
        for (ticker, tickerTrades) in groupedByTicker {
            let sorted = tickerTrades.sorted { $0.tradeDate < $1.tradeDate }
            
            var cspTrades: [Trade] = []
            var ccTrades: [Trade] = []
            
            for trade in sorted {
                if trade.type == .cashSecuredPut {
                    cspTrades.append(trade)
                } else if trade.type == .coveredCall {
                    ccTrades.append(trade)
                }
            }
            
            // Create cycles
            if !cspTrades.isEmpty || !ccTrades.isEmpty {
                let totalPL = sorted.filter { $0.isClosed }.compactMap { $0.realizedPL }.reduce(0, +)
                let totalDays = sorted.isEmpty ? 0 : Calendar.current.dateComponents([.day],
                    from: sorted.first!.tradeDate,
                    to: sorted.last!.tradeDate).day ?? 0
                
                cycles.append(WheelCycle(
                    ticker: ticker,
                    cspCount: cspTrades.count,
                    ccCount: ccTrades.count,
                    totalPL: totalPL,
                    totalDays: totalDays,
                    isComplete: ccTrades.contains { $0.isClosed }
                ))
            }
        }
        
        return cycles.sorted { $0.totalPL > $1.totalPL }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "arrow.clockwise.circle")
                    .font(.title2)
                    .foregroundStyle(.purple)
                
                Text("Wheel Strategy Tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HelpButton(
                    title: "The Wheel Strategy",
                    message: "Sell CSP → Get Assigned → Sell CC → Get Called Away. This tracks your complete wheel cycles per ticker."
                )
            }
            
            CalloutView(
                type: .tip,
                message: "The Wheel is a popular income strategy that generates premium from CSPs and Covered Calls."
            )
            
            // Stats Overview
            if !wheelCycles.isEmpty {
                let totalCycles = wheelCycles.count
                let completedCycles = wheelCycles.filter { $0.isComplete }.count
                let totalPL = wheelCycles.map { $0.totalPL }.reduce(0, +)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatCard(
                        title: "Tickers",
                        value: "\(totalCycles)",
                        icon: "chart.bar",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Complete",
                        value: "\(completedCycles)",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Total P&L",
                        value: totalPL.formatted(.currency(code: "USD")),
                        icon: "dollarsign.circle",
                        color: totalPL >= 0 ? .green : .red
                    )
                }
                
                Divider()
                
                // Individual Cycles
                Text("Wheel Cycles by Ticker")
                    .font(.headline)
                
                ForEach(wheelCycles, id: \.ticker) { cycle in
                    WheelCycleCard(cycle: cycle)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("No Wheel Cycles Yet")
                        .font(.headline)
                    
                    Text("Start selling Cash-Secured Puts and Covered Calls to track wheel cycles")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

private struct WheelCycle {
    let ticker: String
    let cspCount: Int
    let ccCount: Int
    let totalPL: Double
    let totalDays: Int
    let isComplete: Bool
}

private struct WheelCycleCard: View {
    let cycle: WheelCycle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(cycle.ticker)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if cycle.isComplete {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Label("In Progress", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CSPs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(cycle.cspCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("CCs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(cycle.ccCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total P&L")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(cycle.totalPL.formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(cycle.totalPL >= 0 ? .green : .red)
                }
            }
            
            HStack {
                Label("\(cycle.totalDays) days", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if cycle.totalDays > 0 {
                    let dailyPL = cycle.totalPL / Double(cycle.totalDays)
                    Text(dailyPL.formatted(.currency(code: "USD")) + "/day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Trade Templates

struct TradeTemplates: View {
    @Bindable var profile: ClientProfile
    @State private var showingNewTrade = false
    @State private var selectedTemplate: TradeTemplate?
    
    private let templates: [TradeTemplate] = [
        TradeTemplate(
            name: "30-Day CSP (0.30 Delta)",
            description: "Conservative cash-secured put 30 days out",
            strategy: .cashSecuredPut,
            dte: 30,
            icon: "shield.checkered",
            color: .blue
        ),
        TradeTemplate(
            name: "45-Day Covered Call",
            description: "Generate income on owned stock",
            strategy: .coveredCall,
            dte: 45,
            icon: "arrow.up.forward",
            color: .green
        ),
        TradeTemplate(
            name: "Weekly Wheel",
            description: "Aggressive 7-day CSP for wheel strategy",
            strategy: .cashSecuredPut,
            dte: 7,
            icon: "bolt.circle",
            color: .orange
        ),
        TradeTemplate(
            name: "60-Day CSP (Conservative)",
            description: "Lower premium, more time value",
            strategy: .cashSecuredPut,
            dte: 60,
            icon: "tortoise",
            color: .purple
        ),
        TradeTemplate(
            name: "Monthly CC ATM",
            description: "At-the-money covered call, 30 days",
            strategy: .coveredCall,
            dte: 30,
            icon: "target",
            color: .red
        ),
        TradeTemplate(
            name: "Earnings Play CSP",
            description: "Post-earnings CSP, 14 days",
            strategy: .cashSecuredPut,
            dte: 14,
            icon: "chart.line.uptrend.xyaxis",
            color: .cyan
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "doc.on.doc")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                Text("Trade Templates")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HelpButton(
                    title: "Trade Templates",
                    message: "Quick-start templates for common options strategies. Tap any template to use it as a starting point for a new trade."
                )
            }
            
            CalloutView(
                type: .tip,
                message: "Tap a template to quickly set up a new trade with pre-configured settings."
            )
            
            // Templates Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(templates) { template in
                    TemplateCard(template: template) {
                        selectedTemplate = template
                        showingNewTrade = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewTrade) {
            if let template = selectedTemplate {
                NavigationStack {
                    NewTradeView(
                        recentTickers: Array(Set(profile.trades.map { $0.ticker })).sorted(),
                        onSave: { newTrade in
                            profile.trades.append(newTrade)
                            showingNewTrade = false
                        }
                    )
                    .navigationTitle(template.name)
                }
            }
        }
    }
}

private struct TradeTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let strategy: OptionType
    let dte: Int
    let icon: String
    let color: Color
}

private struct TemplateCard: View {
    let template: TradeTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundStyle(template.color)
                    
                    Spacer()
                    
                    Text("\(template.dte)D")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(template.color.opacity(0.2), in: Capsule())
                        .foregroundStyle(template.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 130)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(template.color.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Portfolio Heat Monitor

struct PortfolioHeatMonitor: View {
    @Bindable var profile: ClientProfile
    
    private var openTrades: [Trade] {
        profile.trades.filter { !$0.isClosed }
    }
    
    private var totalCapitalAtRisk: Double {
        openTrades.reduce(0) { sum, trade in
            switch trade.type {
            case .cashSecuredPut:
                return sum + ((trade.strike ?? 0) * 100 * Double(trade.quantity))
            case .coveredCall:
                return sum + ((trade.underlyingPriceAtEntry ?? 0) * 100 * Double(trade.quantity))
            case .call, .put:
                return sum + (trade.totalPremium)
            }
        }
    }
    
    private var tickerConcentration: [(ticker: String, count: Int, percentage: Double)] {
        let grouped = Dictionary(grouping: openTrades) { $0.ticker }
        let total = openTrades.count
        
        return grouped.map { ticker, trades in
            let count = trades.count
            let percentage = total > 0 ? Double(count) / Double(total) * 100 : 0
            return (ticker, count, percentage)
        }.sorted { $0.percentage > $1.percentage }
    }
    
    private var heatLevel: (level: String, color: Color, message: String) {
        let tradeCount = openTrades.count
        
        // Check ticker concentration
        let maxConcentration = tickerConcentration.first?.percentage ?? 0
        
        if tradeCount == 0 {
            return ("NONE", .gray, "No open positions")
        } else if tradeCount >= 10 || maxConcentration >= 50 {
            return ("HIGH", .red, "High exposure - consider diversifying")
        } else if tradeCount >= 5 || maxConcentration >= 30 {
            return ("MEDIUM", .orange, "Moderate exposure - monitor closely")
        } else {
            return ("LOW", .green, "Conservative exposure")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "flame")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text("Portfolio Heat Monitor")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HelpButton(
                    title: "Portfolio Heat",
                    message: "Monitor your overall risk exposure. High heat means you have many open positions or concentration in one ticker."
                )
            }
            
            CalloutView(
                type: .info,
                message: "Track total capital at risk and diversification across your open positions."
            )
            
            // Heat Level
            let heat = heatLevel
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: heat.level == "HIGH" ? "flame.fill" :
                          heat.level == "MEDIUM" ? "flame" : "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(heat.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heat Level")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(heat.level)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(heat.color)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(heat.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            
            CalloutView(
                type: heat.level == "HIGH" ? .warning : .info,
                message: heat.message
            )
            
            // Stats
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Open Positions", systemImage: "chart.bar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(openTrades.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Capital at Risk", systemImage: "dollarsign.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(totalCapitalAtRisk.formatted(.currency(code: "USD")))
                        .font(.title3)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
            }
            
            // Ticker Concentration
            if !tickerConcentration.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ticker Concentration")
                        .font(.headline)
                    
                    ForEach(tickerConcentration.prefix(5), id: \.ticker) { item in
                        HStack {
                            Text(item.ticker)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 60, alignment: .leading)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.quaternary)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(item.percentage >= 40 ? .red : item.percentage >= 25 ? .orange : .blue)
                                        .frame(width: geometry.size.width * (item.percentage / 100))
                                }
                            }
                            .frame(height: 20)
                            
                            Text("\(item.count)")
                                .font(.subheadline)
                                .frame(width: 30, alignment: .trailing)
                            
                            Text(String(format: "%.0f%%", item.percentage))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                    
                    if tickerConcentration.first?.percentage ?? 0 >= 40 {
                        CalloutView(
                            type: .warning,
                            message: "⚠️ High concentration in \(tickerConcentration.first?.ticker ?? "one ticker"). Consider diversifying."
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ClientToolsView(profile: ClientProfile(name: "Demo"))
    }
}


