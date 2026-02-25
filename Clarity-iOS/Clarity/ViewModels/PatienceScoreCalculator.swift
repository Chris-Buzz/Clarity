import Foundation
import Observation
import SwiftUI

// MARK: - Patience Score Calculator

/// Computes a daily 0-100 "Patience Score" from multiple training signals.
/// Weights: 40% friction completions, 25% challenges, 15% fog journal, 20% program progress.
@Observable
class PatienceScoreCalculator {

    // MARK: - Score Calculation

    /// Calculates the Patience Score (0-100) from daily metrics.
    ///
    /// - Parameters:
    ///   - frictionCompletions: Number of friction challenges completed today (target: 5)
    ///   - challengesDone: Number of daily challenges completed (target: 1)
    ///   - fogEntriesToday: Number of fog journal entries today (target: 1)
    ///   - programDay: Current day in the 30-day dopamine program (0-30)
    /// - Returns: Score from 0 to 100
    func calculateScore(
        frictionCompletions: Int,
        challengesDone: Int,
        fogEntriesToday: Int,
        programDay: Int
    ) -> Int {
        // 40% — Friction completions (target: 5/day)
        let frictionScore = min(Double(frictionCompletions) / 5.0, 1.0) * 100.0

        // 25% — Challenges done (target: 1/day)
        let challengeScore = min(Double(challengesDone), 1.0) * 100.0

        // 15% — Fog journal entries (target: 1/day)
        let fogScore = min(Double(fogEntriesToday), 1.0) * 100.0

        // 20% — Program progress (day/30)
        let programScore = min(Double(programDay) / 30.0, 1.0) * 100.0

        let weighted = frictionScore * 0.40
            + challengeScore * 0.25
            + fogScore * 0.15
            + programScore * 0.20

        return Int(clamp(weighted, 0, 100))
    }

    // MARK: - Insight Generation

    /// Generates a short human-readable insight comparing today's score to a previous one.
    func generateInsight(score: Int, previousScore: Int?) -> String {
        guard let prev = previousScore else {
            return scoreLabel(score)
        }

        let delta = score - prev
        if delta > 0 {
            return "Up \(delta) points from last time. \(scoreLabel(score))"
        } else if delta < 0 {
            return "Down \(abs(delta)) points. \(encouragement(score))"
        } else {
            return "Holding steady at \(score). Consistency is powerful."
        }
    }

    // MARK: - Private Helpers

    private func scoreLabel(_ score: Int) -> String {
        switch score {
        case 80...100: return "Exceptional patience today."
        case 60..<80:  return "Solid day. Your patience is building."
        case 40..<60:  return "Room to grow. Small wins add up."
        case 20..<40:  return "Tough day. Tomorrow is a fresh start."
        default:       return "Every journey starts somewhere."
        }
    }

    private func encouragement(_ score: Int) -> String {
        switch score {
        case 50...100: return "Still in a good range. Keep going."
        case 30..<50:  return "A dip is normal. Focus on one small win."
        default:       return "Be kind to yourself. Progress is not linear."
        }
    }

    private func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        min(max(value, low), high)
    }
}
