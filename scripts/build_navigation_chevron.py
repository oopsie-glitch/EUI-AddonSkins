"""Render original shallow, round-ended navigation artwork. Dev-only: Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw

SIZE = 256
SUPERSAMPLE = 4
# A 22:12 visible footprint on a 30-unit canvas, matching the initial chevron.
POINTS = ((5.5, 19.5), (15, 10.5), (24.5, 19.5))
RADIUS = 1.5
scale = SIZE * SUPERSAMPLE / 30
image = Image.new("RGBA", (SIZE * SUPERSAMPLE, SIZE * SUPERSAMPLE))
draw = ImageDraw.Draw(image)
points = [(round(x * scale), round(y * scale)) for x, y in POINTS]
draw.line(points, fill="white", width=round(2 * RADIUS * scale), joint="curve")
for x, y in POINTS:
    draw.ellipse(tuple(round(v * scale) for v in (x-RADIUS, y-RADIUS, x+RADIUS, y+RADIUS)), fill="white")
image = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
root = Path(__file__).resolve().parents[1]
image.save(root / "EUIAddonSkins/Media/NavigationCaret.tga")
