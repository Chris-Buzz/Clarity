import Foundation
import Observation
import SwiftUI
import SwiftData

// MARK: - Trigger Type

enum Trigger: String, CaseIterable {
    case boredom
    case stress
    case loneliness
    case fomo
    case habit
}

// MARK: - Habit Substitution Engine

/// Detects likely usage triggers and suggests healthier alternatives.
/// Tracks acceptance rates to re-rank suggestions over time.
@Observable
class HabitSubstitutionEngine {
    var recentSubstitutions: [SubstitutionRecord] = []
    var suggestedAction: String?

    // Suggestions ranked by default preference; re-ranked based on acceptance
    private var suggestionsByTrigger: [Trigger: [String]] = [
        .boredom:    ["Call a friend", "Listen to a podcast", "Take a walk", "Read a chapter", "Sketch something"],
        .stress:     ["4-7-8 breathing", "Body scan meditation", "Journal for 5 minutes", "Stretch", "Step outside"],
        .loneliness: ["Text someone you miss", "FaceTime a friend", "Write a letter", "Visit a public space"],
        .fomo:       ["Check messages directly", "Gratitude prompt", "List 3 good things today"],
        .habit:      ["What were you about to do?", "Set an intention first", "Name your goal out loud"],
    ]

    // MARK: - Trigger Detection

    /// Infers the most likely trigger from time-of-day and current mood.
    func detectTrigger(timeOfDay: Date, mood: Double) -> Trigger {
        let hour = Calendar.current.component(.hour, from: timeOfDay)

        // Late night + negative mood -> loneliness
        if (hour >= 22 || hour < 6) && mood < -0.2 {
            return .loneliness
        }
        // High stress signal
        if mood < -0.4 {
            return .stress
        }
        // Neutral mood during typical scrolling hours -> boredom
        if abs(mood) < 0.2 {
            return .boredom
        }
        // Mildly positive but still opening phone -> fomo or habit
        if mood > 0.1 {
            return .fomo
        }

        return .habit
    }

    // MARK: - Suggest Alternative

    /// Returns the top-ranked suggestion for the given trigger.
    func suggestAlternative(for trigger: Trigger) -> String {
        let options = suggestionsByTrigger[trigger] ?? ["Take a deep breath"]
        let suggestion = options.first ?? "Take a deep breath"
        suggestedAction = suggestion
        return suggestion
    }

    // MARK: - Record Outcome

    /// Logs whether the user accepted a substitution, and re-ranks accordingly.
    func recordOutcome(trigger: Trigger, action: String, accepted: Bool, modelContext: ModelContext) {
        let record = SubstitutionRecord(trigger: trigger.rawValue, offeredAction: action, wasAccepted: accepted)
        modelContext.insert(record)
        try? modelContext.save()
        recentSubstitutions.append(record)

        // Re-rank: move accepted suggestions up, declined ones down
        reRankSuggestions(for: trigger)
    }

    /// Re-ranks suggestions based on historical acceptance rates.
    private func reRankSuggestions(for trigger: Trigger) {
        guard var options = suggestionsByTrigger[trigger] else { return }

        let relevantRecords = recentSubstitutions.filter { $0.trigger == trigger.rawValue }

        // Calculate acceptance rate per action
        var rates: [String: Double] = [:]
        for action in options {
            let matches = relevantRecords.filter { $0.offeredAction == action }
            guard !matches.isEmpty else { continue }
            let accepted = matches.filter(\.wasAccepted).count
            rates[action] = Double(accepted) / Double(matches.count)
        }

        // Sort by acceptance rate descending; unrated actions keep original order
        options.sort { a, b in
            (rates[a] ?? 0.5) > (rates[b] ?? 0.5)
        }

        suggestionsByTrigger[trigger] = options
    }
}
