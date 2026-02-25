#!/bin/bash
set -e

echo ""
echo "==================================="
echo "  Clarity iOS — Project Setup"
echo "==================================="
echo ""

cd "$(dirname "$0")"

# Step 1: Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: Xcode is not installed."
    exit 1
fi

echo "[1/5] Checking for XcodeGen..."
if ! command -v xcodegen &> /dev/null; then
    brew install xcodegen
else
    echo "       XcodeGen found."
fi

# Step 2: Download fonts (non-fatal)
echo "[2/5] Checking fonts..."
FONT_DIR="Clarity/Fonts"
mkdir -p "$FONT_DIR"
curl --max-time 15 -fsSL "https://github.com/google/fonts/raw/main/ofl/spacemono/SpaceMono-Regular.ttf" -o "$FONT_DIR/SpaceMono-Regular.ttf" 2>/dev/null || true
curl --max-time 15 -fsSL "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Regular.ttf" -o "$FONT_DIR/Outfit-Regular.ttf" 2>/dev/null || true
curl --max-time 15 -fsSL "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Medium.ttf" -o "$FONT_DIR/Outfit-Medium.ttf" 2>/dev/null || true
curl --max-time 15 -fsSL "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-SemiBold.ttf" -o "$FONT_DIR/Outfit-SemiBold.ttf" 2>/dev/null || true
curl --max-time 15 -fsSL "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Light.ttf" -o "$FONT_DIR/Outfit-Light.ttf" 2>/dev/null || true
curl --max-time 15 -fsSL "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/static/PlayfairDisplay-Regular.ttf" -o "$FONT_DIR/PlayfairDisplay-Regular.ttf" 2>/dev/null || true
echo "       Done"

# Step 3: Generate extension entitlements
echo "[3/5] Generating entitlements..."
for ext in ShieldConfiguration ShieldAction DeviceActivityMonitor DeviceActivityReport; do
cat > "Clarity/Extensions/$ext/$ext.entitlements" << 'ENTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.clarity-focus</string>
    </array>
    <key>com.apple.developer.family-controls</key>
    <true/>
</dict>
</plist>
ENTEOF
done

cat > "Clarity/Extensions/ClarityWidget/ClarityWidget.entitlements" << 'ENTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.clarity-focus</string>
    </array>
</dict>
</plist>
ENTEOF
echo "       Done"

# Step 4: Generate clean project.yml (avoids Windows CRLF issues)
echo "[4/5] Generating Xcode project..."
cat > project.yml << 'YMLEOF'
name: Clarity
options:
  bundleIdPrefix: com.clarity-focus
  deploymentTarget:
    iOS: "17.0"
  generateEmptyDirectories: false
  groupSortPosition: top

settings:
  base:
    INFOPLIST_FILE: Clarity/Info.plist
    CODE_SIGN_ENTITLEMENTS: Clarity/Clarity.entitlements
    SUPPORTED_INTERFACE_ORIENTATIONS: UIInterfaceOrientationPortrait
    SWIFT_VERSION: "5.9"

targets:

  Clarity:
    type: application
    platform: iOS
    sources:
      - path: Clarity
        excludes:
          - "Extensions/**"
          - "Fonts/**"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.clarity-focus
        INFOPLIST_FILE: Clarity/Info.plist
        CODE_SIGN_ENTITLEMENTS: Clarity/Clarity.entitlements
        DEVELOPMENT_TEAM: ${DEVELOPMENT_TEAM}
    dependencies:
      - target: ClarityShieldConfiguration
      - target: ClarityShieldAction
      - target: ClarityDeviceActivityMonitor
      - target: ClarityDeviceActivityReport
      - target: ClarityWidget

  ClarityShieldConfiguration:
    type: app-extension
    platform: iOS
    sources:
      - path: Clarity/Extensions/ShieldConfiguration
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.clarity-focus.ShieldConfiguration
        CODE_SIGN_ENTITLEMENTS: Clarity/Extensions/ShieldConfiguration/ShieldConfiguration.entitlements
        DEVELOPMENT_TEAM: ${DEVELOPMENT_TEAM}
    info:
      properties:
        CFBundleDisplayName: ClarityShieldConfiguration
        NSExtension:
          NSExtensionPointIdentifier: com.apple.ManagedSettingsUI.shield-configuration
          NSExtensionPrincipalClass: $(PRODUCT_MODULE_NAME).ClarityShieldConfiguration

  ClarityShieldAction:
    type: app-extension
    platform: iOS
    sources:
      - path: Clarity/Extensions/ShieldAction
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.clarity-focus.ShieldAction
        CODE_SIGN_ENTITLEMENTS: Clarity/Extensions/ShieldAction/ShieldAction.entitlements
        DEVELOPMENT_TEAM: ${DEVELOPMENT_TEAM}
    info:
      properties:
        CFBundleDisplayName: ClarityShieldAction
        NSExtension:
          NSExtensionPointIdentifier: com.apple.ManagedSettings.shield-action
          NSExtensionPrincipalClass: $(PRODUCT_MODULE_NAME).ClarityShieldAction

  ClarityDeviceActivityMonitor:
    type: app-extension
    platform: iOS
    sources:
      - path: Clarity/Extensions/DeviceActivityMonitor
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.clarity-focus.DeviceActivityMonitor
        CODE_SIGN_ENTITLEMENTS: Clarity/Extensions/DeviceActivityMonitor/DeviceActivityMonitor.entitlements
        DEVELOPMENT_TEAM: ${DEVELOPMENT_TEAM}
    info:
      properties:
        CFBundleDisplayName: ClarityDeviceActivityMonitor
        NSExtension:
          NSExtensionPointIdentifier: com.apple.DeviceActivity.monitor
          NSExtensionPrincipalClass: $(PRODUCT_MODULE_NAME).ClarityMonitorExtension

  ClarityDeviceActivityReport:
    type: app-extension
    platform: iOS
    sources:
      - path: Clarity/Extensions/DeviceActivityReport
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.clarity-focus.DeviceActivityReport
        CODE_SIGN_ENTITLEMENTS: Clarity/Extensions/DeviceActivityReport/DeviceActivityReport.entitlements
        DEVELOPMENT_TEAM: ${DEVELOPMENT_TEAM}
    info:
      properties:
        CFBundleDisplayName: ClarityDeviceActivityReport
        NSExtension:
          NSExtensionPointIdentifier: com.apple.DeviceActivity.report
          NSExtensionPrincipalClass: $(PRODUCT_MODULE_NAME).ClarityDeviceActivityReport

  ClarityWidget:
    type: app-extension
    platform: iOS
    sources:
      - path: Clarity/Extensions/ClarityWidget
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.clarity-focus.Widget
        CODE_SIGN_ENTITLEMENTS: Clarity/Extensions/ClarityWidget/ClarityWidget.entitlements
        DEVELOPMENT_TEAM: ${DEVELOPMENT_TEAM}
    info:
      properties:
        CFBundleDisplayName: ClarityWidget
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension
YMLEOF

xcodegen generate

echo "[5/5] Done!"
echo "==================================="
echo "  Project generated successfully!"
echo "==================================="
