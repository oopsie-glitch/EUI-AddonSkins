"""Spy adapter comparison on a GitHub-hosted runner; no game/FPS claims."""
import argparse
import ctypes
import json
import os
from pathlib import Path
import statistics
import tempfile
import urllib.request

parser=argparse.ArgumentParser()
parser.add_argument('--baseline',default='b4f2e7b6e4ac86b2b2a1ec9352c93422bdc3abe2')
parser.add_argument('--trials',type=int,default=5)
parser.add_argument('--iterations',type=int,default=1000)
parser.add_argument('--rows',type=int,default=40)
args=parser.parse_args()
if not (1<=args.rows<=100 and 1<=args.trials<=20 and args.iterations>0):
    raise SystemExit('invalid workload size')

# Reuse only fixture construction, never remove/skip regression assertions.
test=Path('tests/spy_spec.lua').read_text()
marker='module.install(S,module);flush()'
assert test.count(marker)==1
prefix=test.split(marker,1)[0]
prefix=prefix.replace('counts.objects=counts.objects+1',
    'counts.objects=counts.objects+1; counts.frames=(counts.frames or 0)+((kind~="Texture" and kind~="FontString") and 1 or 0); counts.textures=(counts.textures or 0)+(kind=="Texture" and 1 or 0)')
lib=ctypes.CDLL('liblua5.4.so.0')
lib.luaL_newstate.restype=ctypes.c_void_p
lib.luaL_openlibs.argtypes=[ctypes.c_void_p]
lib.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
lib.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
lib.lua_tolstring.restype=ctypes.c_char_p
lib.lua_close.argtypes=[ctypes.c_void_p]

tail=r'''
-- Only native list dispatch/bootstrap and pointer entry are shaped.
Spy.SetCurrentList=function(self,list) return list,nil,"native-tail" end
MouseIsOver=function(row) return row.mouseOver==true end
for i=2,BENCH_ROWS do
    Spy:CreateRow(i)
    Spy:SetBar(i,"Enemy","60 Druid",75,"Class","DRUID",nil,0.7)
end
local originalSlot=Spy.MainWindow.Rows[2]
Spy.MainWindow.Rows[2]=nil;Spy:CreateRow(2)
local spareSlot=Spy.MainWindow.Rows[2];spareSlot:Hide()
Spy.MainWindow.Rows[2]=originalSlot
for _,nativeRow in pairs(Spy.MainWindow.Rows) do nativeRow:Show() end
local function hover(entered)
    row.mouseOver=entered
    row:FireScript(entered and "OnEnter" or "OnLeave")
end
local fields={"objects","frames","textures","hooks","reads","scans","geometry","paint","alphaWrites","visibility"}
local output={}
local function measure(label,fn,n)
    collectgarbage("collect");collectgarbage("collect")
    local before={}
    for _,key in ipairs(fields) do before[key]=counts[key] or 0 end
    local heap=collectgarbage("count")
    collectgarbage("stop")
    local started=os.clock()
    for i=1,n do fn() end
    local ms=(os.clock()-started)*1000
    local churn=collectgarbage("count")-heap
    collectgarbage("restart");collectgarbage("collect");collectgarbage("collect")
    local retained=collectgarbage("count")-heap
    local values={}
    for _,key in ipairs(fields) do values[#values+1]=string.format('"%s":%d',key,(counts[key] or 0)-before[key]) end
    output[#output+1]=string.format('"%s":{"iterations":%d,"ms":%.6f,"churn_kib":%.6f,"retained_kib":%.6f,%s}',
        label,n,ms,churn,retained,table.concat(values,","))
end
local profiles={}
local function profile(label,fn,n)
    local total,adapter,native,shared,c=0,0,0,0,0
    local function observe(event)
        if event~="call" and event~="tail call" then return end
        local info=debug.getinfo(2,"S")
        total=total+1
        local source=info.source or ""
        if source:find("Skins/Spy.lua",1,true) or source:find("baseline.lua",1,true) then adapter=adapter+1 end
        if source:find("spy-upstream/",1,true) then native=native+1 end
        if source:find("EUIAddonSkins/Widgets.lua",1,true) then shared=shared+1 end
        if info.what=="C" then c=c+1 end
    end
    debug.sethook(observe,"c")
    for i=1,n do fn() end
    debug.sethook()
    profiles[#profiles+1]=string.format('"%s":{"iterations":%d,"total":%d,"adapter":%d,"native":%d,"shared":%d,"c":%d}',label,n,total,adapter,native,shared,c)
end

local function acquire()
    if not BENCH_NATIVE then
        module.install(S,module);flush()
        EUIAddonSkinsDB.spy.style="forever";module.refresh();flush()
    end
end
if BENCH_COLD_PROFILE then
    profile("cold",acquire,1)
    local f=assert(io.open(BENCH_OUTPUT,"w"))
    f:write("{",table.concat(profiles,","),"}");f:close()
    return
end
measure("cold",acquire,1)
local function update() Spy:SetBar(1,"Enemy","60 Druid",75,"Class","DRUID",nil,0.7) end
local function sync() Spy:SetCurrentList(1) end
local function enterleave() hover(true);hover(false) end
local function pooled() row:Hide();row:Show() end
local function recycle()
    local old=Spy.MainWindow.Rows[2]
    local nextRow=old==originalSlot and spareSlot or originalSlot
    old:Hide();Spy.MainWindow.Rows[2]=nextRow
    sync();nextRow:Show()
end
local function reopen() Spy.MainWindow:Hide();Spy.MainWindow:Show();flush() end
local function themes()
    if BENCH_NATIVE then return end
    EUIAddonSkinsDB.spy.style="standard";module.refresh();flush()
    EUIAddonSkinsDB.spy.style="forever";module.refresh();flush()
end
local setting
if not BENCH_NATIVE then
    SlashCmdList.EUISPYSKIN()
    setting=registry.tables.EUIAddonSkinsSpy.args.opacity
end
local function opacity()
    if not setting then return end
    for _,v in ipairs({0,75,100,75}) do setting.set(nil,v);flush() end
end
local function opacitySame() if setting then setting.set(nil,75);flush() end end
local workloads={{"player_updates",update,BENCH_ITERATIONS},
    {"row_sync",sync,BENCH_ITERATIONS},{"hover_pairs",enterleave,BENCH_ITERATIONS},
    {"pooled_hide_show",pooled,BENCH_ITERATIONS},{"slot_transfer",recycle,BENCH_ITERATIONS},
    {"reopen",reopen,100},{"theme_pairs",themes,100},
    {"opacity_cycles",opacity,100},{"unchanged_opacity",opacitySame,BENCH_ITERATIONS}}
for _,job in ipairs(workloads) do
    for i=1,100 do job[2]() end
    measure(job[1],job[2],job[3])
end
Spy.MainWindow:Hide();flush()
measure("closed_player_updates",update,BENCH_ITERATIONS)
measure("closed_idle",function() end,BENCH_ITERATIONS)
-- Separate fixed 10-callback call profile: debug hooks never affect timed passes.
profile("closed_player_updates",update,10)
profile("closed_idle",function() end,10)
Spy.MainWindow:Show();flush()
for _,job in ipairs(workloads) do profile(job[1],job[2],10) end
local f=assert(io.open(BENCH_OUTPUT,"w"))
f:write("{",table.concat(output,","),',"profiles":{',table.concat(profiles,","),"}}");f:close()
end
'''
report={"baseline":args.baseline,"rows":args.rows,"iterations":args.iterations,
        "trials":args.trials,"warmup":100,"lifecycle_iterations":100,"profile_iterations":10,"source":bool(os.environ.get("SPY_SOURCE")),
        "limits":"Mock UI/Lua host; actual-source constructors/SetBar, shaped list dispatcher/hover. GC-stopped churn is not retained/native/GPU memory.","modes":{}}
