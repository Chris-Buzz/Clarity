import Foundation
import SwiftData

@Model
class ProsocialChallenge {
    var id: UUID = UUID()
    var issuedAt: Date = Date()
    var type: String = "textSomeone" // textSomeone, callSomeone, voiceMemo, facetime, replyToMessage
    var suggestedContactName: String?
    var suggestedContactIdentifier: String? // CNContact.identifier
    var suggestedContactPhone: String?
    var targetApp: String = "" // Which doomscroll app triggered this
    var wasVerified: Bool = false
    var verifiedAt: Date?
    var verificationMethod: String? // callObserver, communicationCategory, timerBased, autoVerified
    var userSkipped: Bool = false
    var frictionLayer: Int = 1
    var xpEarned: Int = 0
    var failureMessage: String? // The sassy response shown if verification failed

    init(type: String, contactName: String?, contactIdentifier: String?, contactPhone: String?, targetApp: String, frictionLayer: Int) {
        self.type = type
        self.suggestedContactName = contactName
        self.suggestedContactIdentifier = contactIdentifier
        self.suggestedContactPhone = contactPhone
        self.targetApp = targetApp
        self.frictionLayer = frictionLayer
    }
}
