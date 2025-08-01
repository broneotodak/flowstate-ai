#!/bin/bash

# Build #19 - FINAL iOS-ONLY FIX
# Removes ALL macOS references that were causing multi-platform builds

set -e

echo "🎯 Build #19 - FINAL iOS-ONLY FIX"
echo "================================"

cd /Users/broneotodak/Projects/flowstate-ai

echo "📊 Git Status:"
git status --short

echo "📝 Staging FINAL iOS-only fixes..."
git add ios-app/FlowStateApp/FlowStateApp.xcodeproj/project.pbxproj
git add ios-app/FlowStateApp/ci_scripts/ci_post_clone.sh

echo "💾 Committing..."
git commit -m "🎯 Build #19 - FINAL iOS-only fix - Remove ALL macOS references

ROOT CAUSE FOUND AND FIXED:
❌ MACOSX_DEPLOYMENT_TARGET = 15.5 was still present (6 occurrences)
❌ This told Xcode Cloud the project supports macOS
❌ Caused automatic multi-platform builds (iOS + macOS + visionOS)

FIXES APPLIED:
✅ REMOVED all MACOSX_DEPLOYMENT_TARGET references
✅ Fixed ci_post_clone.sh directory navigation (cd .. to find .xcodeproj)
✅ Now TRULY iOS-only configuration

PREVIOUS ATTEMPTS:
- Build #16: Fixed ci script (passed)
- Build #17: Fixed SUPPORTED_PLATFORMS (still had macOS refs)
- Build #18: Nuclear approach (still had macOS refs)
- Build #19: REMOVED macOS deployment targets (should work!)

EXPECTED RESULT:
- Should show ONLY 'Archive - iOS' (no macOS/visionOS)
- ci_post_clone.sh should find project correctly
- Clean iOS-only build and archive

FlowState v1.2 (Build 6) - iOS App Store ready"

echo "🚀 Pushing..."
git push origin main

echo ""
echo "✅ Build #19 - FINAL iOS-only fix deployed!"
echo ""
echo "🎯 This should FINALLY work because:"
echo "✅ Removed ALL macOS deployment targets"
echo "✅ Fixed script directory navigation"
echo "✅ No more multi-platform confusion"
echo ""
echo "📱 ONLY iOS build should appear in Xcode Cloud!"