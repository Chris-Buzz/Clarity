import Foundation
import Observation
import SwiftUI
import SwiftData

// MARK: - Tab Navigation

enum Tab: String, CaseIterable {
    case dashboard = "Dashboard"
    case patience = "Patience"
    case settings = "Settings"
}

// MARK: - Global App State

/// Central observable state that drives navigation and user context.
/// Injected into the SwiftUI environment at the root level.
@Observable
class AppState {
    var currentUser: UserProfile?
    var isOnboarded: Bool = false
    var selectedTab: Tab = .dashboard
    var isShowingFocusTimer: Bool = false
    var isShowingReflection: Bool = false
    var pendingSession: FocusSession?

    // Services — singletons injected via environment for view access
    var subscriptionService = SubscriptionService.shared
    var dailyBudgetService = DailyBudgetService.shared
    var focusBlockingService = FocusSessionBlockingService.shared
    var patienceManager = PatienceManager.shared
    var countdownManager = CountdownManager.shared

    /// Checks SwiftData for an existing user profile and restores onboarding state.
    func checkOnboardingStatus(context: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        if let user = try? context.fetch(descriptor).first {
            currentUser = user
            isOnboarded = user.isOnboarded
        }
    }
}
