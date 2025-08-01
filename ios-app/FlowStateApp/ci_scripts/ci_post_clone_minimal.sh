#!/bin/sh

# ci_post_clone.sh for FlowState iOS App v1.2 - MINIMAL VERSION
# Xcode Cloud CI Script - Maximum compatibility
# This script runs after Xcode Cloud clones the repository

echo "=== Xcode Cloud Post-Clone Setup ==="
echo "FlowState v1.2 Build Environment Setup"
echo "Timestamp: $(date)"
echo "Current directory: $(pwd)"

# Simple directory check and navigation
if [ -f "FlowStateApp.xcodeproj/project.pbxproj" ]; then
    echo "SUCCESS: Found iOS project in current directory"
elif [ -d "ios-app/FlowStateApp" ]; then
    echo "SUCCESS: Found iOS project in nested structure"
    cd ios-app/FlowStateApp
    echo "Navigated to: $(pwd)"
    if [ -f "FlowStateApp.xcodeproj/project.pbxproj" ]; then
        echo "SUCCESS: iOS project verified"
    else
        echo "ERROR: iOS project not found after navigation"
        exit 1
    fi
else
    echo "ERROR: Could not locate iOS project"
    echo "Directory contents:"
    ls -la
    exit 1
fi

# Basic project verification
echo "=== Project Verification ==="
echo "Working directory: $(pwd)"
echo "Project files:"
ls -la *.xcodeproj/ 2>/dev/null || echo "No .xcodeproj directory listing available"

# Simple success message
echo "=== Setup Complete ==="
echo "FlowState v1.2 (Build 6) ready for build"
echo "Bundle ID: com.neotodaksts.FlowStateApp"
echo "Post-clone setup completed at: $(date)"

exit 0