"""Build a disposable, opt-in render trace ZIP from this checkout."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("output", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
output = args.output.resolve()
with tempfile.TemporaryDirectory(prefix="rxp-render-probe-") as temp:
    build = Path(temp) / "checkout"
    shutil.copytree(root, build, ignore=shutil.ignore_patterns(".git", "*.zip", "__pycache__"))
    skin = build / "EUIAddonSkins/Skins/RXPGuides.lua"
    text = skin.read_text()
    probe = Path(__file__).with_name("rxp_render_probe.lua").read_text()
    for marker in ("    local function Apply()\n", "    refresh = function() H.Queue(module, Apply) end"):
        if text.count(marker) != 1:
            raise SystemExit(f"Unexpected skin source, missing unique marker {marker!r}")
    text = text.replace("    local function Apply()\n",
                        'local RXPRENDER_BUILD_ID = "PR75-render-trace-1"\n'
                        + probe + '\n    local function Apply()\n'
                        + '        renderProbe("EUIAS.Apply.before")\n')
    text = text.replace("    end\n    refresh = function() H.Queue(module, Apply) end",
                        '        renderProbe("EUIAS.Apply.after")\n'
                        + "    end\n    refresh = function() H.Queue(module, Apply) end")
    skin.write_text(text)
    collection = build / "tests/collection_spec.lua"
    spec = collection.read_text()
    setup = "modules.RXPGuides.install(S, modules.RXPGuides); flush()"
    anchor = "local legacyArt, guideArt = rings[guide].host, rings[window.frame].host\n"
    if spec.count(setup) != 1 or spec.count(anchor) != 1:
        raise SystemExit("Collection diagnostic smoke-test anchors changed")
    spec = spec.replace(setup, "SlashCmdList = SlashCmdList or {}\nGetTime = GetTime or function() return 5 end\n" + setup)
    smoke = Path(__file__).with_name("rxp_render_probe_smoke.lua").read_text()
    collection.write_text(spec.replace(anchor, anchor + smoke + "\n"))
    subprocess.run([sys.executable, "scripts/package.py"], cwd=build, check=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(build / "EUIAddonSkins.zip", output)
