#!/bin/bash

# FlowState AI v1.2 Build and Test Script
echo "🚀 Building FlowState AI v1.2 with memory sync fix..."

cd /Users/broneotodak/Projects/flowstate-ai/ios-app/FlowStateApp

# Check if Xcode project exists
if [ ! -d "FlowStateApp.xcodeproj" ]; then
    echo "❌ Xcode project not found!"
    exit 1
fi

echo "📁 Xcode project found"

# Open in Xcode for building
echo "🔨 Opening in Xcode..."
echo "   Next steps:"
echo "   1. Build the project (⌘+B)"
echo "   2. Run on device/simulator (⌘+R)"
echo "   3. Check console for 'FlowState: Decoded X activities' message"
echo "   4. Verify activities are now displaying in the app"

echo ""
echo "🎯 Expected results:"
echo "   - Console: 'FlowState: Decoded 31 activities' (or similar)"
echo "   - App: Activities and projects now visible"
echo "   - Memory sync: Real-time display working"

echo ""
echo "📋 Testing checklist:"
echo "   □ Activities view shows recent entries"
echo "   □ Projects section populated"
echo "   □ Stats showing today/week counts"
echo "   □ Auto-refresh working (30s interval)"
echo "   □ No more empty arrays in console"

# Open Xcode
open FlowStateApp.xcodeproj

echo "✅ Xcode opened. Ready for v1.2 build and testing!"
