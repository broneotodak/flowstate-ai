#!/bin/bash
# FlowState Icon Setup Script

echo "🌊 Setting up FlowState iOS App Icons"
echo "======================================"

# Navigate to project directory
cd /Users/broneotodak/Projects/flowstate-ai/ios-app/FlowStateApp

# Check if Pillow is installed
if ! python3 -c "import PIL" 2>/dev/null; then
    echo "📦 Installing Pillow for image processing..."
    pip3 install Pillow
else
    echo "✅ Pillow already installed"
fi

# Check if the downloaded icon exists
if [ -f "flowstate-icon-1-1024x1024.png" ]; then
    echo "🎨 Found Flow Waves icon, generating all sizes..."
    
    # Run the icon generator
    python3 generate_icons.py flowstate-icon-1-1024x1024.png \
        -o FlowStateApp/Assets.xcassets/AppIcon.appiconset \
        -p AppIcon
    
    echo ""
    echo "🚀 NEXT STEPS:"
    echo "1. Open Xcode (if not already open)"
    echo "2. Build your project (Cmd+B)"  
    echo "3. Your new Flow Waves icon will appear on your phone!"
    echo "4. Ready for App Store submission! 🎉"
    
else
    echo "❌ Please download the Flow Waves icon first:"
    echo "   1. Go back to the icon generator tool above"
    echo "   2. Click 'Generate 1024x1024' on the Flow Waves option"
    echo "   3. Save as 'flowstate-icon-1-1024x1024.png' in this directory"
    echo "   4. Run this script again"
fi
