import SwiftUI

/// Tracks daily patience metrics and computes the composite patience score (0-100).
/// Score formula: 40% friction completions + 25% challenges + 15% fog journal + 20% program progress.
@Observable
@MainActor
final class PatienceManager {
    static let shared = PatienceManager()

    private let defaults = UserDefaults(suiteName: "group.com.clarity-focus")!

    var dailyPatienceScore: Int = 0
    var challengeStreak: Int = 0
    var currentFogLevel: Int = 3
    var todaysChallengeCompleted: Bool = false
    var frictionCompletionsToday: Int = 0
    var frictionBypassesToday: Int = 0

    private init() {
        loadFromDefaults()
    }

    /// Computes patience score from daily inputs.
    /// - Parameters:
    ///   - frictionCompletions: Number of friction challenges completed (target: 5)
    ///   - challengesDone: Number of daily challenges completed (target: 1)
    ///   - fogEntriesToday: Number of fog journal entries (target: 1)
    ///   - programDay: Current day in 30-day dopamine program (0-30)
    /// - Returns: Score from 0-100
    @discardableResult
    func calculatePatienceScore(
        frictionCompletions: Int,
        challengesDone: Int,
        fogEntriesToday: Int,
        programDay: Int
    ) -> Int {
        // Friction completions: 40% (target: 5 completions = 100%)
        let frictionScore = min(Double(frictionCompletions) / 5.0, 1.0) * 40
        // Challenges done: 25% (target: 1/day = 100%)
        let challengeScore = min(Double(challengesDone), 1.0) * 25
        // Fog journal: 15% (target: 1 entry/day = 100%)
        let fogScore = min(Double(fogEntriesToday), 1.0) * 15
        // Program progress: 20% (day/30)
        let programScore = min(Double(programDay) / 30.0, 1.0) * 20

        let total = Int(frictionScore + challengeScore + fogScore + programScore)
        dailyPatienceScore = total
        defaults.set(total, forKey: "clarityScore") // widget reads this key
        return total
    }

    func recordFrictionCompletion() {
        frictionCompletionsToday += 1
        defaults.set(frictionCompletionsToday, forKey: "patience.frictionCompletions")
    }

    func recordFrictionBypass() {
        frictionBypassesToday += 1
        defaults.set(frictionBypassesToday, forKey: "patience.frictionBypasses")
    }

    func resetDaily() {
        frictionCompletionsToday = 0
        frictionBypassesToday = 0
        todaysChallengeCompleted = false
        defaults.set(0, forKey: "patience.frictionCompletions")
        defaults.set(0, forKey: "patience.frictionBypasses")
    }

    private func loadFromDefaults() {
        frictionCompletionsToday = defaults.integer(forKey: "patience.frictionCompletions")
        frictionBypassesToday = defaults.integer(forKey: "patience.frictionBypasses")
    }
}
