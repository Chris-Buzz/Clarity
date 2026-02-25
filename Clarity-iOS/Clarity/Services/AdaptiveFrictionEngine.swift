import Foundation
import Observation

// MARK: - Friction Intensity

/// Four escalation levels that control how aggressively friction thresholds compress.
/// Think of it like a threat level: normal operations → elevated awareness → high alert → extreme lockdown.
enum FrictionIntensity: Int, CaseIterable {
    case normal = 0     // 1.0x multiplier — default behavior
    case elevated = 1   // 0.75x — noticeable pickup frequency or first bypass
    case high = 2       // 0.5x — doomscroll pattern detected or repeated bypasses
    case extreme = 3    // 0.25x — sustained doomscroll + heavy bypasses

    var multiplier: Double {
        switch self {
        case .normal:   return 1.0
        case .elevated: return 0.75
        case .high:     return 0.5
        case .extreme:  return 0.25
        }
    }

    var label: String {
        switch self {
        case .normal:   return "Normal"
        case .elevated: return "Elevated"
        case .high:     return "High"
        case .extreme:  return "Extreme"
        }
    }

    var taunt: String {
        switch self {
        case .normal:   return "Friction at baseline"
        case .elevated: return "We noticed. Thresholds tightening."
        case .high:     return "Pattern detected. Friction doubled."
        case .extreme:  return "Maximum friction. Quit while you're behind."
        }
    }
}

// MARK: - Pickup Record

/// A single app-open event with timestamp and duration.
/// Stored as a lightweight Codable struct for rolling-window analysis.
struct PickupRecord: Codable {
    let timestamp: Date
    let durationSeconds: Int  // 0 if still active or unknown
}

// MARK: - Adaptive Friction Engine

/// Tracks doomscroll behavior patterns and friction bypass history,
/// dynamically adjusting friction thresholds to match the user's
/// current resistance level.
///
/// Two signals feed into a single FrictionIntensity output:
/// 1. **Pickup frequency** — rapid app opens in a rolling 1-hour window
/// 2. **Bypass count** — daily count of "I Choose to Continue" taps on shields
///
/// All state persists in App Group UserDefaults so extensions
/// (ShieldAction, ShieldConfiguration) can read/write bypass counts.
@Observable
@MainActor
class AdaptiveFrictionEngine {
    static let shared = AdaptiveFrictionEngine()

    private let sharedDefaults = UserDefaults(suiteName: "group.com.clarity-focus")

    // MARK: - Observable State

    /// Current friction intensity level based on combined signals
    var currentIntensity: FrictionIntensity = .normal

    /// Number of friction bypasses today (user tapped "I Choose to Continue")
    var dailyBypassCount: Int = 0

    /// Number of app pickups in the last rolling hour
    var recentPickupCount: Int = 0

    /// Whether doomscroll mode is currently detected
    var isDoomscrollDetected: Bool = false

    /// The computed friction multiplier (1.0 = normal, 0.25 = extreme)
    var frictionMultiplier: Double = 1.0

    /// Emergency unlock wait minutes (escalates with bypasses)
    var currentEmergencyWaitMinutes: Int = 5

    // MARK: - Internal State

    /// Rolling window of recent pickups (last 60 minutes)
    private var recentPickups: [PickupRecord] = []

    /// Timestamp of last app open (to compute session duration)
    private var lastAppOpenTime: Date?

    // MARK: - Thresholds

    /// Rolling window duration for pickup analysis (1 hour)
    private static let pickupWindowSeconds: TimeInterval = 3600

    /// Minimum pickups in the window to trigger elevated
    private static let elevatedPickupThreshold = 4

    /// Minimum pickups for high intensity
    private static let highPickupThreshold = 6

    /// Minimum pickups for extreme intensity
    private static let extremePickupThreshold = 8

    /// Maximum duration (seconds) for a pickup to count as "short" —
    /// a doomscroll indicator: open app, scroll briefly, leave
    private static let shortSessionThreshold: TimeInterval = 60

    /// Percentage of short sessions that triggers doomscroll detection
    private static let doomscrollShortRatio = 0.6

    /// Base emergency wait minutes
    private static let baseEmergencyWait = 5

    /// Emergency wait escalation schedule indexed by bypass count
    private static let emergencyWaitSchedule = [5, 10, 20, 20]

