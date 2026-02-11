import UserNotifications
import Foundation

/// JITAI (Just-In-Time Adaptive Intervention) smart notification service.
/// Frequency-capped to 3 notifications per day to avoid notification fatigue.
class NotificationService {
    static let shared = NotificationService()

    private let dailyCapKey = "notificationDailyCount"
    private let dailyCapDateKey = "notificationDailyCountDate"
    private let maxDailyNotifications = 3

    private init() {}

    // MARK: - Permission

    /// Request notification permission. Returns true if granted.
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Smart Reminders

    /// Schedule a local notification at the specified time, respecting the daily cap.
    func scheduleSmartReminder(title: String, body: String, at dateComponents: DateComponents) {
        guard shouldSendNotification() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if error == nil {
                self?.incrementDailyCount()
            }
        }
    }

    /// Schedule a pre-emptive friction reminder before the user's habitual app-open time.
    /// Fires 5 minutes before the usual time.
    func scheduleFrictionReminder(appName: String, usualTime: Date) {
        guard shouldSendNotification() else { return }

        // Fire 5 minutes before the habitual open time
        guard let reminderTime = Calendar.current.date(byAdding: .minute, value: -5, to: usualTime)
        else { return }

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

        let content = UNMutableNotificationContent()
        content.title = "Heads up"
        content.body = "It's almost time you usually open \(appName). Want to do something else?"
        content.sound = .default
        content.categoryIdentifier = "FRICTION_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "friction_\(appName)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if error == nil {
                self?.incrementDailyCount()
            }
        }
    }

    /// Remove all pending notifications.
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Frequency Cap

    /// Check whether we can still send notifications today (max 3).
    func shouldSendNotification() -> Bool {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())

        // Reset counter if the stored date is not today
        if let storedDate = defaults.object(forKey: dailyCapDateKey) as? Date,
           Calendar.current.isDate(storedDate, inSameDayAs: today)
        {
            return defaults.integer(forKey: dailyCapKey) < maxDailyNotifications
        } else {
            // New day — reset
            defaults.set(0, forKey: dailyCapKey)
            defaults.set(today, forKey: dailyCapDateKey)
            return true
        }
    }

    private func incrementDailyCount() {
        let defaults = UserDefaults.standard
        let current = defaults.integer(forKey: dailyCapKey)
        defaults.set(current + 1, forKey: dailyCapKey)
    }
}
