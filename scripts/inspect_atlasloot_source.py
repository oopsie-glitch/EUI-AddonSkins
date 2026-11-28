"""Pinned 13014 source tests and hosted Classic comparison. No upstream files ship."""
import ctypes, hashlib, io, json, statistics, sys, urllib.request, zipfile
from pathlib import Path
URL="https://github.com/user-attachments/files/35548736/AtlasLootContinued-Forever_13014.zip"
SHA="f3a7ffc65480a92c7b18961409087d9b2f83b1bf9d942fcd230b3cc28d479a1d"
with urllib.request.urlopen(URL,timeout=60) as r: data=r.read()
assert hashlib.sha256(data).hexdigest()==SHA
print("VERIFIED_SOURCE_SHA256",SHA)
archive=zipfile.ZipFile(io.BytesIO(data))
assert archive.testzip() is None
def source(path): return archive.read(path).decode("utf-8-sig")
assert "## Version: 13014" in source("AtlasLootContinued/AtlasLootContinued_Camelot.toc")
nav=source("AtlasLootContinued/GUI/Nav.lua")
gui=source("AtlasLootContinued/GUI/GUI.lua")
fav=source("AtlasLootContinued_Favourites/Favourites_Nav.lua")
assert 'GUI.NavStyle = FN' in fav and 'FN.applied = true' in fav and 'self.applied = false' in fav
assert 'Nav.active = true' in nav and 'self.active = false' in nav
assert 'if (db.style or "nav") == "nav" and GUI.Nav then' in gui
assert 'GUI.Nav:Apply(frame)' in gui
print("PASS: exact 13014 main navigation/fallback and independent Favourites runtime contracts")
def part(start, stop):
    return nav[nav.index(start):nav.index(stop,nav.index(start))]
parts=[
    part("function Nav:Revert()", "function Nav.GetStyle()"),
    part("function Nav.GetStyle()", "function Nav.SetStyle("),
    part("function Nav.SetStyle(", "function Nav.GetTheme()"),
    part("function Nav.GetLook()", "local function LookName("),
    part("function Nav.SetLook(", "function Nav.GetDungeonSort()"),
]
for name in ("ATLASLOOT_RELOAD_STYLE","ATLASLOOT_RELOAD_THEME"):
    start=nav.index('_G.StaticPopupDialogs["'+name+'"] = {')
    end=nav.index("\n\t}",start)+len("\n\t}")
    parts.append(nav[start:end])
factory="""
ATLAS_SOURCE_LIFECYCLE = function(AtlasLoot, GUI, Nav, db)
    local realG = _G
    local _G = setmetatable({StaticPopupDialogs={}, StaticPopup_Show=function()end,
        ReloadUI=function() Nav.testReloaded=true end}, {__index=realG})
    local Theme={LEGACY='legacy', themes={foreverbronze={},atlasnav={}},
        GetKey=function() return db.theme end, SetKey=function(key) db.theme=key;return true end}
    local DB=function()return db end
    local AL=setmetatable({}, {__index=function(_,key)return key end})
    local ShowBottomBar, ShowLegacyInfo, RestorePoints, UnskinItemButton =
        function()end,function()end,function()end,function()end
"""
factory+="\n".join(parts)+"""
    Nav.TestCancelReload=function()
        for _,dialog in pairs(_G.StaticPopupDialogs) do assert(dialog.OnCancel==nil) end
    end
end
"""
lua=ctypes.CDLL("liblua5.4.so.0")
lua.luaL_newstate.restype=ctypes.c_void_p
lua.luaL_openlibs.argtypes=[ctypes.c_void_p]
lua.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
lua.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lua.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
lua.lua_tolstring.restype=ctypes.c_char_p
lua.lua_getglobal.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
lua.lua_close.argtypes=[ctypes.c_void_p]
def run(code,result=False):
    state=lua.luaL_newstate();lua.luaL_openlibs(state)
    try:
        data=code.encode()
        rc=lua.luaL_loadbufferx(state,data,len(data),b"@tests/legacy_controls_spec.lua",None)
        if not rc: rc=lua.lua_pcallk(state,0,0,0,0,None)
        if rc: raise RuntimeError(lua.lua_tolstring(state,-1,None).decode())
        if result:
            lua.lua_getglobal(state,b"ATLAS_BENCH")
            return json.loads(lua.lua_tolstring(state,-1,None).decode())
    finally: lua.lua_close(state)
fixture=Path("tests/legacy_controls_spec.lua").read_text()
run(factory+fixture)
print("PASS: actual 13014 GetStyle/SetStyle/GetLook/SetLook/Revert and reload dialogs in adapter fixture")
paths=["EUIAddonSkins/Scoped.lua","EUIAddonSkins/Skins/AtlasLootContinued.lua"]
candidate={p:Path(p).read_text() for p in paths}
baseline={}
for p in paths:
    with urllib.request.urlopen("https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/0e388c8fc9fd635d5ec50d2a78d83a843005b7fd/"+p,timeout=60) as r:
        baseline[p]=r.read().decode()
try:
    for p in paths: Path(p).write_text(baseline[p])
    try: run(factory+fixture)
    except RuntimeError as e:
        assert "AtlasLoot navigation mode was styled" in str(e),str(e)
        print("EXPECTED_BASELINE_FAILURE",str(e))
    else: raise AssertionError("Released adapter unexpectedly passed navigation ownership regression")
    marker="assert(loadfile('tests/atlasloot_mode_cases.lua'))()"
    bench=fixture[:fixture.index(marker)]+"""
do
    atlasGUI:Toggle();flush();collectgarbage('collect')
    local memory, start, fonts, scans, regions = collectgarbage('count'),os.clock(),item.label.fontWrites,auditScans[atlasRoot],#atlasRoot.regions
    for _=1,1000 do atlasGUI:Toggle();flush() end
    local elapsed=(os.clock()-start)*1000
    collectgarbage('collect')
    ATLAS_BENCH=string.format('{"ms":%.6f,"retained_kib":%.6f,"font_writes":%d,"root_scans":%d,"added_regions":%d}',
        elapsed,collectgarbage('count')-memory,item.label.fontWrites-fonts,auditScans[atlasRoot]-scans,#atlasRoot.regions-regions)
    assert(#atlasRoot.regions==regions)
end
"""
    results={}
    for label, files in (("v1.6.8",baseline),("candidate",candidate)):
        for p in paths: Path(p).write_text(files[p])
        trials=[run("print=function()end\n"+bench,True) for _ in range(5)]
        results[label]={k:statistics.median(t[k] for t in trials) for k in trials[0]}
    print("CLASSIC_HOSTED_MEDIANS",json.dumps(results,sort_keys=True))
finally:
    for p in paths: Path(p).write_text(candidate[p])
