"""Check every downloaded artifact file against the validated installation archive."""
import os,json
from zipfile import ZipFile
from pathlib import Path
built=ZipFile("EUIAddonSkins.zip")
root=Path("/tmp/cheap-verify")
actual={p.relative_to(root).as_posix():p for p in root.rglob("*") if p.is_file()}
assert set(actual)==set(built.namelist()),"Unexpected uploaded files or wrapper directory"
assert built.testzip() is None
for name,path in actual.items():assert path.read_bytes()==built.read(name),name
assert "EUIAddonSkins/Skins/CheapUpgrades.lua" in actual
assert not any("/tests/" in n or "/.github/" in n or n.startswith("CheapUpgrades/") for n in actual)
print("UPLOADED_PACKAGE",json.dumps({"commit":os.environ["GITHUB_SHA"],"files":len(actual),"all_runtime_bytes_match":True}))
