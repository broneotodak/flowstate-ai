#!/bin/bash

# commit-and-deploy-v1.2-fixed.sh
# Commits the Xcode Cloud fixes and triggers Build #15

set -e

echo "🚀 FlowState v1.2 - Committing Xcode Cloud Fixes"
echo "================================================="

# Navigate to repository root
cd /Users/broneotodak/Projects/flowstate-ai

echo "📍 Repository: $(pwd)"
echo "📅 Timestamp: $(date)"

# Check git status
echo ""
echo "📊 Git Status:"
git status --short

# Stage the changes
echo ""
echo "📝 Staging changes..."
git add ios-app/FlowStateApp/ci_scripts/ci_post_clone.sh
git add ios-app/FlowStateApp/.xcode-cloud/workflows/flowstate-app.yml
git add ci_scripts/ci_post_clone.sh
git add test-xcode-cloud-setup.sh

# Commit with descriptive message
echo ""
echo "💾 Committing changes..."
git commit -m "🔧 Fix Xcode Cloud Build #15 - FlowState v1.2

- Fixed ci_post_clone.sh script for nested project structure
- Enhanced script with comprehensive error checking and logging
- Updated Xcode Cloud workflow configuration for ios-app/FlowStateApp/
- Added test script for local validation
- Resolved Build #14 failure: 'Run ci_post_clone.sh script' step

Changes:
✅ ios-app/FlowStateApp/ci_scripts/ci_post_clone.sh - Fixed directory detection
✅ ios-app/FlowStateApp/.xcode-cloud/workflows/flowstate-app.yml - Updated project paths
✅ ci_scripts/ci_post_clone.sh - Backup script at root level
✅ test-xcode-cloud-setup.sh - Local testing utility

Ready for Build #15 - FlowState v1.2 (Build 6)
App Store submission preparation complete"

# Push to trigger Xcode Cloud build
echo ""
echo "🚀 Pushing to origin..."
git push origin main

echo ""
echo "✅ SUCCESS! Changes pushed to repository"
echo ""
echo "🎯 What happens next:"
echo "1. Xcode Cloud will detect the push and start Build #15"
echo "2. The fixed ci_post_clone.sh script should run successfully"
echo "3. Build should proceed to compilation and archiving"
echo "4. Monitor the build in Xcode Cloud dashboard"
echo ""
echo "📱 FlowState v1.2 Build Information:"
echo "   Version: 1.2"
echo "   Build: 6"
echo "   Bundle ID: com.neotodaksts.FlowStateApp"
echo "   Expected Build: #15"
echo ""
echo "🔗 Check build status at:"
echo "   Xcode > Developer > Xcode Cloud > FlowState App"
echo ""
echo "📋 If Build #15 succeeds:"
echo "   ✅ Archive will be created"
echo "   ✅ Ready for App Store submission"
echo "   ✅ TestFlight deployment available"
echo ""