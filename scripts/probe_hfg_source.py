"""Inspect public upstream UI symbols; never print addon source."""
from urllib.request import Request,urlopen
from zipfile import ZipFile
from io import BytesIO
from hashlib import sha256
import re,json
from pathlib import Path
def get(u):
 with urlopen(Request(u,headers={"User-Agent":"Mozilla/5.0"}),timeout=30)as r:return r.read()
data=get("https://edge.forgecdn.net/files/9780/878/HuntersFieldGuide-1.3.0.zip")
print("HFG_SOURCE_ARCHIVE",json.dumps({"version":"1.3.0","fileId":9780878,"sha256":sha256(data).hexdigest()}))
z=ZipFile(BytesIO(data));Path("/tmp/hfg-upstream.zip").write_bytes(data)
print("HFG_SOURCE_FILES",json.dumps([n for n in z.namelist()if n.endswith(".lua")]))
for n in z.namelist():
 if not n.endswith(".lua"):continue
 t=z.read(n).decode("utf-8-sig")
 if not any(v in t for v in ("CreateFontString","SetTextColor","Skins =","styles =")):continue
 symbols=[]
 for i,line in enumerate(t.splitlines(),1):
  if "function"in line:
   match=re.search(r"function\s+([\w.:]+)\s*\(([^)]*)\)|([\w.]+)\s*=\s*function\s*\(([^)]*)\)",line)
   if match:symbols.append({"line":i,"function":match.group(1)or match.group(3),"args":match.group(2)or match.group(4)})
 colors=[]
 lines=t.splitlines()
 for i,line in enumerate(lines):
  if "SetTextColor"in line or "CreateFontString"in line or ("styles["in line and "="in line):
   colors.append({"line":i+1,"receiver":re.findall(r"([\w.]+):(?:SetTextColor|CreateFontString)",line),"styleKeys":re.findall(r"(?:styles|style)\[([^\]]+)\]",line),"assignedFields":re.findall(r"([\w.]+)\s*=",line),"calls":re.findall(r"[:.]([\w]+)\(",line)})
 print("HFG_SOURCE_SYMBOLS",json.dumps({"file":n,"functions":symbols,"colorSites":colors}))

t=z.read("HuntersFieldGuide/UI.lua").decode("utf-8-sig")
lines=t.splitlines()
for name,start,stop in (("Text",42,50),("Style",63,72)):
 body="\n".join(lines[start:stop])
 print("HFG_COLOR_DATAFLOW",json.dumps({"function":name,"assignments":[{"target":m.group(1),"valueIdentifiers":re.findall(r"[A-Za-z_][A-Za-z_0-9.]*",m.group(2)),"literals":re.findall(r'["\']([^"\']+)["\']',m.group(2))}for m in re.finditer(r"([\w.]+)\s*=\s*([^\n]+)",body)],"methodCalls":[{"receiver":m.group(1),"method":m.group(2),"arguments":m.group(3)}for m in re.finditer(r"(\w+):(\w+)\(([^)]*)\)",body)]}))
print("HFG_STYLE_EXPORTS",json.dumps(re.findall(r'(\b\w+\.\w+)\s*=\s*(Style|Text)\b',t)))
print("HFG_FONTSTRING_TAGS",json.dumps(sorted(set(re.findall(r"\bfs\.(\w+)\s*=",t)))))
