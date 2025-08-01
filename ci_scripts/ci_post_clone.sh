#!/bin/sh

# ci_post_clone.sh for FlowState iOS App v1.2 - REPOSITORY ROOT VERSION
# This is a backup script at repo root level
# The main script should be in ios-app/FlowStateApp/ci_scripts/

set -e

echo "🚀 Root-level ci_post_clone.sh executing..."
echo "📍 Current directory: $(pwd)"

# Check if we're in the repository root
if [ ! -d ".git" ]; then
    echo "❌ ERROR: Not in repository root"
    exit 1
fi

# The iOS project is nested, so just verify structure
if [ -d "ios-app/FlowStateApp/FlowStateApp.xcodeproj" ]; then
    echo "✅ iOS project structure verified"
    echo "🎯 FlowState v1.2 ready for build"
else
    echo "❌ ERROR: iOS project structure not found"
    echo "📂 Repository contents:"
    ls -la
    exit 1
fi

echo "✅ Root-level setup completed"
exit 0