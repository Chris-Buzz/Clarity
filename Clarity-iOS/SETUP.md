# Clarity iOS Setup

## What You Need

- Mac with macOS 14+ and Xcode 15.2+
- Apple Developer Account ($99/year) — needed for Family Controls
- iPhone running iOS 17+ (Screen Time APIs don't work in Simulator)

## Step 1: Create Xcode Project (on Desktop)

Xcode can't create a project inside `Clarity-iOS/` because a `Clarity/` folder already exists there. So you create it somewhere else and move the `.xcodeproj` in.

1. Open Xcode > **File > New > Project > iOS > App**
2. Settings:
   - **Product Name:** `Clarity`
   - **Team:** Your Apple Developer team
   - **Organization Identifier:** `com`
   - **Bundle Identifier:** should auto-fill to `com.Clarity` — you'll fix it in Step 3
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** SwiftData
   - Uncheck "Include Tests"
3. **Save to Desktop** (or anywhere that isn't `Clarity-iOS/`)

## Step 2: Move the .xcodeproj

```bash
# Move ONLY the .xcodeproj into the Clarity-iOS folder
mv ~/Desktop/Clarity/Clarity.xcodeproj /path/to/clarity-focus-mobile/Clarity-iOS/

# Delete the leftover temp project
rm -rf ~/Desktop/Clarity
```

Now open it:

```bash
cd /path/to/clarity-focus-mobile/Clarity-iOS
open Clarity.xcodeproj
```

## Step 3: Fix Bundle ID + Add Source Files

### Set the correct Bundle ID

1. Click the **Clarity** project in the left sidebar
2. Select the **Clarity** target > **General** tab
3. Change **Bundle Identifier** to: `com.clarity-focus`

### Delete Xcode's auto-generated files

In the project navigator, delete these (Move to Trash):
- `ContentView.swift` (the auto-generated one)
- `ClarityApp.swift` (the auto-generated one)
- `Item.swift` (if it exists)

### Add the real source files

1. Right-click the **Clarity** group in the sidebar
2. **Add Files to "Clarity"...**
3. Navigate to `Clarity-iOS/Clarity/` and select ALL of these:
   - `ClarityApp.swift`
   - `Models/`
   - `Views/`
   - `ViewModels/`
   - `Services/`
   - `Utilities/`
   - `Info.plist`
   - `Clarity.entitlements`
4. Make sure **"Create groups"** is selected (NOT "Create folder references")
5. Make sure **"Add to targets: Clarity"** is checked
6. Click **Add**

Do NOT add the `Extensions/` folder to the main target — those go in their own targets in Step 5.

## Step 4: Fonts

Download these fonts and drag the `.ttf` files into the project:

1. [Playfair Display](https://fonts.google.com/specimen/Playfair+Display) — Regular, Italic, SemiBold Italic
2. [Outfit](https://fonts.google.com/specimen/Outfit) — Thin, ExtraLight, Light, Regular, Medium, SemiBold
3. [Space Mono](https://fonts.google.com/specimen/Space+Mono) — Regular

When dragging in, check "Copy items if needed" and "Add to targets: Clarity". The `Info.plist` already lists all the font filenames under `UIAppFonts`.

## Step 5: Create the 5 Extension Targets

For each extension below: **File > New > Target**, pick the type, set the product name and bundle ID, then replace the auto-generated code with the file from `Extensions/`.

| # | Target Type | Product Name | Bundle ID | Source File |
|---|------------|-------------|-----------|-------------|
| 1 | Shield Configuration Extension | ClarityShieldConfiguration | `com.clarity-focus.ShieldConfiguration` | `Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift` |
| 2 | Shield Action Extension | ClarityShieldAction | `com.clarity-focus.ShieldAction` | `Extensions/ShieldAction/ShieldActionExtension.swift` |
| 3 | Device Activity Monitor Extension | ClarityDeviceActivityMonitor | `com.clarity-focus.DeviceActivityMonitor` | `Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift` |
| 4 | Device Activity Report Extension | ClarityDeviceActivityReport | `com.clarity-focus.DeviceActivityReport` | `Extensions/DeviceActivityReport/DeviceActivityReportExtension.swift` |
| 5 | Widget Extension | ClarityWidget | `com.clarity-focus.Widget` | `Extensions/ClarityWidget/ClarityWidget.swift` |

**After creating each extension target:**
1. Go to target > **Signing & Capabilities**
2. Click **+ Capability** > **App Groups**
3. Add: `group.com.clarity-focus`

## Step 6: Signing & Entitlements

### Main App Target

1. Select **Clarity** target > **Signing & Capabilities**
2. Set your **Team**
3. Click **+ Capability** and add:
   - **Family Controls** (requires Apple approval — see below)
   - **App Groups** > add `group.com.clarity-focus`
   - **HealthKit**
   - **Access WiFi Information**
   - **In-App Purchase**
   - **Background Modes** > check "Background fetch" and "Background processing"
4. Verify the `Clarity.entitlements` file is set in Build Settings > Code Signing Entitlements

### Family Controls Approval

Apple restricts Family Controls. You need to:
1. Go to [developer.apple.com/account](https://developer.apple.com/account) > Certificates, Identifiers & Profiles > Identifiers
2. Select or create the `com.clarity-focus` App ID
3. Enable **Family Controls**
4. If it's not available, request access at [developer.apple.com/contact/family-controls](https://developer.apple.com/contact/family-controls/)
5. Create a Development Provisioning Profile that includes Family Controls
6. Download and install it (double-click), then select it in Xcode

## Step 7: StoreKit (Subscriptions)

For testing subscriptions locally without App Store Connect:

1. **File > New > File > StoreKit Configuration File**
2. Add two subscriptions in group "Clarity Pro":
   - `com.clarity-focus.monthly` — $4.99/month
   - `com.clarity-focus.yearly` — $39.99/year
3. In **Product > Scheme > Edit Scheme > Run > Options**, set the StoreKit Configuration to your file

## Step 8: Build & Run

### Simulator (limited — no Screen Time)

```bash
xcodebuild -scheme Clarity -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Or in Xcode: pick a simulator, hit Cmd+R. FamilyControls/ManagedSettings/DeviceActivity won't work, but the UI will render.

### Real Device (full features)

1. Plug in your iPhone or connect via WiFi
2. Select your device in Xcode
3. Cmd+R
4. Grant permissions when prompted (Screen Time, Contacts, Location, HealthKit, Notifications)

## Troubleshooting

**"Family Controls entitlement not found"** — You need Apple's approval. Submit a request and wait, or use a provisioning profile that already has it.

**"No such module 'FamilyControls'"** — Build for a real device, not the Simulator. These frameworks don't exist in Simulator.

**Fonts not rendering** — Check Build Phases > Copy Bundle Resources includes all `.ttf` files. Clean build (Cmd+Shift+K) and retry.

**"Clarity" folder conflict** — You tried to create the project inside `Clarity-iOS/`. Go back to Step 1 and create it on Desktop first.

## Reference: Bundle IDs

| Target | Bundle ID |
|--------|-----------|
| Main App | `com.clarity-focus` |
| Shield Configuration | `com.clarity-focus.ShieldConfiguration` |
| Shield Action | `com.clarity-focus.ShieldAction` |
| Device Activity Monitor | `com.clarity-focus.DeviceActivityMonitor` |
| Device Activity Report | `com.clarity-focus.DeviceActivityReport` |
| Widget | `com.clarity-focus.Widget` |
| App Group | `group.com.clarity-focus` |
| Monthly Sub | `com.clarity-focus.monthly` |
| Yearly Sub | `com.clarity-focus.yearly` |
| BG Task | `com.clarity-focus.dataCleanup` |
