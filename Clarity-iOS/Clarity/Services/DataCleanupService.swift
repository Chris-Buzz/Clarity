import BackgroundTasks
import SwiftData
import Foundation

class DataCleanupService {
    static let taskIdentifier = "com.clarity-focus.dataCleanup"

    /// Register the background task in ClarityApp.init
    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            handleCleanup(task: task as! BGAppRefreshTask)
        }
    }

    /// Schedule the next cleanup (daily)
    static func scheduleCleanup() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
        try? BGTaskScheduler.shared.submit(request)
    }

    /// Perform the cleanup
    static func handleCleanup(task: BGAppRefreshTask) {
        let container = try! ModelContainer(for:
            FocusSession.self, MoodEntry.self, ProsocialChallenge.self,
            ConnectionLog.self, DailySnapshot.self
        )
        let context = ModelContext(container)

        performCleanup(context: context)

        scheduleCleanup()
        task.setTaskCompleted(success: true)
    }

    /// Also run cleanup on app launch (in case background task was missed)
    static func cleanupOnLaunch(context: ModelContext) {
        performCleanup(context: context)
    }

    private static func performCleanup(context: ModelContext) {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -DataRetention.sessionDays, to: Date())!
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -DataRetention.snapshotDays, to: Date())!

        // 30-day cleanup
        try? context.delete(model: FocusSession.self, where: #Predicate { $0.startTime < thirtyDaysAgo })
        try? context.delete(model: MoodEntry.self, where: #Predicate { $0.timestamp < thirtyDaysAgo })
        try? context.delete(model: ProsocialChallenge.self, where: #Predicate { $0.issuedAt < thirtyDaysAgo })
        try? context.delete(model: ConnectionLog.self, where: #Predicate { $0.timestamp < thirtyDaysAgo })

        // 90-day cleanup for snapshots
        try? context.delete(model: DailySnapshot.self, where: #Predicate { $0.date < ninetyDaysAgo })

        try? context.save()
    }
}
