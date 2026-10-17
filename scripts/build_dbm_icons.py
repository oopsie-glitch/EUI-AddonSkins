"""Render the original EUI DBM mechanic glyphs. Dev-only; requires Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw

SCALE = 4
CELL = 32
atlas = Image.new('RGBA', (CELL * 8 * SCALE, CELL * SCALE))

for index in range(8):
    tile = Image.new('RGBA', (CELL * SCALE, CELL * SCALE))
    draw = ImageDraw.Draw(tile)
    color = (255, 255, 255, 255)

    def line(points, width=2):
        draw.line([(round(x*SCALE), round(y*SCALE)) for x,y in points], fill=color, width=round(width*SCALE), joint='curve')

    def ellipse(box, width=2):
        draw.ellipse(tuple(round(v*SCALE) for v in box), outline=color, width=round(width*SCALE))

    if index == 0:  # Tank: shield.
        line([(16,4),(26,8),(25,18),(22,24),(16,28),(10,24),(7,18),(6,8),(16,4)])
        line([(16,9),(16,23)], 1.5)
    elif index == 1:  # Damage: sword.
        line([(11,21),(21,6),(27,5),(26,11),(11,21)])
        line([(8,16),(17,25)])
        line([(12,21),(6,27)], 3)
    elif index == 2:  # Healer: cross.
        line([(13,5),(19,5),(19,13),(27,13),(27,19),(19,19),(19,27),(13,27),(13,19),(5,19),(5,13),(13,13),(13,5)])
    elif index == 3:  # Interrupt: stop symbol.
        ellipse((5,5,27,27))
        line([(8,24),(24,8)])
    elif index == 4:  # Important: warning triangle.
        line([(16,4),(29,27),(3,27),(16,4)])
        line([(16,11),(16,19)], 2.5)
        ellipse((15,22,17,24), 1)
    elif index == 5:  # Magic: four-point star.
        line([(16,3),(20,12),(29,16),(20,20),(16,29),(12,20),(3,16),(12,12),(16,3)])
    elif index == 6:  # Bleed: drop.
        line([(16,3),(25,17),(26,21),(24,26),(20,29),(12,29),(8,26),(6,21),(7,17),(16,3)])
        line([(11,20),(12,24),(15,26)], 1.5)
    else:  # Deadly: skull.
        ellipse((5,4,27,24))
        line([(10,22),(10,28),(22,28),(22,22)])
        ellipse((10,12,14,16), 1.5)
        ellipse((18,12,22,16), 1.5)
        line([(16,17),(14,20),(18,20),(16,17)], 1)
        line([(14,24),(14,28)], 1)
        line([(18,24),(18,28)], 1)
    atlas.alpha_composite(tile, (index * CELL * SCALE, 0))

atlas = atlas.resize((CELL*8,CELL), Image.Resampling.LANCZOS)
root = Path(__file__).resolve().parents[1]
atlas.save(root / 'EUIAddonSkins/Media/DBMMechanics.tga')
