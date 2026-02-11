import Foundation
import SwiftData

@Model
class DailySnapshot {
    var id: UUID = UUID()
    var date: String = "" // "YYYY-MM-DD"
    var clarityScore: Int = 0 // 0-100
    var totalScreenTime: Int = 0 // minutes
    var connectionTime: Int = 0 // minutes
    var mindfulPickups: Int = 0
    var successfulSubstitutions: Int = 0
    var averageMood: Double = 0.0
    var sleepHours: Double? = nil
    var steps: Int? = nil
    var points: Int = 0

    init(date: String) {
        self.id = UUID()
        self.date = date
    }
}