with tempfile.TemporaryDirectory(prefix='spy-bench-') as tmp:
    tmp=Path(tmp)
    baseline=tmp/'baseline.lua'
    baseline.write_bytes(urllib.request.urlopen(
        f'https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/{args.baseline}/EUIAddonSkins/Skins/Spy.lua').read())
    for mode,skin in (("native",Path("EUIAddonSkins/Skins/Spy.lua")),("baseline",baseline),("candidate",Path("EUIAddonSkins/Skins/Spy.lua"))):
        trials=[]
        for number in range(args.trials):
            destination=tmp/f'{mode}-{number}.json'
            configured=prefix.replace('loadfile("EUIAddonSkins/Skins/Spy.lua")',f'loadfile({json.dumps(str(skin))})')
            settings=f'BENCH_NATIVE={str(mode=="native").lower()};BENCH_ROWS={args.rows};BENCH_ITERATIONS={args.iterations};BENCH_OUTPUT={json.dumps(str(destination))};\n'
            code=settings+configured+tail
            state=lib.luaL_newstate()
            lib.luaL_openlibs(state)
            try:
                encoded=code.encode()
                result=lib.luaL_loadbufferx(state,encoded,len(encoded),b"@benchmarks/spy_fixture.lua",None)
                if result==0:
                    result=lib.lua_pcallk(state,0,0,0,0,None)
                if result:
                    raise RuntimeError(lib.lua_tolstring(state,-1,None).decode())
            finally:
                lib.lua_close(state)
            trial=json.loads(destination.read_text())
            # A separate fresh VM profiles first acquisition without contaminating timing.
            profile_code='BENCH_COLD_PROFILE=true;\n'+settings+configured+tail
            encoded=profile_code.encode()
            state=lib.luaL_newstate()
            lib.luaL_openlibs(state)
            try:
                result=lib.luaL_loadbufferx(state,encoded,len(encoded),b"@benchmarks/spy_fixture.lua",None)
                if result==0:
                    result=lib.lua_pcallk(state,0,0,0,0,None)
                if result:
                    raise RuntimeError(lib.lua_tolstring(state,-1,None).decode())
            finally:
                lib.lua_close(state)
            trial["profiles"]["cold"]=json.loads(destination.read_text())["cold"]
            trials.append(trial)
        median={name:{key:statistics.median(trial[name][key] for trial in trials)
                      for key in trials[0][name]} for name in trials[0] if name!="profiles"}
        profiles={name:{key:statistics.median(trial["profiles"][name][key] for trial in trials)
                        for key in trials[0]["profiles"][name]} for name in trials[0]["profiles"]}
        report["modes"][mode]={"median":median,"profiles":profiles,"trials":trials}
    report["candidate_minus_baseline"]={
        name:{key:report["modes"]["candidate"]["median"][name][key]-report["modes"]["baseline"]["median"][name][key]
              for key in report["modes"]["candidate"]["median"][name]}
        for name in report["modes"]["candidate"]["median"]}
print("SPY_PERFORMANCE_JSON_BEGIN")
print(json.dumps(report,indent=2))
print("SPY_PERFORMANCE_JSON_END")
