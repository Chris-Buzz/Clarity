import SwiftData
import Foundation

struct DayLog: Codable, Identifiable {
    var id: UUID = UUID()
    let date: Date
    var impulsesCaught: Int
    var delaysPracticed: Int
    var notes: String?
}

@Model
final class DopamineProgram {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var currentDay: Int = 1  // 1-30
    var phase: String = "awareness"  // awareness, delay, substitute, integrate
    var dailyLogsData: Data? = nil

    var dailyLogs: [DayLog] {
        get {
            guard let data = dailyLogsData else { return [] }
            return (try? JSONDecoder().decode([DayLog].self, from: data)) ?? []
        }
        set {
            dailyLogsData = try? JSONEncoder().encode(newValue)
        }
    }

    var currentPhase: String {
        switch currentDay {
        case 1...7: return "awareness"
        case 8...14: return "delay"
        case 15...21: return "substitute"
        case 22...30: return "integrate"
        default: return "complete"
        }
    }

    init() {
        self.id = UUID()
        self.startDate = Date()
        self.currentDay = 1
        self.phase = "awareness"
    }
}
