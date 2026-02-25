import SwiftUI
import SwiftData

/// Root view that checks for an existing user profile and routes to
/// AuthScreen (first launch) or TabContainer (returning user).
/// Also manages full-screen covers for the focus timer and reflection flow.
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State var appState = AppState()
    @State private var sessionManager = SessionManager()
    @State private var gamificationManager = GamificationManager()

    var body: some View {
        ZStack {
            ClarityColors.background.ignoresSafeArea()

            if appState.isOnboarded {
                TabContainer()
            } else {
                AuthScreen()
            }
        }
        .environment(appState)
        .environment(sessionManager)
        .environment(gamificationManager)
        .onAppear {
            appState.checkOnboardingStatus(context: modelContext)

            // Service initialization
            Task { await SubscriptionService.shared.loadProducts() }
            DataCleanupService.shared.scheduleCleanup()

            // Daily budget: reset counters at midnight + check for lock state
            DailyBudgetService.shared.resetDaily()
            DailyBudgetService.shared.checkAndApplyLock()

            // Adaptive friction: reset daily counters
            AdaptiveFrictionEngine.shared.resetDaily()

            // Patience systems: daily reset
            CountdownManager.shared.resetDaily()
            PatienceManager.shared.resetDaily()

            // Claude API: reset daily usage
            ClaudeAPIService.shared.resetDaily()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                AdaptiveFrictionEngine.shared.recordAppOpen()
                AdaptiveFrictionEngine.shared.syncFromExtensions()
            case .background:
                AdaptiveFrictionEngine.shared.recordAppClose()
            default:
                break
            }
        }
        // Active focus session — presented over everything
        .fullScreenCover(isPresented: $appState.isShowingFocusTimer) {
            FocusTimerView()
                .environment(appState)
                .environment(sessionManager)
                .environment(gamificationManager)
                .modelContainer(for: [FocusSession.self, UserProfile.self])
        }
        // Post-session reflection
        .fullScreenCover(isPresented: $appState.isShowingReflection) {
            ReflectionView()
                .environment(appState)
                .environment(sessionManager)
                .environment(gamificationManager)
                .modelContainer(for: [FocusSession.self, UserProfile.self, Achievement.self])
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, FocusSession.self], inMemory: true)
}
