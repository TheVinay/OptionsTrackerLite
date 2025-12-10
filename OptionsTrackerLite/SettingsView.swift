import SwiftUI

struct SettingsView: View {
    @State private var showingExportAlert = false

    var body: some View {
        Form {
            Section("Data") {
                Button("Export All Trades as CSV") {
                    // Placeholder for now – avoids compile errors and UI still looks right.
                    showingExportAlert = true
                }
            }

            Section("About") {
                Text("OptionsTracker Lite helps you manage options systematically across many client accounts, with checklists, calendars, analytics, and education.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .navigationTitle("Settings")
        .alert("Export coming soon", isPresented: $showingExportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We’ll wire up CSV export once you’re ready to decide how and where to save the file.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
