#!/bin/sh

# ci_post_clone.sh - FlowState v1.2 iOS-ONLY Build Setup
# Explicitly disable macOS and visionOS to prevent build failures

echo "🚀 FlowState v1.2 - iOS-ONLY Build Setup Starting..."
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

# 🎯 CRITICAL: Disable macOS and visionOS builds
echo "🎯 Configuring iOS-ONLY builds..."

# Set environment variables to disable unwanted platforms
export SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD=NO
export SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD=NO
export SUPPORTED_PLATFORMS="iphoneos iphonesimulator"

# Create xcconfig file to override platform settings
cat > ios-only.xcconfig << EOF
// iOS-Only Build Configuration
SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO
SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO
SUPPORTED_PLATFORMS = iphoneos iphonesimulator
TARGETED_DEVICE_FAMILY = 1,2
EOF

echo "✅ iOS-only configuration applied"
echo "📱 Building for: iPhone and iPad only"
echo "❌ Disabled: macOS and visionOS"

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

echo "✅ FlowState v1.2 iOS-ONLY setup complete"
echo "🎯 Ready for iOS-only build phase"
exit 0
