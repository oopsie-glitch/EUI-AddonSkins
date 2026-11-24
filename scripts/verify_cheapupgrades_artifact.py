"""Verify GitHub's uploaded installation ZIP against the already validated package."""
import os,json
from urllib.request import Request,urlopen,build_opener,HTTPRedirectHandler
from urllib.error import HTTPError
from zipfile import ZipFile
from io import BytesIO
from pathlib import Path
from hashlib import sha256
class NoRedirect(HTTPRedirectHandler):
 def redirect_request(self,req,fp,code,msg,headers,newurl):return None
url=f"https://api.github.com/repos/{os.environ['GITHUB_REPOSITORY']}/actions/artifacts/{os.environ['ARTIFACT_ID']}/zip"
request=Request(url,headers={"Authorization":"Bearer "+os.environ["GH_READ_TOKEN"],"Accept":"application/vnd.github+json"})
try:response=build_opener(NoRedirect).open(request,timeout=45)
except HTTPError as error:
 if error.code not in (301,302,303,307,308):raise
 location=error.headers["Location"]
 assert location.startswith("https://")
 # Download the signed blob without forwarding the GitHub credential.
 data=urlopen(location,timeout=60).read()
else:data=response.read()
archive=ZipFile(BytesIO(data))
built=ZipFile("EUIAddonSkins.zip")
actual={n for n in archive.namelist() if not n.endswith("/")}
assert actual==set(built.namelist()),"Unexpected uploaded files or wrapper directory"
assert archive.testzip() is None
for name in actual:assert archive.read(name)==built.read(name),name
assert "EUIAddonSkins/Skins/CheapUpgrades.lua" in actual
assert not any("/tests/" in n or "/.github/" in n or n.startswith("CheapUpgrades/") for n in actual)
print("UPLOADED_PACKAGE",json.dumps({"commit":os.environ["GITHUB_SHA"],"files":len(actual),"sha256":sha256(data).hexdigest(),"all_runtime_bytes_match":True}))
