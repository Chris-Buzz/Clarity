import Foundation
import Observation
import SwiftUI

// MARK: - Friction Level

enum FrictionLevel: Int, CaseIterable {
    case awareness = 1        // 5 min threshold
    case breathingGate = 2    // 15 min threshold
    case intentDeclaration = 3 // 30 min threshold
    case countdownUnlock = 4  // 45 min threshold
    case scrollFriction = 5   // 60 min threshold

    var title: String {
        switch self {
        case .awareness: return "Awareness"
        case .breathingGate: return "Breathing Gate"
        case .intentDeclaration: return "Intent Declaration"
        case .countdownUnlock: return "Countdown Unlock"
        case .scrollFriction: return "Scroll Friction"
        }
    }

    var description: String {
        switch self {
        case .awareness: return "A gentle nudge that you've been scrolling"
        case .breathingGate: return "6-second forced breath before continuing"
        case .intentDeclaration: return "State why you need this app right now"
        case .countdownUnlock: return "Escalating timer that gets longer each time"
        case .scrollFriction: return "Slow-scroll mindful content before re-entry"
        }
    }

    var baseThresholdMinutes: Double {
        switch self {
        case .awareness: return 5
        case .breathingGate: return 15
        case .intentDeclaration: return 30
        case .countdownUnlock: return 45
        case .scrollFriction: return 60
        }
    }
}

// MARK: - Progressive Friction Manager

/// Escalates patience-based friction interventions as screen time accumulates.
/// Thresholds halve during night mode (10pm-6am) and compress further with
/// adaptive friction (doomscroll / bypass detection). Multipliers stack multiplicatively.
@Observable
class ProgressiveFrictionManager {
    var currentLevel: Int = 0 // 0 = no friction active
    var isShowingFriction: Bool = false
    var activeFriction: FrictionLevel?

    /// Default thresholds in minutes; user can customize via UserProfile.frictionThresholds
    var thresholds: [Int] = [5, 15, 30, 45, 60]

    /// Tracks which thresholds have already fired this session to avoid repeat triggers
    private var firedThresholds: Set<Int> = []

    // MARK: - Multipliers

    /// Night mode is active between 10pm and 6am, halving all thresholds
    var nightModeMultiplier: Double {
        isNightMode() ? 0.5 : 1.0
    }

    /// Adaptive friction multiplier from the engine (1.0x normal, 0.25x extreme)
    var adaptiveMultiplier: Double {
        AdaptiveFrictionEngine.shared.frictionMultiplier
    }

    // MARK: - Threshold Check

    /// Returns the friction level if a new threshold was just crossed.
    /// Effective threshold = base * nightModeMultiplier * adaptiveMultiplier.
    func checkThreshold(minutesUsed: Int) -> FrictionLevel? {
        let combinedMultiplier = nightModeMultiplier * adaptiveMultiplier
        let effective = thresholds.map { Swift.max(Int(Double($0) * combinedMultiplier), 1) }

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

    /// Effective threshold for a given level (after multipliers)
    func effectiveThreshold(for level: FrictionLevel) -> Int {
        let baseIndex = level.rawValue - 1
        guard baseIndex < thresholds.count else { return Int(level.baseThresholdMinutes) }
        let base = Double(thresholds[baseIndex])
        return Swift.max(Int(base * nightModeMultiplier * adaptiveMultiplier), 1)
    }

    /// Dismisses the current friction overlay and records a completion.
    func handleFrictionComplete(level: FrictionLevel) {
        PatienceManager.shared.recordFrictionCompletion()
        isShowingFriction = false
        activeFriction = nil
    }

    /// Called when user bypasses (cancels) friction instead of completing it.
    /// Records the bypass in both PatienceManager and AdaptiveFrictionEngine.
    func handleFrictionBypassed(level: FrictionLevel) {
        PatienceManager.shared.recordFrictionBypass()
        AdaptiveFrictionEngine.shared.recordBypass()
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
