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
    echo "Install it from the Mac App Store first."
    exit 1
fi

echo "[1/5] Checking for XcodeGen..."

# Step 2: Install XcodeGen if needed
if ! command -v xcodegen &> /dev/null; then
    echo "       XcodeGen not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "ERROR: Homebrew is not installed."
        exit 1
    fi
    brew install xcodegen
else
    echo "       XcodeGen found."
fi

# Step 3: Download fonts (non-fatal)
echo "[2/5] Checking fonts..."
FONT_DIR="Clarity/Fonts"
mkdir -p "$FONT_DIR"

download_font_file() {
    local name="$1"
    local url="$2"
    [ -f "$FONT_DIR/$name" ] && return 0
    curl --max-time 15 -fsSL "$url" -o "$FONT_DIR/$name" 2>/dev/null || rm -f "$FONT_DIR/$name"
}

download_font_file "SpaceMono-Regular.ttf" "https://github.com/google/fonts/raw/main/ofl/spacemono/SpaceMono-Regular.ttf"
download_font_file "PlayfairDisplay-Regular.ttf" "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/static/PlayfairDisplay-Regular.ttf"
download_font_file "Outfit-Regular.ttf" "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Regular.ttf"
download_font_file "Outfit-Medium.ttf" "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Medium.ttf"
download_font_file "Outfit-SemiBold.ttf" "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-SemiBold.ttf"
download_font_file "Outfit-Light.ttf" "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Light.ttf"

FONT_COUNT=$(find "$FONT_DIR" -name "*.ttf" 2>/dev/null | wc -l | tr -d ' ')
echo "       $FONT_COUNT font files ready"

# Step 4: Generate extension entitlements
echo "[3/5] Generating entitlements..."

FAMILY_ENT='<?xml version="1.0" encoding="UTF-8"?>
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
</plist>'

GROUP_ENT='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.clarity-focus</string>
    </array>
</dict>
</plist>'

for ext in ShieldConfiguration ShieldAction DeviceActivityMonitor DeviceActivityReport; do
    echo "$FAMILY_ENT" > "Clarity/Extensions/$ext/$ext.entitlements"
done
echo "$GROUP_ENT" > "Clarity/Extensions/ClarityWidget/ClarityWidget.entitlements"
echo "       5 entitlements files created"

# Step 5: Generate Xcode project
echo "[4/5] Generating Xcode project..."
# Strip Windows CRLF
sed -i '' 's/\r$//' project.yml 2>/dev/null || true
xcodegen generate

echo "[5/5] Done!"
echo ""
echo "==================================="
echo "  Project generated successfully!"
echo "==================================="
echo ""
