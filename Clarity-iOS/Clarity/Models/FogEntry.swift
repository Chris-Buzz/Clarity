import SwiftData
import Foundation

@Model
final class FogEntry {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var clarityLevel: Int = 3  // 1-5 scale
    var trigger: String = "unknown"  // scrolling, workStress, sleep, overstimulation, unknown
    var notes: String? = nil

    init(clarityLevel: Int, trigger: String = "unknown", notes: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.clarityLevel = clarityLevel
        self.trigger = trigger
        self.notes = notes
    }
}
