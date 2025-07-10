#!/bin/bash

echo "Creating FlowState iOS App Xcode project..."

# Create a new iOS app project using xcodegen or manual setup
# Since we don't have xcodegen, let's create a minimal working structure

# Create Info.plist
cat > FlowStateApp/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF

echo "✅ Info.plist created"

# Create a simple SwiftPM executable that will open Xcode
cat > build.swift << 'EOF'
import Foundation

print("🚀 FlowState iOS App")
print("Since we can't create a proper Xcode project programmatically,")
print("here's how to set it up manually:")
print("")
print("1. Open Xcode")
print("2. File → New → Project")
print("3. Choose 'iOS' → 'App'")
print("4. Product Name: FlowStateApp")
print("5. Interface: SwiftUI")
print("6. Language: Swift")
print("7. Click 'Next' and save in this directory")
print("")
print("Then copy the Swift files into the project:")
print("- FlowStateApp.swift")
print("- ContentView.swift") 
print("- FlowStateViewModel.swift")
print("- ActivitiesView.swift")
print("- StatsView.swift")
print("- SettingsView.swift")
print("")
print("The app is ready to use! Just add your service key in Settings.")
EOF

swift build.swift
rm build.swift

echo ""
echo "Alternative: Open Xcode manually and drag all .swift files into a new project"