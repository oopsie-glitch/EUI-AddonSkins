"""Inspect supplied authoritative archive without executing or redistributing it."""
from urllib.request import urlopen
from zipfile import ZipFile
from io import BytesIO
from hashlib import sha256
import re,json
URL="https://github.com/user-attachments/files/35381363/CheapUpgrades-0.18.9.zip"
with urlopen(URL,timeout=45)as r:data=r.read()
z=ZipFile(BytesIO(data))
names=z.namelist()
assert not any("SavedVariables/"in n or n.startswith("/")or"../"in n for n in names)
print("CU_ARCHIVE",json.dumps({"sha256":sha256(data).hexdigest(),"files":len(names)}))
for n in names:
 if n.endswith(".toc"):
  t=z.read(n).decode("utf-8-sig")
  print("CU_TOC",json.dumps({"path":n,"metadata":dict(re.findall(r"## ([^:]+):\s*([^\r\n]+)",t)),"loads":[l for l in t.splitlines()if l and not l.startswith("#")]}))
 if not n.endswith((".lua",".xml"))or"/Lib"in n or"/lib"in n:continue
 t=z.read(n).decode("utf-8-sig")
 functions=[{"name":m.group(1),"args":m.group(2)}for m in re.finditer(r"(?:local\s+)?function\s+([\w.:]+)\s*\(([^)]*)\)",t)]
 create=[{"target":m.group(1),"kind":m.group(2),"name":m.group(3),"parent":m.group(4),"template":m.group(5)}for m in re.finditer(r'([\w.]+)\s*=\s*CreateFrame\s*\(\s*["\'](\w+)["\']\s*,\s*([^,\n]+)\s*,\s*([^,\n)]+)(?:,\s*([^)\n]+))?',t)]
 methods=sorted(set(re.findall(r"\b([\w.]+):(?:RegisterCallback|RegisterEvent|HookScript|SetScript)\s*\(\s*['\"]([^'\"]+)",t)))
 refs=sorted(set(re.findall(r"\b(?:CheapUpgrades\w*|Auctionator\w*|Naowh\w*|AuctionFrame\w*|AuctionHouseFrame\w*|LibAHTab\w*)",t)))
 exports=sorted(set(re.findall(r"(?:_G\.|_G\[)([\w'\"]+)",t)))
 print("CU_UI_SYMBOLS",json.dumps({"file":n,"bytes":len(t),"functions":functions,"creates":create,"callbacks":methods,"integrationRefs":refs,"exports":exports,"templates":sorted(set(re.findall(r'["\'](\w+(?:Template|Mixin))["\']',t)))}))
from pathlib import Path
Path("/tmp/cheapupgrades-source.zip").write_bytes(data)
