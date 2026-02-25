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

# Step 3: Download fonts if not present (non-fatal — fonts are optional)
echo "[2/4] Checking fonts..."
FONT_DIR="Clarity/Fonts"
mkdir -p "$FONT_DIR"

# Use direct GitHub raw URLs for Google Fonts (reliable in CI)
download_font_file() {
    local name="$1"
    local url="$2"

    if [ -f "$FONT_DIR/$name" ]; then
        return 0
    fi

    if curl --max-time 15 -fsSL "$url" -o "$FONT_DIR/$name" 2>/dev/null; then
        echo "       Downloaded $name"
    else
        echo "       WARNING: Could not download $name"
        rm -f "$FONT_DIR/$name"
    fi
}

# Playfair Display
echo "       Fetching Playfair Display..."
download_font_file "PlayfairDisplay-Regular.ttf" "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/static/PlayfairDisplay-Regular.ttf"
download_font_file "PlayfairDisplay-Italic.ttf" "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/static/PlayfairDisplay-Italic.ttf"
download_font_file "PlayfairDisplay-SemiBoldItalic.ttf" "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/static/PlayfairDisplay-SemiBoldItalic.ttf"

# Outfit
echo "       Fetching Outfit..."
download_font_file "Outfit-Thin.ttf" "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Thin.ttf"
download_font_file "Outfit-ExtraLight.ttf" "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-ExtraLight.ttf"
download_font_file "Outfit-Light.ttf" "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Light.ttf"
download_font_file "Outfit-Regular.ttf" "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Regular.ttf"
download_font_file "Outfit-Medium.ttf" "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Medium.ttf"
download_font_file "Outfit-SemiBold.ttf" "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-SemiBold.ttf"

# Space Mono
echo "       Fetching Space Mono..."
download_font_file "SpaceMono-Regular.ttf" "https://github.com/google/fonts/raw/main/ofl/spacemono/SpaceMono-Regular.ttf"

FONT_COUNT=$(find "$FONT_DIR" -name "*.ttf" 2>/dev/null | wc -l | tr -d ' ')
echo "       Total: $FONT_COUNT font files"

# Step 4: Generate Xcode project
echo "[3/4] Generating Xcode project..."
# Strip Windows CRLF line endings (project edited on Windows)
if command -v sed &> /dev/null; then
    sed -i '' 's/\r$//' project.yml
fi
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
