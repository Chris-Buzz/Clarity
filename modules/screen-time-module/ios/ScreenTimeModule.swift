import Foundation
import React
import FamilyControls
import ManagedSettings
import DeviceActivity

@available(iOS 15.0, *)
@objc(ScreenTimeModule)
class ScreenTimeModule: NSObject {

  private let center = AuthorizationCenter.shared
  private let store = ManagedSettingsStore()
  private var activitySelection = FamilyActivitySelection()

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc
  func checkAuthorization(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      let status = self.center.authorizationStatus
      resolve(status == .approved)
    }
  }

  @objc
  func requestAuthorization(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    Task {
      do {
        try await center.requestAuthorization(for: .individual)
        DispatchQueue.main.async {
          resolve(self.center.authorizationStatus == .approved)
        }
      } catch {
        DispatchQueue.main.async {
          reject("AUTH_ERROR", "Failed to request authorization: \(error.localizedDescription)", error)
        }
      }
    }
  }

  @objc
  func getInstalledApps(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    // Note: We can't get app names directly due to privacy
    // We use FamilyActivityPicker in the UI instead
    resolve([])
  }

  @objc
  func setBlockedApps(_ appTokens: [String], resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    // In a real implementation, you would store the selection from FamilyActivityPicker
    // and convert tokens back. For now, we use the stored selection.
    DispatchQueue.main.async {
      do {
        self.store.shield.applications = self.activitySelection.applicationTokens
        self.store.shield.applicationCategories = .specific(self.activitySelection.categoryTokens)
        resolve(true)
      }
    }
  }

  @objc
  func startBlocking(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      // Block all selected apps
      self.store.shield.applications = self.activitySelection.applicationTokens
      self.store.shield.applicationCategories = .specific(self.activitySelection.categoryTokens)
      resolve(true)
    }
  }

  @objc
  func stopBlocking(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      // Clear all shields
      self.store.shield.applications = nil
      self.store.shield.applicationCategories = nil
      self.store.shield.webDomains = nil
      resolve(true)
    }
  }

  @objc
  func startFocusSession(_ durationMinutes: Double, resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      // Start blocking
      self.store.shield.applications = self.activitySelection.applicationTokens
      self.store.shield.applicationCategories = .specific(self.activitySelection.categoryTokens)

      // Schedule automatic unblock (optional - can use DeviceActivity for more robust scheduling)
      let duration = durationMinutes * 60
      DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
        self?.store.shield.applications = nil
        self?.store.shield.applicationCategories = nil
      }

      resolve(true)
    }
  }

  @objc
  func endFocusSession(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      // Clear all shields
      self.store.shield.applications = nil
      self.store.shield.applicationCategories = nil
      self.store.shield.webDomains = nil
      resolve(true)
    }
  }

  @objc
  func updateActivitySelection(_ selection: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    // This would be called from the native FamilyActivityPicker
    // The selection is stored and used when blocking starts
    resolve(true)
  }
}

// Fallback for iOS < 15
@objc(ScreenTimeModule)
class ScreenTimeModuleFallback: NSObject {

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return false
  }

  @objc
  func checkAuthorization(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(false)
  }

  @objc
  func requestAuthorization(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    reject("NOT_SUPPORTED", "Screen Time API requires iOS 15 or later", nil)
  }

  @objc
  func startBlocking(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    reject("NOT_SUPPORTED", "Screen Time API requires iOS 15 or later", nil)
  }

  @objc
  func stopBlocking(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    reject("NOT_SUPPORTED", "Screen Time API requires iOS 15 or later", nil)
  }

  @objc
  func startFocusSession(_ durationMinutes: Double, resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    reject("NOT_SUPPORTED", "Screen Time API requires iOS 15 or later", nil)
  }

  @objc
  func endFocusSession(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    reject("NOT_SUPPORTED", "Screen Time API requires iOS 15 or later", nil)
  }
}
