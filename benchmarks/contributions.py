"""Read-only synthetic audit of contributor source-shaped fixtures; no client claims."""
import ctypes,json,statistics
from pathlib import Path
from urllib.request import urlopen
ROOT=Path(__file__).resolve().parents[1]
BASE={"HuntersFieldGuide":"bb24ae8f463990d6b4ffc5c4aa866d0660c7ac8c"}
MEASURE=r'''
local report={}
local function snapshot()
 return {frames=frames,textures=textures,hooks=hooks,calls=calls,walks=audit.walks,writes=audit.writes,fontstrings=audit.fontstrings,listeners=audit.listeners}
end
local function measure(name,n,fn)
 local b=snapshot()
 collectgarbage("collect");local heap=collectgarbage("count");collectgarbage("stop")
 local t=os.clock();for i=1,n do fn(i)end;local ms=(os.clock()-t)*1000
 local allocated=collectgarbage("count")-heap
 collectgarbage("restart");collectgarbage("collect")
 local a=snapshot();local fields={name,n,ms,allocated,collectgarbage("count")-heap}
 for _,k in ipairs({"frames","textures","hooks","calls","walks","writes","fontstrings","listeners"})do fields[#fields+1]=k.."="..(a[k]-b[k])end
 report[#report+1]=table.concat(fields,"\t")
end
'''
HFG=r'''
local mode=MODE
measure("activation",1,function()if mode~="native"then assert(loadfile(ADAPTER))("EUIAddonSkins",ns)end end)
local function show()
 root.shown=true
 if root.scripts.OnShow then root.scripts.OnShow(root)end
 guide:RefreshUI()
end
measure("first_open",1,show)
measure("warm_reopen",1000,function()root.shown=false;show()end)
measure("page_filter_search",1000,function()guide:RefreshUI();guide:PetTabRefresh()end)
measure("first_export",1,function()guide:ShowExport()end)
measure("warm_export",1000,function()guide:ShowExport()end)
measure("toast",1000,function()guide:Toast("Boar","new")end)
root.shown=false
measure("closed_native_refresh",1000,function()guide:RefreshUI()end)
measure("closed_theme_1000",1000,function(i)
 accent=i%2==0 and {.2,.7,.6}or{.8,.3,.2}
 for _,fn in ipairs(looks)do fn()end
end)
measure("closed_theme_second_1000",1000,function(i)
 accent=i%2==0 and {.2,.7,.6}or{.8,.3,.2}
 for _,fn in ipairs(looks)do fn()end
end)
root.shown=true
measure("theme_then_reopen",1,show)
measure("warm_after_themes",1000,function()guide:RefreshUI()end)
local rootWrites=audit.writes
locked=true;guide:RefreshUI();guide:PetTabRefresh();locked=false
report[#report+1]="COMBAT\t"..(audit.writes-rootWrites)
measure("combat_recovery",100,function()
 locked=true;for _,fn in ipairs(looks)do fn()end;locked=false
 if events.PLAYER_REGEN_ENABLED then events.PLAYER_REGEN_ENABLED.scripts.OnEvent(events.PLAYER_REGEN_ENABLED)end
end)
enabled=false
measure("disabled",1000,function()guide:RefreshUI();guide:ShowExport();for _,fn in ipairs(looks)do fn()end end)
report[#report+1]="INVENTORY\t"..jsonInventory(snapshot())
return table.concat(report,"\n")
end
return Run(LOOK)
end
'''
ITEM=r'''
local mode=MODE
measure("activation",1,function()if mode~="native"then assert(loadfile(ADAPTER))("EUIAddonSkins",ns)end end)
local frame
measure("first_open",1,function()frame=Frame.Build();RunTimers();if frame.scripts.OnShow then frame.scripts.OnShow(frame)end end)
measure("warm_reopen",1000,function()if frame.scripts.OnShow then frame.scripts.OnShow(frame)end end)
measure("tab_switch",1000,function(i)Frame.SelectTab(i%2==0 and "Tree"or"BossLoot")end)
measure("asset_refresh",1000,function()Assets.Apply(Frame.corner,"INFO_FRAME_CORNER_TL")end)
measure("first_info",1,function()InfoPanel.Attach(frame);Tree.Attach(frame)end)
measure("warm_info",1000,function()InfoPanel.Attach(frame);Tree.Attach(frame)end)
local boss=CreateFrame("Frame",nil,frame)
measure("first_boss_column",1,function()InfoPanel.NewSurface(boss)end)
ItemTree.ProfessionsSkin=Skin
local Bar={}
function Bar.Draw(strip)for _,piece in ipairs({strip.tag.left,strip.tag.middle,strip.tag.right})do piece:Show()end end
ItemTree.ProfessionsBar=Bar
if events.ADDON_LOADED then events.ADDON_LOADED.scripts.OnEvent(events.ADDON_LOADED,"ADDON_LOADED","ItemTree_Professions")end
local card=CreateFrame("Frame",nil,frame)
measure("first_card",1,function()Skin.Border(card,200,80,{edge="ITEMTREE_COLOR_PROFESSION_CARD_EDGE"})end)
measure("profession_card_redraw",1000,function()Skin.Border(card,200,80,{edge="ITEMTREE_COLOR_PROFESSION_CARD_EDGE"})end)
local strip=CreateFrame("Frame",nil,frame);strip.tag=CreateFrame("Frame",nil,strip)
strip.tag.left,strip.tag.middle,strip.tag.right=strip.tag:CreateTexture(),strip.tag:CreateTexture(),strip.tag:CreateTexture()
local rank=CreateFrame("Frame",nil,strip)
measure("first_rank",1,function()Skin.ThreeSlice(rank,"PROFESSION_BAR_BG",0,4,300,14,"bgPieces")end)
measure("rank_redraw",1000,function()Skin.ThreeSlice(rank,"PROFESSION_BAR_BG",0,4,300,14,"bgPieces");Bar.Draw(strip)end)
measure("closed_theme",1000,function(i)accent=i%2==0 and {.2,.7,.6}or{.8,.3,.2};for _,fn in ipairs(looks)do fn()end end)
measure("idle",10000,function()end)
measure("combat_recovery",100,function()locked=true;for _,fn in ipairs(looks)do fn()end;locked=false;if events.PLAYER_REGEN_ENABLED then events.PLAYER_REGEN_ENABLED.scripts.OnEvent(events.PLAYER_REGEN_ENABLED)end end)
enabled=false
measure("disabled",1000,function()Frame.SelectTab("Tree");Assets.Apply(Frame.corner,"INFO_FRAME_CORNER_TL");for _,fn in ipairs(looks)do fn()end end)
report[#report+1]="INVENTORY\t"..jsonInventory(snapshot())
return table.concat(report,"\n")
end
'''
def source(addon,mode,path,look):
 text=(ROOT/("tests/huntersfieldguide_spec.lua" if addon=="HuntersFieldGuide"else"tests/itemtree_spec.lua")).read_text()
 if addon=="HuntersFieldGuide":
  text=text[:text.index("    -- Activation during combat")]
  # Count native objects even when the fixture uses table-shaped frames.
  text=text.replace("local locked, enabled = false, true","local locked, enabled = false, true\n    local audit={walks=0,writes=0,fontstrings=0,listeners=0}")
  text=text.replace('local f = {kind = kind,','if kind=="FontString"then audit.fontstrings=audit.fontstrings+1 end\n        local f = {kind = kind,')
  suffix=HFG
 else:
  text=text[:text.index('assert(loadfile("EUIAddonSkins/Skins/ItemTree.lua"))')]
  text=text.replace("local locked, enabled = false, true","local locked, enabled = false, true\nlocal audit={walks=0,writes=0,fontstrings=0,listeners=0}")
  text=text.replace('local f = {kind = kind,','if kind=="FontString"then audit.fontstrings=audit.fontstrings+1 end\n    local f = {kind = kind,')
  # Native synthetic FontStrings created from texture-shaped regions.
  text=text.replace('local function fontString() local fs = region("FontString");','local function fontString() local fs = region("FontString");')
  suffix=ITEM
 for method,args in [("SetAlpha","value"),("SetAllPoints","target"),("SetPoint","..."),("ClearAllPoints",""),("SetSize","w, h"),("SetHeight","h"),("SetWidth","w"),("SetColorTexture","..."),("SetTextColor","r, g, b"),("SetVertexColor","r, g, b"),("SetTexture","path"),("SetTexCoord","..."),("SetText","text"),("SetShown","on")]:
  text=text.replace("function f:"+method+"("+args+")","function f:"+method+"("+args+") audit.writes=audit.writes+1;")
 for method in ("GetRegions","GetChildren"):
  text=text.replace("function f:"+method+"()","function f:"+method+"() audit.walks=audit.walks+1;")
 text=text.replace("function f:RegisterEvent(event)","function f:RegisterEvent(event) audit.listeners=audit.listeners+1;")
 inv='local function jsonInventory(t)local f={};for k,v in pairs(t)do f[#f+1]=k.."="..v end;table.sort(f);return table.concat(f,"\\t")end\n'
 return (text+inv+MEASURE+suffix.replace("MODE",json.dumps(mode)).replace("ADAPTER",json.dumps(str(path))).replace("LOOK",json.dumps(look))).encode()
