#!/bin/sh

# ci_post_clone.sh - Repository Root Version
# FlowState iOS App v1.2 - Xcode Cloud CI Script
# This script handles nested iOS project structure

echo "=== Xcode Cloud Post-Clone Setup ==="
echo "FlowState v1.2 - Repository Root CI Script"
echo "Timestamp: $(date)"
echo "Current directory: $(pwd)"

# Show repository structure for debugging
echo "=== Repository Structure Debug ==="
echo "Repository root contents:"
ls -la

# Navigate to the iOS project
if [ -d "ios-app/FlowStateApp" ]; then
    echo "SUCCESS: Found iOS project directory"
    cd ios-app/FlowStateApp
    echo "Navigated to iOS project: $(pwd)"
    
    # Verify project structure
    if [ -f "FlowStateApp.xcodeproj/project.pbxproj" ]; then
        echo "SUCCESS: iOS project verified"
    else
        echo "ERROR: project.pbxproj not found"
        echo "iOS project directory contents:"
        ls -la
        exit 1
    fi
else
    echo "ERROR: ios-app/FlowStateApp directory not found"
    echo "Available directories:"
    ls -la
    exit 1
fi

# Basic project info
echo "=== Project Information ==="
echo "FlowState App v1.2 (Build 6)"
echo "Bundle ID: com.neotodaksts.FlowStateApp"
echo "Working directory: $(pwd)"

# Verify Xcode project files
echo "=== Project Files Verification ==="
if [ -f "FlowStateApp.xcodeproj/project.pbxproj" ]; then
    echo "FOUND: project.pbxproj"
else
    echo "MISSING: project.pbxproj"
fi

if [ -f "FlowStateApp.xcodeproj/xcshareddata/xcschemes/FlowStateApp.xcscheme" ]; then
    echo "FOUND: FlowStateApp.xcscheme"
else
    echo "MISSING: FlowStateApp.xcscheme"
fi

if [ -f "FlowStateApp/ContentView.swift" ]; then
    echo "FOUND: ContentView.swift"
else
    echo "MISSING: ContentView.swift"
fi

echo "=== Setup Complete ==="
echo "Ready to build FlowState v1.2"
echo "Setup completed at: $(date)"

exit 0