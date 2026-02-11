import Foundation
import Observation
import SwiftUI

// MARK: - Clarity Score Calculator

/// Computes a daily 0-100 "Clarity Score" from multiple wellness signals.
/// Weights: 30% screen ratio, 20% mindful pickups, 20% substitutions, 15% mood, 15% intention.
@Observable
class ClarityScoreCalculator {

    // MARK: - Score Calculation

    /// Calculates the Clarity Score (0-100) from daily metrics.
    ///
    /// - Parameters:
    ///   - screenTime: Total screen time in minutes
    ///   - connectionTime: Meaningful/intentional screen time in minutes
    ///   - pickups: Number of phone pickups today
    ///   - substitutions: Number of successful substitutions (user chose alternative)
    ///   - moodTrend: Mood trajectory from -1.0 (worsening) to 1.0 (improving)
    ///   - intentionAdherence: Fraction of sessions matching stated intention (0.0-1.0)
    /// - Returns: Score from 0 to 100
    func calculateScore(
        screenTime: Int,
        connectionTime: Int,
        pickups: Int,
        substitutions: Int,
        moodTrend: Double,
        intentionAdherence: Double
    ) -> Int {
        // 30% — Meaningful vs mindless ratio (higher meaningful = better)
        let ratioScore: Double
        if screenTime > 0 {
            ratioScore = min(Double(connectionTime) / Double(screenTime), 1.0) * 100.0
        } else {
            ratioScore = 100.0 // No screen time is perfect
        }

        // 20% — Mindful pickups (fewer pickups = better, baseline 80/day)
        let pickupScore = max(0.0, min(100.0, (1.0 - Double(pickups) / 80.0) * 100.0))

        // 20% — Successful substitutions (more = better, target 5/day)
        let substitutionScore = min(Double(substitutions) / 5.0, 1.0) * 100.0

        // 15% — Mood trajectory (maps -1...1 to 0...100)
        let moodScore = (moodTrend + 1.0) / 2.0 * 100.0

        // 15% — Intention adherence (0.0-1.0 mapped to 0-100)
        let intentionScore = clamp(intentionAdherence, 0.0, 1.0) * 100.0

        let weighted = ratioScore * 0.30
            + pickupScore * 0.20
            + substitutionScore * 0.20
            + moodScore * 0.15
            + intentionScore * 0.15

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
        case 80...100: return "Exceptional clarity today."
        case 60..<80:  return "Solid day. You're building good habits."
        case 40..<60:  return "Room to grow. Small wins add up."
        case 20..<40:  return "Tough day. Tomorrow is a fresh start."
        default:       return "Every journey starts somewhere."
        }
    }

    private func encouragement(_ score: Int) -> String {
        switch score {
        case 50...100: return "Still in a good range. Keep going."
        case 30..<50:  return "A dip is normal. Focus on one small win."
        default:       return "Be kind to yourself. Progress isn't linear."
        }
    }

    private func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        min(max(value, low), high)
    }
}
