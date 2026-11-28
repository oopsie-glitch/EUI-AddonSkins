import hashlib, io, re, urllib.request, zipfile
with urllib.request.urlopen("https://github.com/user-attachments/files/35548736/AtlasLootContinued-Forever_13014.zip",timeout=60) as r: data=r.read()
assert hashlib.sha256(data).hexdigest()=="f3a7ffc65480a92c7b18961409087d9b2f83b1bf9d942fcd230b3cc28d479a1d"
with zipfile.ZipFile(io.BytesIO(data)) as z:
    for p in ["AtlasLootContinued/GUI/Nav.lua","AtlasLootContinued/GUI/GUI.lua","AtlasLootContinued/GUI/NavKit.lua","AtlasLootContinued_Favourites/Favourites_Nav.lua","AtlasLootContinued_Options/SettingsNav.lua"]:
        lines=z.read(p).decode("utf-8-sig").splitlines(); selected=set()
        for i,l in enumerate(lines):
            if re.search(r'sessionLook|active\\s*=|applied\\s*=|function.*Fail|function.*IsEnabled|function GUI:Create|RELOAD_THEME|RELOAD_STYLE|OnCancel|OnAccept',l):
                selected.update(range(max(0,i-3),min(len(lines),i+12)))
        print("CONTRACT",p)
        for i in sorted(selected): print(str(i+1)+": "+lines[i])
