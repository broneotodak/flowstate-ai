#!/bin/sh

# ci_pre_xcodebuild.sh - Pre-build optimizations for iOS builds
# Simplified version to avoid Xcode Cloud environment issues

echo "⚡ Pre-xcodebuild: FlowState v1.2 setup"
echo "Current directory: $(pwd)"
echo "Build configuration: ${CONFIGURATION:-Release}"
echo "Platform: ${PLATFORM_NAME:-Unknown}"

# Set iOS-focused environment variables (non-blocking)
echo "🎯 Setting iOS build preferences..."
export SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD=NO
export SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD=NO
export SUPPORTED_PLATFORMS="iphoneos iphonesimulator"

# Set compiler optimizations for release builds
if [ "$CONFIGURATION" = "Release" ]; then
    echo "🔧 Applying Release optimizations..."
    export SWIFT_OPTIMIZATION_LEVEL="-O"
    export SWIFT_COMPILATION_MODE="wholemodule"
    export ENABLE_BITCODE="NO"
fi

# Clear potentially problematic caches (with error handling)
echo "🧹 Clearing build caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/FlowStateApp-* 2>/dev/null || true

# Log platform info for debugging (but don't fail)
echo "📊 Environment Info:"
echo "   PLATFORM_NAME: ${PLATFORM_NAME:-Not Set}"
echo "   CONFIGURATION: ${CONFIGURATION:-Not Set}"
echo "   SDK_NAME: ${SDK_NAME:-Not Set}"

echo "✅ Pre-build setup complete"
exit 0
