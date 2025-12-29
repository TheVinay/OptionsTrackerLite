import SwiftUI

// MARK: - Contextual Tooltip

struct ContextualTooltip: View {
    let message: String
    @State private var isVisible = false
    
    var body: some View {
        Text(message)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.spring(response: 0.3), value: isVisible)
            .onAppear {
                withAnimation {
                    isVisible = true
                }
            }
    }
}

// MARK: - Tutorial Spotlight

struct SpotlightOverlay: View {
    let targetFrame: CGRect
    let title: String
    let message: String
    let onNext: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Dimmed background with cutout
            Color.black.opacity(0.7)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .frame(width: targetFrame.width + 8, height: targetFrame.height + 8)
                        .position(x: targetFrame.midX, y: targetFrame.midY)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
            
            // Instruction card
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                
                Text(message)
                    .font(.subheadline)
                
                HStack {
                    Button("Skip", action: onDismiss)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Next", action: onNext)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()
            .position(x: targetFrame.midX, y: targetFrame.maxY + 100)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Quick Action Guide

struct QuickActionGuide: View {
    let gesture: String
    let action: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue.gradient)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(gesture)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(action)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Formula Explainer

struct FormulaExplainer: View {
    let formulaName: String
    let formula: String
    let example: String
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    showingDetails.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "function")
                        .foregroundStyle(.purple)
                    
                    Text(formulaName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showingDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Formula:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(formula)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                    
                    Text("Example:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(example)
                        .font(.caption)
                }
                .padding(.leading, 28)
            }
        }
    }
}

// MARK: - Video Tutorial Link

struct VideoTutorialLink: View {
    let title: String
    let duration: String
    let thumbnailIcon: String
    let url: URL
    
    var body: some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.gradient)
                        .frame(width: 60, height: 45)
                    
                    Image(systemName: "play.fill")
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(duration)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Interactive Example

struct InteractiveExample: View {
    let title: String
    let description: String
    @State private var userInput: String = ""
    let calculateResult: (String) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "hand.tap")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                TextField("Try it", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                
                if !userInput.isEmpty {
                    Text("=")
                        .foregroundStyle(.secondary)
                    
                    Text(calculateResult(userInput))
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Callout View (Info/Warning/Error/Tip)

struct CalloutView: View {
    enum CalloutType {
        case info, warning, error, tip
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .tip: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            case .tip: return "lightbulb.fill"
            }
        }
    }
    
    let type: CalloutType
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)
                .font(.title3)
            
            Text(message)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(type.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - Help Progress Indicator

struct HelpProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitles: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step < currentStep ? .blue : .secondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            
            if currentStep < stepTitles.count {
                Text("Step \(currentStep + 1) of \(totalSteps): \(stepTitles[currentStep])")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Glossary Term

struct GlossaryTerm: View {
    let term: String
    let definition: String
    @State private var isExpanded = false
    
    var body: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(term)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "book.closed")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                
                if isExpanded {
                    Text(definition)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Help Search Bar

struct HelpSearchBar: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search help topics", text: $searchText)
                .focused($isFocused)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Help Button Component

struct HelpButton: View {
    let title: String
    let message: String
    @State private var showingHelp = false
    
    var body: some View {
        Button {
            showingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.blue)
                .font(.subheadline)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Help: \(title)")
        .popover(isPresented: $showingHelp) {
            HelpCard(title: title, message: message)
                .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Help Card Component

struct HelpCard: View {
    let title: String
    let message: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: 350, maxHeight: 250)
    }
}

// MARK: - Info Row with Help

struct InfoRowWithHelp: View {
    let icon: String
    let title: String
    let detail: String
    let helpTitle: String
    let helpMessage: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HelpButton(title: helpTitle, message: helpMessage)
                }
                
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Expandable Section (Accordion)

struct ExpandableSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @State private var isExpanded: Bool = false
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                content
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Hint TextField

struct HintTextField: View {
    let title: String
    let hint: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField(hint, text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboardType)
        }
    }
}

// MARK: - Hint Number Field

struct HintNumberField: View {
    let title: String
    let hint: String
    @Binding var value: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField(hint, value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
        }
    }
}

// MARK: - Hint Integer Field

struct HintIntegerField: View {
    let title: String
    let hint: String
    @Binding var value: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField(hint, value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
        }
    }
}
// MARK: - Preview & Usage Examples

