import Foundation
import SwiftData

@Model
class SubstitutionRecord {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var trigger: String = ""
    var offeredAction: String = ""
    var wasAccepted: Bool = false
    var effectivenessRating: Int? = nil

    init(trigger: String, offeredAction: String, wasAccepted: Bool) {
        self.id = UUID()
        self.timestamp = Date()
        self.trigger = trigger
        self.offeredAction = offeredAction
        self.wasAccepted = wasAccepted
    }
}
