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

echo "[1/4] Checking for XcodeGen..."

# Step 2: Install XcodeGen if needed
if ! command -v xcodegen &> /dev/null; then
    echo "       XcodeGen not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "ERROR: Homebrew is not installed."
        echo "Install it first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    brew install xcodegen
else
    echo "       XcodeGen found."
fi

# Step 3: Download fonts if not present
echo "[2/4] Checking fonts..."
FONT_DIR="Clarity/Fonts"
mkdir -p "$FONT_DIR"

if [ ! -f "$FONT_DIR/PlayfairDisplay-Regular.ttf" ]; then
    echo "       Downloading Playfair Display..."
    curl -sL "https://fonts.google.com/download?family=Playfair+Display" -o /tmp/playfair.zip
    unzip -qo /tmp/playfair.zip -d /tmp/playfair
    cp /tmp/playfair/static/PlayfairDisplay-Regular.ttf "$FONT_DIR/"
    cp /tmp/playfair/static/PlayfairDisplay-Italic.ttf "$FONT_DIR/"
    cp /tmp/playfair/static/PlayfairDisplay-SemiBoldItalic.ttf "$FONT_DIR/"
    rm -rf /tmp/playfair /tmp/playfair.zip
    echo "       Playfair Display downloaded."
else
    echo "       Playfair Display already present."
fi

if [ ! -f "$FONT_DIR/Outfit-Regular.ttf" ]; then
    echo "       Downloading Outfit..."
    curl -sL "https://fonts.google.com/download?family=Outfit" -o /tmp/outfit.zip
    unzip -qo /tmp/outfit.zip -d /tmp/outfit
    cp /tmp/outfit/static/Outfit-Thin.ttf "$FONT_DIR/"
    cp /tmp/outfit/static/Outfit-ExtraLight.ttf "$FONT_DIR/"
    cp /tmp/outfit/static/Outfit-Light.ttf "$FONT_DIR/"
    cp /tmp/outfit/static/Outfit-Regular.ttf "$FONT_DIR/"
    cp /tmp/outfit/static/Outfit-Medium.ttf "$FONT_DIR/"
    cp /tmp/outfit/static/Outfit-SemiBold.ttf "$FONT_DIR/"
    rm -rf /tmp/outfit /tmp/outfit.zip
    echo "       Outfit downloaded."
else
    echo "       Outfit already present."
fi

if [ ! -f "$FONT_DIR/SpaceMono-Regular.ttf" ]; then
    echo "       Downloading Space Mono..."
    curl -sL "https://fonts.google.com/download?family=Space+Mono" -o /tmp/spacemono.zip
    unzip -qo /tmp/spacemono.zip -d /tmp/spacemono
    cp /tmp/spacemono/static/SpaceMono-Regular.ttf "$FONT_DIR/" 2>/dev/null || cp /tmp/spacemono/SpaceMono-Regular.ttf "$FONT_DIR/"
    rm -rf /tmp/spacemono /tmp/spacemono.zip
    echo "       Space Mono downloaded."
else
    echo "       Space Mono already present."
fi

# Step 4: Generate Xcode project
echo "[3/4] Generating Xcode project..."
xcodegen generate

echo "[4/4] Done!"
echo ""
echo "==================================="
echo "  Project generated successfully!"
echo "==================================="
echo ""
echo "Next steps:"
echo "  1. Open:  open Clarity.xcodeproj"
echo "  2. Set your Team on ALL 6 targets (Clarity + 5 extensions)"
echo "  3. You may need a manual provisioning profile for Family Controls"
echo "  4. Cmd+B to build"
echo ""
