import Foundation
import Observation
import SwiftUI

// MARK: - Friction Level

enum FrictionLevel: Int, CaseIterable {
    case awareness = 1
    case prosocialText = 2      // was: breathing — now prompts user to text someone
    case intentionCheck = 3
    case prosocialCall = 4      // was: reflection — now prompts user to call someone
    case strongEncouragement = 5

    var title: String {
        switch self {
        case .awareness:          return "Awareness Nudge"
        case .prosocialText:      return "Text Someone"
        case .intentionCheck:     return "Intention Check"
        case .prosocialCall:      return "Call Someone"
        case .strongEncouragement: return "Strong Encouragement"
        }
    }

    /// Classic (non-prosocial) fallback title for when prosocial mode is disabled
    var classicTitle: String {
        switch self {
        case .awareness:          return "Awareness Nudge"
        case .prosocialText:      return "Breathing Exercise"
        case .intentionCheck:     return "Intention Check"
        case .prosocialCall:      return "Reflection Prompt"
        case .strongEncouragement: return "Strong Encouragement"
        }
    }

    var description: String {
        switch self {
        case .awareness:          return "You've been scrolling for a while. Is this intentional?"
        case .prosocialText:      return "Someone would love to hear from you right now."
        case .intentionCheck:     return "What were you planning to do? Is this still it?"
        case .prosocialCall:      return "A quick call can change your whole day."
        case .strongEncouragement: return "You've spent significant time today. Consider taking a real break."
        }
    }

    /// Classic (non-prosocial) fallback description
    var classicDescription: String {
        switch self {
        case .awareness:          return "You've been scrolling for a while. Is this intentional?"
        case .prosocialText:      return "Let's take three deep breaths before continuing."
        case .intentionCheck:     return "What were you planning to do? Is this still it?"
        case .prosocialCall:      return "How are you feeling right now? Rate your mood."
        case .strongEncouragement: return "You've spent significant time today. Consider taking a real break."
        }
    }
}

// MARK: - Progressive Friction Manager

/// Escalates friction interventions as screen time accumulates.
/// Thresholds halve during night mode (10pm-6am by default).
@Observable
class ProgressiveFrictionManager {
    var currentLevel: Int = 0 // 0 = no friction active
    var isShowingFriction: Bool = false
    var activeFriction: FrictionLevel?

    /// When true, layers 2 and 4 use prosocial challenges instead of classic friction
    var prosocialEnabled: Bool = true

    /// Default thresholds in minutes; user can customize via UserProfile.frictionThresholds
    var thresholds: [Int] = [5, 15, 30, 45, 60]

    /// Tracks which thresholds have already fired this session to avoid repeat triggers
    private var firedThresholds: Set<Int> = []

    // MARK: - Threshold Check

    /// Returns the friction level if a new threshold was just crossed.
    func checkThreshold(minutesUsed: Int) -> FrictionLevel? {
        let effective = isNightMode() ? thresholds.map { $0 / 2 } : thresholds

        for (index, threshold) in effective.enumerated() {
            guard index < FrictionLevel.allCases.count else { break }

            if minutesUsed >= threshold && !firedThresholds.contains(index) {
                firedThresholds.insert(index)
                let level = FrictionLevel(rawValue: index + 1)!
                currentLevel = level.rawValue
                activeFriction = level
                isShowingFriction = true
                return level
            }
        }
        return nil
    }

    /// Whether the given friction level should show a prosocial challenge
    func isProsocialLevel(_ level: FrictionLevel) -> Bool {
        prosocialEnabled && (level == .prosocialText || level == .prosocialCall)
    }

    /// Dismisses the current friction overlay so the user can continue.
    func handleFrictionComplete() {
        isShowingFriction = false
        activeFriction = nil
    }

    /// Resets fired thresholds (call at start of a new day).
    func resetForNewDay() {
        firedThresholds.removeAll()
        currentLevel = 0
    }

    // MARK: - Night Mode

    /// Night mode is active between 10pm and 6am, halving all thresholds.
    private func isNightMode() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 22 || hour < 6
    }
}
