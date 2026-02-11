import Foundation
import SwiftData

@Model
class UserProfile {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var isOnboarded: Bool = false

    // Gamification
    var totalXP: Int = 0
    var currentLevel: Int = 1
    var streak: Int = 0
    var lastActiveDate: String = "" // "YYYY-MM-DD"

    // Settings
    var theme: String = "vibrant" // "vibrant" | "eerie"
    var frictionThresholds: [Int] = [5, 15, 30, 45, 60] // minutes, user configurable
    var nudgesEnabled: Bool = true
    var nightModeStart: Int = 22 // hour 0-23
    var nightModeEnd: Int = 6

    // Assessment
    var assessmentScore: Int? = nil
    var goals: [String] = []

    // Badges
    var unlockedBadges: [String] = []

    // Shielded apps (stored as encoded FamilyActivitySelection data)
    var shieldedAppsData: Data? = nil

    // Daily Budget — hard block after limit reached
    var dailyBudgetEnabled: Bool = false
    var dailyBudgetMinutes: Int = 180 // 3 hours default
    var budgetAppsData: Data? = nil   // FamilyActivitySelection for budget-controlled apps
    var emergencyUnlocksToday: Int = 0
    var lastEmergencyUnlock: Date? = nil
    var budgetResetDate: String = ""  // "YYYY-MM-DD" tracks when counters last reset
    var maxEmergencyUnlocksPerDay: Int = 2
    var emergencyWaitMinutes: Int = 5 // how long user must wait during unlock

    // Focus Session Blocking
    var focusSessionBlockingEnabled: Bool = false

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
