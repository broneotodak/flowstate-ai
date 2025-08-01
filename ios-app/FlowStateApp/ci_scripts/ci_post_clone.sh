#!/bin/sh

# ci_post_clone.sh - FIXED directory navigation
# Working directory: /Volumes/workspace/repository/ios-app/FlowStateApp/ci_scripts
# Need to go up one level to find the .xcodeproj

echo "FlowState v1.2 - iOS ONLY build setup"
echo "Working directory: $(pwd)"
echo "Build timestamp: $(date)"

# Navigate up one level to the project directory
cd ..
echo "Navigated to project directory: $(pwd)"

# Now check for the iOS project
if [ -f "FlowStateApp.xcodeproj/project.pbxproj" ]; then
    echo "SUCCESS: iOS project found"
else
    echo "ERROR: Still cannot find iOS project"
    echo "Current directory contents:"
    ls -la
    exit 1
fi

echo "FlowState v1.2 iOS-only setup complete"
exit 0