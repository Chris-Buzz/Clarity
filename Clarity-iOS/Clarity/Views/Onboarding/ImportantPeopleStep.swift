import SwiftUI
import SwiftData
import Contacts

/// Onboarding step for selecting important contacts.
struct ImportantPeopleStep: View {
    let onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var contactStore = CNContactStore()
    @State private var contacts: [CNContact] = []
    @State private var selectedIdentifiers: Set<String> = []
    @State private var permissionDenied = false
    @State private var manualName = ""
    @State private var manualPhone = ""
    @State private var manualContacts: [(name: String, phone: String)] = []

    private var totalSelected: Int {
        selectedIdentifiers.count + manualContacts.count
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: ClaritySpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                        Text("YOUR PEOPLE")
                            .font(ClarityFonts.mono(size: 11))
                            .tracking(3)
                            .foregroundStyle(ClarityColors.textMuted)

                        Text("Who matters most?")
                            .font(ClarityFonts.serif(size: 28))
                            .foregroundStyle(ClarityColors.textPrimary)

                        Text("Instead of scrolling, we'll encourage you to connect with these people — and verify you did.")
                            .font(ClarityFonts.sans(size: 15))
                            .foregroundStyle(ClarityColors.textTertiary)
                            .lineSpacing(4)
                    }

                    // Counter pill
                    Text("\(totalSelected)/\(ProsocialLimits.maxImportantContacts) selected")
                        .font(ClarityFonts.mono(size: 12))
                        .foregroundStyle(ClarityColors.primary)
                        .padding(.horizontal, ClaritySpacing.md)
                        .padding(.vertical, ClaritySpacing.xs)
                        .background(ClarityColors.primaryMuted)
                        .clipShape(Capsule())

                    if permissionDenied {
                        manualEntrySection
                    } else {
                        contactListSection
                    }
                }
                .padding(.horizontal, ClaritySpacing.lg)
                .padding(.top, ClaritySpacing.lg)
                .padding(.bottom, ClaritySpacing.xxxl)
            }

            // Bottom CTA
            VStack(spacing: ClaritySpacing.sm) {
                ClarityButton("Continue", variant: .primary, size: .lg, fullWidth: true) {
                    saveContacts()
                    onContinue()
                }

                if totalSelected == 0 {
                    ClarityButton("Skip for now", variant: .ghost, size: .sm) {
                        onContinue()
                    }
                }
            }
            .padding(.horizontal, ClaritySpacing.lg)
            .padding(.bottom, ClaritySpacing.lg)
        }
        .background(ClarityColors.background)
        .onAppear { requestContactPermission() }
    }

    // MARK: - Contact List

    private var contactListSection: some View {
        VStack(spacing: ClaritySpacing.sm) {
            ForEach(contacts, id: \.identifier) { contact in
                let isSelected = selectedIdentifiers.contains(contact.identifier)

                Button {
                    HapticManager.light()
                    if isSelected {
                        selectedIdentifiers.remove(contact.identifier)
                    } else if totalSelected < ProsocialLimits.maxImportantContacts {
                        selectedIdentifiers.insert(contact.identifier)
                    }
                } label: {
                    HStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ClarityColors.primary)
                                .frame(width: 3, height: 40)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(contact.givenName) \(contact.familyName)")
                                .font(ClarityFonts.sansMedium(size: 15))
                                .foregroundStyle(ClarityColors.textPrimary)

                            if let phone = contact.phoneNumbers.first?.value.stringValue {
                                Text(phone)
                                    .font(ClarityFonts.sans(size: 13))
                                    .foregroundStyle(ClarityColors.textMuted)
                            }
                        }

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ClarityColors.primary)
                        }
                    }
                    .padding(ClaritySpacing.md)
                    .background(isSelected ? ClarityColors.primaryMuted : ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ClarityRadius.md)
                            .stroke(isSelected ? ClarityColors.primary.opacity(0.3) : ClarityColors.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isSelected && totalSelected >= ProsocialLimits.maxImportantContacts)
                .opacity(!isSelected && totalSelected >= ProsocialLimits.maxImportantContacts ? 0.5 : 1)
            }
        }
    }

    // MARK: - Manual Entry (when permission denied)

    private var manualEntrySection: some View {
        VStack(spacing: ClaritySpacing.md) {
            Text("Contact permission not available. Add people manually.")
                .font(ClarityFonts.sans(size: 14))
                .foregroundStyle(ClarityColors.textTertiary)

            HStack(spacing: ClaritySpacing.sm) {
                TextField("Name", text: $manualName)
                    .font(.custom("Outfit-Regular", size: 15))
                    .foregroundStyle(ClarityColors.textPrimary)
                    .padding(ClaritySpacing.sm)
                    .background(ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.sm))

                TextField("Phone", text: $manualPhone)
                    .font(.custom("Outfit-Regular", size: 15))
                    .foregroundStyle(ClarityColors.textPrimary)
                    .keyboardType(.phonePad)
                    .padding(ClaritySpacing.sm)
                    .background(ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.sm))
                    .frame(width: 140)

                Button {
                    guard !manualName.isEmpty, totalSelected < ProsocialLimits.maxImportantContacts else { return }
                    HapticManager.light()
                    manualContacts.append((name: manualName, phone: manualPhone))
                    manualName = ""
                    manualPhone = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(ClarityColors.primary)
                        .font(.system(size: 28))
                }
            }

            // Added contacts as removable pills
            if !manualContacts.isEmpty {
                HStack(spacing: ClaritySpacing.xs) {
                    ForEach(manualContacts.indices, id: \.self) { index in
                        HStack(spacing: ClaritySpacing.xs) {
                            Text(manualContacts[index].name)
                                .font(ClarityFonts.sansMedium(size: 13))
                                .foregroundStyle(ClarityColors.primary)

                            Button {
                                HapticManager.light()
                                manualContacts.remove(at: index)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(ClarityColors.textMuted)
                            }
                        }
                        .padding(.horizontal, ClaritySpacing.sm)
                        .padding(.vertical, ClaritySpacing.xs)
                        .background(ClarityColors.primaryMuted)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func requestContactPermission() {
        contactStore.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    fetchContacts()
                } else {
                    permissionDenied = true
                }
            }
        }
    }

    private func fetchContacts() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactIdentifierKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .givenName

        var fetched: [CNContact] = []
        try? contactStore.enumerateContacts(with: request) { contact, _ in
            if !contact.givenName.isEmpty {
                fetched.append(contact)
            }
        }
        contacts = fetched
    }

    private func saveContacts() {
        for identifier in selectedIdentifiers {
            if let contact = contacts.first(where: { $0.identifier == identifier }) {
                let phone = contact.phoneNumbers.first?.value.stringValue
                let important = ImportantContact(
                    contactIdentifier: contact.identifier,
                    contactName: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                    contactPhone: phone
                )
                modelContext.insert(important)
            }
        }

        for manual in manualContacts {
            let important = ImportantContact(
                contactIdentifier: UUID().uuidString,
                contactName: manual.name,
                contactPhone: manual.phone.isEmpty ? nil : manual.phone
            )
            modelContext.insert(important)
        }
    }
}
