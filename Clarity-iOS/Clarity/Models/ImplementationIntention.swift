import Foundation
import SwiftData

@Model
class ImplementationIntention {
    var id: UUID = UUID()
    var triggerCondition: String = ""
    var intendedAction: String = ""
    var targetApp: String? = nil
    var createdAt: Date = Date()
    var timesTriggered: Int = 0
    var timesFollowed: Int = 0
    var isActive: Bool = true

    init(triggerCondition: String, intendedAction: String, targetApp: String? = nil) {
        self.id = UUID()
        self.triggerCondition = triggerCondition
        self.intendedAction = intendedAction
        self.targetApp = targetApp
        self.createdAt = Date()
    }
}
