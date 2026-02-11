import FamilyControls
import ManagedSettings
import DeviceActivity
import Foundation

/// Manages Screen Time integration via FamilyControls, ManagedSettings, and DeviceActivity.
/// Provides app shielding and progressive usage threshold monitoring.
class ScreenTimeService {
    static let shared = ScreenTimeService()
    let center = AuthorizationCenter.shared
    let store = ManagedSettingsStore()
    let sharedDefaults = UserDefaults(suiteName: "group.com.clarity.focus")

    private init() {}

    var isAuthorized: Bool {
        center.authorizationStatus == .approved
    }

    /// Request Screen Time authorization from the user.
    func requestAuthorization() async throws {
        try await center.requestAuthorization(for: .individual)
    }

    /// Apply shields to the selected apps and categories.
    func applyShield(for selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            selection.categoryTokens
        )
    }

    /// Remove all shields and managed settings.
    func removeShield() {
        store.clearAllSettings()
    }

    /// Set up DeviceActivity monitoring with progressive minute thresholds.
    /// Each threshold triggers an escalating friction event via the DeviceActivity extension.
    /// - Parameter thresholds: Array of minute values (e.g. [15, 30, 60, 120, 180])
    func startMonitoring(thresholds: [Int]) throws {
        let activityCenter = DeviceActivityCenter()
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for (index, minutes) in thresholds.enumerated() {
            let eventName = DeviceActivityEvent.Name("threshold_\(index + 1)")
            events[eventName] = DeviceActivityEvent(
                threshold: DateComponents(minute: minutes)
            )
        }

        try activityCenter.startMonitoring(
            DeviceActivityName("daily_monitoring"),
            during: schedule,
            events: events
        )
    }

    /// Stop all DeviceActivity monitoring.
    func stopMonitoring() {
        DeviceActivityCenter().stopMonitoring()
    }

    /// Persist the current friction level so Shield extensions can read it.
    func setCurrentFrictionLevel(_ level: Int) {
        sharedDefaults?.set(level, forKey: "currentFrictionLevel")
    }

    /// Read the current friction level from shared storage.
    func getCurrentFrictionLevel() -> Int {
        sharedDefaults?.integer(forKey: "currentFrictionLevel") ?? 0
    }
}
