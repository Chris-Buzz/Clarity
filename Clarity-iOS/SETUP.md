# Clarity iOS — MacBook Setup Guide

## Prerequisites

1. **Mac** running macOS 14 (Sonoma) or later
2. **Xcode 15.2+** — Download from the Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/)
3. **Apple Developer Account** ($99/year) — Required for Family Controls entitlement
   - Sign up at [developer.apple.com/programs](https://developer.apple.com/programs/)
4. **iPhone** running iOS 17+ (Screen Time APIs don't work in Simulator)

## Step 1: Clone the Repository

```bash
git clone <your-repo-url> clarity-focus-mobile
cd clarity-focus-mobile/Clarity-iOS
```

## Step 2: Create the Xcode Project

Since the source files are pre-built but the `.xcodeproj` needs to be created:

### Option A: Create from Xcode (Recommended)

1. Open Xcode
2. **File → New → Project**
3. Choose **iOS → App**
4. Configure:
   - Product Name: `Clarity`
   - Team: Your Apple Developer team
   - Organization Identifier: `com.clarity`
   - Bundle Identifier: `com.clarity.focus`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**
   - Uncheck "Include Tests" (add later)
5. Save to the `Clarity-iOS/` directory
6. **Delete** the auto-generated `ContentView.swift` and `ClarityApp.swift` (you'll use the existing ones)
7. **Add existing files**: Right-click the `Clarity` group → **Add Files to "Clarity"**
   - Select ALL files/folders from `Clarity-iOS/Clarity/`:
     - `ClarityApp.swift`
     - `Models/` (entire folder)
     - `Views/` (entire folder)
     - `ViewModels/` (entire folder)
     - `Services/` (entire folder)
     - `Utilities/` (entire folder)
     - `Extensions/` (entire folder)
     - `Info.plist`
     - `Clarity.entitlements`
   - Check "Create groups" (not folder references)
   - Check "Add to targets: Clarity"

### Option B: Use the project generation script

```bash
# From Clarity-iOS directory
# If a .xcodeproj exists, just open it:
open Clarity.xcodeproj
```

## Step 3: Add Custom Fonts

The app uses three font families. Download and add them to the project:

1. **Playfair Display** — [Google Fonts](https://fonts.google.com/specimen/Playfair+Display)
   - Regular, Italic, SemiBold Italic
2. **Outfit** — [Google Fonts](https://fonts.google.com/specimen/Outfit)
   - Thin, ExtraLight, Light, Regular, Medium, SemiBold
3. **Space Mono** — [Google Fonts](https://fonts.google.com/specimen/Space+Mono)
   - Regular

Add font files:
1. Create a `Fonts/` group in the project
2. Drag all `.ttf` files into the group
3. Ensure they're added to the `Clarity` target
4. Verify `Info.plist` has `UIAppFonts` listing all font filenames (already configured)

## Step 4: Configure Signing & Entitlements

### Signing

1. Select the **Clarity** project in the Navigator
2. Select the **Clarity** target → **Signing & Capabilities**
3. Set your **Team** (your Apple Developer account)
4. Set **Bundle Identifier**: `com.clarity.focus`
5. **Uncheck** "Automatically manage signing"
6. You need a **manually provisioned** profile with Family Controls entitlement

### Family Controls Entitlement

This is the critical step — Apple restricts Family Controls to approved apps:

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles → Identifiers**
3. Select or create the `com.clarity.focus` App ID
4. Enable the **Family Controls** capability
5. You may need to **request access** from Apple — submit at [developer.apple.com/family-controls](https://developer.apple.com/contact/family-controls/)
6. Create a **Provisioning Profile** (Development) that includes Family Controls
7. Download and double-click to install, or use the included `Clarity_AdHoc_FamilyControls.mobileprovision`

### Entitlements

The `Clarity.entitlements` file should already be configured with:
- Family Controls
- HealthKit
- App Groups: `group.com.clarity.focus`
- WiFi Information
- In-App Purchases
- Background Fetch

Verify in Xcode: Target → **Signing & Capabilities** → Add any missing capabilities.

## Step 5: Create Extension Targets

The app has 5 extension targets. Create each one:

### ShieldConfiguration Extension

1. **File → New → Target**
2. Choose **Shield Configuration Extension** (under Device Activity)
3. Product Name: `ClarityShieldConfiguration`
4. Bundle ID: `com.clarity.focus.ShieldConfiguration`
5. Add `group.com.clarity.focus` to App Groups
6. Replace generated code with `Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift`

### ShieldAction Extension

1. **File → New → Target → Shield Action Extension**
2. Product Name: `ClarityShieldAction`
3. Bundle ID: `com.clarity.focus.ShieldAction`
4. Add App Group
5. Replace with `Extensions/ShieldAction/ShieldActionExtension.swift`

### DeviceActivityMonitor Extension

1. **File → New → Target → Device Activity Monitor Extension**
2. Product Name: `ClarityDeviceActivityMonitor`
3. Bundle ID: `com.clarity.focus.DeviceActivityMonitor`
4. Add App Group
5. Replace with `Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift`

### DeviceActivityReport Extension

1. **File → New → Target → Device Activity Report Extension**
2. Product Name: `ClarityDeviceActivityReport`
3. Bundle ID: `com.clarity.focus.DeviceActivityReport`
4. Add App Group
5. Replace with `Extensions/DeviceActivityReport/DeviceActivityReportExtension.swift`

### Widget Extension

1. **File → New → Target → Widget Extension**
2. Product Name: `ClarityWidget`
3. Bundle ID: `com.clarity.focus.Widget`
4. Add App Group
5. Replace with `Extensions/ClarityWidget/ClarityWidget.swift`

**Important:** All extensions must share the same App Group (`group.com.clarity.focus`).

## Step 6: Configure App Store Connect (for StoreKit)

For subscription testing:

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Create a new app with bundle ID `com.clarity.focus`
3. Under **Monetization → Subscriptions**:
   - Create subscription group: "Clarity Pro"
   - Add product: `com.clarity.focus.monthly` — $4.99/month
   - Add product: `com.clarity.focus.yearly` — $39.99/year
4. For local testing, create a **StoreKit Configuration File**:
   - In Xcode: File → New → File → StoreKit Configuration File
   - Add both subscription products
   - In scheme settings, set this file as the StoreKit Configuration

## Step 7: Build & Run

### On Simulator (Limited)

```bash
# Build for simulator (Screen Time features won't work)
xcodebuild -scheme Clarity \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

Or in Xcode: Select iPhone simulator → Cmd+R

**Note:** FamilyControls, ManagedSettings, and DeviceActivity frameworks are **not available** in the Simulator. The app will build and run, but Screen Time features will be no-ops.

### On Physical Device (Full Features)

1. Connect your iPhone via USB or WiFi
2. In Xcode, select your device as the destination
3. Cmd+R to build and run
4. On first launch, grant permissions when prompted:
   - Screen Time / Family Controls
   - Contacts (for prosocial challenges)
   - Location (for WiFi gate)
   - HealthKit
   - Notifications

## Step 8: Testing Checklist

- [ ] App launches to AuthScreen on fresh install
- [ ] Onboarding flows through all 9 steps
- [ ] Dashboard shows Clarity Score ring
- [ ] Focus timer starts and tracks time
- [ ] Friction overlays appear at thresholds (physical device only)
- [ ] Prosocial challenges show contact prompts
- [ ] Settings sections all render correctly
- [ ] Subscription paywall displays pricing
- [ ] WiFi gate detects current network

## Troubleshooting

### "Family Controls entitlement not found"
- You need Apple's approval for the Family Controls entitlement
- Submit a request at developer.apple.com and wait for approval
- Use the included provisioning profile if available

### "No such module 'FamilyControls'"
- Ensure minimum deployment target is iOS 16.0+
- This framework is not available in Simulator — build for a real device

### Fonts not rendering
- Verify font files are in the "Copy Bundle Resources" build phase
- Check that `Info.plist` `UIAppFonts` array matches your font filenames exactly
- Clean build folder (Cmd+Shift+K) and rebuild

### StoreKit products not loading
- Ensure StoreKit Configuration File is set in the scheme
- For real products, ensure App Store Connect has the products in "Ready to Submit" status

### Build errors with extensions
- Each extension target needs its own bundle ID (`com.clarity.focus.XXX`)
- All extensions must be in the same App Group
- Extension targets have a 5MB memory limit — don't import heavy frameworks

## Project Structure

```
Clarity-iOS/
  Clarity/
    ClarityApp.swift              # App entry point
    Info.plist                    # App configuration
    Clarity.entitlements          # Capabilities

    Models/                       # SwiftData models
      UserProfile.swift
      FocusSession.swift
      MoodEntry.swift
      DailySnapshot.swift
      ImplementationIntention.swift
      SubstitutionRecord.swift
      Achievement.swift
      ProsocialChallenge.swift    # v2
      ConnectionLog.swift         # v2
      ImportantContact.swift      # v2
      WiFiGateConfig.swift        # v2

    ViewModels/                   # @Observable state
      AppState.swift
      SessionManager.swift
      ProgressiveFrictionManager.swift
      GamificationManager.swift
      ClarityScoreCalculator.swift
      EmotionalContextEngine.swift
      HabitSubstitutionEngine.swift
      HealthManager.swift

    Views/
      App/
        ContentView.swift         # Root view
        TabContainer.swift        # Tab navigation
      Auth/
        AuthScreen.swift
      Dashboard/
        DashboardView.swift
        ClarityScoreRing.swift
        QuickStartButton.swift
      Focus/
        FocusTimerView.swift
        BreathingOverlay.swift
        CandleVisual.swift
        ReflectionView.swift
      Friction/
        FrictionOverlay.swift
        AwarenessToast.swift
        BreathingShield.swift
        IntentionCheck.swift
        ReflectionShield.swift
        StrongEncouragement.swift
        ProsocialChallengeView.swift  # v2
        ConnectionStatsCard.swift     # v2
        ImportantPeopleStrip.swift    # v2
        Challenges/               # Individual challenge types
      Insights/
        InsightsView.swift
        MoodTrendChart.swift
        WeeklyReportView.swift
      Onboarding/
        OnboardingFlow.swift      # 9-step coordinator
        WelcomeStep.swift
        AssessmentStep.swift
        HealthPermissionStep.swift
        AppSelectionStep.swift
        ImportantPeopleStep.swift  # v2
        HomeBaseStep.swift         # v2
        GoalSettingStep.swift
        IntentionBuilderStep.swift
        ReadyStep.swift
      Settings/
        SettingsView.swift
        FrictionConfigView.swift
      Subscription/               # v2
        SubscriptionView.swift
        SubscriptionBadge.swift
      Shared/
        ClarityButton.swift
        MoodCheckIn.swift
        AnimatedBackground.swift

    Services/
      ScreenTimeService.swift
      HealthKitService.swift
      NotificationService.swift
      AIVerificationService.swift
      AppGroupStorage.swift
      CallVerificationService.swift       # v2
      CommunicationMonitorService.swift   # v2
      WiFiGateService.swift               # v2
      ProsocialChallengeEngine.swift      # v2
      DataCleanupService.swift            # v2
      SubscriptionService.swift           # v2

    Utilities/
      ClarityColors.swift         # Color palette
      ClarityFonts.swift          # Typography
      ClaritySpacing.swift        # 8pt grid + radius
      HapticManager.swift         # Haptic feedback
      Color+Hex.swift             # Color(hex:) extension
      Date+Helpers.swift          # Date utilities
      ProsocialConstants.swift    # v2 constants & responses

    Extensions/                   # Extension targets
      ShieldConfiguration/
      ShieldAction/
      DeviceActivityMonitor/
      DeviceActivityReport/
      ClarityWidget/

  CLAUDE.md                       # Architecture docs
  SETUP.md                        # This file
```
