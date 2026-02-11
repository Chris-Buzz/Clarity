import Foundation
import Observation
import SwiftUI
import SwiftData

// MARK: - Gamification Manager

/// Manages XP awards, level progression, badge unlocks, and daily streaks.
@Observable
class GamificationManager {

    // MARK: - XP Constants

    enum XP {
        static let perMinute         = 10
        static let urgeResisted      = 25
        static let sessionCompletion = 50
        static let perfectSession    = 100
        static let streakMultiplier  = 0.1
        static let maxStreakBonus    = 0.5
    }

    // MARK: - Level Definitions

    struct Level {
        let name: String
        let xpThreshold: Int
    }

    static let levels: [Level] = [
        Level(name: "Ember",     xpThreshold: 0),
        Level(name: "Spark",     xpThreshold: 100),
        Level(name: "Kindle",    xpThreshold: 250),
        Level(name: "Glow",      xpThreshold: 500),
        Level(name: "Flame",     xpThreshold: 1_000),
        Level(name: "Blaze",     xpThreshold: 1_750),
        Level(name: "Torch",     xpThreshold: 2_750),
        Level(name: "Beacon",    xpThreshold: 4_000),
        Level(name: "Radiance",  xpThreshold: 5_500),
        Level(name: "Luminance", xpThreshold: 7_500),
        Level(name: "Brilliance",xpThreshold: 10_000),
        Level(name: "Flare",     xpThreshold: 13_000),
        Level(name: "Corona",    xpThreshold: 16_500),
        Level(name: "Aurora",    xpThreshold: 20_500),
        Level(name: "Phoenix",   xpThreshold: 25_000),
        Level(name: "Sunburst",  xpThreshold: 30_000),
        Level(name: "Supernova", xpThreshold: 36_000),
        Level(name: "Starfire",  xpThreshold: 43_000),
        Level(name: "Solaris",   xpThreshold: 52_000),
        Level(name: "Inferno",   xpThreshold: 62_000),
    ]

    // MARK: - Badge Definitions

    static let badgeDefinitions: [(id: String, name: String, check: (UserProfile, [FocusSession]) -> Bool)] = [
        ("first_session",   "First Light",     { _, sessions in sessions.count >= 1 }),
        ("streak_3",        "Three-Peat",      { user, _ in user.streak >= 3 }),
        ("streak_7",        "Week Warrior",    { user, _ in user.streak >= 7 }),
        ("streak_30",       "Monthly Master",  { user, _ in user.streak >= 30 }),
        ("level_5",         "Blazing Trail",   { user, _ in user.currentLevel >= 5 }),
        ("level_10",        "Brilliant Mind",  { user, _ in user.currentLevel >= 10 }),
        ("level_20",        "Inferno",         { user, _ in user.currentLevel >= 20 }),
        ("sessions_10",     "Dedicated",       { _, sessions in sessions.filter(\.wasCompleted).count >= 10 }),
        ("sessions_50",     "Focused Force",   { _, sessions in sessions.filter(\.wasCompleted).count >= 50 }),
        ("perfect_5",       "Perfectionist",   { _, sessions in
            sessions.filter { $0.wasCompleted && $0.tabLeavesCount == 0 }.count >= 5
        }),
    ]

    // MARK: - Award XP

    /// Adds XP to the user profile and persists.
    func awardXP(amount: Int, user: UserProfile, context: ModelContext) {
        user.totalXP += amount
        _ = checkLevelUp(user: user)
        try? context.save()
    }

    // MARK: - Level Up

    /// Checks if the user qualifies for a higher level. Returns true if leveled up.
    func checkLevelUp(user: UserProfile) -> Bool {
        var newLevel = 1
        for (index, level) in Self.levels.enumerated() {
            if user.totalXP >= level.xpThreshold {
                newLevel = index + 1
            }
        }
        if newLevel > user.currentLevel {
            user.currentLevel = newLevel
            return true
        }
        return false
    }

    // MARK: - Badge Unlocks

    /// Evaluates all badge conditions and unlocks any newly earned badges.
    func checkBadgeUnlocks(user: UserProfile, sessions: [FocusSession], context: ModelContext) {
        for badge in Self.badgeDefinitions {
            if !user.unlockedBadges.contains(badge.id) && badge.check(user, sessions) {
                user.unlockedBadges.append(badge.id)
            }
        }
        try? context.save()
    }

    // MARK: - Streak

    /// Calculates the streak bonus multiplier: 10% per day, capped at 50%.
    static func calculateStreakMultiplier(streak: Int) -> Double {
        min(Double(streak) * XP.streakMultiplier, XP.maxStreakBonus)
    }

    /// Updates the user's streak by comparing lastActiveDate with today.
    func updateStreak(user: UserProfile) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        guard todayString != user.lastActiveDate else { return } // Already logged today

        if let lastDate = formatter.date(from: user.lastActiveDate) {
            let calendar = Calendar.current
            let daysBetween = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysBetween == 1 {
                user.streak += 1
            } else if daysBetween > 1 {
                user.streak = 1 // Reset streak after a gap
            }
        } else {
            user.streak = 1 // First recorded day
        }

        user.lastActiveDate = todayString
    }

    // MARK: - Helpers

    /// Returns the name of the user's current level.
    static func levelName(for level: Int) -> String {
        guard level >= 1, level <= levels.count else { return "Unknown" }
        return levels[level - 1].name
    }

    /// XP needed to reach the next level, or nil if at max.
    static func xpToNextLevel(currentXP: Int, currentLevel: Int) -> Int? {
        guard currentLevel < levels.count else { return nil }
        return levels[currentLevel].xpThreshold - currentXP
    }
}
