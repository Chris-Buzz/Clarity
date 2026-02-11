import ManagedSettings

class ClarityShieldAction: ShieldActionDelegate {
    let sharedDefaults = UserDefaults(suiteName: "group.com.clarity.focus")

    /// Whether a hard lock is active (budget exceeded or focus session running).
    /// When hard-locked, the secondary button does nothing — shield stays.
    private var isHardLocked: Bool {
        let budgetLocked = sharedDefaults?.bool(forKey: "budgetLocked") ?? false
        let focusActive = sharedDefaults?.bool(forKey: "focusSessionActive") ?? false
        return budgetLocked || focusActive
    }

    override func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // "Open Clarity" — always opens the main app
            completionHandler(.defer)
        case .secondaryButtonPressed:
            if isHardLocked {
                // BLOCKED — shield stays, button does nothing
                completionHandler(.none)
            } else {
                // Normal friction — "I Choose to Continue"
                completionHandler(.close)
            }
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action: action, for: Application(), completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.defer)
        case .secondaryButtonPressed:
            if isHardLocked {
                completionHandler(.none)
            } else {
                completionHandler(.close)
            }
        @unknown default:
            completionHandler(.close)
        }
    }
}
