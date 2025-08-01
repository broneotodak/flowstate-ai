#!/bin/sh
echo "FlowState v1.2 - iOS ONLY build setup"
echo "Working directory: $(pwd)"
echo "Build timestamp: $(date)"

# Simple validation
if [ -f "FlowStateApp.xcodeproj/project.pbxproj" ]; then
    echo "SUCCESS: iOS project found"
elif [ -d "ios-app/FlowStateApp" ]; then
    cd ios-app/FlowStateApp
    echo "SUCCESS: Navigated to iOS project"
else
    echo "ERROR: Cannot find iOS project"
    exit 1
fi

echo "FlowState v1.2 iOS-only setup complete"
exit 0
