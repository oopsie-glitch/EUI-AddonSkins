"""Rebuild the licensed native Details toolbar art; development only.

Sources are unchanged Feather v4.29.2 SVGs at
1b002399e8758fb2bccea4d07312dc9e0f43dcb8 (MIT, Cole Bemis).
No EllesmereUI or Blizzard pixels are copied. Requires CairoSVG and Pillow
on the GitHub Actions runner; neither library enters the addon package.
"""
from pathlib import Path
from io import BytesIO
import argparse
import base64
import json
import struct
import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source/details-native-toolbar"
TARGET = ROOT / "EUIAddonSkins/Media/DetailsNative"
ICONS = {
    "settings": "settings", "undo": "rotate-ccw", "sheet": "file-text",
    "report": "radio", "reset": "refresh-cw", "open": "plus", "close": "x",
}

def build(name):
    svg = (SOURCE / (name + ".svg")).read_text().replace("currentColor", "#ffffff")
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=128, output_height=128)
    image = Image.open(BytesIO(png)).convert("RGBA").resize((32, 32), Image.Resampling.LANCZOS)
    # WoW-compatible uncompressed BGRA, top-left origin, 8 alpha bits.
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, 32, 32, 32, 0x28)
    # Transparent RGB does not matter; white RGB preserves native state tinting.
    pixels = bytes(channel for _, _, _, alpha in image.getdata() for channel in (255, 255, 255, alpha))
    return header + pixels

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--emit", action="store_true", help="emit GitHub blob payloads without writing files")
    args = parser.parse_args()
    for output, source in ICONS.items():
        data = build(source)
        path = TARGET / (output + ".tga")
        if args.emit:
            print("DETAILS_MEDIA_BLOB " + json.dumps({"path": path.relative_to(ROOT).as_posix(), "base64": base64.b64encode(data).decode()}))
        else:
            assert path.read_bytes() == data, str(path) + ": rebuild differs from tracked artwork"
    if not args.emit:
        assert (TARGET / "LICENSE.txt").read_bytes() == (SOURCE / "LICENSE").read_bytes()
        print("Verified seven tracked Feather rasterizations and exact MIT notice")
