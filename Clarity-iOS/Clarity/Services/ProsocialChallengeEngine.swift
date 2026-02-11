import SwiftUI
import SwiftData
import Foundation

/// Generates prosocial challenges and orchestrates verification.
/// Selects contacts intelligently, issues challenges, deep-links to Messages/Phone,
/// and coordinates with CallVerificationService and CommunicationMonitorService.
@Observable
class ProsocialChallengeEngine {
    var currentChallenge: ProsocialChallenge?
    var verificationStatus: VerificationState = .idle
    var lastVerificationMessage: String?

    enum VerificationState {
        case idle
        case waitingForAction   // User tapped deep link, we're watching
        case verified           // Confirmed
        case failed             // "...no you didn't"
        case callAttempted      // Rang but no answer — counts
        case autoVerified       // 3+ connections today, free pass
    }

    private let callService = CallVerificationService.shared
    private let commService = CommunicationMonitorService.shared

    // MARK: - Challenge Generation

    /// Generate a prosocial challenge based on friction layer and available contacts.
    func generateChallenge(
        frictionLayer: Int,
        targetApp: String,
        importantContacts: [ImportantContact],
        recentLogs: [ConnectionLog],
        modelContext: ModelContext
    ) -> ProsocialChallenge {
        let contact = selectContact(from: importantContacts, recentLogs: recentLogs)
        let type = challengeTypeForLayer(frictionLayer)

        let challenge = ProsocialChallenge(
            type: type,
            contactName: contact?.contactName,
            contactIdentifier: contact?.contactIdentifier,
            contactPhone: contact?.contactPhone,
            targetApp: targetApp,
            frictionLayer: frictionLayer
        )

        modelContext.insert(challenge)
        currentChallenge = challenge
        verificationStatus = .idle

        return challenge
    }

    /// Select a contact intelligently:
    /// 1. Prefer contacts not contacted in 7+ days
    /// 2. Then any not contacted today
    /// 3. Then random
    private func selectContact(from contacts: [ImportantContact], recentLogs: [ConnectionLog]) -> ImportantContact? {
        guard !contacts.isEmpty else { return nil }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let todayStart = Calendar.current.startOfDay(for: Date())

        let recentIdentifiers = Set(
            recentLogs
                .filter { $0.timestamp > sevenDaysAgo }
                .compactMap { $0.contactIdentifier }
        )

        let todayIdentifiers = Set(
            recentLogs
                .filter { $0.timestamp > todayStart }
                .compactMap { $0.contactIdentifier }
        )

        // Priority 1: Not contacted in 7 days
        let lostTouch = contacts.filter { !recentIdentifiers.contains($0.contactIdentifier) }
        if let pick = lostTouch.randomElement() { return pick }

        // Priority 2: Not contacted today
        let notToday = contacts.filter { !todayIdentifiers.contains($0.contactIdentifier) }
        if let pick = notToday.randomElement() { return pick }

        // Priority 3: Random
        return contacts.randomElement()
    }

    /// Map friction layer to challenge type:
    /// Layers 1-2: text-based, Layers 3-5: call-based
    private func challengeTypeForLayer(_ layer: Int) -> String {
        switch layer {
        case 1, 2: return ["textSomeone", "replyToMessage"].randomElement()!
        case 3, 4, 5: return "callSomeone"
        default: return "textSomeone"
        }
    }

    // MARK: - Deep Linking

    /// Open Messages to a specific contact.
    func deepLinkToMessages(phone: String?) {
        let urlString = phone != nil ? "sms://\(phone!)" : "sms://"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }

        if let challenge = currentChallenge {
            commService.startTextVerification(challengeId: challenge.id)
            verificationStatus = .waitingForAction
        }
    }

    /// Open Phone to a specific contact.
    func deepLinkToPhone(phone: String?) {
        let urlString = phone != nil ? "tel://\(phone!)" : "tel://"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }

        if let challenge = currentChallenge {
            callService.watchForCall(challengeId: challenge.id) { [weak self] result in
                self?.handleCallResult(result)
            }
            verificationStatus = .waitingForAction
        }
    }

    // MARK: - Verification Handling

    /// Handle call verification result from CXCallObserver.
    private func handleCallResult(_ result: CallVerificationService.CallResult) {
        guard let challenge = currentChallenge else { return }

        switch result {
        case .completed(let duration):
            verificationStatus = .verified
            challenge.wasVerified = true
            challenge.verifiedAt = Date()
            challenge.verificationMethod = "callObserver"
            let xp = duration >= 300 ? ProsocialXP.longCall5min : ProsocialXP.callCompleted
            challenge.xpEarned = xp
            lastVerificationMessage = ProsocialResponses.verified.randomElement()

        case .attempted:
            verificationStatus = .callAttempted
            challenge.wasVerified = true // Attempting counts!
            challenge.verifiedAt = Date()
            challenge.verificationMethod = "callObserver"
            challenge.xpEarned = ProsocialXP.callAttempted
            lastVerificationMessage = ProsocialResponses.callAttempted.randomElement()

        case .tooShort:
            verificationStatus = .failed
            challenge.wasVerified = false
            lastVerificationMessage = ProsocialResponses.failedCall.randomElement()

        case .noCallDetected:
            verificationStatus = .failed
            challenge.wasVerified = false
            lastVerificationMessage = ProsocialResponses.failed.randomElement()
        }
    }

    /// Check text verification (polled from main app when returning from Messages).
    func checkTextVerification() {
        guard let challenge = currentChallenge else { return }

        if commService.isVerified() {
            verificationStatus = .verified
            challenge.wasVerified = true
            challenge.verifiedAt = Date()
            challenge.verificationMethod = "communicationCategory"
            challenge.xpEarned = ProsocialXP.textSent
            lastVerificationMessage = ProsocialResponses.verified.randomElement()
            commService.stopVerification()
        }
    }

    /// Check if user has earned auto-verification (3+ connections today).
    func shouldAutoVerify(todayLogs: [ConnectionLog]) -> Bool {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayConnections = todayLogs.filter { $0.timestamp > todayStart && $0.type != "callAttempted" }
        return todayConnections.count >= ProsocialLimits.autoVerifyThreshold
    }

    /// Skip the current challenge.
    func skipChallenge() {
        currentChallenge?.userSkipped = true
        lastVerificationMessage = ProsocialResponses.skipped.randomElement()
        verificationStatus = .idle
        commService.stopVerification()
    }

    /// Reset state for a new challenge.
    func reset() {
        currentChallenge = nil
        verificationStatus = .idle
        lastVerificationMessage = nil
        commService.stopVerification()
    }
}
