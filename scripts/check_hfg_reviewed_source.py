"""Inspect authoritative version-history metadata; no source contents in logs."""
from urllib.request import Request,urlopen
from concurrent.futures import ThreadPoolExecutor
from zipfile import ZipFile
from io import BytesIO
from hashlib import sha256
import re,json
URLS=[
"https://www.curseforge.com/wow/addons/hunters-field-guide/files/all?page=1&pageSize=50",
"https://www.curseforge.com/wow/addons/hunters-field-guide/files/all?page=2&pageSize=50",
"https://www.curseforge.com/api/v1/mods/1741897/files?pageIndex=0&pageSize=50&sort=dateCreated&sortDescending=true&removeAlphas=false",
"https://www.curseforge.com/api/v1/mods/1741897/files",
"https://api.cfwidget.com/1741897"]
def get(u):
 with urlopen(Request(u,headers={"User-Agent":"Mozilla/5.0"}),timeout=20)as r:return r.read()
def fetch(u):
 try:return u,get(u),None
 except Exception as e:return u,None,type(e).__name__+": "+str(e)[:100]
candidates=[]
for u,raw,error in ThreadPoolExecutor(max_workers=4).map(fetch,URLS):
 if error:print("HFG_HISTORY_FETCH",json.dumps({"url":u,"error":error}));continue
 s=raw.decode("utf-8","replace");decoded=s.replace('\\"','"')
 names=sorted(set(re.findall(r'[A-Za-z0-9_. -]*[Hh]unters?[A-Za-z0-9_. -]*\.zip',decoded)))
 ids=sorted(set(re.findall(r'/wow/addons/hunters-field-guide/files/(\d+)',decoded)))
 print("HFG_HISTORY_FETCH",json.dumps({"url":u,"bytes":len(raw),"contains_1_1_1":"1.1.1"in decoded,"fileNames":names[:60],"linkedFileIds":ids[:60]}))
 try:
  obj=json.loads(s)
 except Exception:obj=None
 def visit(x):
  if isinstance(x,dict):
   name=x.get("name")or x.get("fileName")or x.get("displayName")or x.get("display")or""
   fid=x.get("id")or x.get("fileId")
   if "1.1.1"in str(name)and fid:candidates.append((str(fid),str(name)))
   for value in x.values():visit(value)
  elif isinstance(x,list):
   for value in x:visit(value)
 if obj:visit(obj)
 if "1.1.1"in decoded:
  for m in re.finditer("1.1.1",decoded):
   block=decoded[max(0,m.start()-800):m.end()+800]
   possible=re.findall(r'"(?:id|fileId)"\s*:\s*(\d+)',block)
   fn=re.findall(r'[\w.-]*HuntersFieldGuide[\w.-]*1\.1\.1[\w.-]*\.zip',block,re.I)
   for fid in possible:
    for name in fn:candidates.append((fid,name))
print("HFG_REVIEWED_SOURCE_CANDIDATES",json.dumps(sorted(set(candidates))))
verified=False
for fid,name in sorted(set(candidates))[:12]:
 if not name.endswith(".zip"):name="HuntersFieldGuide-1.1.1.zip"
 try:
  data=get("https://edge.forgecdn.net/files/"+fid[:-3]+"/"+str(int(fid[-3:]))+"/"+name)
  z=ZipFile(BytesIO(data))
  tocs={p:z.read(p).decode("utf-8-sig")for p in z.namelist()if p.endswith(".toc")}
  versions={p:re.findall(r"## Version:\s*([^\r\n]+)",s)for p,s in tocs.items()}
  if not any("1.1.1"in v for vs in versions.values()for v in vs):continue
  verified=True
  ui=z.read("HuntersFieldGuide/UI.lua").decode("utf-8-sig")
  start=ui.find("local function Style(fs, kind)");end=ui.find("local function SubText",start)
  style=ui[start:end]if start>=0 and end>start else""
  print("HFG_REVIEWED_SOURCE_VERIFIED",json.dumps({"fileId":fid,"fileName":name,"sha256":sha256(data).hexdigest(),"tocVersions":versions,"stylePrivate":start>=0,"styleRoleTags":re.findall(r"\bfs\.(\w+)\s*=",style),"styleReadsRolePalette":"skin.styles[kind]"in style,"styleSetsFont":"fs:SetFontObject(st.font)"in style,"styleSetsRGB":"fs:SetTextColor(st.color[1], st.color[2], st.color[3])"in style}))
  from pathlib import Path
  Path("/tmp/hfg-reviewed-1.1.1.zip").write_bytes(data)
  break
 except Exception as e:print("HFG_REVIEWED_CANDIDATE_UNAVAILABLE",fid,type(e).__name__)
if not verified:print("HFG_REVIEWED_SOURCE_UNAVAILABLE: exact 1.1.1 archive was not retrievable from the inspected official history/public metadata; no substitution is authorized.")
