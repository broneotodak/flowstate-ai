#!/bin/sh

# ci_post_clone.sh
# This script runs after Xcode Cloud clones the repository

set -e

echo "🔧 Running Xcode Cloud post-clone setup for FlowState v1.2..."

# Print environment info for debugging
echo "📍 Current directory: $(pwd)"
echo "📍 Available files:"
ls -la

# Navigate to the iOS app directory
cd ios-app/FlowStateApp

echo "📱 iOS app directory contents:"
ls -la

# Set up any dependencies if needed
echo "✅ Post-clone setup completed successfully!"
echo "🚀 Ready to build FlowState v1.2"
