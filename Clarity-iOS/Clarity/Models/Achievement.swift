import Foundation
import SwiftData

@Model
class Achievement {
    @Attribute(.unique) var id: String = ""
    var name: String = ""
    var desc: String = "" // "description" is reserved in some contexts
    var iconName: String = "" // SF Symbol name
    var unlockedAt: Date? = nil
    var isUnlocked: Bool = false
    var requirement: String = ""

    init(id: String, name: String, description: String, iconName: String, requirement: String) {
        self.id = id
        self.name = name
        self.desc = description
        self.iconName = iconName
        self.requirement = requirement
    }

    /// All available achievements in the app
    static let allAchievements: [(id: String, name: String, description: String, iconName: String, requirement: String)] = [
        (
            id: "first_flame",
            name: "First Flame",
            description: "Complete first focus session",
            iconName: "flame.fill",
            requirement: "Complete first focus session"
        ),
        (
            id: "streak_3",
            name: "Kindling",
            description: "3-day streak",
            iconName: "flame",
            requirement: "3-day streak"
        ),
        (
            id: "streak_7",
            name: "Bonfire",
            description: "7-day streak",
            iconName: "flame.circle.fill",
            requirement: "7-day streak"
        ),
        (
            id: "streak_30",
            name: "Eternal Flame",
            description: "30-day streak",
            iconName: "sun.max.fill",
            requirement: "30-day streak"
        ),
        (
            id: "hour_focused",
            name: "First Hour",
            description: "1 hour total focused",
            iconName: "clock.fill",
            requirement: "1 hour total focused"
        ),
        (
            id: "five_hours",
            name: "Deep Focus",
            description: "5 hours total focused",
            iconName: "brain.head.profile",
            requirement: "5 hours total focused"
        ),
        (
            id: "twenty_hours",
            name: "Flow State",
            description: "20 hours total focused",
            iconName: "sparkles",
            requirement: "20 hours total focused"
        ),
        (
            id: "urge_master",
            name: "Urge Master",
            description: "Resist 50 urges",
            iconName: "shield.checkered",
            requirement: "Resist 50 urges"
        ),
        (
            id: "perfect_ten",
            name: "Perfect Ten",
            description: "10 perfect sessions",
            iconName: "star.circle.fill",
            requirement: "10 perfect sessions"
        ),
        (
            id: "clarity_achieved",
            name: "Clarity Achieved",
            description: "Reach Clarity Score 90",
            iconName: "eye.fill",
            requirement: "Reach Clarity Score 90"
        )
    ]
}
