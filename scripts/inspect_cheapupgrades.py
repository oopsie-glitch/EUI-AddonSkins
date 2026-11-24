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

# Report only owned UI structure and call contracts, not source bodies.
for file,names in {
"UI.lua":["CU.TabOffset","OwnTabs","CU:AttachAHButton","CU:CreateUI","CU:ShowTab","UpdateCell","CreateCell","CreateAltCell","UpdateAlternatives","CU:RefreshUI","CreateAHHost"],
"Options.lua":["Options:CreatePanel","Options:BuildPage","Options:ShowPage","Options:Open","Options:AskSpec","Options:CreateProfileBar"]}.items():
 text=z.read("CheapUpgrades/"+file).decode("utf-8-sig")
 for name in names:
  m=re.search(r"^(?:local\s+)?function\s+"+re.escape(name)+r"\s*\(([^)]*)\)",text,re.M)
  if not m:continue
  end=re.search(r"^(?:local\s+)?function\s+",text[m.end():],re.M)
  body=text[m.end():m.end()+end.start()]if end else text[m.end():]
  fields=[{"field":x.group(1),"type":"call"if"("in x.group(2)else"table"if"{"in x.group(2)else"value","valueRefs":sorted(set(re.findall(r"\b(?:CU|UI|Options|frame|panel|up|alt|self|ahHost|ownRoot|holder|tab)\.[\w.]+",x.group(2))))}for x in re.finditer(r"\b((?:CU|UI|Options|frame|panel|up|alt|self|ahHost|ownRoot|holder|tab)\.[\w.]+)\s*=\s*([^\n]+)",body)]
  calls=[{"callee":x.group(1),"args":x.group(2)[:220]}for x in re.finditer(r"([\w.:]+)\s*\(([^()\n]*)\)",body)if any(k in x.group(1)for k in ("Tab","Point","Size","Width","Height","CreateFrame","Hook","SetScript","Register"))]
  print("CU_FUNCTION_CONTRACT",json.dumps({"file":file,"name":name,"fields":fields,"calls":calls}))

for file,names in {"UI.lua":["CU.TabOffset","UpdateAlternatives","CU:RefreshUI","CreateCell","CreateAltCell","CU:AttachAHButton","CU:CreateUI"],"Options.lua":["Options:CreatePanel","Options:BuildPage","Options:Open","Options:ShowPage","Options:AskSpec"]}.items():
 text=z.read("CheapUpgrades/"+file).decode("utf-8-sig")
 for name in names:
  m=re.search(r"^(?:local\s+)?function\s+"+re.escape(name)+r"\s*\(([^)]*)\)",text,re.M)
  if not m:continue
  end=re.search(r"^(?:local\s+)?function\s+",text[m.end():],re.M)
  body=text[m.end():m.end()+end.start()]if end else text[m.end():]
  assignments=[{"target":x.group(1),"refs":re.findall(r"[\w.]+",x.group(2))[:28],"strings":re.findall(r'["\']([^"\']*)["\']',x.group(2))}for x in re.finditer(r"((?:\b\w+\.)+\w+)\s*=\s*([^\n]+)",body)]
  returned=re.findall(r"^\s*return\s+([^\n]+)",body,re.M)
  calls=[{"callee":x.group(1),"args":x.group(2)[:160]}for x in re.finditer(r"([\w.:]+)\s*\(([^()\n]*)\)",body)if "Create"in x.group(1)or"Refresh"in x.group(1)or"Hook"in x.group(1)or"Update"in x.group(1)]
  print("CU_DETAILS",json.dumps({"file":file,"function":name,"assignments":assignments,"returns":returned,"createsAndUpdates":calls,"loops":re.findall(r"^\s*for\s+([^\n]+)\s+do",body,re.M)}))
