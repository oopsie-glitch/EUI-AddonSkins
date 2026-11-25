"""Read public distribution metadata; never upload or expose credentials."""
from urllib.request import Request,urlopen
from urllib.error import HTTPError
from concurrent.futures import ThreadPoolExecutor
from io import BytesIO
from zipfile import ZipFile
from pathlib import Path
import json,re
slugs=("1737903",)
def get(url):
 with urlopen(Request(url,headers={"User-Agent":"Mozilla/5.0","Accept":"application/json"}),timeout=25)as r:return r.read()
def probe(slug):
 url="https://api.cfwidget.com/"+slug if slug.isdigit() else "https://api.cfwidget.com/wow/addons/"+slug
 try:
  data=json.loads(get(url))
  return slug,data,None
 except Exception as error:return slug,None,type(error).__name__+": "+str(error)
found=False
for slug,data,error in ThreadPoolExecutor(max_workers=4).map(probe,slugs):
 if error:
  print("CURSEFORGE_LOOKUP",json.dumps({"slug":slug,"state":"unavailable","detail":error}));continue
 files=data.get("files",[])
 if isinstance(files,dict):files=list(files.values())
 match=[f for f in files if isinstance(f,dict)and re.search(r"(?<![0-9])1\.6\.8(?![0-9])",str(f.get("name",""))+" "+str(f.get("display",""))+" "+str(f.get("displayName","")))]
 print("CURSEFORGE_PROJECT",json.dumps({"slug":slug,"id":data.get("id"),"title":data.get("title",data.get("name")),"url":data.get("url"),"source_links":data.get("links"),"recent_files":[{k:f.get(k)for k in ("id","name","display","url","type","versions")}for f in files[:5]if isinstance(f,dict)],"v1.6.8_files":len(match)}))
 for f in match:
  fid=str(f.get("id",""));name=f.get("name","")
  if not(fid.isdigit() and name.endswith(".zip")):
   print("CURSEFORGE_VERSION_FOUND_PACKAGE_UNVERIFIED",json.dumps(f));continue
  url="https://edge.forgecdn.net/files/"+fid[:-3]+"/"+str(int(fid[-3:]))+"/"+name
  try:
   raw=get(url);archive=ZipFile(BytesIO(raw));assert archive.testzip()is None
   expected=ZipFile("EUIAddonSkins-1.6.8.zip")
   assert set(archive.namelist())==set(expected.namelist()),"Package file list differs"
   for n in expected.namelist():
    actual=archive.read(n);wanted=expected.read(n)
    if n.endswith(".toc"):
     assert b"## Version: 1.6.8" in actual
     # Client-specific interface normalization is allowed by the release docs.
     clean=lambda b:re.sub(rb"(?m)^## Interface:.*(?:\r?\n|$)",b"",b)
     assert clean(actual)==clean(wanted),"Unexpected TOC change: "+n
    else:assert actual==wanted,"Runtime byte mismatch: "+n
   found=True
   print("CURSEFORGE_CONFIRMED",json.dumps({"file_id":fid,"filename":name,"url":f.get("url"),"version":"1.6.8","files":len(archive.namelist()),"runtime_verified":True,"game_versions":f.get("versions")}))
  except Exception as error:print("CURSEFORGE_PACKAGE_UNVERIFIED",json.dumps({"file_id":fid,"error":str(error)}))
print("DISTRIBUTION_AUDIT",json.dumps({"CurseForge_confirmed":found,"webhook_delivery":"not accessible through public metadata","Wago_upload_initiated":False,"note":"No external distribution is claimed unless a public package was downloaded and verified."}))
