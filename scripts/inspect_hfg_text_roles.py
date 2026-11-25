"""Inspect source-owned text roles without outputting upstream source bodies."""
from urllib.request import Request,urlopen
from zipfile import ZipFile
from io import BytesIO
from hashlib import sha256
import re,json
u="https://edge.forgecdn.net/files/9780/878/HuntersFieldGuide-1.3.0.zip"
data=urlopen(Request(u,headers={"User-Agent":"EUIAddonSkins-OwnershipAudit/1"}),timeout=45).read()
assert sha256(data).hexdigest()=="caa507c63478c10140478e231694e9d79883213010dfdd5007dc59244cceb941"
z=ZipFile(BytesIO(data))
print("HFG_SOURCE_FILES",json.dumps(z.namelist()))
for path in z.namelist():
 if not path.endswith(".lua") or "/Lib" in path:continue
 s=z.read(path).decode("utf-8-sig")
 functions=list(re.finditer(r"^(?:local\s+)?function\s+([\w.:]+)\s*\(([^)]*)\)",s,re.M))
 def context(pos):
  prior=[m for m in functions if m.start()<pos]
  return prior[-1].group(1) if prior else "<module>"
 def arguments(start):
  depth=1;i=start;quote=None
  while i<len(s) and depth:
   c=s[i]
   if quote:
    if c=="\\":i+=2;continue
    if c==quote:quote=None
   elif c in "\"'":quote=c
   elif c=="(":depth+=1
   elif c==")":depth-=1
   i+=1
  return s[start:i-1]
 records=[]
 for m in re.finditer(r"\b(Style|SubText|Text|NewText|CreateFontString|SetFontObject|SetTextColor|SetFont)\s*\(",s):
  a=arguments(m.end())
  line=s[s.rfind("\n",0,m.start())+1:s.find("\n",m.start())]
  lhs=re.match(r"\s*(?:local\s+)?([\w., ]+)\s*=\s*",line)
  records.append({"line":s.count("\n",0,m.start())+1,"function":context(m.start()),"call":m.group(1),
    "assignment":lhs.group(1).strip()if lhs else None,
    "arguments":re.findall(r"[\w.:]+|[\"'][^\"'\n]*[\"']",a)[:35]})
 if records:
  print("HFG_TEXT_ROLE_CALLS",json.dumps({"file":path,"calls":records}))
 if path.endswith("UI.lua"):
  print("HFG_FUNCTIONS",json.dumps([{"name":m.group(1),"args":m.group(2),"line":s.count("\n",0,m.start())+1}for m in functions]))
  fields=[{"owner":m.group(1),"field":m.group(2),"refs":re.findall(r"[\w.:]+",m.group(3))[:18],"function":context(m.start()),"line":s.count("\n",0,m.start())+1}for m in re.finditer(r"\b(\w+)\.(\w+)\s*=\s*([^\n]+)",s)]
  print("HFG_STRUCTURES",json.dumps(fields))

# Trace public producers and arguments of the private pooled-text writers.
ui=z.read("HuntersFieldGuide/UI.lua").decode("utf-8-sig")
top=list(re.finditer(r"^(?:local\s+)?function\s+([\w.:]+)\s*\(([^)]*)\)",ui,re.M))
for i,m in enumerate(top):
 stop=top[i+1].start()if i+1<len(top)else len(ui)
 body=ui[m.end():stop]
 if re.search(r"\bWrite(?:Lines|Side)\(",body) or m.group(1).startswith("PD:"):
  calls=sorted(set(re.findall(r"\b((?:PD:|self:)[A-Za-z_][\w]*|WriteLines|WriteSide|[A-Z][A-Za-z_]*(?:Lines|Text|Detail))\s*\(",body)))
  if calls:print("HFG_TEXT_FLOW",json.dumps({"function":m.group(1),"line":ui.count("\n",0,m.start())+1,"calls":calls,"pooledWrites":[re.findall(r"[\w.:]+",x)[:30]for x in re.findall(r"\bWrite(?:Lines|Side)\(([^\n]*)",body)]}))
for path in z.namelist():
 if not path.endswith(".lua"):continue
 text=z.read(path).decode("utf-8-sig")
 exports=re.findall(r"^(?:function\s+(PD:[\w]+)|\s*(PD\.[\w]+)\s*=)",text,re.M)
 if exports:print("HFG_NAMESPACE_EXPORTS",json.dumps({"file":path,"exports":[a or b for a,b in exports]}))

assert any(m.group(1)=="WriteLines" for m in top),"Pooled-writer flow parser did not find native WriteLines"