#Preview("Help Components") {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: Help Button
                Section {
                    HStack {
                        Text("Premium")
                        HelpButton(
                            title: "What is Premium?",
                            message: "Premium is the price paid per share for an options contract. It represents the cost to buy or income received from selling the option."
                        )
                    }
                } header: {
                    Text("Help Button")
                        .font(.headline)
                }
                
                Divider()
                
                // MARK: Callout Views
                Section {
                    CalloutView(
                        type: .tip,
                        message: "Pro tip: Track commissions to see your true net P&L!"
                    )
                    
                    CalloutView(
                        type: .warning,
                        message: "Options trading involves significant risk. Never risk more than you can afford to lose."
                    )
                    
                    CalloutView(
                        type: .error,
                        message: "This trade cannot be saved. Strike price is required."
                    )
                    
                    CalloutView(
                        type: .info,
                        message: "This is a simulated trade for practice purposes."
                    )
                } header: {
                    Text("Callout Views")
                        .font(.headline)
                }
                
                Divider()
                
                // MARK: Formula Explainer
                Section {
                    FormulaExplainer(
                        formulaName: "Total Premium Calculation",
                        formula: "Total Premium = Contract Price × Quantity × 100",
                        example: "If you sell 2 contracts at $0.50 each:\n$0.50 × 2 × 100 = $100 total premium"
                    )
                    
                    FormulaExplainer(
                        formulaName: "Profit/Loss Calculation",
                        formula: "P&L = (Exit Price - Entry Price) × Quantity × 100",
                        example: "Bought at $1.00, sold at $1.50, 1 contract:\n($1.50 - $1.00) × 1 × 100 = $50 profit"
                    )
                } header: {
                    Text("Formula Explainer")
                        .font(.headline)
                }
                
                Divider()
                
                // MARK: Glossary Terms
                Section {
                    VStack(spacing: 12) {
                        GlossaryTerm(
                            term: "Strike Price",
                            definition: "The predetermined price at which the option can be exercised. For calls, it's the price you can buy the stock. For puts, it's the price you can sell the stock."
                        )
                        
                        GlossaryTerm(
                            term: "Premium",
                            definition: "The price paid for an options contract, quoted on a per-share basis. Multiply by 100 to get the total contract cost."
                        )
                        
                        GlossaryTerm(
                            term: "ITM (In The Money)",
                            definition: "When an option has intrinsic value. For calls, when stock price > strike. For puts, when stock price < strike."
                        )
                        
                        GlossaryTerm(
                            term: "OTM (Out of The Money)",
                            definition: "When an option has no intrinsic value, only time value. For calls, when stock price < strike. For puts, when stock price > strike."
                        )
                    }
                } header: {
                    Text("Glossary Terms")
                        .font(.headline)
                }
                
                Divider()
                
                // MARK: Quick Action Guide
                Section {
                    VStack(spacing: 8) {
                        QuickActionGuide(
                            gesture: "Swipe Left",
                            action: "Delete a trade",
                            icon: "trash"
                        )
                        
                        QuickActionGuide(
                            gesture: "Swipe Right",
                            action: "Close a position",
                            icon: "checkmark.circle"
                        )
                        
                        QuickActionGuide(
                            gesture: "Long Press",
                            action: "Add a note to trade",
                            icon: "note.text"
                        )
                    }
                } header: {
                    Text("Quick Action Guide")
                        .font(.headline)
                }
                
                Divider()
                
                // MARK: Interactive Example
                Section {
                    InteractiveExample(
                        title: "Calculate Total Premium",
                        description: "Enter a contract price to see total premium for 1 contract"
                    ) { input in
                        if let price = Double(input) {
                            let total = price * 100
                            return String(format: "$%.2f", total)
                        }
                        return "Invalid"
                    }
                } header: {
                    Text("Interactive Example")
                        .font(.headline)
                }
                
                Divider()
                
                // MARK: Video Tutorial Link
                Section {
                    VideoTutorialLink(
                        title: "How to Track Your First Trade",
                        duration: "3:45",
                        thumbnailIcon: "play.circle.fill",
                        url: URL(string: "https://example.com")!
                    )
                } header: {
                    Text("Video Tutorial")
                        .font(.headline)
                }
                
                Divider()
                
                // MARK: Progress Indicator
                Section {
                    HelpProgressIndicator(
                        currentStep: 2,
                        totalSteps: 5,
                        stepTitles: [
                            "Create Profile",
                            "Add First Trade",
                            "Set Notifications",
                            "Review Analytics",
                            "Export Data"
                        ]
                    )
                } header: {
                    Text("Progress Indicator")
                        .font(.headline)
                }
                
                Divider()
                
                // MARK: Info Row with Help
                Section {
                    InfoRowWithHelp(
                        icon: "dollarsign.circle",
                        title: "Total P&L",
                        detail: "$1,250.00",
                        helpTitle: "Profit & Loss",
                        helpMessage: "This shows your total realized profit or loss across all closed positions. It includes commissions if you've entered them."
                    )
                } header: {
                    Text("Info Row with Help")
                        .font(.headline)
                }
                
                Divider()
                
                // MARK: Expandable Section
                Section {
                    ExpandableSection(title: "Advanced Settings", icon: "gearshape.2") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Enable notifications", isOn: .constant(true))
                            Toggle("Track commissions", isOn: .constant(false))
                            Toggle("Show simulated trades", isOn: .constant(true))
                        }
                        .padding(.horizontal)
                    }
                } header: {
                    Text("Expandable Section")
                        .font(.headline)
                }
                
                Divider()
                
                // MARK: Contextual Tooltip
                Section {
                    HStack {
                        Text("Hover for tooltip")
                        
                        Spacer()
                        
                        ContextualTooltip(message: "This is a helpful hint!")
                    }
                } header: {
                    Text("Contextual Tooltip")
                        .font(.headline)
                }
                
            }
            .padding()
        }
        .navigationTitle("Help System Components")
    }
}

