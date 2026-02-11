import Foundation
import Observation
import ManagedSettings
import DeviceActivity
import FamilyControls

/// Manages the daily screen time budget with hard app blocking.
/// Uses a dedicated ManagedSettingsStore ("dailyBudget") so budget shields
/// operate independently from friction shields and WiFi gating.
///
/// When the user's cumulative screen time exceeds their budget, all budget-controlled
/// apps get a hard shield with NO secondary button — the only way through is
/// the EmergencyUnlockView (type phrase → wait 5 min → confirm).
@Observable
class DailyBudgetService {
    static let shared = DailyBudgetService()

    private let budgetStore = ManagedSettingsStore(named: .init("dailyBudget"))
    private let sharedDefaults = UserDefaults(suiteName: "group.com.clarity.focus")

    // MARK: - State

    var isLocked: Bool = false
    var budgetMinutes: Int = 180
    var emergencyUnlockActive: Bool = false
    var emergencyUnlockExpiresAt: Date?

    private var relockTimer: Timer?

    // MARK: - Constants

    static let emergencyUnlockDuration: TimeInterval = 30 * 60 // 30 minutes
    static let maxDefaultUnlocks = 2
    static let activityName = DeviceActivityName("budget_monitoring")
    static let budgetEventName = DeviceActivityEvent.Name("budget_exceeded")

    // MARK: - Init

    private init() {
        // Restore lock state from shared defaults
        isLocked = sharedDefaults?.bool(forKey: "budgetLocked") ?? false
        emergencyUnlockActive = sharedDefaults?.bool(forKey: "emergencyUnlockActive") ?? false

        if let expiresInterval = sharedDefaults?.double(forKey: "emergencyUnlockExpires"),
           expiresInterval > 0 {
            let expires = Date(timeIntervalSince1970: expiresInterval)
            if expires > Date() {
                emergencyUnlockExpiresAt = expires
                scheduleRelock(at: expires)
            } else {
                // Expired while app was closed — re-lock
                emergencyUnlockActive = false
                sharedDefaults?.set(false, forKey: "emergencyUnlockActive")
                if sharedDefaults?.bool(forKey: "budgetLocked") == true {
                    relockApps()
                }
            }
        }
    }

    // MARK: - Budget Monitoring

    /// Start DeviceActivity monitoring for the daily budget threshold.
    /// Called when budget is enabled or app launches with budget active.
    func startBudgetMonitoring(budgetMinutes: Int, apps: FamilyActivitySelection) {
        self.budgetMinutes = budgetMinutes

        // Store budget apps in shared defaults so extensions can read them
        if let encoded = try? JSONEncoder().encode(apps) {
            sharedDefaults?.set(encoded, forKey: "budgetAppsData")
        }
        sharedDefaults?.set(budgetMinutes, forKey: "budgetMinutes")

        let activityCenter = DeviceActivityCenter()

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            Self.budgetEventName: DeviceActivityEvent(
                threshold: DateComponents(minute: budgetMinutes)
            )
        ]

