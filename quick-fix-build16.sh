#!/bin/bash

# Quick commit for Build #16 with minimal script

set -e

echo "🔧 Quick Fix for Build #16 - Minimal Script"
echo "==========================================="

cd /Users/broneotodak/Projects/flowstate-ai

echo "📊 Git Status:"
git status --short

echo "📝 Staging minimal script..."
git add ios-app/FlowStateApp/ci_scripts/ci_post_clone.sh
git add ci_scripts/ci_post_clone.sh

echo "💾 Committing..."
git commit -m "🔧 Build #16 - Ultra minimal ci_post_clone.sh script

- Simplified to bare minimum for Xcode Cloud compatibility  
- Removed all complex logic that might cause failures
- Just basic echo statements and directory listing
- Should pass the ci_post_clone.sh step

Test: Minimal script for Build #16"

echo "🚀 Pushing..."
git push origin main

echo "✅ Build #16 should start with minimal script"
echo "🎯 If this passes, we can gradually add back functionality"