# Clarity v2: Full Native Swift Implementation

## Read First
- `Clarity-iOS/CLAUDE.md` — Full architecture overview, design system, 6 targets, coding patterns
- `Clarity-iOS/Clarity/Utilities/` — ClarityColors, ClarityFonts, ClaritySpacing (design system is already built)
- `Clarity-iOS/Clarity/Views/` — All existing views (dashboard, onboarding, friction, settings, focus timer)
- `Clarity-iOS/Clarity/Services/ScreenTimeService.swift` — Existing Screen Time integration
- `Clarity-iOS/Clarity/ViewModels/ProgressiveFrictionManager.swift` — Existing friction escalation logic

The Swift codebase already has the full UI matching the React Native prototype. Same colors (#030303 bg, #f97316 orange primary), same fonts (Playfair Display/Outfit/Space Mono), same 8pt grid, same dark-only theme, same custom tab bar, same friction overlay system.

## What We're Adding

### 1. Prosocial Friction with Verification
Friction challenges redirect users toward real phone use — texting, calling specific contacts. Clarity VERIFIES the action happened using CXCallObserver and DeviceActivity Communication category monitoring. If the user lies, Clarity calls them out playfully: "...no you didn't 😏"

### 2. WiFi-Gated Unlocking
Doomscroll apps are shielded everywhere EXCEPT on the user's home WiFi network(s). Uses NEHotspotNetwork for SSID detection.

### 3. Enhanced Focus Sessions with iOS Focus Mode
Focus sessions activate iOS Focus mode (silence notifications), show Live Activity on Dynamic Island, and shield ALL apps except whitelisted ones.

### 4. 30-Day Auto-Cleanup
All session/challenge/connection data auto-deletes after 30 days. DailySnapshots kept 90 days.

### 5. Subscription via StoreKit 2
In-app subscription ($4.99/month or $39.99/year) using StoreKit 2. No custom server for payments — Apple handles everything.

---

## TASK 1: New SwiftData Models

### 1a. Create `Models/ProsocialChallenge.swift`

```swift
import Foundation
import SwiftData

@Model
class ProsocialChallenge {
    var id: UUID = UUID()
    var issuedAt: Date = Date()
    var type: String = "textSomeone" // textSomeone, callSomeone, voiceMemo, facetime, replyToMessage
    var suggestedContactName: String?
    var suggestedContactIdentifier: String? // CNContact.identifier
    var suggestedContactPhone: String?
    var targetApp: String = "" // Which doomscroll app triggered this
    var wasVerified: Bool = false
    var verifiedAt: Date?
    var verificationMethod: String? // callObserver, communicationCategory, timerBased, autoVerified
    var userSkipped: Bool = false
    var frictionLayer: Int = 1
    var xpEarned: Int = 0
    var failureMessage: String? // The sassy response shown if verification failed
    
    init(type: String, contactName: String?, contactIdentifier: String?, contactPhone: String?, targetApp: String, frictionLayer: Int) {
        self.type = type
        self.suggestedContactName = contactName
        self.suggestedContactIdentifier = contactIdentifier
        self.suggestedContactPhone = contactPhone
        self.targetApp = targetApp
        self.frictionLayer = frictionLayer
    }
}
```

### 1b. Create `Models/ConnectionLog.swift`

```swift
import Foundation
import SwiftData

@Model
class ConnectionLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var type: String = "textSent" // callCompleted, callAttempted, textSent, facetimeCompleted, voiceMemoSent
    var contactName: String?
    var contactIdentifier: String?
    var durationSeconds: Int = 0
    var challengeId: UUID? // Link to triggering ProsocialChallenge
    var xpEarned: Int = 0
    
    init(type: String, contactName: String?, durationSeconds: Int, challengeId: UUID?, xpEarned: Int) {
        self.type = type
        self.contactName = contactName
        self.durationSeconds = durationSeconds
        self.challengeId = challengeId
        self.xpEarned = xpEarned
    }
}
```

### 1c. Create `Models/ImportantContact.swift`

```swift
import Foundation
import SwiftData

@Model
class ImportantContact {
    var id: UUID = UUID()
    var contactIdentifier: String = "" // CNContact.identifier
    var contactName: String = ""
    var contactPhone: String?
    var addedAt: Date = Date()
    var lastSuggestedAt: Date?
    var timesConnected: Int = 0
    var lastConnectedAt: Date?
    
    init(contactIdentifier: String, contactName: String, contactPhone: String?) {
        self.contactIdentifier = contactIdentifier
        self.contactName = contactName
        self.contactPhone = contactPhone
    }
}
```

### 1d. Create `Models/WiFiGateConfig.swift`

```swift
import Foundation
import SwiftData

@Model
class WiFiGateConfig {
    var id: UUID = UUID()
    var isEnabled: Bool = true
    var homeNetworks: [String] = [] // SSIDs, max 3
    var strictMode: Bool = false // false = show override after 30s, true = no override
    
    init() {}
}
```

### 1e. Update `ClarityApp.swift`

Add all new models to the SwiftData modelContainer:
```swift
.modelContainer(for: [
    UserProfile.self,
    FocusSession.self,
    MoodEntry.self,
    DailySnapshot.self,
    ImplementationIntention.self,
    SubstitutionRecord.self,
    Achievement.self,
    // v2 models:
    ProsocialChallenge.self,
    ConnectionLog.self,
    ImportantContact.self,
    WiFiGateConfig.self,
])
```

---

## TASK 2: Verification Services

### 2a. Create `Services/CallVerificationService.swift`

Uses CXCallObserver to verify outgoing calls happened. This is the core of "...no you didn't."

```swift
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
        
        // Timeout after 2 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) { [weak self] in
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
            
            if callConnected && duration > 10 {
                onResult?(.completed(duration: duration))
            } else if callConnected && duration <= 10 {
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
```

### 2b. Create `Services/CommunicationMonitorService.swift`

Uses DeviceActivity to verify text messaging by monitoring the Communication app category.

```swift
import DeviceActivity
import ManagedSettings
import Foundation

/// Monitors Communication category usage (Messages, Phone, FaceTime) to verify
/// that the user actually texted someone after a prosocial challenge.
///
/// Flow:
/// 1. Challenge issued → startCommunicationVerification() sets up a DeviceActivityEvent
/// 2. User opens Messages → spends 30+ seconds composing
/// 3. DeviceActivityMonitor extension fires eventDidReachThreshold
/// 4. Extension writes "verified" to App Group UserDefaults
/// 5. Main app reads verification status
class CommunicationMonitorService {
    static let shared = CommunicationMonitorService()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.clarity.focus")
    
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
            threshold: DateComponents(second: 30)
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
```

### 2c. Update `Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift`

Add prosocial verification handling to the existing extension:

```swift
// Add this to the existing DeviceActivityMonitorExtension class:

override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    
    let sharedDefaults = UserDefaults(suiteName: "group.com.clarity.focus")
    
    // Handle prosocial text verification
    if event == DeviceActivityEvent.Name("text_threshold_reached") 
       && activity == DeviceActivityName("prosocial_text_verification") {
        // User spent 30+ seconds in Communication apps — verified!
        sharedDefaults?.set(true, forKey: "prosocialChallengeVerified")
        
        // Remove prosocial friction shield if active
        let store = ManagedSettingsStore(named: .init("prosocialFriction"))
        store.clearAllSettings()
    }
    
    // Keep existing threshold handling for progressive friction...
}
```

### 2d. Create `Services/WiFiGateService.swift`

Detects home WiFi network and manages WiFi-gated shields.

```swift
import NetworkExtension
import CoreLocation
import ManagedSettings
import Foundation

/// Manages WiFi-gated app shielding.
/// Apps are shielded by default everywhere. Shield removed only on home WiFi.
/// Uses a SEPARATE ManagedSettingsStore (.wifiGate) so WiFi shields don't
/// interfere with focus session shields or progressive friction shields.
class WiFiGateService: NSObject, CLLocationManagerDelegate {
    static let shared = WiFiGateService()
    
    private let locationManager = CLLocationManager()
    private let wifiStore = ManagedSettingsStore(named: .init("wifiGate"))
    private let sharedDefaults = UserDefaults(suiteName: "group.com.clarity.focus")
    private var monitorTimer: Timer?
    
    var currentSSID: String? {
        didSet {
            evaluateGate()
        }
    }
    
    var homeNetworks: [String] {
        get { sharedDefaults?.stringArray(forKey: "homeNetworkSSIDs") ?? [] }
        set { sharedDefaults?.set(newValue, forKey: "homeNetworkSSIDs") }
    }
    
    var isEnabled: Bool {
        get { sharedDefaults?.bool(forKey: "wifiGateEnabled") ?? true }
        set { 
            sharedDefaults?.set(newValue, forKey: "wifiGateEnabled")
            evaluateGate()
        }
    }
    
    var isOnHomeNetwork: Bool {
        guard let ssid = currentSSID else { return false }
        return homeNetworks.contains(ssid)
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    /// Start monitoring WiFi changes. Call after getting Location permission.
    func startMonitoring() {
        // Request location permission (required for WiFi SSID access)
        locationManager.requestWhenInUseAuthorization()
        
        // Check immediately
        fetchCurrentSSID()
        
        // Check every 30 seconds
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.fetchCurrentSSID()
        }
    }
    
    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }
    
    /// Fetch current WiFi network SSID.
    /// Requires: CoreLocation authorization + "Access WiFi Information" entitlement
    func fetchCurrentSSID() {
        NEHotspotNetwork.fetchCurrent { [weak self] network in
            DispatchQueue.main.async {
                self?.currentSSID = network?.ssid
            }
        }
    }
    
    /// Add a home network (max 3).
    func addHomeNetwork(_ ssid: String) -> Bool {
        var networks = homeNetworks
        guard networks.count < 3, !networks.contains(ssid) else { return false }
        networks.append(ssid)
        homeNetworks = networks
        evaluateGate()
        return true
    }
    
    /// Remove a home network.
    func removeHomeNetwork(_ ssid: String) {
        homeNetworks.removeAll { $0 == ssid }
        evaluateGate()
    }
    
    /// Core logic: shield apps when NOT on home WiFi, unshield when on home WiFi.
    private func evaluateGate() {
        guard isEnabled else {
            // WiFi gate disabled — remove all WiFi shields
            wifiStore.clearAllSettings()
            return
        }
        
        if isOnHomeNetwork {
            // On home WiFi — remove WiFi gate shields
            wifiStore.clearAllSettings()
        } else {
            // NOT on home WiFi — apply shields to doomscroll apps
            applyWiFiShields()
        }
    }
    
    /// Apply shields from the user's shielded app selection.
    private func applyWiFiShields() {
        // Read the saved FamilyActivitySelection from App Group
        guard let data = sharedDefaults?.data(forKey: "shieldedAppsSelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelectionData.self, from: data)
        else { return }
        
        wifiStore.shield.applications = selection.applicationTokens
        wifiStore.shield.applicationCategories = .specific(selection.categoryTokens)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse 
            || manager.authorizationStatus == .authorizedAlways {
            fetchCurrentSSID()
        }
    }
}
```

**Note:** `FamilyActivitySelectionData` is a Codable wrapper for FamilyActivitySelection tokens. Since FamilyActivitySelection itself isn't directly Codable, you'll need to store the application tokens and category tokens separately in App Group UserDefaults, similar to how `ScreenTimeService` already handles this with `shieldedAppsData` on UserProfile. Adapt the serialization approach to match the existing pattern.

### 2e. Create `Services/ProsocialChallengeEngine.swift`

Smart contact selection + challenge generation + verification orchestration.

```swift
import Contacts
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
        case verified           // Confirmed ✅
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
    /// 1. Prefer contacts from "Important People" not contacted in 7+ days
    /// 2. Then any important contact not contacted today
    /// 3. Then random important contact
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
    /// Layers 1-2: text-based challenges
    /// Layers 3-4: call-based challenges  
    /// Layer 5: long call challenge
    private func challengeTypeForLayer(_ layer: Int) -> String {
        switch layer {
        case 1, 2: return ["textSomeone", "replyToMessage"].randomElement()!
        case 3, 4: return "callSomeone"
        case 5: return "callSomeone" // Will require longer duration
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
        
        // Start communication verification
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
        
        // Start call verification
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
        // If not verified yet, keep waiting — the extension will fire when threshold reached
    }
    
    /// Check if user has earned auto-verification (3+ connections today).
    func shouldAutoVerify(todayLogs: [ConnectionLog]) -> Bool {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayConnections = todayLogs.filter { $0.timestamp > todayStart && $0.type != "callAttempted" }
        return todayConnections.count >= 3
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
```

---

## TASK 3: Constants / Personality Responses

### 3a. Create `Utilities/ProsocialConstants.swift`

```swift
import Foundation

// MARK: - XP Values

enum ProsocialXP {
    static let textSent = 15
    static let callCompleted = 25
    static let callAttempted = 10
    static let facetimeCompleted = 30
    static let longCall5min = 50
    static let autoVerifiedBonus = 5
}

// MARK: - Data Retention

enum DataRetention {
    static let sessionDays = 30
    static let challengeDays = 30
    static let connectionLogDays = 30
    static let snapshotDays = 90
}

// MARK: - Limits

enum ProsocialLimits {
    static let maxImportantContacts = 5
    static let maxTrustedNetworks = 3
    static let autoVerifyThreshold = 3 // connections needed for auto-pass
    static let callMinSeconds = 10     // minimum call duration to count
    static let textMinSeconds = 30     // minimum time in Messages to count
    static let callWatchTimeout = 120  // seconds to wait for a call
}

// MARK: - Personality Responses

/// The "voice" of Clarity. Playful, warm, not preachy.
/// A friend who calls you out with a smirk, not a parent who lectures.
enum ProsocialResponses {
    
    static let verified = [
        "Nice! Connection made 💛",
        "That's what your phone is actually for ✨",
        "Real humans > reels",
        "See? That felt better than scrolling",
        "Your mom says hi back (probably) 💛",
        "5 minutes with a real person beats 5 hours of scrolling",
    ]
    
    static let failed = [
        "...nice try 😏",
        "That was suspiciously fast. Say more than 'hey'?",
        "We're watching 👀 Actually do it!",
        "Your phone literally told us you didn't",
        "C'mon, they'd love to hear from you. For real this time.",
    ]
    
    static let failedCall = [
        "That wasn't long enough to be a real call 📞",
        "Ring ring... hang up? That doesn't count 😄",
        "Try letting it ring more than once",
    ]
    
    static let callAttempted = [
        "They didn't pick up, but you tried! That counts ✅",
        "Voicemail counts — leave them something nice 🎙️",
    ]
    
    static let alreadyConnected = [
        "You've been a great communicator today. Go ahead 🎉",
        "3+ real conversations? You're a social butterfly 🦋",
        "You've earned your scroll. Enjoy it guilt-free.",
    ]
    
    static let skipped = [
        "Okay. But the scroll hits different when you haven't talked to anyone all day.",
        "Skipped for now. We'll ask again later 😏",
    ]
    
    // Challenge prompts — {name} gets replaced with actual contact name
    static let textPrompts = [
        "Send {name} a quick text",
        "Tell {name} you're thinking of them",
        "Check in on {name} — it's been a while",
        "Ask {name} how their day's going",
    ]
    
    static let callPrompts = [
        "Call {name} — even just for a minute",
        "Give {name} a ring instead of scrolling",
        "A quick call to {name} beats an hour of reels",
    ]
    
    static func prompt(for type: String, contactName: String?) -> String {
        let name = contactName ?? "someone you care about"
        let templates: [String]
        switch type {
        case "callSomeone": templates = callPrompts
        default: templates = textPrompts
        }
        return (templates.randomElement() ?? "Connect with {name}").replacingOccurrences(of: "{name}", with: name)
    }
}

// MARK: - Updated Friction Descriptions (Prosocial)

/// Updated layer descriptions that incorporate prosocial framing
enum ProsocialFrictionDescriptions {
    static func title(for layer: Int, contactName: String?) -> String {
        let name = contactName ?? "someone"
        switch layer {
        case 1: return "\(name) would love to hear from you"
        case 2: return "Text \(name) instead"
        case 3: return "What are you looking for?"
        case 4: return "Call \(name) — for real"
        case 5: return "0 texts today. 58 min scrolling."
        default: return "Take a breath"
        }
    }
    
    static func subtitle(for layer: Int) -> String {
        switch layer {
        case 1: return "You've been on this app for 5 minutes"
        case 2: return "A real connection beats any feed"
        case 3: return "Or call someone instead of scrolling"
        case 4: return "Have a real conversation"
        case 5: return "Type 'I choose to keep scrolling' to continue. Or connect with someone."
        default: return "Be intentional"
        }
    }
}
```

---

## TASK 4: Prosocial Friction Views

### 4a. Create `Views/Friction/ProsocialChallengeView.swift`

Full-screen overlay for prosocial challenges. This is the main UI the user sees. It cycles through states: prompt → waiting → verified/failed.

Design must match the existing friction overlay pattern (`FrictionOverlay.swift`):
- Dark overlay background (ClarityColors.overlayHeavy)
- Centered card on ClarityColors.surface
- Orange accent for CTAs
- Spring animations
- Haptic feedback on all interactions

**States:**
1. **Initial** — Contact name in large SerifText, challenge prompt in SansText, deep-link button (ClarityButton primary), skip button (ghost)
2. **Waiting** — Pulsing orange dot animation, "Take your time, we'll know when you're done" in SansText
3. **Verified** — Green checkmark animation, random success message, XP earned display, "Continue" button
4. **Failed** — Random sassy failure message in orange, "Try Again" + "Skip" buttons
5. **Call Attempted** — Green-ish message acknowledging the attempt, slightly less celebratory than full verified
6. **Auto-verified** — Celebratory message from alreadyConnected responses, immediate pass

The component receives:
- `challenge: ProsocialChallenge`
- `engine: ProsocialChallengeEngine` (for state + deep link actions)
- `onComplete: () -> Void`
- `onCancel: () -> Void` (text: "Go back to what I was doing")
- `onSkip: () -> Void`

Show the contact's first initial in a large circular avatar (colored with their name hash) at the top of the card.

### 4b. Create `Views/Friction/ConnectionStatsCard.swift`

Dashboard card showing today's prosocial stats:
- "You connected with X people today" — number in large SerifText
- "Y minutes of real conversation" — secondary stat
- Contrast line: "vs Z minutes scrolling" in muted text
- If 0 connections: "No real connections yet today. Your people miss you." in muted text
- Mini list of contact name pills (first names of today's connections)

Design: Same card style as the existing healthCard in DashboardView (surface background, rounded corners, subtle border).

### 4c. Create `Views/Friction/ImportantPeopleStrip.swift`

Horizontal ScrollView of the user's important contacts:
- Circular avatars with first initial and deterministic color (based on name hash)
- Name underneath in small SansText
- Tap → shows action sheet: "Call" / "Text" via deep links
- Shows on dashboard below ConnectionStatsCard

### 4d. Update `Views/Friction/FrictionOverlay.swift`

Integrate prosocial challenges into the layer switch. When the user has set up important contacts, layers 2 and 4 show ProsocialChallengeView instead of BreathingShield and ReflectionShield:

```swift
@ViewBuilder
private var frictionContent: some View {
    switch frictionLevel {
    case 1:
        EmptyView() // Still handled as AwarenessToast
    case 2:
        if hasImportantContacts {
            ProsocialChallengeView(/* textSomeone challenge */)
        } else {
            BreathingShield(onComplete: onComplete, onCancel: onCancel)
        }
    case 3:
        IntentionCheck(onComplete: onComplete, onCancel: onCancel)
    case 4:
        if hasImportantContacts {
            ProsocialChallengeView(/* callSomeone challenge */)
        } else {
            ReflectionShield(onComplete: onComplete, onCancel: onCancel)
        }
    case 5:
        StrongEncouragement(onComplete: onComplete, onCancel: onCancel)
    default:
        EmptyView()
    }
}
```

### 4e. Update `Views/Friction/AwarenessToast.swift`

Add prosocial nudge to the Layer 1 toast message. If the user has important contacts, the toast subtitle should mention a specific person:
- "You've been on [app] for 5 minutes. [Name] would love to hear from you."

### 4f. Update existing challenge views

Update `CallSomeoneChallenge.swift`, `TextLovedOneChallenge.swift`, `ContactParentChallenge.swift`:
- Accept specific contact name and phone number as parameters
- Deep link to SPECIFIC contact: `tel://+15551234567` not just `tel://`
- Do NOT mark `completed = true` immediately on button tap
- Instead, show verification waiting state
- Integrate with ProsocialChallengeEngine for verification flow
- Show personality responses on verification result

### 4g. Update `Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift`

Update shield titles/subtitles to include prosocial framing:
- Level 1: "Take a breath" → "Someone would love to hear from you"
- Level 2: "Pause and breathe" → "Text someone instead"
- Level 4: "Check in with yourself" → "Call someone you care about"
- Primary button: "Open Clarity" (unchanged)
- Secondary button: "I Choose to Continue" (unchanged)

Also add prosocial challenge context from App Group:
```swift
// Read pending challenge contact name from shared defaults
let contactName = sharedDefaults?.string(forKey: "prosocialContactName") ?? "someone"
```

---

## TASK 5: Onboarding Updates

### 5a. Add "Important People" step

Add a new onboarding step between AppSelectionStep (step 3) and GoalSettingStep (step 4). Update OnboardingFlow.swift to have 9 total steps.

**`Views/Onboarding/ImportantPeopleStep.swift`**

Design (matching existing onboarding steps):
- MonoText label: "YOUR PEOPLE" (tracking: 3, muted color)
- SerifText heading: "Who matters most?" (28pt)
- SansText body: "Instead of scrolling, we'll encourage you to connect with these people — and verify you did 😏" (15pt, textTertiary)
- Contact list from CNContactStore (request permission here):
  - Show contacts with names in a scrollable list
  - Tap to select (same toggle style as AppSelectionStep app tiles, but as list rows)
  - Selected contacts show orange left border + checkmark
  - Max 5, show counter pill: "3/5 selected"
- If contact permission denied: Manual entry mode
  - Text field for name
  - Optional text field for phone number
  - "Add" button, shows added contacts as removable pills
- ClarityButton "Continue" at bottom
- Store selections as ImportantContact models in SwiftData

### 5b. Add "Home Base" step

New onboarding step after Important People.

**`Views/Onboarding/HomeBaseStep.swift`**

Design:
- MonoText label: "HOME BASE"
- SerifText heading: "Where's home?"
- SansText body: "Doomscroll apps will only unlock when you're on your home WiFi. Everywhere else, Clarity keeps you present."
- Show current WiFi network name (from WiFiGateService.shared.currentSSID)
  - If detected: "📶 Connected to: [NetworkName]" with "Set as Home Base" button
  - If no WiFi / permission denied: Manual entry text field for SSID
- ToggleRow: "Enable WiFi Gate" (default: on)
- Note text: "You can add up to 3 trusted networks in Settings" (muted)
- ClarityButton "Continue"
- Store in WiFiGateConfig model

### 5c. Update `OnboardingFlow.swift`

Change `totalSteps` from 7 to 9. Insert ImportantPeopleStep at index 4 and HomeBaseStep at index 5. Shift existing steps:

```
0: WelcomeStep
1: AssessmentStep
2: HealthPermissionStep
3: AppSelectionStep
4: ImportantPeopleStep     ← NEW
5: HomeBaseStep            ← NEW
6: GoalSettingStep
7: IntentionBuilderStep
8: ReadyStep
```

---

## TASK 6: Dashboard Updates

### 6a. Update `Views/Dashboard/DashboardView.swift`

Add to the VStack after quickStatsRow and before healthCard:

1. **ConnectionStatsCard** — Today's prosocial connection stats
2. **ImportantPeopleStrip** — Horizontal scroll of favorite contacts with tap-to-call/text

Both use @Query to pull ConnectionLog and ImportantContact from SwiftData.

### 6b. Add prosocial stats to Quick Stats row

Add a 4th stat card (or replace PICKUPS placeholder):
- "CONNECTIONS" label
- Count of today's verified ConnectionLogs
- "💛" unit

---

## TASK 7: Settings Updates

### 7a. Update `Views/Settings/SettingsView.swift`

Add new sections (matching existing section patterns with SectionHeader + content):

**"YOUR PEOPLE" section** (between THE CURE and YOUR SHIELDS):
- List of ImportantContact items with swipe-to-delete
- Each row: contact name, times connected, last connected date
- "Add Contact" button → sheet with CNContactPickerViewController or manual entry
- Counter: "X/5 contacts"

**"WIFI GATE" section** (after YOUR SHIELDS):
- ToggleRow: "WiFi Gate" on/off
- Current network display: "📶 [NetworkName]" with "Add as Home Base" button
- List of trusted networks with swipe-to-delete
- Counter: "X/3 networks"

**"PROSOCIAL FRICTION" section** (inside THE CURE section):
- ToggleRow: "Prosocial Challenges" — on/off
- Description: "Replace some friction with challenges to text or call people"
- When off: uses traditional breathing/intention/reflection friction

**"DATA" section** (before Reset):
- Info text in muted SansText: "Focus sessions and challenge history are automatically deleted after 30 days. Trend data is kept for 90 days."
- "Delete All Data" button (keep existing reset functionality, extend to delete new models)

---

## TASK 8: 30-Day Auto-Cleanup

### 8a. Create `Services/DataCleanupService.swift`

Background cleanup of old data using BGAppRefreshTask:

```swift
import BackgroundTasks
import SwiftData
import Foundation

class DataCleanupService {
    static let taskIdentifier = "com.clarity.focus.dataCleanup"
    
    /// Register the background task in ClarityApp.init or didFinishLaunching
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
        
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        
        // 30-day cleanup
        try? context.delete(model: FocusSession.self, where: #Predicate { $0.startTime < thirtyDaysAgo })
        try? context.delete(model: MoodEntry.self, where: #Predicate { $0.timestamp < thirtyDaysAgo })
        try? context.delete(model: ProsocialChallenge.self, where: #Predicate { $0.issuedAt < thirtyDaysAgo })
        try? context.delete(model: ConnectionLog.self, where: #Predicate { $0.timestamp < thirtyDaysAgo })
        
        // 90-day cleanup for snapshots
        try? context.delete(model: DailySnapshot.self, where: #Predicate { $0.date < ninetyDaysAgo })
        
        try? context.save()
        
        // Schedule next cleanup
        scheduleCleanup()
        task.setTaskCompleted(success: true)
    }
    
    /// Also run cleanup on app launch (in case background task was missed)
    static func cleanupOnLaunch(context: ModelContext) {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        
        try? context.delete(model: FocusSession.self, where: #Predicate { $0.startTime < thirtyDaysAgo })
        try? context.delete(model: MoodEntry.self, where: #Predicate { $0.timestamp < thirtyDaysAgo })
        try? context.delete(model: ProsocialChallenge.self, where: #Predicate { $0.issuedAt < thirtyDaysAgo })
        try? context.delete(model: ConnectionLog.self, where: #Predicate { $0.timestamp < thirtyDaysAgo })
        try? context.delete(model: DailySnapshot.self, where: #Predicate { $0.date < ninetyDaysAgo })
    }
}
```

### 8b. Update `ClarityApp.swift`

- Register background task in init
- Call `DataCleanupService.cleanupOnLaunch(context:)` on app launch
- Schedule first background cleanup

### 8c. Update `Info.plist`

Add `BGTaskSchedulerPermittedIdentifiers`:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.clarity.focus.dataCleanup</string>
</array>
```

---

## TASK 9: Subscription with StoreKit 2

**No custom server needed for payments.** StoreKit 2 handles everything on-device with Apple's infrastructure. Apple manages the billing, receipts, renewal, and cancellation. No Stripe. No backend.

### 9a. Create `Services/SubscriptionService.swift`

```swift
import StoreKit
import Observation

/// Manages in-app subscriptions using StoreKit 2.
/// No server needed — Apple handles billing, receipts, renewal.
@Observable
class SubscriptionService {
    static let shared = SubscriptionService()
    
    // Product IDs (configure in App Store Connect)
    static let monthlyProductId = "com.clarity.focus.monthly"
    static let yearlyProductId = "com.clarity.focus.yearly"
    
    var products: [Product] = []
    var purchasedSubscription: Product? = nil
    var isSubscribed: Bool = false
    var subscriptionStatus: String = "none" // "monthly", "yearly", "none", "expired"
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    /// Load available products from App Store Connect
    func loadProducts() async {
        do {
            products = try await Product.products(for: [
                Self.monthlyProductId,
                Self.yearlyProductId,
            ])
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    /// Purchase a subscription
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    /// Check current subscription status
    func updateSubscriptionStatus() async {
        var hasActive = false
        
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == Self.monthlyProductId {
                    subscriptionStatus = "monthly"
                    hasActive = true
                } else if transaction.productID == Self.yearlyProductId {
                    subscriptionStatus = "yearly"
                    hasActive = true
                }
            }
        }
        
        isSubscribed = hasActive
        if !hasActive {
            subscriptionStatus = "none"
        }
    }
    
    /// Restore purchases (for "Restore Purchases" button in Settings)
    func restorePurchases() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    /// Listen for transaction updates (renewals, cancellations, refunds)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    enum StoreError: Error {
        case failedVerification
    }
}
```

### 9b. Create `Views/Subscription/SubscriptionView.swift` (Paywall)

Full-screen paywall shown when the user tries to access premium features (or after onboarding free trial ends).

Design:
- Large SerifText: "Unlock Clarity"
- Feature list (NOT bullet points — use horizontal icon + text rows):
  - "🛡️ App shielding & progressive friction"
  - "📱 Prosocial challenges with verification"
  - "📶 WiFi-gated unlocking"
  - "📊 Insights & connection stats"
  - "🔒 100% private — everything on your phone"
- Two pricing cards side by side:
  - Monthly: "$4.99/month" — ClarityButton secondary
  - Yearly: "$39.99/year" with "Save 33%" badge — ClarityButton primary (recommended)
- "Restore Purchases" text button at bottom (muted)
- "Terms" and "Privacy Policy" links at very bottom

Card design matches existing surface cards. The yearly card should have a subtle primaryMuted background + primary border to indicate "best value."

### 9c. Create `Views/Subscription/SubscriptionBadge.swift`

Small pill/badge for Settings showing current subscription status:
- "Pro — Monthly" or "Pro — Yearly" in green
- "Free" in muted text
- Tap → opens SubscriptionView

### 9d. Update Settings

Add "SUBSCRIPTION" section at the top of SettingsView with:
- SubscriptionBadge
- "Manage Subscription" → opens SubscriptionView
- "Restore Purchases" button

### 9e. Determine free vs paid features

**Free tier (always available):**
- 1 focus session per day
- Basic friction (layers 1-2 only)
- Mood check-ins
- 1 shielded app

**Paid tier ($4.99/mo or $39.99/yr):**
- Unlimited focus sessions
- All 5 friction layers + prosocial challenges
- WiFi gate
- Unlimited shielded apps
- Connection stats & insights
- All gamification features

Check `SubscriptionService.shared.isSubscribed` before showing premium features. Show SubscriptionView as a sheet when a locked feature is tapped.

### 9f. App Store Connect Configuration

In App Store Connect, you'll need to create:
- Auto-Renewable Subscription Group: "Clarity Pro"
- Product 1: `com.clarity.focus.monthly` — $4.99/month
- Product 2: `com.clarity.focus.yearly` — $39.99/year
- Configure subscription offers, free trial period (recommend 7-day free trial)

---

## TASK 10: Entitlements & Permissions

### 10a. Update `Clarity.entitlements`

Ensure these entitlements are present:
- Family Controls
- App Groups: `group.com.clarity.focus`
- Access WiFi Information
- HealthKit
- Background Modes: Background fetch
- In-App Purchase (StoreKit)

### 10b. Update `Info.plist`

Add permission descriptions:
```xml
<key>NSContactsUsageDescription</key>
<string>Clarity suggests people to connect with instead of scrolling</string>

<key>NSLocationWhenInUseUsageDescription</key>  
<string>Clarity uses your location to detect your home WiFi network</string>

<key>NSHealthShareUsageDescription</key>
<string>Clarity correlates your sleep and mindfulness with screen time habits</string>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.clarity.focus.dataCleanup</string>
</array>
```

---

## TASK 11: Update ProgressiveFrictionManager

### 11a. Update `ViewModels/ProgressiveFrictionManager.swift`

Update FrictionLevel enum to include prosocial context:

```swift
enum FrictionLevel: Int, CaseIterable {
    case awareness = 1
    case prosocialText = 2      // Was: breathing
    case intentionCheck = 3
    case prosocialCall = 4       // Was: reflection
    case strongEncouragement = 5
    
    var isProsocial: Bool {
        self == .prosocialText || self == .prosocialCall
    }
    
    var title: String {
        switch self {
        case .awareness:           return "Awareness Nudge"
        case .prosocialText:       return "Text Someone"        // Updated
        case .intentionCheck:      return "Intention Check"
        case .prosocialCall:       return "Call Someone"         // Updated
        case .strongEncouragement: return "Strong Encouragement"
        }
    }
}
```

Add property to track if prosocial mode is enabled:
```swift
var prosocialEnabled: Bool = true // Toggled in Settings
```

The friction check logic stays the same — just the label and which view is shown changes based on `prosocialEnabled`.

---

## TASK 12: AppState & Environment Updates

### 12a. Update `ViewModels/AppState.swift`

Add new state properties:
```swift
// Prosocial
var prosocialEngine = ProsocialChallengeEngine()

// WiFi Gate
var wifiGateService = WiFiGateService.shared

// Subscription
var subscriptionService = SubscriptionService.shared
```

### 12b. Update `ContentView.swift`

Add new environment objects and call initialization on appear:
```swift
.onAppear {
    appState.checkOnboardingStatus(context: modelContext)
    
    // Start WiFi monitoring
    WiFiGateService.shared.startMonitoring()
    
    // Load subscription products
    Task { await SubscriptionService.shared.loadProducts() }
    Task { await SubscriptionService.shared.updateSubscriptionStatus() }
    
    // Run data cleanup
    DataCleanupService.cleanupOnLaunch(context: modelContext)
    DataCleanupService.scheduleCleanup()
}
```

---

## Summary of New Files

```
Models/
  ProsocialChallenge.swift
  ConnectionLog.swift
  ImportantContact.swift
  WiFiGateConfig.swift

Services/
  CallVerificationService.swift
  CommunicationMonitorService.swift
  WiFiGateService.swift
  ProsocialChallengeEngine.swift
  DataCleanupService.swift
  SubscriptionService.swift

Utilities/
  ProsocialConstants.swift

Views/Friction/
  ProsocialChallengeView.swift
  ConnectionStatsCard.swift
  ImportantPeopleStrip.swift

Views/Onboarding/
  ImportantPeopleStep.swift
  HomeBaseStep.swift

Views/Subscription/
  SubscriptionView.swift
  SubscriptionBadge.swift
```

## Files to Update

```
ClarityApp.swift                    — New models in container, background task, cleanup
Views/App/ContentView.swift         — New services init, environment
Views/App/TabContainer.swift        — Pass new environment objects
ViewModels/AppState.swift           — New properties
ViewModels/ProgressiveFrictionManager.swift — Prosocial friction levels
Views/Dashboard/DashboardView.swift — Connection stats + people strip
Views/Friction/FrictionOverlay.swift — Prosocial challenge integration
Views/Friction/AwarenessToast.swift — Prosocial nudge in subtitle
Views/Friction/Challenges/CallSomeoneChallenge.swift — Real verification
Views/Friction/Challenges/TextLovedOneChallenge.swift — Real verification
Views/Friction/Challenges/ContactParentChallenge.swift — Real verification
Views/Onboarding/OnboardingFlow.swift — 9 steps (was 7)
Views/Settings/SettingsView.swift — New sections
Views/Settings/FrictionConfigView.swift — Prosocial toggle
Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift — Prosocial shield text
Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift — Text verification threshold
Info.plist — New permissions + background task ID
Clarity.entitlements — WiFi, StoreKit, Background Modes
```

## Key Rules

- **Dark mode only. Always. #030303 background. No light mode.**
- **Haptic feedback on every interaction** (HapticManager.light/medium/success/warning/error)
- **Spring animations** (response: 0.3, dampingFraction: 0.6-0.8)
- **User ALWAYS has option to continue past friction** — never locked out
- **Playful tone, not preachy** — friend with a smirk, not a parent lecturing
- **All data on-device** — SwiftData for persistence, App Group UserDefaults for extension communication, no cloud
- **StoreKit 2 for payments** — Apple handles everything, no custom server
- **Extension targets have 5MB memory limit** — keep extension logic minimal, heavy logic in main app
- **Follow existing design patterns exactly** — ClarityColors, ClarityFonts, ClaritySpacing, ClarityRadius, SectionHeader, ToggleRow, ClarityButton, ScalePress button style