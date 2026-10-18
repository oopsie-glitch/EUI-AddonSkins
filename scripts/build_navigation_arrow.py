"""Render our original open navigation chevron. Dev-only; requires Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw

SIZE = 128
SUPERSAMPLE = 4
# Geometry in native 32-unit coordinates. Long, open legs fill approximately
# 30 x 27 units instead of magnifying EUI's small menu-caret bitmap.
POINTS = [(1, 27), (16, 2), (31, 27), (27, 29), (16, 9), (5, 29)]
scale = SIZE / 32 * SUPERSAMPLE
image = Image.new('RGBA', (SIZE * SUPERSAMPLE, SIZE * SUPERSAMPLE))
draw = ImageDraw.Draw(image)
draw.polygon([(round(x * scale), round(y * scale)) for x, y in POINTS],
             fill=(255, 255, 255, 255), outline=(5, 7, 10, 200),
             width=round(0.35 * scale))
image = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
root = Path(__file__).resolve().parents[1]
image.save(root / 'EUIAddonSkins/Media/NavigationChevron.tga')
