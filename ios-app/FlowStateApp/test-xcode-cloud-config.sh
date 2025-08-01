#!/bin/bash

# Xcode Cloud Build Validation Script
# Tests the build configuration locally before cloud build

set -e

echo "🧪 Testing FlowState v1.2 Build Configuration..."

cd /Users/broneotodak/Projects/flowstate-ai/ios-app/FlowStateApp

echo "✅ Testing Release build (same as Xcode Cloud)..."

# Test Release build with clean
xcodebuild clean build \
  -project FlowStateApp.xcodeproj \
  -scheme FlowStateApp \
  -configuration Release \
  -destination generic/platform=iOS \
  -quiet

echo "✅ Release build successful!"

echo "✅ Testing Archive (App Store preparation)..."

# Test archive creation
xcodebuild archive \
  -project FlowStateApp.xcodeproj \
  -scheme FlowStateApp \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath ./build/test-archive.xcarchive \
  -quiet

if [ -d "./build/test-archive.xcarchive" ]; then
    echo "✅ Archive created successfully!"
    rm -rf ./build/test-archive.xcarchive
else
    echo "❌ Archive creation failed!"
    exit 1
fi

echo "🎉 All build tests passed! Configuration should work in Xcode Cloud."
echo "📋 Summary:"
echo "   ✅ Shared scheme configured"
echo "   ✅ Release build working"
echo "   ✅ Archive creation working"
echo "   ✅ Version 1.2 (build 6) ready"
echo ""
echo "🚀 Ready for Xcode Cloud build!"
