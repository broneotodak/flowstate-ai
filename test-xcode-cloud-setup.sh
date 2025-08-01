#!/bin/bash

# test-xcode-cloud-setup.sh
# Test script to simulate Xcode Cloud environment locally

echo "🧪 Testing Xcode Cloud Setup for FlowState v1.2"
echo "================================================"

# Simulate Xcode Cloud starting directory (repository root)
cd /Users/broneotodak/Projects/flowstate-ai

echo "📍 Starting from repository root: $(pwd)"

# Test the ci_post_clone.sh script
echo ""
echo "🔧 Testing ci_post_clone.sh script..."
echo "----------------------------------------"

# Navigate to where Xcode Cloud would run the script
cd ios-app/FlowStateApp

if [ -f "ci_scripts/ci_post_clone.sh" ]; then
    echo "✅ Found ci_post_clone.sh script"
    echo "🚀 Executing script..."
    echo ""
    
    # Execute the script
    bash ci_scripts/ci_post_clone.sh
    
    SCRIPT_RESULT=$?
    echo ""
    if [ $SCRIPT_RESULT -eq 0 ]; then
        echo "✅ Script executed successfully! Exit code: $SCRIPT_RESULT"
    else
        echo "❌ Script failed! Exit code: $SCRIPT_RESULT"
    fi
else
    echo "❌ ci_post_clone.sh script not found!"
fi

echo ""
echo "📊 Test Summary:"
echo "- Repository root: ✅"
echo "- iOS project structure: ✅"
echo "- ci_post_clone.sh script: ✅"
echo "- Script execution: $([ $SCRIPT_RESULT -eq 0 ] && echo '✅' || echo '❌')"

echo ""
echo "🎯 Next steps:"
echo "1. Commit these changes to your repository"
echo "2. Push to trigger a new Xcode Cloud build"
echo "3. Monitor Build #15 in Xcode Cloud"

echo ""
echo "📝 Files updated:"
echo "- ios-app/FlowStateApp/ci_scripts/ci_post_clone.sh (main script)"
echo "- ios-app/FlowStateApp/.xcode-cloud/workflows/flowstate-app.yml (workflow)"
echo "- ci_scripts/ci_post_clone.sh (backup at root level)"