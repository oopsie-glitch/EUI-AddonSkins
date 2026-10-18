"""Render our original north-up navigation pointer. Dev-only; requires Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw

SIZE = 64
SCALE = 8
# Keep the native 64px canvas and center. At RestedXP's default 32-unit size,
# the 60px-wide silhouette occupies 30 units, close to its original pointer.
POINTS = [(32, 1), (62, 62), (32, 50), (2, 62)]
image = Image.new('RGBA', (SIZE * SCALE, SIZE * SCALE))
draw = ImageDraw.Draw(image)
draw.polygon([(x * SCALE, y * SCALE) for x, y in POINTS],
             fill=(255, 255, 255, 255), outline=(8, 10, 13, 255), width=3 * SCALE)
image = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
root = Path(__file__).resolve().parents[1]
image.save(root / 'EUIAddonSkins/Media/NavigationArrow.tga')
