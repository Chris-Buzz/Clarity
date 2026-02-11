import DeviceActivity
import ManagedSettings
import Foundation

class ClarityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let sharedDefaults = UserDefaults(suiteName: "group.com.clarity-focus")

    override func intervalDidStart(for activity: DeviceActivityName) {
        // Daily monitoring started — apply shields if configured
        if let data = sharedDefaults?.data(forKey: "shieldedTokens") {
            // Decode and apply shields
            // Note: FamilyActivitySelection must be decoded from stored data
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        // Daily monitoring ended — reset friction level
        sharedDefaults?.set(0, forKey: "currentFrictionLevel")
        store.clearAllSettings()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        let rawValue = event.rawValue

        // Handle daily budget exceeded — triggers hard lock
        if rawValue == "budget_exceeded" {
            sharedDefaults?.set(true, forKey: "budgetLocked")
            sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "budgetLockedAt")
            // The DailyBudgetService in the main app will apply hard shields
            // via the dedicated "dailyBudget" ManagedSettingsStore when it reads this flag
            return
        }

        // Handle prosocial text verification threshold
        if rawValue == "text_threshold_reached" {
            // User hit the text-based prosocial threshold
            // Mark in shared defaults so the main app can verify the text was sent
            sharedDefaults?.set(true, forKey: "prosocialTextThresholdReached")
            sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "prosocialTextThresholdTime")
            return
        }

        // Progressive friction threshold reached
        let level = Int(rawValue.replacingOccurrences(of: "threshold_", with: "")) ?? 1

        // Update shared state for shield configuration to read
        sharedDefaults?.set(level, forKey: "currentFrictionLevel")

        // Post notification for main app to show friction overlay if in foreground
        // Extensions can't directly show UI, but can update shield config
        // The ShieldConfigurationDataSource will read the new level

        // Force shield config refresh by re-applying shields
        if let data = sharedDefaults?.data(forKey: "shieldedTokens") {
            // Re-apply to trigger config refresh
        }
    }

    override func eventWillReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) -> Bool {
        // Return true to allow the threshold event to fire
        return true
    }
}
