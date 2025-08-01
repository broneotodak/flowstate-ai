#!/bin/sh

# ci_post_clone.sh for FlowState iOS App v1.2
# Xcode Cloud CI Script - Fixed for repository structure
# This script runs after Xcode Cloud clones the repository

set -e  # Exit on any error

echo "🚀 Xcode Cloud: Setting up FlowState v1.2 build environment..."
echo "📅 Build started at: $(date)"

# Debug: Show current environment
echo "📍 Current directory: $(pwd)"
echo "📂 Current directory contents:"
ls -la

# Check if we're in the iOS project directory or need to navigate
if [ -f "FlowStateApp.xcodeproj/project.pbxproj" ]; then
    echo "✅ Already in iOS project directory"
    PROJECT_ROOT="."
elif [ -f "ios-app/FlowStateApp/FlowStateApp.xcodeproj/project.pbxproj" ]; then
    echo "✅ Found iOS project from repository root"
    PROJECT_ROOT="ios-app/FlowStateApp"
    cd "$PROJECT_ROOT"
    echo "📍 Navigated to: $(pwd)"
else
    echo "❌ ERROR: Could not find FlowStateApp.xcodeproj"
    echo "📂 Available files:"
    ls -la
    echo "📂 Looking for ios-app directory:"
    if [ -d "ios-app" ]; then
        ls -la ios-app/
        if [ -d "ios-app/FlowStateApp" ]; then
            echo "📂 FlowStateApp directory contents:"
            ls -la ios-app/FlowStateApp/
        fi
    fi
    exit 1
fi

echo "📱 iOS project directory contents:"
ls -la

# Verify essential project files
ESSENTIAL_FILES=(
    "FlowStateApp.xcodeproj/project.pbxproj"
    "FlowStateApp.xcodeproj/xcshareddata/xcschemes/FlowStateApp.xcscheme"
    "FlowStateApp/ContentView.swift"
    "FlowStateApp/FlowStateViewModel.swift"
)

echo "🔍 Verifying essential project files:"
ALL_FILES_FOUND=true
for file in "${ESSENTIAL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "⚠️  WARNING: Essential file missing: $file"
        ALL_FILES_FOUND=false
    else
        echo "✅ Found: $file"
    fi
done

if [ "$ALL_FILES_FOUND" = false ]; then
    echo "⚠️  Some essential files are missing, but continuing..."
fi

# Display project info
echo ""
echo "📱 FlowState App Information:"
echo "   Version: 1.2"
echo "   Build: 6"
echo "   Bundle ID: com.neotodaksts.FlowStateApp"
echo "   Team ID: YG4N678CT6"
echo "   Target iOS: 18.5+"
echo "   Xcode Scheme: FlowStateApp"

# Check for dependencies
echo ""
echo "📦 Checking for dependencies:"
if [ -f "Package.swift" ]; then
    echo "📦 Swift Package Manager dependencies found"
elif [ -f "Podfile" ]; then
    echo "📦 CocoaPods dependencies found"
    echo "ℹ️  Note: If CocoaPods installation is needed, uncomment in script"
    # pod install
elif [ -f "Cartfile" ]; then
    echo "📦 Carthage dependencies found"
else
    echo "📦 No external dependencies detected (clean project)"
fi

# Final verification
echo ""
echo "🎯 Build Environment Verification:"
echo "📍 Working directory: $(pwd)"
echo "📂 Xcode project: $(ls *.xcodeproj 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "📋 Shared scheme: $(ls FlowStateApp.xcodeproj/xcshareddata/xcschemes/*.xcscheme 2>/dev/null | head -1 || echo 'NOT FOUND')"

# Success
echo ""
echo "✅ Post-clone setup completed successfully!"
echo "🎯 Ready to build FlowState v1.2 (Build 6)"
echo "⏰ Setup completed at: $(date)"
echo ""

exit 0