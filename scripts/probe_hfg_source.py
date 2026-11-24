"""Public source discovery metadata only; no addon source is logged."""
from urllib.request import Request,urlopen
from urllib.error import HTTPError
import json,re
def get(u):
 with urlopen(Request(u,headers={"User-Agent":"Mozilla/5.0"}),timeout=30)as r:return r.read().decode()
for url in ("https://www.curseforge.com/wow/addons/hunters-field-guide","https://www.curseforge.com/wow/addons/hunters-field-guide/files/all"):
 try:
  s=get(url)
  print("HFG_PAGE_METADATA",json.dumps({"url":url,"bytes":len(s),"title":re.findall(r"<title>(.*?)</title>",s)[:1],"projectIds":re.findall(r'(?:projectId|projectID|Project ID|data-project-id)[^0-9]{0,30}([0-9]{4,10})',s)[:8],"filenames":re.findall(r'[A-Za-z0-9_. -]*[Hh]unters?[A-Za-z0-9_. -]*\.zip',s)[:8],"fileIds":re.findall(r'/wow/addons/hunters-field-guide/files/([0-9]+)',s)[:12]}))
 except Exception as e:print("HFG_PAGE_UNAVAILABLE",url,type(e).__name__,str(e)[:120])
