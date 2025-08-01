#!/bin/bash

# Create explicit iOS-only scheme configuration

echo "🔧 Creating iOS-only scheme configuration for Xcode Cloud"
echo "======================================================"

cd /Users/broneotodak/Projects/flowstate-ai

# Let's also create a simple ci_pre_xcodebuild.sh script to force iOS destination
cat > ios-app/FlowStateApp/ci_scripts/ci_pre_xcodebuild.sh << 'EOF'
#!/bin/sh

echo "=== Pre-Xcodebuild Setup ==="
echo "Forcing iOS-only build configuration"
echo "Timestamp: $(date)"

# Show available destinations for debugging
echo "Available build destinations:"
xcodebuild -project FlowStateApp.xcodeproj -scheme FlowStateApp -showdestinations

# Set environment variables to force iOS-only builds
export ONLY_ACTIVE_ARCH=NO
export ARCHS="arm64"
export VALID_ARCHS="arm64"
export SUPPORTED_PLATFORMS="iphoneos iphonesimulator"

echo "Environment configured for iOS-only build"
echo "Pre-xcodebuild setup complete"

exit 0
EOF

chmod +x ios-app/FlowStateApp/ci_scripts/ci_pre_xcodebuild.sh

echo "✅ Created ci_pre_xcodebuild.sh to force iOS-only builds"