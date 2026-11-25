"""Exact approved-tree and release package checks; no publication."""
from pathlib import Path
from hashlib import sha1,sha256
from zipfile import ZipFile
import json,re
manifest=json.loads(Path("docs/RELEASE_1.6.8_SOURCES.json").read_text())
for name,wanted in manifest["expected_runtime_blobs"].items():
 data=Path(name).read_bytes()
 actual=sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
 assert actual==wanted,"Unapproved runtime difference: "+name
for name in ("EUIAddonSkins.toc","EUIAddonSkins_Camelot.toc","EUIAddonSkins_Mainline.toc"):
 t=Path("EUIAddonSkins",name).read_text()
 assert "## Version: 1.6.8" in t and "16001" in t and "120105" in t
 assert t.count("DetailsNative.lua")==1 and t.count("Skins\\CheapUpgrades.lua")==1 and t.count("Skins\\LFGForever.lua")==1
assert 'ns.VERSION = "1.6.8"' in Path("EUIAddonSkins/Core.lua").read_text()
catalog=json.loads(Path("scripts/skin_catalog.json").read_text())
assert len(catalog)==49 and len({x[0]for x in catalog})==49
credit="Special thanks to [goldenpipes](https://github.com/goldenpipes) for contributing the original Hunter's Field Guide and ItemTree skins."
assert credit in Path("CHANGELOG.md").read_text() and credit in Path("docs/releases/v1.6.8.md").read_text()
assert Path("CHANGELOG.md").read_bytes()==Path("EUIAddonSkins/CHANGELOG.md").read_bytes()
with ZipFile("EUIAddonSkins-1.6.8.zip")as z:
 assert z.testzip()is None
 assert all(n.startswith("EUIAddonSkins/")for n in z.namelist())
 for n in z.namelist():assert z.read(n)==Path(n).read_bytes(),n
 assert not any("/GuildyBorder/"in n or "/tests/"in n or "/.github/"in n or "/source/"in n for n in z.namelist())
 for n in ("Skins/HuntersFieldGuide.lua","Skins/ItemTree.lua","Skins/LFGForever.lua","Skins/CheapUpgrades.lua","DetailsNative.lua","Media/DetailsNative/LICENSE.txt"):
  assert "EUIAddonSkins/"+n in z.namelist()
 assert z.read("EUIAddonSkins/LICENSE")==Path("LICENSE").read_bytes()
 print("RELEASE_PACKAGE",json.dumps({"version":"1.6.8","files":len(z.namelist()),"sha256":sha256(Path("EUIAddonSkins-1.6.8.zip").read_bytes()).hexdigest(),"approved_runtime_blobs":len(manifest["expected_runtime_blobs"]),"catalog":len(catalog),"HFG_main_unchanged":True}))
