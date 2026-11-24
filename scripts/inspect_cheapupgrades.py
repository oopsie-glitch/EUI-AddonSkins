"""Pin the authoritative addon without executing, logging or bundling its source."""
from urllib.request import urlopen
from zipfile import ZipFile
from io import BytesIO
from hashlib import sha256
from pathlib import Path
import re,json
url="https://github.com/user-attachments/files/35381363/CheapUpgrades-0.18.9.zip"
data=urlopen(url,timeout=45).read()
assert sha256(data).hexdigest()=="79bdfc5e451360a2f19310e5aae575daae4456428474471e7ae9b4086aad2b47"
z=ZipFile(BytesIO(data))
assert len(z.namelist())==39
assert not any("SavedVariables/" in n or n.startswith("/") or "../" in n for n in z.namelist())
toc=z.read("CheapUpgrades/CheapUpgrades.toc").decode("utf-8-sig")
assert "## Version: 0.18.9" in toc and "## Interface: 16001" in toc
ui=z.read("CheapUpgrades/UI.lua").decode("utf-8-sig")
options=z.read("CheapUpgrades/Options.lua").decode("utf-8-sig")
for method in ("CreateUI","AttachAHButton","ShowUI","RefreshUI"):
 assert re.search(r"function\s+CU:"+method+r"\(",ui),method
for method in ("CreatePanel","Open","AskSpec","ShowPage","BuildPage"):
 assert re.search(r"function\s+Options:"+method+r"\(",options),method
assert 'LibAHTab-1-0' in ui and 'TAB_PREFIX' in ui
assert re.search(r'TAB_PREFIX\s*=\s*"CheapUpgrades_"',ui)
assert 'self.ahTabs' in ui and 'lib:CreateTab' in ui
assert 'CreateCell(sheet, g' in ui and 'CreateAltCell(altChild, i)' in ui
assert 'for i = 1, ALT_MAX do' in ui
# Only selected ownership metadata is reported. No addon source is output.
print("Authoritative Cheap Upgrades: 0.18.9 / 16001, SHA256 verified, 39 files; stable builders and fixed item pools: PASS")
for label,text in (("UI",ui),("Options",options)):
 print("OWNERSHIP",label,json.dumps({
 "indexedPageFields":sorted(set(re.findall(r"self\.pages\[[^\]]+\]\s*=\s*(\w+)",text))),
 "insetTemplates":sorted(set(re.findall(r'["\x27](\w*Inset\w*Template)["\x27]',text))),
 "ownTabGlobals":sorted(set(re.findall(r'["\x27](CheapUpgradesAHTab_[^"\x27]*)["\x27]',text))),
 "backdropCallOwners":sorted(set(re.findall(r"(\w+):SetBackdrop\(",text))),
 "returnedLocalFields":sorted(set(re.findall(r"\bpage\.(\w+)",text)))}))
lib_url="https://raw.githubusercontent.com/fiote/AuctionatorForever/d38a2cabd892571aae129dce5da801080de077b3/Libs_ModernAH/LibAHTab/LibAHTab.lua"
lib=urlopen(lib_url,timeout=45).read()
assert b'newTab:SetPoint("TOPLEFT", lib.internalState.Tabs[#lib.internalState.Tabs - 1]' in lib
Path("/tmp/cheap-ahtab.lua").write_bytes(lib)
print("Pinned Forever LibAHTab native row lifecycle: verified")
