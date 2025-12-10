import SwiftUI

/// Sheet / screen to create a new client profile.
struct NewClientView: View {
    let onSave: (ClientProfile) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""

    // Option type interests
    @State private var interestedInCalls: Bool = true
    @State private var interestedInPuts: Bool = false
    @State private var interestedInCoveredCalls: Bool = true
    @State private var interestedInCSPs: Bool = true

    // Dates
    private let createdAt: Date = Date()
    @State private var lastModified: Date = Date()

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            basicSection
            interestsSection
            notesSection
            metaSection
        }
        .navigationTitle("New Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveClient() }
                    .disabled(!canSave)
            }
        }
    }

    // MARK: - Sections

    private var basicSection: some View {
        Section("Client info") {
            TextField("Name", text: $name)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Phone", text: $phone)
                .keyboardType(.phonePad)

            TextField("Address", text: $address)
        }
    }

    private var interestsSection: some View {
        Section("Interested in") {
            Toggle("Calls", isOn: $interestedInCalls)
            Toggle("Puts", isOn: $interestedInPuts)
            Toggle("Covered Calls", isOn: $interestedInCoveredCalls)
            Toggle("Cash-Secured Puts", isOn: $interestedInCSPs)
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Anything special about this client or their risk profile…",
                      text: $notes,
                      axis: .vertical)
                .lineLimit(3, reservesSpace: true)
        }
    }

    private var metaSection: some View {
        Section("Meta") {
            HStack {
                Text("Created")
                Spacer()
                Text(createdAt, format: .dateTime.year().month().day())
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Last modified")
                Spacer()
                DatePicker("", selection: $lastModified, displayedComponents: .date)
                    .labelsHidden()
            }
        }
    }

    // MARK: - Save

    private func saveClient() {
        var interestedTypes = Set<OptionType>()
        if interestedInCalls { interestedTypes.insert(.call) }
        if interestedInPuts { interestedTypes.insert(.put) }
        if interestedInCoveredCalls { interestedTypes.insert(.coveredCall) }
        if interestedInCSPs { interestedTypes.insert(.cashSecuredPut) }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        let client = ClientProfile(
            name: trimmedName,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            address: address.isEmpty ? nil : address,
            notes: notes.isEmpty ? nil : notes,
            createdAt: createdAt,
            lastModified: lastModified,
            interestedTypes: interestedTypes,
            trades: []
        )

        onSave(client)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        NewClientView { _ in }
    }
}
