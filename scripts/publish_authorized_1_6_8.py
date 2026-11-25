"""Publish only the exact merged, validated, explicitly authorized v1.6.8 tree."""
import os,json,hashlib,time
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.error import HTTPError
from urllib.parse import quote
from datetime import datetime,timezone
repo="oopsie-glitch/EUI-AddonSkins"
base="https://api.github.com/repos/"+repo
token=os.environ["GITHUB_TOKEN"]
target=os.environ["EXPECTED_MAIN"]
candidate=os.environ["EXPECTED_CANDIDATE"]
expected_tree=os.environ["EXPECTED_TREE"]
def api(path,data=None,method=None):
 url=path if path.startswith("https://")else base+"/"+path
 body=None if data is None else json.dumps(data).encode()
 headers={"Authorization":"Bearer "+token,"Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28"}
 if body is not None:headers["Content-Type"]="application/json"
 with urlopen(Request(url,data=body,headers=headers,method=method),timeout=60)as response:
  payload=response.read()
  return json.loads(payload)if payload else None
def absent(path):
 try:api(path)
 except HTTPError as error:
  assert error.code==404,"Unexpected release/tag access error"
 else:raise AssertionError("Release/tag already exists; do not recreate or move it")
assert api("branches/main")["commit"]["sha"]==target,"main advanced"
for sha in (target,candidate):
 assert api("git/commits/"+sha)["tree"]["sha"]==expected_tree,"Untested release tree"
pr=api("pulls/101")
assert pr["merged"] and pr["merge_commit_sha"]==target and pr["head"]["sha"]==candidate
for sha,required in ((target,"validate"),(candidate,"combined")):
 checks=api("commits/"+sha+"/check-runs")["check_runs"]
 assert any(c["name"]==required and c["conclusion"]=="success"for c in checks),required
 assert all(c["status"]=="completed" and c["conclusion"]in("success","skipped","neutral")for c in checks),"Unfinished/failing checks"
absent("git/ref/tags/v1.6.8");absent("releases/tags/v1.6.8")
toc=Path("EUIAddonSkins/EUIAddonSkins.toc").read_text()
assert "## Version: 1.6.8" in toc
notes=Path("docs/releases/v1.6.8.md").read_text()+"\nRequires EllesmereUI with Blizzard Skins+ enabled. Extract the EUIAddonSkins folder into Interface/AddOns and restart the game. Keep SavedVariables to retain your settings.\n"
archive=Path("EUIAddonSkins-1.6.8.zip").read_bytes()
digest=hashlib.sha256(archive).hexdigest()
# Annotation and immutable reference creation follow the existing release convention.
tag=api("git/tags",{"tag":"v1.6.8","message":"EUI AddonSkins 1.6.8","object":target,"type":"commit","tagger":{"name":"github-actions[bot]","email":"41898282+github-actions[bot]@users.noreply.github.com","date":datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}})
api("git/refs",{"ref":"refs/tags/v1.6.8","sha":tag["sha"]})
assert api("git/tags/"+tag["sha"])["object"]["sha"]==target
release=api("releases",{"tag_name":"v1.6.8","target_commitish":target,"name":"EUI AddonSkins v1.6.8","body":notes,"draft":False,"prerelease":False,"generate_release_notes":False})
url=release["upload_url"].split("{",1)[0]+"?name="+quote("EUIAddonSkins-1.6.8.zip")
request=Request(url,data=archive,headers={"Authorization":"Bearer "+token,"Content-Type":"application/zip","Accept":"application/vnd.github+json"},method="POST")
with urlopen(request,timeout=120)as response:asset=json.loads(response.read())
actual=None
for attempt in range(5):
 try:
  with urlopen(asset["browser_download_url"],timeout=90)as response:actual=response.read()
  break
 except HTTPError as error:
  if error.code not in(404,429,500,502,503,504)or attempt==4:raise
  time.sleep(min(2**attempt,8))
assert actual==archive,"Published asset differs from validated ZIP"
confirmed=api("releases/tags/v1.6.8")
assert not confirmed["draft"] and not confirmed["prerelease"] and confirmed["published_at"]
assert len(confirmed["assets"])==1 and confirmed["assets"][0]["id"]==asset["id"]
print("PUBLISHED_RELEASE",json.dumps({"tag":"v1.6.8","commit":target,"tag_object":tag["sha"],"url":confirmed["html_url"],"asset_url":asset["browser_download_url"],"asset_bytes":len(archive),"sha256":digest,"download_verified":True,"Wago_dispatch_initiated":False}))
