import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("useDarkMode") private var useDarkMode = false
    @AppStorage("defaultStrategy") private var defaultStrategy = "Covered Call"
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("notificationDaysBefore") private var notificationDaysBefore = 3
    @AppStorage("defaultQuantity") private var defaultQuantity = 1
    @AppStorage("advisorName") private var advisorName = "Vinay Viswambharan"
    @AppStorage("advisorEmail") private var advisorEmail = ""
    @AppStorage("advisorPhone") private var advisorPhone = ""
    
    @Query private var profiles: [ClientProfile]
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var showDeleteConfirmation = false
    @State private var showExportOptions = false
    @State private var showLoadDemoConfirmation = false
    @State private var exportFormat: ExportFormat = .csv
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case summary = "Summary Text"
    }
    
    var body: some View {
        Form {
            profileSection
            appearanceSection
            defaultsSection
            notificationsSection
            dataSection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showShareSheet) {
            if !shareItems.isEmpty {
                ShareSheet(items: shareItems)
            }
        }
    }
    
    // MARK: - Sections
    
    private var profileSection: some View {
        Section {
            TextField("Name", text: $advisorName)
                .textContentType(.name)
            
            TextField("Email", text: $advisorEmail)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            
            TextField("Phone", text: $advisorPhone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
        } header: {
            Label("Your Profile", systemImage: "person.circle.fill")
        } footer: {
            Text("This information appears in your Profile tab")
                .font(.caption)
        }
    }
    
    private var appearanceSection: some View {
        Section {
            Toggle(isOn: $useDarkMode) {
                Label("Dark Mode", systemImage: "moon.fill")
            }
        } header: {
            Label("Appearance", systemImage: "paintbrush.fill")
        }
    }
    
    private var defaultsSection: some View {
        Section {
            Picker("Default Strategy", selection: $defaultStrategy) {
                ForEach(OptionType.allCases) { type in
                    Text(type.rawValue).tag(type.rawValue)
                }
            }
            
            Stepper("Default Quantity: \(defaultQuantity)", value: $defaultQuantity, in: 1...100)
        } header: {
            Label("Trade Defaults", systemImage: "doc.text.fill")
        } footer: {
            Text("These values will pre-fill when creating new trades")
                .font(.caption)
        }
    }
    
    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $enableNotifications) {
                Label("Enable Notifications", systemImage: "bell.fill")
            }
            .onChange(of: enableNotifications) { _, newValue in
                if newValue {
                    Task {
                        let granted = await notificationManager.requestAuthorization()
                        if granted {
                            await notificationManager.rescheduleAllNotifications(
                                for: profiles,
                                daysBeforeExpiry: notificationDaysBefore
                            )
                        }
                    }
                }
            }
            
            if enableNotifications {
                Stepper(
                    "Alert \(notificationDaysBefore) day\(notificationDaysBefore == 1 ? "" : "s") before expiry",
                    value: $notificationDaysBefore,
                    in: 1...14
                )
                .onChange(of: notificationDaysBefore) { _, _ in
                    Task {
                        await notificationManager.rescheduleAllNotifications(
                            for: profiles,
                            daysBeforeExpiry: notificationDaysBefore
                        )
                    }
                }
            }
            
            if !notificationManager.isAuthorized && enableNotifications {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings to Allow Notifications", systemImage: "gear")
                        .foregroundStyle(.orange)
                }
            }
        } header: {
            Label("Notifications", systemImage: "bell.badge.fill")
        } footer: {
            Text("Get reminders before options expire so you never miss an important date")
                .font(.caption)
        }
    }
    
    private var dataSection: some View {
        Section {
            // Load demo data
            Button {
                showLoadDemoConfirmation = true
            } label: {
                Label("Load Sample Portfolios", systemImage: "person.3.fill")
            }
            .confirmationDialog(
                "Load Sample Data?",
                isPresented: $showLoadDemoConfirmation,
                titleVisibility: .visible
            ) {
                Button("Load 3 Sample Clients") {
                    loadDemoData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will add John Doe, Mary Jane, and Josh Posh with sample trades for testing.")
            }
            
            Divider()
            
            // Export options
            Button {
                showExportOptions = true
            } label: {
                Label("Export All Data", systemImage: "square.and.arrow.up")
            }
            .confirmationDialog("Choose Export Format", isPresented: $showExportOptions) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button(format.rawValue) {
                        exportData(format: format)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            
            // Stats
            LabeledContent("Total Clients", value: "\(profiles.count)")
            LabeledContent("Total Trades", value: "\(profiles.flatMap { $0.trades }.count)")
            
            Divider()
            
            // Delete all data
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash.fill")
                    .foregroundStyle(.red)
            }
        } header: {
            Label("Data Management", systemImage: "externaldrive.fill")
        }
        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all \(profiles.count) client(s) and \(profiles.flatMap { $0.trades }.count) trade(s). This action cannot be undone.")
        }
    }
    
    private var aboutSection: some View {
        Section {
            LabeledContent {
                Text("1.0")
                    .foregroundStyle(.secondary)
            } label: {
                Label("Version", systemImage: "info.circle")
            }
            
            LabeledContent {
                Text("100")
                    .foregroundStyle(.secondary)
            } label: {
                Label("Build", systemImage: "hammer")
            }
            
            Link(destination: URL(string: "https://www.apple.com")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            
            Link(destination: URL(string: "mailto:support@optionstrackerapp.com")!) {
                Label("Contact Support", systemImage: "envelope.fill")
            }
        } header: {
            Label("About", systemImage: "app.gift.fill")
        } footer: {
            VStack(alignment: .center, spacing: 8) {
                Text("OptionsTracker Lite")
                    .font(.headline)
                Text("Professional Options Portfolio Management")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Made with ♥ for options traders")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Actions
    
    private func loadDemoData() {
        // Load the sample profiles
        let demoProfiles = ClientProfile.demoProfiles()
        
        // Insert into model context
        for profile in demoProfiles {
            modelContext.insert(profile)
        }
        
        // Save context
        try? modelContext.save()
    }
    
    private func exportData(format: ExportFormat) {
        switch format {
        case .csv:
            let csv = DataExporter.exportToCSV(profiles: profiles)
            if let data = csv.data(using: .utf8) {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("OptionsTracker_Export.csv")
                try? data.write(to: tempURL)
                shareItems = [tempURL]
                showShareSheet = true
            }
            
        case .json:
            if let data = try? DataExporter.exportToJSON(profiles: profiles) {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("OptionsTracker_Export.json")
                try? data.write(to: tempURL)
                shareItems = [tempURL]
                showShareSheet = true
            }
            
        case .summary:
            let summary = DataExporter.exportSummaryText(profiles: profiles)
            shareItems = [summary]
            showShareSheet = true
        }
    }
    
    private func deleteAllData() {
        // Delete all profiles (cascade will delete trades and notes)
        for profile in profiles {
            modelContext.delete(profile)
        }
        
        // Save context
        try? modelContext.save()
        
        // Cancel all notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: [ClientProfile.self, Trade.self, TradeNote.self])
    }
}
