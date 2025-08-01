#!/bin/bash

# ci_pre_xcodebuild.sh
# This script runs before Xcode builds your app
# Use this for any pre-build configuration

set -e

echo "🔨 FlowState App - Pre-Build Setup"

# Set build number based on CI build number if available
if [ -n "$CI_BUILD_NUMBER" ]; then
    echo "📈 Setting build number to: $CI_BUILD_NUMBER"
    
    # Update build number in Info.plist
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "FlowStateApp/Info.plist" || true
fi

# Print current version info
echo "📱 Current app version info:"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "FlowStateApp/Info.plist" 2>/dev/null || echo "1.0.0")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "FlowStateApp/Info.plist" 2>/dev/null || echo "1")

echo "Version: $VERSION"
echo "Build: $BUILD"

echo "✅ Pre-build setup completed!"
