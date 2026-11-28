"""Inspect verified 13014 lifecycle; do not bundle target code or assets."""
import hashlib, io, re, urllib.request, zipfile
URL = "https://github.com/user-attachments/files/35548736/AtlasLootContinued-Forever_13014.zip"
with urllib.request.urlopen(URL, timeout=60) as r:
    data=r.read()
digest=hashlib.sha256(data).hexdigest()
assert digest=="f3a7ffc65480a92c7b18961409087d9b2f83b1bf9d942fcd230b3cc28d479a1d"
print("ARCHIVE_SHA256",digest)
with zipfile.ZipFile(io.BytesIO(data)) as z:
    for path in ["AtlasLootContinued/GUI/Nav.lua","AtlasLootContinued/GUI/GUI.lua",
                 "AtlasLootContinued_Favourites/Favourites_GUI.lua","AtlasLootContinued_Favourites/Favourites_Nav.lua",
                 "AtlasLootContinued_Options/Core.lua","AtlasLootContinued_Options/SettingsNav.lua"]:
        lines=z.read(path).decode('utf-8-sig').splitlines()
        selected=set()
        if path.endswith('/Nav.lua'):
            selected.update(range(0,70));selected.update(range(2270,min(2490,len(lines))))
        else:
            for i,line in enumerate(lines):
                if re.search(r'Nav|nav|style|Style|Reload|reload|fallback|Fallback',line):
                    selected.update(range(max(0,i-3),min(len(lines),i+5)))
        print("LIFECYCLE",path)
        for i in sorted(selected):print(str(i+1)+": "+lines[i])
