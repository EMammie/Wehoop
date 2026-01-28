#!/usr/bin/env python3
"""
Generate placeholder team logos for Unrivaled Basketball app
This creates simple circular logos with team colors and abbreviations
Requires: Pillow (PIL) - install with: pip install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Team data matching your app's TeamThemeProvider
TEAMS = [
    {
        "id": "team-1",
        "name": "Mist BC",
        "abbreviation": "MST",
        "color": (77, 102, 140),  # Misty blue-gray
        "text_color": (255, 255, 255),
    },
    {
        "id": "team-2",
        "name": "Lunar Owls BC",
        "abbreviation": "LOW",
        "color": (38, 38, 64),  # Deep night blue
        "text_color": (255, 255, 255),
    },
    {
        "id": "team-3",
        "name": "Rose BC",
        "abbreviation": "RSE",
        "color": (204, 51, 76),  # Rose red
        "text_color": (255, 255, 255),
    },
    {
        "id": "team-4",
        "name": "Vinyl BC",
        "abbreviation": "VNL",
        "color": (26, 26, 26),  # Deep black
        "text_color": (230, 230, 230),
    },
    {
        "id": "team-5",
        "name": "Phantom BC",
        "abbreviation": "PHT",
        "color": (51, 38, 77),  # Phantom purple
        "text_color": (255, 255, 255),
    },
    {
        "id": "team-6",
        "name": "Laces BC",
        "abbreviation": "LAC",
        "color": (242, 242, 245),  # White/cream
        "text_color": (51, 51, 77),
    },
    {
        "id": "team-7",
        "name": "Breeze",
        "abbreviation": "BRZ",
        "color": (102, 184, 230),  # Sky blue
        "text_color": (255, 255, 255),
    },
    {
        "id": "team-8",
        "name": "Hive",
        "abbreviation": "HVE",
        "color": (255, 214, 51),  # Golden yellow
        "text_color": (51, 51, 51),
    },
]

def create_circle_logo(team, size=512, output_dir="output"):
    """
    Create a circular logo with team color and abbreviation
    """
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Create a transparent image
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw circle
    draw.ellipse([0, 0, size-1, size-1], fill=(*team['color'], 255))
    
    # Add inner circle for depth effect
    inner_size = int(size * 0.85)
    inner_offset = (size - inner_size) // 2
    lighter_color = tuple(min(c + 20, 255) for c in team['color'])
    draw.ellipse(
        [inner_offset, inner_offset, size - inner_offset, size - inner_offset],
        fill=(*lighter_color, 255)
    )
    
    # Add abbreviation text
    try:
        # Try to use a system font
        font_size = int(size * 0.35)
        try:
            # macOS system fonts
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            try:
                # Linux fonts
                font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
            except:
                # Windows fonts
                try:
                    font = ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", font_size)
                except:
                    # Fallback to default
                    font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()
    
    # Get text bounding box
    text = team['abbreviation']
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - bbox[1]
    
    # Draw text with shadow for depth
    shadow_offset = int(size * 0.01)
    shadow_color = tuple(max(c - 50, 0) for c in team['color'])
    draw.text((x + shadow_offset, y + shadow_offset), text, fill=(*shadow_color, 200), font=font)
    draw.text((x, y), text, fill=(*team['text_color'], 255), font=font)
    
    # Save image
    filename = f"logo-{team['id']}.png"
    filepath = os.path.join(output_dir, filename)
    img.save(filepath, 'PNG')
    print(f"✓ Created {filename}")
    
    return filepath

def create_all_logos(size=512, output_dir="output"):
    """
    Create logos for all teams
    """
    print(f"\n🏀 Generating Unrivaled Basketball Team Logos")
    print(f"   Size: {size}x{size} pixels")
    print(f"   Output: {output_dir}/\n")
    
    for team in TEAMS:
        create_circle_logo(team, size, output_dir)
    
    print(f"\n✅ Done! Created {len(TEAMS)} logos")
    print(f"\n📦 Next steps:")
    print(f"   1. Open your Xcode project")
    print(f"   2. Navigate to Assets.xcassets")
    print(f"   3. Drag all PNG files from '{output_dir}/' into Assets")
    print(f"   4. Make sure asset names match: logo-team-1, logo-team-2, etc.")
    print(f"   5. Build and run your app!")
    print(f"\n📖 See SETUP_LOCAL_LOGOS.md for detailed instructions\n")

def main():
    """
    Main entry point
    """
    import sys
    
    # Parse command line arguments
    size = 512
    output_dir = "team_logos"
    
    if len(sys.argv) > 1:
        try:
            size = int(sys.argv[1])
        except:
            print("Usage: python generate_placeholder_logos.py [size] [output_dir]")
            print("Example: python generate_placeholder_logos.py 512 team_logos")
            sys.exit(1)
    
    if len(sys.argv) > 2:
        output_dir = sys.argv[2]
    
    try:
        create_all_logos(size, output_dir)
    except ImportError:
        print("\n❌ Error: Pillow library not installed")
        print("\n   Install it with:")
        print("   pip install Pillow")
        print("\n   Or using conda:")
        print("   conda install pillow\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
