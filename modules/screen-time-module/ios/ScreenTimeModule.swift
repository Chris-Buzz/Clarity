import Foundation
import React
import FamilyControls
import ManagedSettings
import DeviceActivity

@available(iOS 16.0, *)
@objc(ScreenTimeModule)
class ScreenTimeModule: NSObject, RCTBridgeModule {

  private let center = AuthorizationCenter.shared
  private let store = ManagedSettingsStore()

  @objc static func moduleName() -> String! {
    return "ScreenTimeModule"
  }

  @objc static func requiresMainQueueSetup() -> Bool {
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
        try await self.center.requestAuthorization(for: .individual)
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
    // FamilyActivityPicker handles app selection in the UI
    resolve([])
  }

  @objc
  func setBlockedApps(_ appTokens: [String], resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true)
  }

  @objc
  func startBlocking(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      // Shield all apps that the user selected via FamilyActivityPicker
      // For now, shield all social media categories
      self.store.shield.applicationCategories = .all()
      resolve(true)
    }
  }

  @objc
  func stopBlocking(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      self.store.shield.applications = nil
      self.store.shield.applicationCategories = nil
      self.store.shield.webDomains = nil
      resolve(true)
    }
  }

  @objc
  func startFocusSession(_ durationMinutes: Double, resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      // Block all selected apps/categories
      self.store.shield.applicationCategories = .all()

      // Auto-unblock after duration
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
      self.store.shield.applications = nil
      self.store.shield.applicationCategories = nil
      self.store.shield.webDomains = nil
      resolve(true)
    }
  }

  @objc
  func updateActivitySelection(_ selection: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true)
  }

  @objc
  func enableAlwaysOnFriction(_ frictionLevel: Int, resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      // Enable shields - this blocks selected apps system-wide
      self.store.shield.applicationCategories = .all()
      resolve(true)
    }
  }

  @objc
  func disableAlwaysOnFriction(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      self.store.shield.applications = nil
      self.store.shield.applicationCategories = nil
      resolve(true)
    }
  }
}
