"""Render original straight-edged navigation artwork. Dev-only: Pillow."""
from pathlib import Path
from math import hypot
from PIL import Image, ImageDraw

SIZE = 256
SUPERSAMPLE = 8
# Preserve the 22:12 coloured footprint. Parallel straight sides, flat ends
# and a mitered peak replace the rounded caps/joins that looked swollen.
inner_peak = 21 - 9.5 * 10.5 / 11
POINTS = ((4, 19.5), (15, 9), (26, 19.5), (24.5, 21),
          (15, inner_peak), (5.5, 21))
# About 0.95 UI units at the default 32-unit frame / 110% artwork scale.
OUTLINE = 0.65


def offset_polygon(points, distance):
    """Intersect offset edges: a uniform outline with straight mitered joins."""
    edges = []
    for a, b in zip(points, points[1:] + points[:1]):
        dx, dy = b[0]-a[0], b[1]-a[1]
        length = hypot(dx, dy)
        edges.append(((a[0]+distance*dy/length, a[1]-distance*dx/length), (dx, dy)))
    result = []
    for i, (q, e) in enumerate(edges):
        p, d = edges[i-1]
        cross = d[0]*e[1]-d[1]*e[0]
        t = ((q[0]-p[0])*e[1]-(q[1]-p[1])*e[0])/cross
        result.append((p[0]+t*d[0], p[1]+t*d[1]))
    return result


scale = SIZE * SUPERSAMPLE / 30
image = Image.new("RGBA", (SIZE * SUPERSAMPLE, SIZE * SUPERSAMPLE))
draw = ImageDraw.Draw(image)
# A single texture retains native rotation; black stays black under accent tint.
for polygon, color in ((offset_polygon(POINTS, OUTLINE), "black"), (POINTS, "white")):
    draw.polygon([(round(x*scale), round(y*scale)) for x, y in polygon], fill=color)
# Coverage antialiasing avoids ringing around the thin black edge.
image = image.resize((SIZE, SIZE), Image.Resampling.BOX)
root = Path(__file__).resolve().parents[1]
image.save(root / "EUIAddonSkins/Media/NavigationChevronStraight.tga")
