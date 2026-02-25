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

download_font() {
    local family="$1"
    local url="$2"
    local dir="$3"
    local check_file="$4"

    if [ -f "$FONT_DIR/$check_file" ]; then
        echo "       $family already present."
        return 0
    fi

    echo "       Downloading $family..."
    if curl --max-time 30 -fSL "$url" -o "/tmp/$dir.zip" 2>/dev/null; then
        if unzip -qo "/tmp/$dir.zip" -d "/tmp/$dir" 2>/dev/null; then
            local count
            count=$(find "/tmp/$dir" -name "*.ttf" 2>/dev/null | wc -l)
            if [ "$count" -gt 0 ]; then
                find "/tmp/$dir" -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
                echo "       $family: copied $count font files."
            else
                echo "       WARNING: $family zip had no .ttf files"
            fi
        else
            echo "       WARNING: $family zip could not be unzipped"
        fi
        rm -rf "/tmp/$dir" "/tmp/$dir.zip"
    else
        echo "       WARNING: Could not download $family (skipping)"
    fi
}

download_font "Playfair Display" "https://fonts.google.com/download?family=Playfair+Display" "playfair" "PlayfairDisplay-Regular.ttf"
download_font "Outfit" "https://fonts.google.com/download?family=Outfit" "outfit" "Outfit-Regular.ttf"
download_font "Space Mono" "https://fonts.google.com/download?family=Space+Mono" "spacemono" "SpaceMono-Regular.ttf"

FONT_COUNT=$(find "$FONT_DIR" -name "*.ttf" 2>/dev/null | wc -l)
echo "       Total fonts: $FONT_COUNT files in $FONT_DIR"

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