    // MARK: - App Group Keys

    private enum Keys {
        static let dailyBypassCount = "adaptiveFriction.dailyBypassCount"
        static let pickupRecords = "adaptiveFriction.pickupRecords"
        static let frictionMultiplier = "adaptiveFriction.frictionMultiplier"
        static let intensityRaw = "adaptiveFriction.intensityRaw"
        static let isDoomscroll = "adaptiveFriction.isDoomscroll"
        static let resetDate = "adaptiveFriction.resetDate"
        static let emergencyWaitMinutes = "adaptiveFriction.emergencyWaitMinutes"
    }

    // MARK: - Init

    private init() {
        restoreState()
    }

    // MARK: - Public API

    /// Call when the app comes to the foreground (records a pickup).
    func recordAppOpen() {
        let now = Date()

        // Close previous session if exists
        if let openTime = lastAppOpenTime, !recentPickups.isEmpty {
            let duration = Int(now.timeIntervalSince(openTime))
            let last = recentPickups[recentPickups.count - 1]
            recentPickups[recentPickups.count - 1] = PickupRecord(
                timestamp: last.timestamp,
                durationSeconds: duration
            )
        }

        // Record new pickup
        let pickup = PickupRecord(timestamp: now, durationSeconds: 0)
        recentPickups.append(pickup)
        lastAppOpenTime = now

        // Prune pickups outside the rolling window
        prunePickups()

        // Recalculate intensity
        recalculate()

        // Persist
        persistState()
    }

    /// Call when the app goes to the background (closes current session).
    func recordAppClose() {
        guard let openTime = lastAppOpenTime else { return }
        let duration = Int(Date().timeIntervalSince(openTime))

        if !recentPickups.isEmpty {
            let last = recentPickups[recentPickups.count - 1]
            recentPickups[recentPickups.count - 1] = PickupRecord(
                timestamp: last.timestamp,
                durationSeconds: duration
            )
        }

        lastAppOpenTime = nil
        recalculate()
        persistState()
    }

    /// Called when user taps "I Choose to Continue" on a friction shield.
    /// The ShieldAction extension increments the counter directly in UserDefaults;
    /// the main app calls this method for in-app friction overlays.
    func recordBypass() {
        dailyBypassCount += 1
        recalculate()
        persistState()
    }

    /// Sync bypass count from App Group (extensions may have incremented it).
    /// Call on each foreground transition.
    func syncFromExtensions() {
        let extCount = sharedDefaults?.integer(forKey: Keys.dailyBypassCount) ?? 0
        if extCount > dailyBypassCount {
            dailyBypassCount = extCount
            recalculate()
        }
    }

    /// Reset all daily counters. Call on app launch (idempotent per day).
    func resetDaily() {
        let today = formatDate(Date())
        let lastReset = sharedDefaults?.string(forKey: Keys.resetDate) ?? ""

        guard today != lastReset else { return }

        dailyBypassCount = 0
        recentPickups.removeAll()
        currentIntensity = .normal
        frictionMultiplier = 1.0
        isDoomscrollDetected = false
        currentEmergencyWaitMinutes = Self.baseEmergencyWait

        sharedDefaults?.set(0, forKey: Keys.dailyBypassCount)
        sharedDefaults?.set(1.0, forKey: Keys.frictionMultiplier)
        sharedDefaults?.set(FrictionIntensity.normal.rawValue, forKey: Keys.intensityRaw)
        sharedDefaults?.set(false, forKey: Keys.isDoomscroll)
        sharedDefaults?.set(Self.baseEmergencyWait, forKey: Keys.emergencyWaitMinutes)
        sharedDefaults?.set(today, forKey: Keys.resetDate)
        sharedDefaults?.removeObject(forKey: Keys.pickupRecords)
    }

    // MARK: - Computation

