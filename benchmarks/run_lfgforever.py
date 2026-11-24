"""Instrumented source-shaped UI control, original PR head, and candidate; cloud only."""
import ctypes,json,os,re,statistics
from pathlib import Path
from urllib.request import urlopen
BASE=os.getenv('LFG_AUDIT_BASE','ec84dc8c75bd9fa7a794557d9d51241a079c8fbd')
def run():
    root=Path(__file__).resolve().parents[1]
    url='https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/'+BASE+'/EUIAddonSkins/Skins/LFGForever.lua'
    with urlopen(url,timeout=30) as r:baseline=r.read()
    old=Path('/tmp/lfgforever-audit-baseline.lua');old.write_bytes(baseline)
    fixture=(root/'tests/lfgforever_spec.lua').read_text()
    prefix=fixture[:fixture.index('assert(installed.available());installed.install(S,module)')]
    # Count the inspected adapter's reads/writes, while keeping the same native UI model.
    prefix=prefix.replace('local function font()\n','local function font()\n    stats.fontstrings=(stats.fontstrings or 0)+1\n')
    prefix=prefix.replace('function t:GetFont()return','function t:GetFont()stats.fontReads=(stats.fontReads or 0)+1;return')
    prefix=prefix.replace('function f:GetParent()return','function f:GetParent()stats.parents=(stats.parents or 0)+1;return')
    prefix=prefix.replace('function t:SetColorTexture(...)','function t:SetColorTexture(...)stats.texWrites=(stats.texWrites or 0)+1;')
    prefix=prefix.replace('function t:SetVertexColor(...)','function t:SetVertexColor(...)stats.texWrites=(stats.texWrites or 0)+1;')
    for call in ('ClearAllPoints()','SetPoint(...)','SetSize(w,h)','SetHeight(h)'):
        prefix=prefix.replace('function t:'+call,'function t:'+call+'stats.pointWrites=(stats.pointWrites or 0)+1;')
    prefix=prefix.replace('function f:SetBackdrop(v)','function f:SetBackdrop(v)stats.backdrops=(stats.backdrops or 0)+1;')
    prefix=prefix.replace('function f:RegisterEvent(e)self.callbacks[e]=true end',
        'function f:RegisterEvent(e)if not self.callbacks[e]then stats.listeners=(stats.listeners or 0)+1 end;self.callbacks[e]=true end')
    prefix=prefix.replace('function f:UnregisterEvent(e)self.callbacks[e]=nil end',
        'function f:UnregisterEvent(e)if self.callbacks[e]then stats.listeners=stats.listeners-1 end;self.callbacks[e]=nil end')
    # Native Show fires visible descendants' OnShow, not only the root's.
    start=prefix.index('    function f:Show()')
    stop=prefix.index('    function f:SetBackdrop',start)
    prefix=prefix[:start]+'''    local function visible(o)while o do if not o.shown then return false end;o=o.parent end;return true end
    local function fire(o,event)
        if o.scripts[event]then o.scripts[event](o)end
        for _,child in ipairs(o.children)do if child.shown then fire(child,event)end end
    end
    function f:IsVisible()return visible(self)end
    function f:Show()
        local was=visible(self);self.shown=true
        if not was and visible(self)then fire(self,"OnShow")end
    end
    function f:Hide()
        local was=visible(self);self.shown=false
        if was then fire(self,"OnHide")end
    end
'''+prefix[stop:]
    prefix=prefix.replace('local popup=frame("Frame");popup.openOwner=owner',
        'local popup=self.pool or frame("Frame");self.pool=popup;popup.openOwner=owner')
    begin=prefix.index('assert(loadfile("EUIAddonSkins/Skins/LFGForever.lua"))')
    end=prefix.index('local function build()',begin)
    registration='''local registrationMS,registrationKiB,registrationRetained,registrationStats,registrationAfter=0,0,0,{},{}
if os.getenv("LFG_AUDIT_MODE")~="native"then
    for k,v in pairs(stats)do registrationStats[k]=v end
    collectgarbage("collect");local heap=collectgarbage("count");collectgarbage("stop")
    local started=os.clock()
    assert(loadfile(ADAPTER_PATH))("EUIAddonSkins",ns)
    assert(definition and not installed);definition();assert(not installed.available())
    registrationMS=(os.clock()-started)*1000;registrationKiB=collectgarbage("count")-heap
    collectgarbage("restart");collectgarbage("collect")
    registrationRetained=collectgarbage("count")-heap
    for k,v in pairs(stats)do registrationAfter[k]=v end
end
'''
    prefix=prefix[:begin]+registration+prefix[end:]
    lua=ctypes.CDLL('liblua5.4.so.0')
    lua.luaL_newstate.restype=ctypes.c_void_p
    lua.luaL_openlibs.argtypes=[ctypes.c_void_p]
    lua.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
    lua.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
    lua.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];lua.lua_tolstring.restype=ctypes.c_char_p
    lua.lua_close.argtypes=[ctypes.c_void_p]
    workloads=(root/'benchmarks/lfgforever_workloads.lua').read_text()
    output={};visuals={}
    for mode in ('native','baseline','candidate'):
        records=[];visuals[mode]=set()
        os.environ['LFG_AUDIT_MODE']=mode
        path=old if mode=='baseline' else root/'EUIAddonSkins/Skins/LFGForever.lua'
        source=(prefix.replace('ADAPTER_PATH',json.dumps(str(path)))+workloads+'\nend\n').encode()
        for trial in range(5):
            state=lua.luaL_newstate();lua.luaL_openlibs(state)
            try:
                rc=lua.luaL_loadbufferx(state,source,len(source),b'lfg-audit',None)
                if not rc:rc=lua.lua_pcallk(state,0,1,0,0,None)
                result=lua.lua_tolstring(state,-1,None).decode()
                if rc:raise RuntimeError(result)
                trial_records={}
                for line in result.splitlines():
                    columns=line.split('\t')
                    if columns[0]=='VISUAL':visuals[mode].add(columns[1]);continue
                    if columns[0]=='INVENTORY':trial_records['inventory']={k:int(v) for k,v in (x.split('=') for x in columns[1:])};continue
                    name,n,ms,allocated,retained=columns[:5]
                    trial_records[name]={'iterations':int(n),'ms':float(ms),'allocated_KiB':float(allocated),'retained_KiB':float(retained),
                        **{k:int(v) for k,v in (x.split('=') for x in columns[5:])}}
                records.append(trial_records)
            finally:lua.lua_close(state)
        output[mode]={}
        for name in records[0]:
            output[mode][name]={key:statistics.median(r[name][key] for r in records) for key in records[0][name]}
    assert visuals['baseline']==visuals['candidate'],'Approved visual properties changed'
    artifact=root/'lfgforever-audit.json'
    artifact.write_text(json.dumps({'baseline':BASE,'trials':5,'environment':'Ubuntu 24.04 hosted Lua 5.4; source-shaped UI, public EUI primitive stubs; not live WoW','results':output,'visuals':{k:sorted(v) for k,v in visuals.items()}},indent=2)+'\n')
    for mode,data in output.items():
        for name,record in data.items():print('LFG_AUDIT '+json.dumps({'mode':mode,'workload':name,**record}),flush=True)
    print('PASS: baseline/candidate visual-property snapshots match; five fresh-state trials per treatment')
if __name__=='__main__':run()
