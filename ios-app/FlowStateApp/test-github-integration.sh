#!/bin/bash

# Test script for GitHub API integration
echo "🧪 Testing FlowState GitHub Integration"
echo "======================================"

cd /Users/broneotodak/Projects/flowstate-ai/ios-app/FlowStateApp

echo "📁 Checking file structure..."
echo "✅ GitHubService.swift exists: $([ -f FlowStateApp/Services/GitHubService.swift ] && echo "YES" || echo "NO")"
echo "✅ GitHubSettingsView.swift exists: $([ -f FlowStateApp/Views/GitHubSettingsView.swift ] && echo "YES" || echo "NO")"

echo ""
echo "🔍 Checking imports and dependencies..."
echo "FlowStateViewModel imports:"
grep -n "import" FlowStateApp/FlowStateViewModel.swift | head -5

echo ""
echo "GitHubService class structure:"
grep -n "class GitHubService\|func fetch\|func validate" FlowStateApp/Services/GitHubService.swift

echo ""
echo "🏗️ Testing build..."
xcodebuild -project FlowStateApp.xcodeproj -scheme FlowStateApp -destination 'platform=macOS' build -quiet > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded - GitHub integration ready!"
else
    echo "❌ Build failed - checking errors..."
    xcodebuild -project FlowStateApp.xcodeproj -scheme FlowStateApp build 2>&1 | grep -A 2 -B 2 "error:" | head -10
fi

echo ""
echo "📋 Next Steps:"
echo "1. Add GitHub token in Settings → GitHub Integration"
echo "2. Test connection to verify API access"
echo "3. Check dashboard for real commit data"