    /// Core recalculation: combines pickup frequency, doomscroll detection,
    /// and bypass count into a single FrictionIntensity.
    private func recalculate() {
        prunePickups()

        recentPickupCount = recentPickups.count

        // --- Doomscroll detection ---
        // If 60%+ of recent pickups were under 60 seconds, it's doomscroll behavior
        let shortSessions = recentPickups.filter {
            $0.durationSeconds > 0 && $0.durationSeconds <= Int(Self.shortSessionThreshold)
        }
        let totalWithDuration = recentPickups.filter { $0.durationSeconds > 0 }
        let shortRatio = totalWithDuration.isEmpty ? 0.0 :
            Double(shortSessions.count) / Double(totalWithDuration.count)
        isDoomscrollDetected = recentPickupCount >= Self.elevatedPickupThreshold
            && shortRatio >= Self.doomscrollShortRatio

        // --- Intensity from pickups ---
        let pickupIntensity: FrictionIntensity
        if recentPickupCount >= Self.extremePickupThreshold {
            pickupIntensity = .extreme
        } else if recentPickupCount >= Self.highPickupThreshold {
            pickupIntensity = .high
        } else if recentPickupCount >= Self.elevatedPickupThreshold {
            pickupIntensity = .elevated
        } else {
            pickupIntensity = .normal
        }

        // --- Intensity from bypasses ---
        let bypassIntensity: FrictionIntensity
        if dailyBypassCount >= 3 {
            bypassIntensity = .extreme
        } else if dailyBypassCount >= 2 {
            bypassIntensity = .high
        } else if dailyBypassCount >= 1 {
            bypassIntensity = .elevated
        } else {
            bypassIntensity = .normal
        }

        // --- Doomscroll boost: adds one intensity level ---
        var doomscrollBoost = 0
        if isDoomscrollDetected { doomscrollBoost = 1 }

        // --- Take the maximum of all signals ---
        let rawMax = Swift.max(pickupIntensity.rawValue, bypassIntensity.rawValue) + doomscrollBoost
        let clampedRaw = Swift.min(rawMax, FrictionIntensity.extreme.rawValue)
        currentIntensity = FrictionIntensity(rawValue: clampedRaw) ?? .extreme

        // --- Compute multiplier ---
        frictionMultiplier = currentIntensity.multiplier

        // --- Emergency wait escalation ---
        let scheduleIndex = Swift.min(dailyBypassCount, Self.emergencyWaitSchedule.count - 1)
        currentEmergencyWaitMinutes = Self.emergencyWaitSchedule[scheduleIndex]
    }

    // MARK: - Pickup Window Management

    private func prunePickups() {
        let cutoff = Date().addingTimeInterval(-Self.pickupWindowSeconds)
        recentPickups.removeAll { $0.timestamp < cutoff }
    }

    // MARK: - Persistence

    private func persistState() {
        sharedDefaults?.set(dailyBypassCount, forKey: Keys.dailyBypassCount)
        sharedDefaults?.set(frictionMultiplier, forKey: Keys.frictionMultiplier)
        sharedDefaults?.set(currentIntensity.rawValue, forKey: Keys.intensityRaw)
        sharedDefaults?.set(isDoomscrollDetected, forKey: Keys.isDoomscroll)
        sharedDefaults?.set(currentEmergencyWaitMinutes, forKey: Keys.emergencyWaitMinutes)

        if let data = try? JSONEncoder().encode(recentPickups) {
            sharedDefaults?.set(data, forKey: Keys.pickupRecords)
        }
    }

    private func restoreState() {
        dailyBypassCount = sharedDefaults?.integer(forKey: Keys.dailyBypassCount) ?? 0

        let storedMultiplier = sharedDefaults?.double(forKey: Keys.frictionMultiplier) ?? 1.0
        frictionMultiplier = storedMultiplier > 0 ? storedMultiplier : 1.0

        isDoomscrollDetected = sharedDefaults?.bool(forKey: Keys.isDoomscroll) ?? false

        let storedWait = sharedDefaults?.integer(forKey: Keys.emergencyWaitMinutes) ?? Self.baseEmergencyWait
        currentEmergencyWaitMinutes = storedWait > 0 ? storedWait : Self.baseEmergencyWait

        let rawIntensity = sharedDefaults?.integer(forKey: Keys.intensityRaw) ?? 0
        currentIntensity = FrictionIntensity(rawValue: rawIntensity) ?? .normal

        // Restore pickup records
        if let data = sharedDefaults?.data(forKey: Keys.pickupRecords),
           let records = try? JSONDecoder().decode([PickupRecord].self, from: data) {
            recentPickups = records
            prunePickups()
        }
    }

    // MARK: - Helpers

    private nonisolated static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func formatDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
}
