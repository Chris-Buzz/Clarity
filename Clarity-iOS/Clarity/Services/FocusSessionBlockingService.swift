import Foundation
import ManagedSettings
import FamilyControls

/// Blocks distracting apps during voluntary focus sessions.
/// Uses a dedicated ManagedSettingsStore ("focusSession") so session shields
/// operate independently from friction and budget shields.
class FocusSessionBlockingService {
    static let shared = FocusSessionBlockingService()

    private let sessionStore = ManagedSettingsStore(named: .init("focusSession"))
    private let sharedDefaults = UserDefaults(suiteName: "group.com.clarity-focus")

    private init() {}

    /// Apply hard shields to selected apps for the duration of a focus session.
    /// Shield has no bypass — user must end the session in Clarity to remove it.
    func activateBlock(apps: FamilyActivitySelection) {
        sessionStore.shield.applications = apps.applicationTokens
        sessionStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            apps.categoryTokens
        )
        sharedDefaults?.set(true, forKey: "focusSessionActive")
    }

    /// Remove all session shields when the focus session ends.
    func deactivateBlock() {
        sessionStore.clearAllSettings()
        sharedDefaults?.set(false, forKey: "focusSessionActive")
    }
}
