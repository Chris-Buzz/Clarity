import Foundation
import Observation
import SwiftUI
import SwiftData
import FamilyControls

// MARK: - Session Status

enum SessionStatus: String {
    case idle
    case active
    case paused
    case completed
    case interrupted
}

// MARK: - Session Manager

/// Manages the full lifecycle of a focus session: start, pause, resume, complete.
/// Runs a one-second timer and calculates XP on completion.
@Observable
class SessionManager {
    var currentSession: FocusSession?
    var status: SessionStatus = .idle
    var timeRemaining: TimeInterval = 0
    var isPaused: Bool = false

    private var timer: Timer?
    private var pauseCount: Int = 0

    // MARK: - Session Lifecycle

    /// Starts a new focus session with the given task and duration.
    /// If focusSessionBlockingEnabled, also blocks shielded apps via FocusSessionBlockingService.
    func startSession(task: String, duration: Int, context: ModelContext, blockApps: FamilyActivitySelection? = nil) {
        let session = FocusSession(task: task, plannedDuration: duration)
        context.insert(session)
        try? context.save()

        currentSession = session
        timeRemaining = TimeInterval(duration * 60)
        isPaused = false
        pauseCount = 0
        status = .active

        // Activate focus session blocking if apps were provided
        if let apps = blockApps {
            FocusSessionBlockingService.shared.activateBlock(apps: apps)
        }

        startTimer()
    }

    func pauseSession() {
        guard status == .active else { return }
        timer?.invalidate()
        timer = nil
        isPaused = true
        pauseCount += 1
        status = .paused
    }

    func resumeSession() {
        guard status == .paused else { return }
        isPaused = false
        status = .active
        startTimer()
    }

    /// Ends the session, calculates XP, and persists the result.
    /// Also removes any focus session app blocks.
    func endSession(completed: Bool, context: ModelContext) {
        timer?.invalidate()
        timer = nil

        // Always remove focus session blocks when session ends
        FocusSessionBlockingService.shared.deactivateBlock()

        guard let session = currentSession else { return }

        session.endTime = Date()
        let elapsed = session.endTime!.timeIntervalSince(session.startTime)
        session.actualDuration = Int(elapsed / 60)
        session.wasCompleted = completed
        status = completed ? .completed : .interrupted

        if completed {
            session.xpEarned = calculateXP(session: session, streakDays: 0)
            // Haptic feedback on successful completion
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        try? context.save()
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Timer fires on main thread by default via RunLoop.main
            self?.tick()
        }
    }

    private func tick() {
        guard status == .active else { return }

        timeRemaining -= 1

        if timeRemaining <= 0 {
            timeRemaining = 0
            timer?.invalidate()
            timer = nil
            status = .completed

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    // MARK: - XP Calculation

    /// XP formula: 10/min + 25/urge resisted + 50 completion + 100 perfect + streak multiplier.
    /// Perfect = no tab leaves and no pauses.
    func calculateXP(session: FocusSession, streakDays: Int) -> Int {
        let minuteXP = session.actualDuration * GamificationManager.XP.perMinute
        let urgeXP = session.urgesResisted * GamificationManager.XP.urgeResisted
        let completionXP = session.wasCompleted ? GamificationManager.XP.sessionCompletion : 0

        let isPerfect = session.tabLeavesCount == 0 && pauseCount == 0
        let perfectXP = isPerfect ? GamificationManager.XP.perfectSession : 0

        let base = Double(minuteXP + urgeXP + completionXP + perfectXP)
        let multiplier = 1.0 + GamificationManager.calculateStreakMultiplier(streak: streakDays)

        return Int(base * multiplier)
    }
}
