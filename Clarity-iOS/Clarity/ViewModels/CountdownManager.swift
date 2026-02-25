import SwiftUI

/// Manages countdown escalation for Level 4 friction.
/// Each app open increases the unlock delay following a Fibonacci-like sequence.
/// Resets daily. State persisted in App Group UserDefaults for extension access.
@Observable
@MainActor
final class CountdownManager {
    static let shared = CountdownManager()

    private let defaults = UserDefaults(suiteName: "group.com.clarity-focus")!

    // Fibonacci-like escalation: 5s → 10s → 20s → 35s → 55s → 60s cap
    private let delaySequence = [5, 10, 20, 35, 55, 60]

    var opensToday: Int = 0
    var lastResetDate: Date = Date()

    var currentDelay: Int {
        delaySequence[min(opensToday, delaySequence.count - 1)]
    }

    var nextDelay: Int {
        delaySequence[min(opensToday + 1, delaySequence.count - 1)]
    }

    /// Full escalation sequence for display (e.g., "5s → 10s → 20s → ...")
    var escalationSequence: [Int] {
        delaySequence
    }

    private init() {
        loadFromDefaults()
        checkDailyReset()
    }

    func recordOpen() {
        HapticManager.light()
        opensToday += 1
        saveToDefaults()
    }

    func resetDaily() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            opensToday = 0
            lastResetDate = Date()
            saveToDefaults()
        }
    }

    private func loadFromDefaults() {
        opensToday = defaults.integer(forKey: "countdown.opensToday")
        lastResetDate = defaults.object(forKey: "countdown.resetDate") as? Date ?? Date()
    }

    private func saveToDefaults() {
        defaults.set(opensToday, forKey: "countdown.opensToday")
        defaults.set(lastResetDate, forKey: "countdown.resetDate")
    }

    private func checkDailyReset() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            resetDaily()
        }
    }
}
