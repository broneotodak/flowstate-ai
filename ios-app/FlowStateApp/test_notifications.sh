#!/bin/bash

# Add NotificationManager.swift to Xcode project
echo "🔔 Adding NotificationManager.swift to Xcode project..."

cd "/Users/broneotodak/Projects/flowstate-ai/ios-app/FlowStateApp"

# Check if the file exists
if [ ! -f "FlowStateApp/NotificationManager.swift" ]; then
    echo "❌ NotificationManager.swift not found!"
    exit 1
fi

echo "✅ NotificationManager.swift found"
echo "📝 Manual step needed:"
echo "   1. Open FlowStateApp.xcodeproj in Xcode"
echo "   2. Right-click 'FlowStateApp' folder in project navigator" 
echo "   3. Select 'Add Files to FlowStateApp'"
echo "   4. Choose NotificationManager.swift"
echo "   5. Build and test on your device"

echo ""
echo "🧪 TEST NOTIFICATIONS:"
echo "   1. Enable 'Memory Notifications' in Settings"
echo "   2. Allow notification permissions when prompted"
echo "   3. Wait for auto-refresh (30 seconds) or pull to refresh"
echo "   4. You should see notifications when:"
echo "      • New activities are detected"
echo "      • Current project changes"
echo "      • Memory updates occur"

echo ""
echo "🎯 NOTIFICATION TYPES:"
echo "   🌊 'New Flow State Activity' - when new activities detected"
echo "   🎯 'Project Switch Detected' - when switching projects"
echo "   🔄 'FlowState Memory Updated' - when data refreshes"

echo ""
echo "✅ Notification system ready to test!"
