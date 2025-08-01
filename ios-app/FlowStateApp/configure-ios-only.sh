#!/bin/bash

# Configure FlowState App for iOS-Only Builds
# This script removes macOS and visionOS support to prevent Xcode Cloud failures

set -e

echo "🔧 Configuring FlowState App for iOS-Only Builds..."

cd /Users/broneotodak/Projects/flowstate-ai/ios-app/FlowStateApp

# Backup current project settings
echo "📋 Creating backup of project settings..."
cp -r FlowStateApp.xcodeproj/project.pbxproj FlowStateApp.xcodeproj/project.pbxproj.backup

echo "🎯 Applying iOS-only configuration..."

# Use xcodebuild to set specific build settings for iOS-only
xcodebuild -project FlowStateApp.xcodeproj \
  -target FlowStateApp \
  -configuration Debug \
  SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD=NO \
  SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD=NO \
  SUPPORTED_PLATFORMS="iphoneos iphonesimulator" \
  -showBuildSettings > /dev/null

xcodebuild -project FlowStateApp.xcodeproj \
  -target FlowStateApp \
  -configuration Release \
  SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD=NO \
  SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD=NO \
  SUPPORTED_PLATFORMS="iphoneos iphonesimulator" \
  -showBuildSettings > /dev/null

echo "✅ iOS-only configuration applied!"

# Verify the changes
echo "🔍 Verifying configuration..."
SUPPORTS_MAC=$(xcodebuild -showBuildSettings -scheme FlowStateApp | grep "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD" | head -1 | awk '{print $3}')
SUPPORTS_XR=$(xcodebuild -showBuildSettings -scheme FlowStateApp | grep "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD" | head -1 | awk '{print $3}')

echo "📊 Current Settings:"
echo "   SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = $SUPPORTS_MAC"
echo "   SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = $SUPPORTS_XR"

if [ "$SUPPORTS_MAC" = "NO" ] && [ "$SUPPORTS_XR" = "NO" ]; then
    echo "✅ SUCCESS: iOS-only configuration verified!"
    echo "🚀 Xcode Cloud should now build iOS only"
else
    echo "⚠️  Configuration may need manual adjustment in Xcode"
    echo "💡 Please check project settings in Xcode"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Test local build: xcodebuild -scheme FlowStateApp -destination 'platform=iOS Simulator,name=iPhone 16' build"
echo "2. Commit changes: git add -A && git commit -m 'Configure iOS-only builds - disable macOS/visionOS'"
echo "3. Push to trigger Xcode Cloud: git push origin main"
