#!/usr/bin/env python3
"""
FlowState iOS Icon Resizer
Automatically generates all required iOS app icon sizes from a 1024x1024 master icon.
"""

import os
import json
from PIL import Image
import argparse

# iOS App Icon sizes for modern iOS (iOS 14+)
IOS_ICON_SIZES = {
    # iPhone
    "iphone_60x60_2x": (120, 120, "iPhone @2x"),
    "iphone_60x60_3x": (180, 180, "iPhone @3x"),
    
    # iPad
    "ipad_76x76_1x": (76, 76, "iPad @1x"),
    "ipad_76x76_2x": (152, 152, "iPad @2x"),
    "ipad_83.5x83.5_2x": (167, 167, "iPad Pro @2x"),
    
    # App Store
    "app_store_1024x1024": (1024, 1024, "App Store"),
    
    # macOS (if supporting Mac Catalyst)
    "mac_16x16_1x": (16, 16, "Mac 16pt @1x"),
    "mac_16x16_2x": (32, 32, "Mac 16pt @2x"),
    "mac_32x32_1x": (32, 32, "Mac 32pt @1x"),
    "mac_32x32_2x": (64, 64, "Mac 32pt @2x"),
    "mac_128x128_1x": (128, 128, "Mac 128pt @1x"),
    "mac_128x128_2x": (256, 256, "Mac 128pt @2x"),
    "mac_256x256_1x": (256, 256, "Mac 256pt @1x"),
    "mac_256x256_2x": (512, 512, "Mac 256pt @2x"),
    "mac_512x512_1x": (512, 512, "Mac 512pt @1x"),
    "mac_512x512_2x": (1024, 1024, "Mac 512pt @2x"),
}

def resize_icon(input_path, output_dir, filename_prefix="icon"):
    """
    Resize a 1024x1024 icon to all required iOS sizes.
    """
    try:
        # Open and validate the input image
        with Image.open(input_path) as img:
            if img.size != (1024, 1024):
                print(f"⚠️  Warning: Input image is {img.size}, expected (1024, 1024)")
                print("   Resizing to 1024x1024 first...")
                img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
            
            # Ensure output directory exists
            os.makedirs(output_dir, exist_ok=True)
            
            print(f"🎨 Generating iOS app icons from {input_path}")
            print(f"📁 Output directory: {output_dir}")
            print()
            
            # Generate all required sizes
            for size_name, (width, height, description) in IOS_ICON_SIZES.items():
                output_filename = f"{filename_prefix}_{width}x{height}.png"
                output_path = os.path.join(output_dir, output_filename)
                
                # Resize using high-quality resampling
                resized_img = img.resize((width, height), Image.Resampling.LANCZOS)
                resized_img.save(output_path, "PNG", optimize=True)
                
                print(f"✅ {output_filename:<25} ({description})")
            
            print()
            print("🎉 All icon sizes generated successfully!")
            
            # Generate updated Contents.json
            generate_contents_json(output_dir, filename_prefix)
            
    except Exception as e:
        print(f"❌ Error processing icon: {e}")
        return False
    
    return True

def generate_contents_json(output_dir, filename_prefix):
    """
    Generate an updated Contents.json file with proper filename references.
    """
    contents_json = {
        "images": [
            # iOS Universal
            {
                "filename": f"{filename_prefix}_1024x1024.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            # macOS sizes
            {
                "filename": f"{filename_prefix}_16x16.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "16x16"
            },
            {
                "filename": f"{filename_prefix}_32x32.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "16x16"
            },
            {
                "filename": f"{filename_prefix}_32x32.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "32x32"
            },
            {
                "filename": f"{filename_prefix}_64x64.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "32x32"
            },
            {
                "filename": f"{filename_prefix}_128x128.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "128x128"
            },
            {
                "filename": f"{filename_prefix}_256x256.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "128x128"
            },
            {
                "filename": f"{filename_prefix}_256x256.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "256x256"
            },
            {
                "filename": f"{filename_prefix}_512x512.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "256x256"
            },
            {
                "filename": f"{filename_prefix}_512x512.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "512x512"
            },
            {
                "filename": f"{filename_prefix}_1024x1024.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "512x512"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    contents_path = os.path.join(output_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents_json, f, indent=2)
    
    print(f"📝 Generated Contents.json at {contents_path}")

def main():
    parser = argparse.ArgumentParser(description="Generate iOS app icons from 1024x1024 master icon")
    parser.add_argument("input", help="Path to input 1024x1024 PNG image")
    parser.add_argument("-o", "--output", default="./icons", help="Output directory (default: ./icons)")
    parser.add_argument("-p", "--prefix", default="AppIcon", help="Filename prefix (default: AppIcon)")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"❌ Error: Input file '{args.input}' not found")
        return 1
    
    success = resize_icon(args.input, args.output, args.prefix)
    
    if success:
        print()
        print("🚀 Next Steps:")
        print("1. Copy the generated icon files to your Xcode project's AppIcon.appiconset folder")
        print("2. Replace the Contents.json file with the generated one")
        print("3. Build your app in Xcode to verify icons appear correctly")
        print("4. Use the 1024x1024 icon for App Store Connect submission")
        return 0
    else:
        return 1

if __name__ == "__main__":
    exit(main())
