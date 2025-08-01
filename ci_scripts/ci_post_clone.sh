#!/bin/sh

# ci_post_clone.sh for FlowState iOS App - Simple version
# This script runs after Xcode Cloud clones the repository

echo "Xcode Cloud: Setting up FlowState v1.2 build environment..."

# Simple environment check
echo "Current directory: $(pwd)"
echo "Available files:"
ls -la

# Basic validation - just check if the iOS project exists
if [ -f "ios-app/FlowStateApp/FlowStateApp.xcodeproj/project.pbxproj" ]; then
    echo "Xcode project found at ios-app/FlowStateApp/FlowStateApp.xcodeproj"
else
    echo "ERROR: Xcode project not found"
    echo "Looking for: ios-app/FlowStateApp/FlowStateApp.xcodeproj/project.pbxproj"
    exit 1
fi

echo "Build info: Version 1.2, Build 6"
echo "Xcode Cloud setup completed successfully"
echo "Ready to build FlowState v1.2"

exit 0
