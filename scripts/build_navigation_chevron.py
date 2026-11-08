"""Render original straight-edged navigation artwork. Dev-only: Pillow."""
from pathlib import Path
from math import hypot, sin
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


BRONZE = (
    (0.00, (106, 61, 36)),
    (0.23, (245, 204, 148)),
    (0.42, (216, 157, 99)),
    (0.72, (180, 111, 63)),
    (1.00, (105, 59, 34)),
)


def metal_face(x, y, white):
    if not white:
        return (0, 0, 0)
    # Light catches the upper bevel on both faces. Fine brushed variation
    # follows the edge and the right face sits a little further from the light.
    across = y - (9 + abs(x - 15) * 10.5 / 11)
    depth = max(0, min(1, across / (inner_peak - 9)))
    grain = 3 * sin(across * 31 + sin(x * 0.9)) + 2 * sin(x * 1.7)
    light = grain - (7 if x > 15 else 0)
    for (start, near), (end, far) in zip(BRONZE, BRONZE[1:]):
        if depth <= end:
            weight = (depth - start) / (end - start)
            return tuple(round((a + (b - a) * weight + light) * white / 255) for a, b in zip(near, far))


outer = offset_polygon(POINTS, OUTLINE)
pixels, bronze_pixels = [], []
for y in range(SIZE):
    for x in range(SIZE):
        px, py = (x+0.5)*30/SIZE, (y+0.5)*30/SIZE
        alpha = coverage(signed_distance(px, py, outer), OUTER_FEATHER)
        white = coverage(signed_distance(px, py, POINTS), INNER_FEATHER) if alpha else 0
        # Accent tint affects only the interior. Opaque outline remains black.
        pixels.append((white, white, white, alpha))
        bronze_pixels.append((*metal_face(px, py, white), alpha))
image = Image.new("RGBA", (SIZE, SIZE))
image.putdata(pixels)
root = Path(__file__).resolve().parents[1]
image.save(root / "EUIAddonSkins/Media/NavigationChevronSmooth.tga")
image.putdata(bronze_pixels)
image.save(root / "EUIAddonSkins/Media/NavigationChevronBronze.tga")
