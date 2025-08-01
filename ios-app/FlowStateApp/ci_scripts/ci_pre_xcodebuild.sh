#!/bin/sh

# ci_pre_xcodebuild.sh - Pre-build optimizations for iOS-ONLY builds

echo "⚡ Pre-xcodebuild: FlowState v1.2 iOS-ONLY optimizations"
echo "Current directory: $(pwd)"
echo "Build configuration: ${CONFIGURATION:-Release}"
echo "Platform: ${PLATFORM_NAME:-iOS}"

# 🚨 CRITICAL: Force iOS-only builds
echo "🎯 Enforcing iOS-ONLY build configuration..."

# Override any macOS/visionOS settings
export SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD=NO
export SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD=NO
export SUPPORTED_PLATFORMS="iphoneos iphonesimulator"
export TARGETED_DEVICE_FAMILY="1,2"

# Ensure we're building iOS only
if [ "$PLATFORM_NAME" != "iphoneos" ] && [ "$PLATFORM_NAME" != "iphonesimulator" ]; then
    echo "❌ ERROR: Attempting to build for unsupported platform: $PLATFORM_NAME"
    echo "✅ FlowState App only supports iOS (iPhone/iPad)"
    exit 1
fi

# Set compiler optimizations for release builds
if [ "$CONFIGURATION" = "Release" ]; then
    echo "🔧 Applying Release optimizations..."
    export SWIFT_OPTIMIZATION_LEVEL="-O"
    export SWIFT_COMPILATION_MODE="wholemodule"
    export ENABLE_BITCODE="NO"
fi

# Clear any cached build data that might cause issues
echo "🧹 Clearing potentially problematic caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/FlowStateApp-*/

# Apply iOS-only xcconfig if it exists
if [ -f "../ios-only.xcconfig" ]; then
    echo "✅ Applying iOS-only configuration"
    export XCODE_XCCONFIG_FILE="../ios-only.xcconfig"
fi

echo "✅ Pre-build setup complete - iOS-ONLY mode enforced"
echo "📱 Building for iOS (iPhone/iPad) only"
exit 0