def run():
 lua=ctypes.CDLL("liblua5.4.so.0")
 lua.luaL_newstate.restype=ctypes.c_void_p
 lua.luaL_openlibs.argtypes=[ctypes.c_void_p]
 lua.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
 lua.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
 lua.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];lua.lua_tolstring.restype=ctypes.c_char_p
 lua.lua_close.argtypes=[ctypes.c_void_p]
 for addon in BASE:
  path=Path("/tmp/"+addon+"-reviewed.lua")
  with urlopen("https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/"+BASE[addon]+"/EUIAddonSkins/Skins/"+addon+".lua",timeout=30)as r:path.write_bytes(r.read())
  previous=Path("/tmp/hfg-previous97.lua")
  with urlopen("https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/2be3e53333114c75a76222fba8f259c11e13222e/EUIAddonSkins/Skins/HuntersFieldGuide.lua",timeout=30)as r:previous.write_bytes(r.read())
  for look in (("forever","classic") if addon=="HuntersFieldGuide"else("forever",)):
   for mode in ("native","reviewed","previous97","candidate"):
    results=[]
    for trial in range(5):
     buf=source(addon,mode,path if mode=="reviewed"else previous if mode=="previous97"else ROOT/"EUIAddonSkins/Skins"/(addon+".lua"),look)
     state=lua.luaL_newstate();lua.luaL_openlibs(state)
     try:
      rc=lua.luaL_loadbufferx(state,buf,len(buf),b"contribution-audit",None)
      if not rc:rc=lua.lua_pcallk(state,0,1,0,0,None)
      result=lua.lua_tolstring(state,-1,None).decode()
      if rc:raise RuntimeError(result)
      records={}
      for line in result.splitlines():
       fields=line.split("\t");name=fields[0]
       if name in ("COMBAT","INVENTORY"):
        records[name]=({"writes":int(fields[1])}if name=="COMBAT"else{k:int(v)for k,v in(x.split("=")for x in fields[1:])})
       else:
        records[name]={"iterations":int(fields[1]),"ms":float(fields[2]),"allocated_KiB":float(fields[3]),"retained_KiB":float(fields[4]),**{k:int(v)for k,v in(x.split("=")for x in fields[5:])}}
      results.append(records)
     finally:lua.lua_close(state)
    for workload in results[0]:
     row={key:statistics.median(x[workload][key]for x in results)for key in results[0][workload]}
     print("CONTRIB_AUDIT "+json.dumps({"addon":addon,"look":look,"mode":mode,"workload":workload,**row}),flush=True)
 print("Five fresh Lua states per treatment; source-shaped fixtures, stubbed EUI; not native-client timing, FPS, taint or GPU validation.")
if __name__=="__main__":run()
