"""GitHub-hosted source sensitivity tests and repeated Lua fixture measurements."""
import ctypes,json,os,statistics
from pathlib import Path
from urllib.request import urlopen
lua=ctypes.CDLL("liblua5.4.so.0")
lua.luaL_newstate.restype=ctypes.c_void_p
lua.luaL_openlibs.argtypes=[ctypes.c_void_p]
lua.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
lua.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lua.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
lua.lua_tolstring.restype=ctypes.c_char_p
lua.lua_close.argtypes=[ctypes.c_void_p]
def run(source):
 state=lua.luaL_newstate();lua.luaL_openlibs(state)
 try:
  result=lua.luaL_loadstring(state,source.encode())
  if not result:result=lua.lua_pcallk(state,0,-1,0,0,None)
  value=lua.lua_tolstring(state,-1,None)
  return result,value.decode() if value else ""
 finally:lua.lua_close(state)
source=Path("tests/auctionator_tabs_spec.lua").read_text()
old=urlopen("https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/82eb4fd5dc22a4bc973b9c47739d40a912f57c26/EUIAddonSkins/Skins/Auctionator.lua",timeout=45).read()
Path("/tmp/cheap-old-auctionator.lua").write_bytes(old)
os.environ["CHEAP_AHTAB_SOURCE"]="/tmp/cheap-ahtab.lua"
os.environ["CHEAP_AUCTIONATOR_SOURCE"]="/tmp/cheap-old-auctionator.lua"
os.environ["CHEAP_TAB_ORDER"]="before"
rc,error=run(source)
assert rc and "COMPATIBILITY:" in error,error
print("Original main reproduces replaced native anchors/geometry: EXPECTED FAIL")
del os.environ["CHEAP_AUCTIONATOR_SOURCE"]
for order in ("before","after","none"):
 os.environ["CHEAP_TAB_ORDER"]=order
 rc,error=run(source);assert not rc,error
print("Corrected native-source configurations: 3/3 PASS")
fixture=Path("tests/cheapupgrades_spec.lua").read_text()
setup=fixture.split("assert(loadfile('EUIAddonSkins/Skins/CheapUpgrades.lua'))")[0]
# The fixture counts native and skin UI objects together. Instrument only tests.
setup=setup.replace("local timers, modules", "local frameCount,textureCount,fontCount=0,0,0\nlocal timers, modules")
setup=setup.replace("local function texture(layer, w, h)", "local function texture(layer, w, h)\n    textureCount=textureCount+1")
setup=setup.replace("local function fontString(text, r, g, b)", "local function fontString(text, r, g, b)\n    fontCount=fontCount+1")
setup=setup.replace("local function frame(kind, parent, name)", "local function frame(kind, parent, name)\n    frameCount=frameCount+1")
body=r"""
local start=os.clock()
assert(loadfile('EUIAddonSkins/Skins/CheapUpgrades.lua'))('EUIAddonSkins',ns)
local m=modules.CheapUpgrades
if USE_SKIN then m.install(S,m)end
local activation=(os.clock()-start)*1000
start=os.clock();CU:ShowUI();CU:AttachAHButton();CU.Options:Open();CU.Options:AskSpec()
local cold=(os.clock()-start)*1000
collectgarbage('collect')
local memory=collectgarbage('count')
local f,t,fs,h=frameCount,textureCount,fontCount,hookCount
local reads,geo,colors,fonts=hierarchyReads,geometryWrites,colorWrites,writes
start=os.clock()
for i=1,1000 do visible(CheapUpgradesFrame,false);CU:ShowUI()end
local warm=(os.clock()-start)*1000
local warmReads,warmGeo,warmColors,warmFonts=hierarchyReads-reads,geometryWrites-geo,colorWrites-colors,writes-fonts
start=os.clock()
for i=1,1000 do CU:RefreshUI()end
local updates=(os.clock()-start)*1000
visible(CheapUpgradesFrame,false)
start=os.clock()
for i=1,1000 do CU:RefreshUI()end
local closed=(os.clock()-start)*1000
local closedReads=hierarchyReads-reads-warmReads
collectgarbage('collect')
local retained=collectgarbage('count')-memory
local growth=frameCount-f+textureCount-t+fontCount-fs
assert(growth==0 and hookCount==h and warmReads==0 and warmGeo==0 and warmColors==0 and warmFonts==0)
return string.format('{"activation_ms":%.6f,"first_open_ms":%.6f,"1000_reopens_ms":%.6f,"1000_updates_ms":%.6f,"1000_closed_updates_ms":%.6f,"retained_kib":%.6f,"frames":%d,"textures":%d,"fontstrings":%d,"hooks":%d,"object_growth":%d,"warm_reads":%d,"warm_geometry_writes":%d,"warm_color_writes":%d,"warm_font_writes":%d,"closed_reads":%d}',activation,cold,warm,updates,closed,retained,frameCount,textureCount,fontCount,hookCount,growth,warmReads,warmGeo,warmColors,warmFonts,closedReads)
"""
for enabled in (False,True):
 trials=[]
 for trial in range(7):
  rc,value=run(setup+"\nlocal USE_SKIN="+str(enabled).lower()+"\n"+body)
  assert not rc,value
  trials.append(json.loads(value))
 medians={key:round(statistics.median(t[key] for t in trials),6) for key in trials[0]}
 print("HOSTED_BENCH",json.dumps({"skin":enabled,"trials":7,"environment":"Ubuntu 24.04, Lua 5.4, source-shaped fixture; not WoW rendering/FPS/taint",**medians},sort_keys=True))