#Preview("Glossary Example") {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Options Trading Terms")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    GlossaryTerm(
                        term: "Call Option",
                        definition: "A contract giving you the right (but not obligation) to buy 100 shares at the strike price before expiration."
                    )
                    
                    GlossaryTerm(
                        term: "Put Option",
                        definition: "A contract giving you the right (but not obligation) to sell 100 shares at the strike price before expiration."
                    )
                    
                    GlossaryTerm(
                        term: "Covered Call",
                        definition: "Selling a call option while owning the underlying stock. Generates income but caps upside potential."
                    )
                    
                    GlossaryTerm(
                        term: "Cash-Secured Put",
                        definition: "Selling a put option while having enough cash to buy the stock if assigned. Generates income while waiting to buy."
                    )
                    
                    GlossaryTerm(
                        term: "Expiration Date",
                        definition: "The date when the option contract expires. After this date, the option becomes worthless if not exercised."
                    )
                    
                    GlossaryTerm(
                        term: "Break-Even",
                        definition: "The stock price at which you neither profit nor lose on the trade, after accounting for premium and commissions."
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Glossary")
    }
}

#Preview("Formula Examples") {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Options Calculations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    FormulaExplainer(
                        formulaName: "Total Premium",
                        formula: "Premium Per Share × Quantity × 100",
                        example: "Selling 3 contracts at $0.75:\n$0.75 × 3 × 100 = $225"
                    )
                    
                    FormulaExplainer(
                        formulaName: "Break-Even (Covered Call)",
                        formula: "Stock Purchase Price - Premium Received",
                        example: "Bought stock at $50, sold call for $2:\n$50 - $2 = $48 break-even"
                    )
                    
                    FormulaExplainer(
                        formulaName: "Max Profit (Covered Call)",
                        formula: "(Strike - Purchase Price + Premium) × Quantity × 100",
                        example: "Stock at $50, sold $52 call for $1.50:\n($52 - $50 + $1.50) × 1 × 100 = $350"
                    )
                    
                    FormulaExplainer(
                        formulaName: "Return on Risk",
                        formula: "(Premium / Capital at Risk) × 100",
                        example: "Sold $50 put for $2, cash reserved $5000:\n($200 / $5000) × 100 = 4%"
                    )
                    
                    FormulaExplainer(
                        formulaName: "Net P&L After Commissions",
                        formula: "Realized P&L - Opening Commission - Closing Commission",
                        example: "Made $200, paid $1.50 to open, $1.50 to close:\n$200 - $1.50 - $1.50 = $197"
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Formulas")
    }
}

