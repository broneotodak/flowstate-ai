#!/bin/sh

# ci_post_clone.sh - FlowState v1.2 Build Setup
# Simplified and robust for Xcode Cloud

echo "🚀 FlowState v1.2 - Build Setup Starting..."
echo "Build timestamp: $(date)"
echo "Working directory: $(pwd)"

# Navigate to project directory
cd ..
echo "Navigated to project directory: $(pwd)"

# Verify project structure
if [ -f "FlowStateApp.xcodeproj/project.pbxproj" ]; then
    echo "✅ SUCCESS: iOS project found"
else
    echo "❌ ERROR: Cannot find iOS project"
    echo "Current directory contents:"
    ls -la
    exit 1
fi

# Clean previous builds (with error handling)
echo "🧹 Cleaning previous builds..."
rm -rf build/ 2>/dev/null || true
rm -rf DerivedData/ 2>/dev/null || true
xcodebuild clean -project FlowStateApp.xcodeproj -scheme FlowStateApp 2>/dev/null || true

# Set iOS-focused build environment
echo "🎯 Configuring for iOS builds..."
export SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD=NO
export SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD=NO
export SUPPORTED_PLATFORMS="iphoneos iphonesimulator"

# Verify essential files
echo "📋 Verifying essential files..."
if [ -f "FlowStateApp/FlowStateAppApp.swift" ]; then
    echo "✅ Main app file found"
else
    echo "⚠️  Main app file not found, but continuing..."
fi

if [ -f "FlowStateApp/Assets.xcassets/AppIcon.appiconset/Contents.json" ]; then
    echo "✅ App icons configured"
else
    echo "⚠️  App icons not found, but continuing..."
fi

echo "✅ FlowState v1.2 setup complete"
echo "🎯 Ready for build phase"
exit 0
