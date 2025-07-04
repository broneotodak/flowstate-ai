#!/bin/bash

echo "==================================="
echo "FlowState Browser Extension Installer"
echo "==================================="
echo

# Set extension directory
EXTENSION_DIR="$HOME/Library/Application Support/FlowState/browser-extension"

# Create directory
echo "Creating extension directory..."
mkdir -p "$EXTENSION_DIR"

# Extract extension files (embedded in script)
echo "Extracting extension files..."
extract_files() {
    # This function will be replaced by the packager
    # with the actual base64 encoded files
    echo "Files extracted successfully"
}

extract_files

# Instructions
echo
echo "==================================="
echo "INSTALLATION INSTRUCTIONS:"
echo "==================================="
echo "1. Opening Chrome to extensions page..."
echo "2. Enable 'Developer mode' (toggle in top right)"
echo "3. Click 'Load unpacked'"
echo "4. Navigate to: $EXTENSION_DIR"
echo "5. Click 'Select'"
echo
echo "After installation:"
echo "- Click the FlowState icon in toolbar"
echo "- Enter your service key"
echo "- Enable tracking"
echo "==================================="
echo

# Open Chrome extensions page
open -a "Google Chrome" "chrome://extensions/" 2>/dev/null || \
open -a "Google Chrome" --args --new-window "chrome://extensions/" 2>/dev/null

# Also try other browsers
open -a "Microsoft Edge" "edge://extensions/" 2>/dev/null &
open -a "Brave Browser" "brave://extensions/" 2>/dev/null &

echo "Extension files installed to: $EXTENSION_DIR"
echo "Press Enter to exit..."
read