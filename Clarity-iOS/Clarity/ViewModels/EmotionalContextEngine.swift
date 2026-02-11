import Foundation
import Observation
import SwiftUI
import SwiftData

// MARK: - Emotional Context Engine

/// Tracks mood over time, detects emotional patterns, and suggests
/// appropriate friction levels based on current emotional state.
@Observable
class EmotionalContextEngine {
    var recentMoods: [MoodEntry] = []
    var currentMoodValence: Double? // -1.0 (very negative) to 1.0 (very positive)
    var dominantPattern: String?

    // MARK: - Log Mood

    /// Persists a mood entry and updates pattern detection.
    func logMood(
        valence: Double,
        label: String,
        context: String?,
        screenTime: Int?,
        modelContext: ModelContext
    ) {
        let entry = MoodEntry(
            valence: valence,
            label: label,
            context: context,
            associatedScreenTime: screenTime
        )
        modelContext.insert(entry)
        try? modelContext.save()

        recentMoods.append(entry)
        currentMoodValence = valence

        // Keep a rolling window of the last 20 entries in memory
        if recentMoods.count > 20 {
            recentMoods.removeFirst(recentMoods.count - 20)
        }

        dominantPattern = detectPattern()
    }

    // MARK: - Pattern Detection

    /// Looks at the most recent moods to identify a dominant emotional trend.
    /// Returns a human-readable pattern label or nil if no clear pattern.
    func detectPattern() -> String? {
        let recent = Array(recentMoods.suffix(5))
        guard recent.count >= 3 else { return nil }

        let negativeCount = recent.filter { $0.valence < -0.2 }.count
        let boredCount = recent.filter {
            $0.label.lowercased().contains("bored") || $0.label.lowercased().contains("restless")
        }.count
        let stressCount = recent.filter {
            $0.label.lowercased().contains("stress") || $0.label.lowercased().contains("anxious")
        }.count

        if negativeCount >= 3 { return "persistentNegative" }
        if boredCount >= 3   { return "boredom" }
        if stressCount >= 3  { return "stress" }

        // Check for improving trend
        if recent.count >= 3 {
            let sorted = recent.suffix(3).map(\.valence)
            if sorted.last ?? 0 > sorted.first ?? 0 + 0.3 {
                return "improving"
            }
        }

        return nil
    }

    // MARK: - Intervention Suggestion

    /// Maps current mood state to an appropriate friction level.
    func suggestIntervention(forMood valence: Double) -> FrictionLevel {
        switch valence {
        case ..<(-0.5):
            // Very negative: gentle breathing is more helpful than confrontation
            return .breathing
        case -0.5..<(-0.1):
            return .intentionCheck
        case -0.1..<0.3:
            // Neutral / mildly positive: standard awareness
            return .awareness
        default:
            // Positive mood but still over threshold: light touch
            return .awareness
        }
    }
}
