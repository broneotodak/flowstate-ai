#!/bin/bash

# Deploy Build #18 - Nuclear iOS-Only Fix

set -e

echo "🔥 Build #18 - Nuclear iOS-Only Fix"
echo "=================================="

cd /Users/broneotodak/Projects/flowstate-ai

echo "📊 Git Status:"
git status --short

echo "📝 Staging all iOS-only fixes..."
git add ios-app/FlowStateApp/ci_scripts/ci_post_clone.sh
git add ios-app/FlowStateApp/ci_scripts/ci_pre_xcodebuild.sh
git add ios-app/FlowStateApp/FlowStateApp.xcodeproj/xcshareddata/xcschemes/FlowStateApp.xcscheme

echo "💾 Committing..."
git commit -m "🔥 Build #18 - Nuclear iOS-only fix for Xcode Cloud

NUCLEAR APPROACH - Complete iOS-only reset:

FIXES APPLIED:
✅ Ultra-minimal ci_post_clone.sh (no complex logic)
✅ Added ci_pre_xcodebuild.sh (enforce iOS-only)  
✅ Updated FlowStateApp.xcscheme (clean iOS scheme)
✅ project.pbxproj already iOS-only (Build #17)

PROBLEM ADDRESSED:
- Build #17 still tried to build for macOS/visionOS despite iOS-only project config
- Xcode Cloud was interpreting scheme for multiple platforms
- Error: Unable to find destination matching { generic:1, platform:macOS }

EXPECTED RESULT:
- Should ONLY show 'Archive - iOS' (no macOS/visionOS sections)
- Should build successfully for iOS destination only
- Should create iOS archive for App Store

FlowState v1.2 (Build 6) - iOS App Store ready"

echo "🚀 Pushing..."
git push origin main

echo ""
echo "✅ Build #18 deployed - Nuclear iOS-only approach!"
echo ""
echo "🎯 Expected Results:"
echo "✅ ONLY 'Archive - iOS' section (no macOS/visionOS)"
echo "✅ No platform destination errors"
echo "✅ Successful iOS build and archive"
echo "✅ Ready for App Store submission"
echo ""
echo "🔍 Monitor: Should see ONLY iOS build targets in Xcode Cloud"