        do {
            try activityCenter.startMonitoring(
                Self.activityName,
                during: schedule,
                events: events
            )
        } catch {
            // DeviceActivity monitoring failed — log but don't crash
        }
    }

    /// Stop budget monitoring.
    func stopBudgetMonitoring() {
        DeviceActivityCenter().stopMonitoring([Self.activityName])
        unlockAll()
    }

    // MARK: - Lock Down

    /// Apply hard shields to all budget-controlled apps.
    /// Called by DeviceActivityMonitor extension when budget is exceeded,
    /// or when the app detects the budget was exceeded while backgrounded.
    func lockDown(apps: FamilyActivitySelection) {
        budgetStore.shield.applications = apps.applicationTokens
        budgetStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            apps.categoryTokens
        )

        isLocked = true
        emergencyUnlockActive = false
        sharedDefaults?.set(true, forKey: "budgetLocked")
        sharedDefaults?.set(false, forKey: "emergencyUnlockActive")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "budgetLockedAt")
    }

    /// Called from main app when it detects the extension set budgetLocked = true
    func checkAndApplyLock() {
        let locked = sharedDefaults?.bool(forKey: "budgetLocked") ?? false
        if locked && !emergencyUnlockActive {
            isLocked = true
        }
    }

    // MARK: - Emergency Unlock

    /// Perform emergency unlock — removes shields for 30 minutes.
    /// Returns false if max unlocks for today have been used.
    func performEmergencyUnlock() -> Bool {
        let unlocksUsed = sharedDefaults?.integer(forKey: "emergencyUnlocksToday") ?? 0
        let maxUnlocks = sharedDefaults?.integer(forKey: "maxEmergencyUnlocks") ?? Self.maxDefaultUnlocks

        guard unlocksUsed < maxUnlocks else { return false }

        // Clear shields temporarily
        budgetStore.clearAllSettings()

        let expires = Date().addingTimeInterval(Self.emergencyUnlockDuration)
        emergencyUnlockActive = true
        emergencyUnlockExpiresAt = expires
        isLocked = false

        sharedDefaults?.set(true, forKey: "emergencyUnlockActive")
        sharedDefaults?.set(expires.timeIntervalSince1970, forKey: "emergencyUnlockExpires")
        sharedDefaults?.set(false, forKey: "budgetLocked")
        sharedDefaults?.set(unlocksUsed + 1, forKey: "emergencyUnlocksToday")

        scheduleRelock(at: expires)
        return true
    }

    /// How many emergency unlocks remain today.
    var remainingUnlocks: Int {
        let used = sharedDefaults?.integer(forKey: "emergencyUnlocksToday") ?? 0
        let maxUnlocks = sharedDefaults?.integer(forKey: "maxEmergencyUnlocks") ?? Self.maxDefaultUnlocks
        return Swift.max(maxUnlocks - used, 0)
    }

    // MARK: - Relock

    private func scheduleRelock(at date: Date) {
        relockTimer?.invalidate()
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else {
            relockApps()
            return
        }

        relockTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.relockApps()
        }
    }

    private func relockApps() {
        emergencyUnlockActive = false
        emergencyUnlockExpiresAt = nil
        sharedDefaults?.set(false, forKey: "emergencyUnlockActive")
        sharedDefaults?.removeObject(forKey: "emergencyUnlockExpires")

        // Re-apply shields if budget was exceeded
        if let data = sharedDefaults?.data(forKey: "budgetAppsData"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            lockDown(apps: selection)
        }
    }

    // MARK: - Daily Reset

    /// Reset budget counters at midnight. Called from app launch and background task.
    func resetDaily() {
        let today = formatDate(Date())
        let lastReset = sharedDefaults?.string(forKey: "budgetResetDate") ?? ""

        guard today != lastReset else { return } // Already reset today

        // Clear all budget shields and counters
        budgetStore.clearAllSettings()
        isLocked = false
        emergencyUnlockActive = false
        emergencyUnlockExpiresAt = nil
        relockTimer?.invalidate()

        sharedDefaults?.set(false, forKey: "budgetLocked")
        sharedDefaults?.set(false, forKey: "emergencyUnlockActive")
        sharedDefaults?.set(0, forKey: "emergencyUnlocksToday")
        sharedDefaults?.removeObject(forKey: "emergencyUnlockExpires")
        sharedDefaults?.set(today, forKey: "budgetResetDate")

        // Re-start monitoring for the new day if budget is enabled
        if let data = sharedDefaults?.data(forKey: "budgetAppsData"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            let minutes = sharedDefaults?.integer(forKey: "budgetMinutes") ?? 180
            startBudgetMonitoring(budgetMinutes: minutes, apps: selection)
        }
    }

    // MARK: - Unlock All

    /// Completely remove budget shields (used when disabling budget feature).
    func unlockAll() {
        budgetStore.clearAllSettings()
        isLocked = false
        emergencyUnlockActive = false
        emergencyUnlockExpiresAt = nil
        relockTimer?.invalidate()
        sharedDefaults?.set(false, forKey: "budgetLocked")
        sharedDefaults?.set(false, forKey: "emergencyUnlockActive")
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
