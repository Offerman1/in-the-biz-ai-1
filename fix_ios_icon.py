#!/usr/bin/env python3
"""
Fix iOS app icons by removing transparency and adding solid background.
iOS does NOT support transparent app icons - transparency appears as black.
"""

from PIL import Image
import os

# Paths
source_icon = "/Users/brandonmunzer/Desktop/in-the-biz-ai-1/apple itb icon.jpg"
output_dir = "/Users/brandonmunzer/Desktop/in-the-biz-ai-1/ios/Runner/Assets.xcassets/AppIcon.appiconset"

# iOS icon sizes (filename: size)
icon_sizes = {
    "Icon-App-1024x1024@1x.png": 1024,
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-50x50@1x.png": 50,
    "Icon-App-50x50@2x.png": 100,
    "Icon-App-57x57@1x.png": 57,
    "Icon-App-57x57@2x.png": 114,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-72x72@1x.png": 72,
    "Icon-App-72x72@2x.png": 144,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
}

def scale_to_fill(img, target_size):
    """Scale image to fill entire square, cropping edges if needed (no transparency)"""
    # Convert RGBA to RGB first
    if img.mode in ('RGBA', 'LA'):
        # Find the bounding box of non-transparent pixels
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)
        # Convert to RGB
        background = Image.new('RGB', img.size, (255, 255, 255))
        if img.mode == 'RGBA':
            background.paste(img, mask=img.split()[3])
        else:
            background.paste(img, mask=img.split()[1])
        img = background
    
    # Scale up by 1.5x to ensure it fills the square edge-to-edge
    scale_factor = 1.5
    new_size = int(target_size * scale_factor)
    img_scaled = img.resize((new_size, new_size), Image.Resampling.LANCZOS)
    
    # Crop to center square
    left = (new_size - target_size) // 2
    top = (new_size - target_size) // 2
    right = left + target_size
    bottom = top + target_size
    
    return img_scaled.crop((left, top, right, bottom))

# Load source icon
print(f"Loading source icon: {source_icon}")
source = Image.open(source_icon)

# Convert to RGB if needed (JPG shouldn't have alpha but just in case)
if source.mode != 'RGB':
    source = source.convert('RGB')

# Generate all sizes - just resize, no scaling tricks
print(f"\nGenerating {len(icon_sizes)} iOS icon sizes...")
for filename, size in icon_sizes.items():
    output_path = os.path.join(output_dir, filename)
    resized = source.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(output_path, 'PNG')
    print(f"✓ {filename} ({size}x{size})")

print(f"\n✅ All iOS icons generated successfully!")
print(f"📁 Location: {output_dir}")
print(f"\n🔄 Next: Run 'flutter run' to see the new icon on your iPhone")
