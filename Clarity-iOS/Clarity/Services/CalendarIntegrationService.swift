import EventKit
import Foundation
import UserNotifications

/// Premium calendar integration service.
/// Finds breathing room gaps and schedules grounding notifications before meetings.
@Observable
@MainActor
final class CalendarIntegrationService {
    static let shared = CalendarIntegrationService()

    private let eventStore = EKEventStore()
    var isAuthorized = false

    private init() {
        checkAuthorization()
    }

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    private func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = status == .fullAccess
    }

    // MARK: - Fetch Today's Events

    func fetchTodaysEvents() -> [EKEvent] {
        guard isAuthorized else { return [] }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )
        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Find Breathing Room Gaps

    /// Returns unscheduled time blocks of at least `minMinutes` duration.
    func findBreathingRoomGaps(minMinutes: Int = 30) -> [DateInterval] {
        let events = fetchTodaysEvents()
        guard !events.isEmpty else { return [] }

        let calendar = Calendar.current
        var gaps: [DateInterval] = []
        let now = Date()

        // Only look at future events
        let futureEvents = events.filter { $0.endDate > now }
        guard !futureEvents.isEmpty else { return [] }

        // Check gap from now to first event
        if let first = futureEvents.first, first.startDate > now {
            let gap = DateInterval(start: now, end: first.startDate)
            if gap.duration >= Double(minMinutes) * 60 {
                gaps.append(gap)
            }
        }

        // Check gaps between events
        for i in 0..<(futureEvents.count - 1) {
            let currentEnd = futureEvents[i].endDate
            let nextStart = futureEvents[i + 1].startDate
            if let currentEnd, let nextStart, nextStart > currentEnd {
                let gap = DateInterval(start: currentEnd, end: nextStart)
                if gap.duration >= Double(minMinutes) * 60 {
                    gaps.append(gap)
                }
            }
        }

        // Check gap after last event until end of day
        if let last = futureEvents.last,
           let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
            let gap = DateInterval(start: last.endDate, end: endOfDay)
            if gap.duration >= Double(minMinutes) * 60 {
                gaps.append(gap)
            }
        }

        return gaps
    }

    // MARK: - Breathing Room Notification

    /// Schedules a notification for an empty time block.
    func scheduleBreathingRoomNotification(for gap: DateInterval) {
        guard SubscriptionService.shared.isSubscribed else { return }

        let content = UNMutableNotificationContent()
        content.title = "Breathing Room"
        content.body = "You have empty time. Protect it."
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: gap.start
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "breathingRoom-\(gap.start.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Pre-Event Grounding

    /// Schedules a grounding notification 2 minutes before an event.
    func schedulePreEventGrounding(for event: EKEvent) {
        guard SubscriptionService.shared.isSubscribed else { return }

        let content = UNMutableNotificationContent()
        content.title = "Meeting in 2 minutes"
        content.body = "Take a breath."
        content.sound = .default

        guard let fireDate = Calendar.current.date(byAdding: .minute, value: -2, to: event.startDate) else { return }
        // Only schedule for future events
        guard fireDate > Date() else { return }

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "grounding-\(event.eventIdentifier ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
