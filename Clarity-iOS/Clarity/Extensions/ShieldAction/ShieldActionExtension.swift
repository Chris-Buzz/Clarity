import ManagedSettings

class ClarityShieldAction: ShieldActionDelegate {
    let sharedDefaults = UserDefaults(suiteName: "group.com.clarity-focus")

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
                // Track the bypass for adaptive friction escalation
                incrementBypassCount()
                // Also increment countdown opens for escalation
                incrementCountdownOpens()
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
                incrementBypassCount()
                incrementCountdownOpens()
                completionHandler(.close)
            }
        @unknown default:
            completionHandler(.close)
        }
    }

    // MARK: - Adaptive Friction

    /// Increment bypass counter in App Group UserDefaults so the main app's
    /// AdaptiveFrictionEngine can read it back and escalate friction.
    private func incrementBypassCount() {
        let current = sharedDefaults?.integer(forKey: "adaptiveFriction.dailyBypassCount") ?? 0
        sharedDefaults?.set(current + 1, forKey: "adaptiveFriction.dailyBypassCount")
    }

    /// Increment countdown opens so the next shield shows a longer delay.
    private func incrementCountdownOpens() {
        let current = sharedDefaults?.integer(forKey: "countdown.opensToday") ?? 0
        sharedDefaults?.set(current + 1, forKey: "countdown.opensToday")
    }
}
