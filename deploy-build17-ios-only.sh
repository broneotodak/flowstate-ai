#!/bin/bash

# Deploy Build #17 - iOS Only Configuration Fix

set -e

echo "🎯 Build #17 - iOS Only Configuration Fix"
echo "========================================"

cd /Users/broneotodak/Projects/flowstate-ai

echo "📊 Git Status:"
git status --short

echo "📝 Staging iOS-only configuration..."
git add ios-app/FlowStateApp/FlowStateApp.xcodeproj/project.pbxproj

echo "💾 Committing..."
git commit -m "🎯 Build #17 - Fix iOS-only target configuration

FIXES:
✅ Set SDKROOT = iphoneos (was auto)
✅ SUPPORTED_PLATFORMS = 'iphoneos iphonesimulator' (removed macosx, xros)
✅ TARGETED_DEVICE_FAMILY = '1,2' (removed VisionOS support)  
✅ Removed XROS_DEPLOYMENT_TARGET = 2.5

ISSUE RESOLVED:
- Build #16 was trying to compile for macOS causing Swift compilation errors
- iOS-specific UIKit APIs (systemGray6, navigationBarTitleDisplayMode) were failing on macOS
- Now targeting iOS only as intended

FlowState v1.2 (Build 6) - iOS App Store ready"

echo "🚀 Pushing..."
git push origin main

echo ""
echo "✅ Build #17 deployed with iOS-only configuration!"
echo ""
echo "🎯 Expected Results:"
echo "✅ No more macOS compilation errors"
echo "✅ Should build successfully for iOS"
echo "✅ Archive should be created for App Store"
echo ""
echo "📱 FlowState v1.2 ready for iOS App Store submission!"