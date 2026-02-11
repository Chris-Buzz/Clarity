import Foundation
import SwiftData

@Model
class MoodEntry {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var valence: Double = 0.0 // -1.0 to 1.0
    var label: String = ""
    var context: String? = nil
    var associatedScreenTime: Int? = nil // minutes

    init(valence: Double, label: String, context: String? = nil, associatedScreenTime: Int? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.valence = valence
        self.label = label
        self.context = context
        self.associatedScreenTime = associatedScreenTime
    }
}
