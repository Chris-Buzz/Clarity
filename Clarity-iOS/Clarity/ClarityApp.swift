import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct ClarityApp: App {

    init() {
        DataCleanupService.shared.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            // Core models
            UserProfile.self,
            FocusSession.self,
            MoodEntry.self,
            DailySnapshot.self,
            ImplementationIntention.self,
            SubstitutionRecord.self,
            Achievement.self,
            // v2 prosocial + WiFi models
            ProsocialChallenge.self,
            ConnectionLog.self,
            ImportantContact.self,
            WiFiGateConfig.self,
        ])
    }
}
