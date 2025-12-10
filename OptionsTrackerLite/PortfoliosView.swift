import SwiftUI

struct PortfoliosView: View {
    @Binding var profiles: [ClientProfile]

    @State private var searchText: String = ""
    @State private var showingNewClient = false

    // Filtered by search
    private var filteredProfiles: [ClientProfile] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return profiles }

        return profiles.filter { profile in
            profile.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        List {
            if profiles.isEmpty {
                ContentUnavailableView(
                    "No clients yet",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("Tap “New Client” to add your first portfolio.")
                )
            } else {
                ForEach(filteredProfiles) { profile in
                    NavigationLink {
                        if let binding = binding(for: profile) {
                            ClientDetailView(profile: binding)
                        }
                    } label: {
                        clientRow(profile)
                    }
                }
            }
        }
        .navigationTitle("Portfolios")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewClient = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Client")
            }
        }
        .sheet(isPresented: $showingNewClient) {
            NavigationStack {
                NewClientView { newClient in
                    profiles.append(newClient)
                }
            }
        }
    }

    // MARK: - Helpers

    private func binding(for profile: ClientProfile) -> Binding<ClientProfile>? {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else {
            return nil
        }
        return $profiles[index]
    }

    private func clientRow(_ profile: ClientProfile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(profile.name)
                    .font(.headline)
                Spacer()
                Text(profile.displayInitials)
                    .font(.caption)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color(.systemGray5))
                    )
            }

            HStack(spacing: 12) {
                Text("\(profile.openCount) open")
                Text("\(profile.closedCount) closed")
                Text(profile.realizedPL, format: .currency(code: "USD"))
                    .foregroundColor(profile.realizedPL >= 0 ? .green : .red)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PortfoliosView(profiles: .constant(ClientProfile.demoProfiles()))
    }
}
