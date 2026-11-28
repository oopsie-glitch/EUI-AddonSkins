import hashlib,io,urllib.request,zipfile
with urllib.request.urlopen('https://github.com/user-attachments/files/35548736/AtlasLootContinued-Forever_13014.zip',timeout=60) as r:data=r.read()
assert hashlib.sha256(data).hexdigest()=='f3a7ffc65480a92c7b18961409087d9b2f83b1bf9d942fcd230b3cc28d479a1d'
with zipfile.ZipFile(io.BytesIO(data)) as z:
    for path,spans in {
        'AtlasLootContinued/GUI/GUI.lua':[(1,85),(1454,1482)],
        'AtlasLootContinued/GUI/Template_DropDown.lua':[(500,760)],
    }.items():
        lines=z.read(path).decode('utf-8-sig').splitlines()
        print('VISUAL_SOURCE',path)
        for start,end in spans:
            for i in range(start-1,min(len(lines),end)):print(str(i+1)+': '+lines[i])
