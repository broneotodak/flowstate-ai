#!/bin/bash

# ci_post_clone.sh
# This script runs after Xcode Cloud clones your repository
# Use this for any setup needed before building

set -e

echo "🚀 FlowState App - Post Clone Setup (v1.1)"
echo "Current directory: $(pwd)"
echo "Branch: $(git branch --show-current 2>/dev/null || echo 'main')"
echo "Available files:"
ls -la

# Check Xcode version
echo "📱 Xcode version:"
xcodebuild -version

# Check available simulators
echo "📱 Available iOS Simulators:"
xcrun simctl list devices iOS | head -20

# Verify project structure
echo "📁 Project structure:"
find . -name "*.xcodeproj" -o -name "*.xcworkspace"

# Any additional setup can go here
# For example:
# - Installing dependencies via CocoaPods or SPM
# - Setting up environment variables
# - Configuring certificates (if needed)

echo "✅ Post-clone setup completed successfully!"
echo "🎯 Ready to build FlowState App!"
