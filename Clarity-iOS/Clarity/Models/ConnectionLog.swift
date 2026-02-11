import Foundation
import SwiftData

@Model
class ConnectionLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var type: String = "textSent" // callCompleted, callAttempted, textSent, facetimeCompleted, voiceMemoSent
    var contactName: String?
    var contactIdentifier: String?
    var durationSeconds: Int = 0
    var challengeId: UUID? // Link to triggering ProsocialChallenge
    var xpEarned: Int = 0

    init(type: String, contactName: String?, durationSeconds: Int, challengeId: UUID?, xpEarned: Int) {
        self.type = type
        self.contactName = contactName
        self.durationSeconds = durationSeconds
        self.challengeId = challengeId
        self.xpEarned = xpEarned
    }
}
