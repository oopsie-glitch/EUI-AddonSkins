"""Exercise late, already-accented labels independently of the existing tests."""
from pathlib import Path
from urllib.request import urlopen
import subprocess,sys
path=Path("EUIAddonSkins/Skins/HuntersFieldGuide.lua")
candidate=path.read_bytes()
with urlopen("https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/bb24ae8f463990d6b4ffc5c4aa866d0660c7ac8c/tests/huntersfieldguide_spec.lua",timeout=30)as r:test=r.read().decode()
test=test.replace("        -- Accent change: owned art and accent text follow, the open page is redrawn.",'''        local lateAccent = text(root, styles.accent.color, "Late accent heading")
        guide:RefreshUI()
        -- Accent change: owned art and accent text follow, the open page is redrawn.''')
test=test.replace("assert(line.fill[1] == 0.9 and styles.accent.color[1] == 0.9 and guide.refreshes == drawn + 1)","assert(line.fill[1] == 0.9 and styles.accent.color[1] == 0.9 and guide.refreshes == drawn + 1)\n        assert(Near(accent, lateAccent:GetTextColor()), 'late native accent label failed theme synchronization')")
target=Path("/tmp/hfg-late-accent-spec.lua");target.write_text(test)
runner=Path("tests/run_lua.py").read_text();first=runner.index("    for test in [");last=runner.index(":\n",first)
runner=runner[:first]+"    for test in ['/tmp/hfg-late-accent-spec.lua']"+runner[last:]
try:
 for mode in ("original","candidate"):
  if mode=="original":
   with urlopen("https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/bb24ae8f463990d6b4ffc5c4aa866d0660c7ac8c/EUIAddonSkins/Skins/HuntersFieldGuide.lua",timeout=30)as r:path.write_bytes(r.read())
  else:path.write_bytes(candidate)
  result=subprocess.run([sys.executable,"-c",runner],capture_output=True,text=True)
  print("LATE_ACCENT",mode,"PASS"if result.returncode==0 else"FAIL",flush=True)
  if result.returncode:
   assert "late native accent label failed theme synchronization"in result.stderr,result.stdout+result.stderr
   print("Confirmed: late native accent label failed theme synchronization")
finally:path.write_bytes(candidate)
