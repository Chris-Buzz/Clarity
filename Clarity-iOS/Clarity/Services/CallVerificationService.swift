import CallKit
import Foundation

/// Monitors outgoing calls to verify prosocial challenges.
/// CXCallObserver tells us: call started, call connected, call ended, and duration.
/// It does NOT tell us who was called — we infer from timing (deep-linked within 2 min).
class CallVerificationService: NSObject, CXCallObserverDelegate {
    static let shared = CallVerificationService()

    private let callObserver = CXCallObserver()
    private var pendingChallengeId: UUID?
    private var callStartTime: Date?
    private var callConnected = false
    private var onResult: ((CallResult) -> Void)?

    enum CallResult {
        case completed(duration: TimeInterval)  // Someone picked up, talked
        case attempted                           // Rang but no answer / voicemail
        case tooShort                           // Connected but < 10 seconds
        case noCallDetected                     // Nothing happened
    }

    override init() {
        super.init()
        callObserver.setDelegate(self, queue: .main)
    }

    /// Start watching for a call after issuing a prosocial challenge.
    /// Times out after 2 minutes if no call detected.
    func watchForCall(challengeId: UUID, completion: @escaping (CallResult) -> Void) {
        pendingChallengeId = challengeId
        callStartTime = nil
        callConnected = false
        onResult = completion

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(ProsocialLimits.callWatchTimeout)) { [weak self] in
            guard let self, self.pendingChallengeId == challengeId else { return }
            self.onResult?(.noCallDetected)
            self.reset()
        }
    }

    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        guard pendingChallengeId != nil else { return }

        // Outgoing call started dialing
        if call.isOutgoing && !call.hasConnected && !call.hasEnded {
            callStartTime = Date()
        }

        // Call connected (someone picked up)
        if call.hasConnected && !call.hasEnded {
            callConnected = true
        }

        // Call ended
        if call.hasEnded {
            guard let start = callStartTime else { return }
            let duration = Date().timeIntervalSince(start)

            if callConnected && duration > Double(ProsocialLimits.callMinSeconds) {
                onResult?(.completed(duration: duration))
            } else if callConnected && duration <= Double(ProsocialLimits.callMinSeconds) {
                onResult?(.tooShort)
            } else if !callConnected {
                onResult?(.attempted) // Rang but no answer — still counts
            }

            reset()
        }
    }

    private func reset() {
        pendingChallengeId = nil
        callStartTime = nil
        callConnected = false
        onResult = nil
    }
}
