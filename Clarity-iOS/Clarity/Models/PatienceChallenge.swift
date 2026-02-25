import SwiftData
import Foundation

@Model
final class PatienceChallenge {
    var id: UUID = UUID()
    var date: Date = Date()
    var challengeText: String = ""
    var challengeType: String = "wait"  // wait, analog, decision, attention
    var durationMinutes: Int = 5
    var wasCompleted: Bool = false
    var completedAt: Date? = nil

    init(challengeText: String, challengeType: String, durationMinutes: Int) {
        self.id = UUID()
        self.date = Date()
        self.challengeText = challengeText
        self.challengeType = challengeType
        self.durationMinutes = durationMinutes
    }
}
