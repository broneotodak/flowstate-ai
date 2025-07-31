#!/bin/bash

# FlowState AI Screenshot Resizer for App Store Connect
# Usage: ./resize-screenshots.sh

echo "🚀 FlowState AI Screenshot Resizer"
echo "Creating iPad and iPhone 6.5\" versions..."

# Create output directories
mkdir -p resized-screenshots/ipad-13inch
mkdir -p resized-screenshots/iphone-6.5inch

# Function to resize image
resize_image() {
    local input_file="$1"
    local output_file="$2"
    local dimensions="$3"
    
    sips -z ${dimensions} "${input_file}" --out "${output_file}"
    echo "✅ Created: ${output_file}"
}

# Check if ImageMagick is available, if not use sips
if command -v convert &> /dev/null; then
    echo "Using ImageMagick for better quality..."
    RESIZE_CMD="convert"
else
    echo "Using sips (built-in Mac tool)..."
    RESIZE_CMD="sips"
fi

echo "
📋 Instructions:
1. Save your 4 screenshots in this folder as:
   - screenshot1.png (Dashboard)
   - screenshot2.png (Activities) 
   - screenshot3.png (Statistics)
   - screenshot4.png (Settings)

2. Run this script: ./resize-screenshots.sh

3. Upload from resized-screenshots/ folders to App Store Connect
"

# Check if screenshots exist
if [ ! -f "screenshot1.png" ]; then
    echo "❌ Please add your screenshots as screenshot1.png, screenshot2.png, etc."
    exit 1
fi

# Resize for iPad 13-inch (2064 x 2752)
for i in {1..4}; do
    if [ -f "screenshot${i}.png" ]; then
        resize_image "screenshot${i}.png" "resized-screenshots/ipad-13inch/screenshot${i}.png" "2752 2064"
    fi
done

# Resize for iPhone 6.5" (1284 x 2778) 
for i in {1..4}; do
    if [ -f "screenshot${i}.png" ]; then
        resize_image "screenshot${i}.png" "resized-screenshots/iphone-6.5inch/screenshot${i}.png" "2778 1284"
    fi
done

echo "
🎉 Conversion Complete!

📁 Resized screenshots saved in:
   - resized-screenshots/ipad-13inch/
   - resized-screenshots/iphone-6.5inch/

📤 Upload these to App Store Connect:
   1. Go to Previews and Screenshots
   2. Select iPad tab → Upload iPad screenshots
   3. iPhone tab → Replace with 6.5\" versions if needed

✅ Ready for App Store submission!
"