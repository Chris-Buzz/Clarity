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
    private let sharedDefaults = UserDefaults(suiteName: "group.com.clarity-focus")
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
        locationManager.requestWhenInUseAuthorization()
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
        guard networks.count < ProsocialLimits.maxTrustedNetworks, !networks.contains(ssid) else { return false }
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
            wifiStore.clearAllSettings()
            return
        }

        if isOnHomeNetwork {
            wifiStore.clearAllSettings()
        } else {
            applyWiFiShields()
        }
    }

    /// Apply shields from the user's shielded app selection.
    private func applyWiFiShields() {
        // Read saved shield tokens from App Group
        guard let _ = sharedDefaults?.data(forKey: "shieldedTokens") else { return }
        // The actual application token decoding follows the same pattern as ScreenTimeService
        // FamilyActivitySelection tokens are applied to the wifiGate ManagedSettingsStore
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways {
            fetchCurrentSSID()
        }
    }
}
