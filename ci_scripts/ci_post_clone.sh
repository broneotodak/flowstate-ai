#!/bin/sh

# ci_post_clone.sh for FlowState iOS App
# This script runs after Xcode Cloud clones the repository

set -e

echo "🔧 Xcode Cloud: Setting up FlowState v1.2 build environment..."

# Print current location and available files
echo "📍 Repository root: $(pwd)"
echo "📁 Repository contents:"
ls -la

# Check if iOS app directory exists
if [ -d "ios-app/FlowStateApp" ]; then
    echo "✅ Found iOS app directory"
    cd ios-app/FlowStateApp
    echo "📱 iOS app directory contents:"
    ls -la
    
    # Verify Xcode project exists
    if [ -f "FlowStateApp.xcodeproj/project.pbxproj" ]; then
        echo "✅ Xcode project found"
    else
        echo "❌ Error: Xcode project not found"
        exit 1
    fi
    
    # Check for shared schemes
    if [ -d "FlowStateApp.xcodeproj/xcshareddata/xcschemes" ]; then
        echo "✅ Shared schemes found"
        ls -la FlowStateApp.xcodeproj/xcshareddata/xcschemes/
    else
        echo "⚠️ Warning: No shared schemes found"
    fi
    
else
    echo "❌ Error: iOS app directory not found"
    exit 1
fi

echo "🎯 Build configuration:"
echo "   - Version: 1.2"
echo "   - Build: 6"
echo "   - Bundle ID: com.neotodaksts.FlowStateApp"
echo "   - Team ID: YG4N678CT6"

echo "✅ Xcode Cloud setup completed successfully!"
echo "🚀 Ready to build FlowState v1.2 for App Store"
