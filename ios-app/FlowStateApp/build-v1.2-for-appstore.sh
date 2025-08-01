#!/bin/bash

# FlowState v1.2 - Xcode Cloud Build & Archive Script
# This script prepares the app for App Store submission

set -e  # Exit on any error

echo "🚀 Starting FlowState v1.2 build process..."

# Navigate to the project directory
cd /Users/broneotodak/Projects/flowstate-ai/ios-app/FlowStateApp

echo "📱 Building for iOS App Store distribution..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean \
  -project FlowStateApp.xcodeproj \
  -scheme FlowStateApp \
  -configuration Release

# Archive for App Store
echo "📦 Creating App Store archive..."
xcodebuild archive \
  -project FlowStateApp.xcodeproj \
  -scheme FlowStateApp \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath ./build/FlowState-v1.2.xcarchive \
  -allowProvisioningUpdates

echo "✅ Archive created successfully!"

# Export for App Store submission
echo "📤 Exporting for App Store submission..."
xcodebuild -exportArchive \
  -archivePath ./build/FlowState-v1.2.xcarchive \
  -exportPath ./build/AppStore \
  -exportOptionsPlist ./ci_scripts/ExportOptions.plist

echo "🎉 FlowState v1.2 is ready for App Store submission!"
echo "📁 Archive location: ./build/FlowState-v1.2.xcarchive"
echo "📁 App Store package: ./build/AppStore/"

# Verify the build
echo "🔍 Verifying build..."
if [ -f "./build/AppStore/FlowStateApp.ipa" ]; then
    echo "✅ FlowStateApp.ipa created successfully"
    ls -la ./build/AppStore/
else
    echo "❌ Error: FlowStateApp.ipa not found"
    exit 1
fi

echo "🚀 Ready to submit to App Store Connect!"
