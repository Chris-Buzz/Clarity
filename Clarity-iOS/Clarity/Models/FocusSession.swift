import Foundation
import SwiftData

@Model
class FocusSession {
    var id: UUID = UUID()
    var startTime: Date = Date()
    var endTime: Date? = nil
    var plannedDuration: Int = 25 // minutes
    var actualDuration: Int = 0
    var task: String = ""
    var wasCompleted: Bool = false
    var tabLeavesCount: Int = 0
    var urgesResisted: Int = 0
    var xpEarned: Int = 0
    var rating: Int? = nil // 1-5
    var note: String? = nil
    var moodBefore: Double? = nil // -1.0 to 1.0
    var moodAfter: Double? = nil

    init(task: String, plannedDuration: Int) {
        self.id = UUID()
        self.task = task
        self.plannedDuration = plannedDuration
        self.startTime = Date()
    }
}
