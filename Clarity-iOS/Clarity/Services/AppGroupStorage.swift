import FamilyControls
import Foundation

/// Shared storage between the main app and extensions (Shield, DeviceActivity)
/// via App Group UserDefaults and file containers.
struct AppGroupStorage {
    static let appGroupID = "group.com.clarity-focus"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Storage Keys

    enum Keys: String {
        case currentFrictionLevel
        case shieldedTokens
        case frictionThresholds
        case activeSession
        case userTheme
        case dailyScreenTime
    }

    // MARK: - Friction Level

    static func setFrictionLevel(_ level: Int) {
        sharedDefaults?.set(level, forKey: Keys.currentFrictionLevel.rawValue)
    }

    static func getFrictionLevel() -> Int {
        sharedDefaults?.integer(forKey: Keys.currentFrictionLevel.rawValue) ?? 0
    }

    // MARK: - Active Session

    static func setActiveSession(_ active: Bool) {
        sharedDefaults?.set(active, forKey: Keys.activeSession.rawValue)
    }

    static func isSessionActive() -> Bool {
        sharedDefaults?.bool(forKey: Keys.activeSession.rawValue) ?? false
    }

    // MARK: - Friction Thresholds

    /// Save the array of minute thresholds for escalating friction.
    static func setFrictionThresholds(_ thresholds: [Int]) {
        sharedDefaults?.set(thresholds, forKey: Keys.frictionThresholds.rawValue)
    }

    static func getFrictionThresholds() -> [Int] {
        sharedDefaults?.array(forKey: Keys.frictionThresholds.rawValue) as? [Int]
            ?? [15, 30, 60, 120, 180]
    }

    // MARK: - FamilyActivitySelection (Shielded Apps)

    /// Encode and save a FamilyActivitySelection to shared storage.
    static func saveSelection(_ selection: FamilyActivitySelection) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        sharedDefaults?.set(data, forKey: Keys.shieldedTokens.rawValue)
    }

    /// Load a previously saved FamilyActivitySelection from shared storage.
    static func loadSelection() -> FamilyActivitySelection? {
        guard let data = sharedDefaults?.data(forKey: Keys.shieldedTokens.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    // MARK: - User Theme

    static func setUserTheme(_ theme: String) {
        sharedDefaults?.set(theme, forKey: Keys.userTheme.rawValue)
    }

    static func getUserTheme() -> String {
        sharedDefaults?.string(forKey: Keys.userTheme.rawValue) ?? "dark"
    }

    // MARK: - Daily Screen Time

    /// Store today's cumulative screen time in minutes.
    static func setDailyScreenTime(_ minutes: Int) {
        sharedDefaults?.set(minutes, forKey: Keys.dailyScreenTime.rawValue)
    }

    static func getDailyScreenTime() -> Int {
        sharedDefaults?.integer(forKey: Keys.dailyScreenTime.rawValue) ?? 0
    }
}
