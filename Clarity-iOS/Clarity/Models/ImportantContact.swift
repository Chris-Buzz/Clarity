import Foundation
import SwiftData

@Model
class ImportantContact {
    var id: UUID = UUID()
    var contactIdentifier: String = "" // CNContact.identifier
    var contactName: String = ""
    var contactPhone: String?
    var addedAt: Date = Date()
    var lastSuggestedAt: Date?
    var timesConnected: Int = 0
    var lastConnectedAt: Date?

    init(contactIdentifier: String, contactName: String, contactPhone: String?) {
        self.contactIdentifier = contactIdentifier
        self.contactName = contactName
        self.contactPhone = contactPhone
    }
}
