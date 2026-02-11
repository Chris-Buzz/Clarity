import DeviceActivity
import ManagedSettings
import Foundation

/// Monitors Communication category usage (Messages, Phone, FaceTime) to verify
/// that the user actually texted someone after a prosocial challenge.
///
/// Flow:
/// 1. Challenge issued -> startTextVerification() sets up a DeviceActivityEvent
/// 2. User opens Messages -> spends 30+ seconds composing
/// 3. DeviceActivityMonitor extension fires eventDidReachThreshold
/// 4. Extension writes "verified" to App Group UserDefaults
/// 5. Main app reads verification status
class CommunicationMonitorService {
    static let shared = CommunicationMonitorService()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.clarity-focus")

    /// Start monitoring Communication category for a 30-second threshold.
    /// Called when a "text someone" prosocial challenge is issued.
    func startTextVerification(challengeId: UUID) {
        let center = DeviceActivityCenter()

        // Store pending challenge ID for the extension to read
        sharedDefaults?.set(challengeId.uuidString, forKey: "pendingProsocialChallengeId")
        sharedDefaults?.set(false, forKey: "prosocialChallengeVerified")

        let now = Date()
        let timeout = Calendar.current.date(byAdding: .minute, value: 15, to: now)!

        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: timeout),
            repeats: false
        )

        // Monitor Communication category (Phone, Messages, FaceTime)
        // Threshold: 30 seconds of usage
        let event = DeviceActivityEvent(
            categories: [.communication()],
            threshold: DateComponents(second: ProsocialLimits.textMinSeconds)
        )

        let activityName = DeviceActivityName("prosocial_text_verification")
        let eventName = DeviceActivityEvent.Name("text_threshold_reached")

        // Stop any existing monitoring first
        center.stopMonitoring([activityName])

        do {
            try center.startMonitoring(activityName, during: schedule, events: [eventName: event])
        } catch {
            print("Failed to start communication monitoring: \(error)")
        }
    }

    /// Check if the DeviceActivity extension marked the challenge as verified.
    func isVerified() -> Bool {
        sharedDefaults?.bool(forKey: "prosocialChallengeVerified") ?? false
    }

    /// Stop monitoring and clean up.
    func stopVerification() {
        let center = DeviceActivityCenter()
        center.stopMonitoring([DeviceActivityName("prosocial_text_verification")])
        sharedDefaults?.removeObject(forKey: "pendingProsocialChallengeId")
    }
}
