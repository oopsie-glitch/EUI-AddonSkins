"""Render original shallow, round-ended navigation artwork. Dev-only: Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw

SIZE = 256
SUPERSAMPLE = 4
# A 22:12 visible footprint on a 30-unit canvas, matching the initial chevron.
POINTS = ((5.5, 19.5), (15, 10.5), (24.5, 19.5))
RADIUS = 1.5
# About 1.25 UI units at the default 32-unit frame and 110% artwork scale.
OUTLINE = 0.85
scale = SIZE * SUPERSAMPLE / 30
image = Image.new("RGBA", (SIZE * SUPERSAMPLE, SIZE * SUPERSAMPLE))
draw = ImageDraw.Draw(image)
points = [(round(x * scale), round(y * scale)) for x, y in POINTS]
# Black remains black under the native accent vertex tint. Bake the outline
# into the same texture so rotation needs no extra objects or update callbacks.
for radius, color in ((RADIUS + OUTLINE, "black"), (RADIUS, "white")):
    draw.line(points, fill=color, width=round(2 * radius * scale), joint="curve")
    for x, y in POINTS:
        draw.ellipse(tuple(round(v * scale) for v in (x-radius, y-radius, x+radius, y+radius)), fill=color)
image = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
root = Path(__file__).resolve().parents[1]
image.save(root / "EUIAddonSkins/Media/NavigationCaretOutlined.tga")
