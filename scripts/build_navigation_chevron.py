"""Render original straight-edged navigation artwork. Dev-only: Pillow."""
from pathlib import Path
from math import hypot
from PIL import Image

SIZE = 256
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


# A subpixel edge transition at the default display size, not a blur of the
# whole image. Texture-resolution-only AA was too narrow after minification.
OUTER_FEATHER = 0.55
INNER_FEATHER = 0.45


def signed_distance(x, y, points):
    inside = False
    distance = float("inf")
    for a, b in zip(points, points[1:] + points[:1]):
        dx, dy = b[0]-a[0], b[1]-a[1]
        t = max(0, min(1, ((x-a[0])*dx+(y-a[1])*dy)/(dx*dx+dy*dy)))
        distance = min(distance, hypot(x-a[0]-t*dx, y-a[1]-t*dy))
        if (a[1] > y) != (b[1] > y) and x < a[0]+(y-a[1])*dx/dy:
            inside = not inside
    return distance if inside else -distance


def coverage(distance, width):
    t = max(0, min(1, distance/width + 0.5))
    return round(255 * t*t*(3-2*t))


outer = offset_polygon(POINTS, OUTLINE)
pixels = []
for y in range(SIZE):
    for x in range(SIZE):
        px, py = (x+0.5)*30/SIZE, (y+0.5)*30/SIZE
        alpha = coverage(signed_distance(px, py, outer), OUTER_FEATHER)
        white = coverage(signed_distance(px, py, POINTS), INNER_FEATHER) if alpha else 0
        # Accent tint affects only the interior. Opaque outline remains black.
        pixels.append((white, white, white, alpha))
image = Image.new("RGBA", (SIZE, SIZE))
image.putdata(pixels)
root = Path(__file__).resolve().parents[1]
image.save(root / "EUIAddonSkins/Media/NavigationChevronSmooth.tga")
