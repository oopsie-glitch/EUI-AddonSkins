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
parser.add_argument('--baseline',default='43beb7c48a1a569964f39e3d4ca2b50e8629a83b')
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
lib.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
lib.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
lib.lua_tolstring.restype=ctypes.c_char_p
lib.lua_close.argtypes=[ctypes.c_void_p]

tail=r'''
-- Shapes only the list dispatcher; native constructors/SetBar remain upstream.
Spy.SetCurrentList=function(self,list) return list,nil,"native-tail" end
MouseIsOver=function(row) return row.mouseOver==true end
for i=2,BENCH_ROWS do
    Spy:CreateRow(i)
    Spy:SetBar(i,"Enemy","60 Druid",75,"Class","DRUID",nil,0.7)
end
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
    output[#output+1]=string.format('"%s":{"ms":%.6f,"churn_kib":%.6f,"retained_kib":%.6f,%s}',
        label,ms,churn,retained,table.concat(values,","))
end
measure("cold",function()
    if not BENCH_NATIVE then
        module.install(S,module);flush()
        EUIAddonSkinsDB.spy.style="forever";module.refresh();flush()
    end
end,1)
local function update() Spy:SetBar(1,"Enemy","60 Druid",75,"Class","DRUID",nil,0.7) end
local function sync() Spy:SetCurrentList(1) end
local function enterleave() hover(true);hover(false) end
for i=1,100 do update();sync();enterleave() end
measure("player_updates",update,BENCH_ITERATIONS)
measure("row_sync",sync,BENCH_ITERATIONS)
measure("hover_pairs",enterleave,BENCH_ITERATIONS)
local f=assert(io.open(BENCH_OUTPUT,"w"))
f:write("{",table.concat(output,","),"}");f:close()
end
'''
report={"baseline":args.baseline,"rows":args.rows,"iterations":args.iterations,
        "trials":args.trials,"warmup":100,"source":bool(os.environ.get("SPY_SOURCE")),
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
                result=lib.luaL_loadstring(state,code.encode())
                if result==0:
                    result=lib.lua_pcallk(state,0,0,0,0,None)
                if result:
                    raise RuntimeError(lib.lua_tolstring(state,-1,None).decode())
            finally:
                lib.lua_close(state)
            trials.append(json.loads(destination.read_text()))
        median={name:{key:statistics.median(trial[name][key] for trial in trials)
                      for key in trials[0][name]} for name in trials[0]}
        report["modes"][mode]={"median":median,"trials":trials}
    report["candidate_minus_baseline"]={
        name:{key:report["modes"]["candidate"]["median"][name][key]-report["modes"]["baseline"]["median"][name][key]
              for key in report["modes"]["candidate"]["median"][name]}
        for name in report["modes"]["candidate"]["median"]}
print("SPY_PERFORMANCE_JSON_BEGIN")
print(json.dumps(report,indent=2))
print("SPY_PERFORMANCE_JSON_END")
