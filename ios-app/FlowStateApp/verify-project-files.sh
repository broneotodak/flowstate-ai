#!/bin/bash

# Verify FlowState App Project Files Integration
echo "🔍 Verifying FlowState App project file integration..."

PROJECT_PATH="/Users/broneotodak/Projects/flowstate-ai/ios-app/FlowStateApp"
PBXPROJ_PATH="$PROJECT_PATH/FlowStateApp.xcodeproj/project.pbxproj"

echo "📁 Project path: $PROJECT_PATH"
echo "📋 Checking project.pbxproj for GitHub integration files..."

# Check if files are referenced in project.pbxproj
echo ""
echo "🔍 Checking for GitHubService.swift..."
if grep -q "GitHubService.swift" "$PBXPROJ_PATH"; then
    echo "✅ GitHubService.swift is referenced in project"
else
    echo "❌ GitHubService.swift NOT found in project file"
fi

echo ""
echo "🔍 Checking for GitHubSettingsView.swift..."
if grep -q "GitHubSettingsView.swift" "$PBXPROJ_PATH"; then
    echo "✅ GitHubSettingsView.swift is referenced in project"
else
    echo "❌ GitHubSettingsView.swift NOT found in project file"
fi

echo ""
echo "📊 File existence check:"
ls -la "$PROJECT_PATH/FlowStateApp/Services/"
ls -la "$PROJECT_PATH/FlowStateApp/Views/" | grep -E "(GitHub|Git)"

echo ""
echo "🏗️ Build configuration check:"
echo "Current version info from Info.plist equivalent:"
plutil -p "$PROJECT_PATH/FlowStateApp/Assets.xcassets" 2>/dev/null || echo "No plist found in Assets"

echo ""
echo "🔧 If files are missing from project, you'll need to:"
echo "1. Open FlowStateApp.xcodeproj in Xcode"
echo "2. Right-click on appropriate folders"
echo "3. Add Files to 'FlowStateApp'"
echo "4. Select GitHubService.swift and GitHubSettingsView.swift"
echo "5. Ensure they're added to the FlowStateApp target"
