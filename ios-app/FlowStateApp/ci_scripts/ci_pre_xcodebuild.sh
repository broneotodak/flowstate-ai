#!/bin/sh

# ci_pre_xcodebuild.sh - Pre-build optimizations for Xcode Cloud

echo "⚡ Pre-xcodebuild: FlowState v1.2 optimizations"
echo "Current directory: $(pwd)"
echo "Build configuration: ${CONFIGURATION:-Release}"
echo "Platform: ${PLATFORM_NAME:-iOS}"

# Ensure we're building iOS only
if [ "$PLATFORM_NAME" != "iphoneos" ] && [ "$PLATFORM_NAME" != "iphonesimulator" ]; then
    echo "⚠️  Warning: Unexpected platform: $PLATFORM_NAME"
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

echo "✅ Pre-build setup complete"
exit 0
