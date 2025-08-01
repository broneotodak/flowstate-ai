#!/bin/sh

# ci_post_clone.sh - FlowState v1.2 iOS Build Setup
# Optimized for Xcode Cloud reliability

echo "🚀 FlowState v1.2 - iOS Build Setup Starting..."
echo "Build timestamp: $(date)"
echo "Working directory: $(pwd)"
echo "Xcode version: $(xcodebuild -version)"

# Navigate to project directory
cd ..
echo "Navigated to project directory: $(pwd)"

# Verify project structure
if [ -f "FlowStateApp.xcodeproj/project.pbxproj" ]; then
    echo "✅ SUCCESS: iOS project found"
    echo "Project contents:"
    ls -la FlowStateApp.xcodeproj/
else
    echo "❌ ERROR: Cannot find iOS project"
    echo "Current directory contents:"
    ls -la
    exit 1
fi

# Clean previous builds to avoid conflicts
echo "🧹 Cleaning previous builds..."
rm -rf build/
rm -rf DerivedData/
xcodebuild clean -project FlowStateApp.xcodeproj -scheme FlowStateApp 2>/dev/null || true

# Verify essential files
echo "📋 Verifying essential files..."
if [ -f "FlowStateApp/FlowStateAppApp.swift" ]; then
    echo "✅ Main app file found"
else
    echo "❌ Main app file missing"
    exit 1
fi

if [ -f "FlowStateApp/Assets.xcassets/AppIcon.appiconset/Contents.json" ]; then
    echo "✅ App icons configured"
else
    echo "❌ App icons missing"
    exit 1
fi

# Set build environment
export XCODE_XCCONFIG_FILE=""
export SWIFT_OPTIMIZATION_LEVEL="-O"

echo "✅ FlowState v1.2 iOS-only setup complete"
echo "🎯 Ready for build phase"
exit 0
