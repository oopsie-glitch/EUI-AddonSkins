"""Verify the exact ownership limitation; never execute whole upstream addons."""
from pathlib import Path
from urllib.request import Request,urlopen
from zipfile import ZipFile
from io import BytesIO
from hashlib import sha256
import subprocess,sys,re,json
ORIGINAL="bb24ae8f463990d6b4ffc5c4aa866d0660c7ac8c"
PREVIOUS="2be3e53333114c75a76222fba8f259c11e13222e"
def get(url):
 with urlopen(Request(url,headers={"User-Agent":"EUIAddonSkins-SourceAudit/1.0"}),timeout=30)as r:return r.read()
data=get("https://edge.forgecdn.net/files/9780/878/HuntersFieldGuide-1.3.0.zip")
assert sha256(data).hexdigest()=="caa507c63478c10140478e231694e9d79883213010dfdd5007dc59244cceb941"
z=ZipFile(BytesIO(data))
toc_versions={name:re.findall(r"## Version:\s*([^\r\n]+)",z.read(name).decode("utf-8-sig"))for name in z.namelist()if name.endswith(".toc")}
assert toc_versions and all(values==["1.3.0"]for values in toc_versions.values()),"Unexpected current-source TOC version"
print("HFG_CURRENT_SOURCE_TOC",json.dumps(toc_versions))
ui=z.read("HuntersFieldGuide/UI.lua").decode("utf-8-sig")
# Verify actual source contracts without printing or redistributing the source.
style=ui[ui.index("local function Style(fs, kind)"):ui.index("local function SubText")]
assert "skin.styles[kind]"in style and "fs:SetFontObject(st.font)"in style and "fs:SetTextColor(st.color[1], st.color[2], st.color[3])"in style
assert not re.search(r"\bfs\.\w+\s*=",style),"Upstream now exposes metadata: reassess the ownership boundary"
assert not re.search(r"\b(?:PD|HuntersFieldGuide)\.\w+\s*=\s*Style\s*(?:\n|$)",ui),"Upstream may now expose Style"
forever=ui[ui.index("function SKINS.forever.Styles()"):ui.index("function SKINS.forever.CreateFrame()")]
for kind in ("body","accent","good","bad"):
 assert re.search(r"\b"+kind+r"\s*=\s*\{\s*font\s*=\s*body",forever)
print("HFG_SOURCE_CONTRACT version=1.3.0 checksum=pinned Style=private role_marker=absent body_accent_good_bad_font=shared")
path=Path("EUIAddonSkins/Skins/HuntersFieldGuide.lua");candidate=path.read_bytes()
test=get("https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/"+ORIGINAL+"/tests/huntersfieldguide_spec.lua").decode()
test=test.replace("        -- Accent change: owned art and accent text follow, the open page is redrawn.",'''        local lateAccent = text(root, styles.accent.color, "Late accent heading")
        local nativeSemantic = text(root, styles.accent.color, "Intentional semantic color")
        local oldAccent = {styles.accent.color[1], styles.accent.color[2], styles.accent.color[3]}
        guide:RefreshUI()
        -- Accent change: owned art and accent text follow, the open page is redrawn.''')
needle="assert(line.fill[1] == 0.9 and styles.accent.color[1] == 0.9 and guide.refreshes == drawn + 1)"
test=test.replace(needle,needle+'''
        print("HFG_OWNERSHIP_CASE late_accent="..tostring(Near(accent, lateAccent:GetTextColor())).." semantic_preserved="..tostring(Near(oldAccent,nativeSemantic:GetTextColor())))
''')
target=Path("/tmp/hfg-ownership-case.lua");target.write_text(test)
runner=Path("tests/run_lua.py").read_text();first=runner.index("    for test in [");last=runner.index(":\n",first)
runner=runner[:first]+"    for test in ['/tmp/hfg-ownership-case.lua']"+runner[last:]
expected={"original":("true","false"),"previous97":("false","true"),"current97":("false","true")}
try:
 for name,revision in (("original",ORIGINAL),("previous97",PREVIOUS),("current97",None)):
  path.write_bytes(get("https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/"+revision+"/EUIAddonSkins/Skins/HuntersFieldGuide.lua")if revision else candidate)
  r=subprocess.run([sys.executable,"-c",runner],capture_output=True,text=True)
  assert not r.returncode,r.stderr
  m=re.search(r"HFG_OWNERSHIP_CASE late_accent=(\w+) semantic_preserved=(\w+)",r.stdout)
  assert m and m.groups()==expected[name],r.stdout
  print("HFG_OWNERSHIP_MATRIX",json.dumps({"implementation":name,"late_accent":m[1]=="true","semantic_preserved":m[2]=="true"}))
finally:path.write_bytes(candidate)
assert path.read_bytes()==candidate
print("BLOCKED: no corrected runtime is claimed; a verified source-role boundary is required to satisfy both ownership cases.")
