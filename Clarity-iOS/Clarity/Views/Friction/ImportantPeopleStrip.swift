import SwiftUI
import SwiftData

/// Horizontal ScrollView of the user's important contacts.
struct ImportantPeopleStrip: View {
    @Query(sort: \ImportantContact.contactName) private var contacts: [ImportantContact]
    @State private var selectedContact: ImportantContact?
    @State private var showActionSheet = false

    private func avatarColor(for name: String) -> Color {
        let hash = abs(name.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }

    var body: some View {
        if !contacts.isEmpty {
            VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                Text("YOUR PEOPLE")
                    .font(ClarityFonts.mono(size: 11))
                    .tracking(3)
                    .foregroundStyle(ClarityColors.textMuted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ClaritySpacing.md) {
                        ForEach(contacts, id: \.id) { contact in
                            Button {
                                HapticManager.light()
                                selectedContact = contact
                                showActionSheet = true
                            } label: {
                                VStack(spacing: ClaritySpacing.xs) {
                                    ZStack {
                                        Circle()
                                            .fill(avatarColor(for: contact.contactName))
                                            .frame(width: 52, height: 52)

                                        Text(String(contact.contactName.prefix(1)).uppercased())
                                            .font(ClarityFonts.sansSemiBold(size: 20))
                                            .foregroundStyle(.white)
                                    }

                                    Text(contact.contactName.components(separatedBy: " ").first ?? contact.contactName)
                                        .font(ClarityFonts.sans(size: 12))
                                        .foregroundStyle(ClarityColors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .confirmationDialog("Connect", isPresented: $showActionSheet, presenting: selectedContact) { contact in
                if let phone = contact.contactPhone {
                    Button("Call \(contact.contactName)") {
                        if let url = URL(string: "tel://\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Text \(contact.contactName)") {
                        if let url = URL(string: "sms://\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
