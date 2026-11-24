"""Locate public upstream source; report UI symbols only, never raw source."""
from urllib.request import Request,urlopen
from zipfile import ZipFile
from io import BytesIO
from hashlib import sha256
import json,re
from pathlib import Path
def get(url):
 with urlopen(Request(url,headers={"User-Agent":"EUIAddonSkins-CompatibilityAudit/1.0"}),timeout=30)as r:return r.read()
try:
 meta=json.loads(get("https://api.cfwidget.com/wow/addons/hunters-field-guide"))
 files=meta.get("files",[])
 print("HFG_PUBLIC_FILES",json.dumps([{k:f.get(k)for k in ("id","display","name","version","url")}for f in files[:5]]))
 file=next((f for f in files if "1.1.1"in str(f)),None)
 if not file:raise RuntimeError("reviewed 1.1.1 source not present in metadata")
 fid=str(file["id"]);name=file.get("name")
 if not name:raise RuntimeError("filename unavailable")
 data=get("https://edge.forgecdn.net/files/"+fid[:-3]+"/"+str(int(fid[-3:]))+"/"+name)
 z=ZipFile(BytesIO(data));print("HFG_ARCHIVE_SHA",sha256(data).hexdigest())
 names=[n for n in z.namelist()if n.lower().endswith(".lua")]
 print("HFG_LUA_FILES",json.dumps(names))
 for n in names:
  if not re.search(r"UI|Skin|Core",n,re.I):continue
  text=z.read(n).decode("utf-8-sig")
  funcs=[]
  for match in re.finditer(r"(?:local\s+)?function\s+([\w.:]+)\s*\(([^)]*)\)",text):
   body=text[match.end():]
   end=re.search(r"\n(?:local\s+)?function\s+",body)
   body=body[:end.start()]if end else body
   if re.search(r"SetTextColor|styles\[|\.styles|CreateFontString|skinName|SKINS|SetFontObject",body):
    funcs.append({"function":match.group(1),"parameters":match.group(2),"calls":sorted(set(re.findall(r"[:.]([A-Za-z_]\w*)\s*\(",body))),"styleFields":sorted(set(re.findall(r"(?:styles|SKINS)[.[]([A-Za-z_]\w*)",body)))})
  print("HFG_UI_SYMBOLS",json.dumps({"file":n,"functions":funcs}))
 Path("/tmp/hfg-upstream.zip").write_bytes(data)
except Exception as e:
 print("HFG_SOURCE_LIMITATION",type(e).__name__,str(e)[:240])
