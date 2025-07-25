#!/usr/bin/env python3
"""
FlowState App Icon Generator
Creates simple 3-wave blue icon for iOS App Store submission
"""

from PIL import Image, ImageDraw
import os
import math

def create_wave_icon(size, output_path):
    """Create a simple 3-wave blue icon"""
    
    # Create white background
    img = Image.new('RGB', (size, size), 'white')
    draw = ImageDraw.Draw(img)
    
    # Blue color (iOS-friendly blue)
    blue_color = '#007AFF'  # Apple's system blue
    
    # Calculate wave parameters
    center_y = size // 2
    wave_spacing = size // 6  # Space between waves
    wave_height = size // 20  # Thickness of each wave
    wave_width = int(size * 0.7)  # 70% of icon width
    wave_start_x = (size - wave_width) // 2
    
    # Create 3 horizontal waves with slight curves
    for i in range(3):
        y_offset = (i - 1) * wave_spacing  # -1, 0, 1 for top, middle, bottom
        wave_y = center_y + y_offset
        
        # Create smooth wave path
        points = []
        num_points = 50
        
        for j in range(num_points + 1):
            x = wave_start_x + (j * wave_width) // num_points
            # Add subtle wave curve (sine wave with small amplitude)
            curve_amplitude = size // 30
            y = wave_y + curve_amplitude * math.sin(2 * math.pi * j / num_points)
            points.append((x, y))
        
        # Draw the wave as a thick line
        for k in range(len(points) - 1):
            x1, y1 = points[k]
            x2, y2 = points[k + 1]
            
            # Draw thick line by drawing multiple thin lines
            for offset in range(-wave_height//2, wave_height//2 + 1):
                draw.line([(x1, y1 + offset), (x2, y2 + offset)], fill=blue_color, width=2)
    
    # Save the image
    img.save(output_path, 'PNG', quality=100)
    print(f"Created {size}x{size} icon: {output_path}")

def generate_all_ios_icons():
    """Generate all required iOS icon sizes"""
    
    # iOS icon sizes required for App Store
    icon_sizes = [
        1024,  # App Store
        180,   # iPhone 6 Plus / 6s Plus / 7 Plus / 8 Plus
        167,   # iPad Pro
        152,   # iPad / iPad mini
        144,   # iPad (iOS 6.0)
        120,   # iPhone / iPod Touch
        114,   # iPhone 4s (iOS 6.1)
        100,   # iPad (iOS 6.0)
        87,    # iPhone 6s / 7 / 8 / SE (2nd gen) / 12 mini / 13 mini
        80,    # iPhone 4s / 5 / 5s / 5c
        76,    # iPad
        72,    # iPad (iOS 6.0)
        60,    # iPhone / iPod Touch
        58,    # iPhone 4s / 5 / 5s / 5c
        57,    # iPhone (iOS 6.1)
        50,    # iPad (iOS 6.0)
        40,    # iPhone / iPod Touch
        29     # iPhone / iPod Touch / iPad
    ]
    
    # Create icons directory
    icons_dir = "FlowStateApp/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(icons_dir, exist_ok=True)
    
    # Generate each icon size
    for size in icon_sizes:
        filename = f"icon-{size}.png"
        output_path = os.path.join(icons_dir, filename)
        create_wave_icon(size, output_path)
    
    print(f"\n✅ Generated {len(icon_sizes)} iOS icons successfully!")
    print("📱 Icons created in: FlowStateApp/Assets.xcassets/AppIcon.appiconset/")

if __name__ == "__main__":
    print("🌊 Creating FlowState 3-Wave Blue Icons...")
    print("=" * 50)
    generate_all_ios_icons()
    print("=" * 50)
    print("✅ All icons ready for Xcode integration!")
