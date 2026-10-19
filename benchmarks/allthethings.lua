-- Lua-host mock: measures skin overhead, not WoW FPS or native UI API cost.
ATT_PERF_FIXTURE=true
ATT_SKIN_PATH=os.getenv('ATT_SKIN_PATH')
local f=assert(loadfile('tests/allthethings_spec.lua'))()
ATT_PERF_FIXTURE=nil
local w=f.prime
for i=2,80 do w.Container.rows[i]=f.Row(w.Container) end
w.rowCount=80; w.stableFonts=true
w:DefaultRedraw()
local checks={f.check}
for i=2,100 do
    local c=f.Object('CheckButton',f.page); c.Text=f.Text(c)
    c.checkedArt=f.Object('Texture'); c.disabledArt=f.Object('Texture')
    f.page:RegisterObject(c); checks[i]=c
end
f.Flush()
local function Measure(label, fn, iterations)
    local samples={}
    for trial=1,7 do
        collectgarbage('collect'); collectgarbage('stop')
        local memory=collectgarbage('count'); local start=os.clock()
        for i=1,iterations do fn(i) end
        local seconds=os.clock()-start; memory=collectgarbage('count')-memory
        collectgarbage('restart')
        samples[trial]={seconds,memory}
    end
    table.sort(samples,function(a,b) return a[1]<b[1] end)
    print(string.format('%s iterations=%d median_ms=%.3f allocated_KiB=%.3f',label,iterations,samples[4][1]*1000,samples[4][2]))
end
local created,hooks=f.allocations()
local fonts,paints,colours=f.writes()
Measure('skin_on_80_rows',function() w:DefaultRedraw() end,2000)
Measure('skin_on_100_settings_enable',function() for _,c in ipairs(checks) do c:Enable() end end,200)
Measure('skin_on_100_settings_show',function() for _,c in ipairs(checks) do c.scripts.OnShow(c) end end,200)
local after,afterHooks=f.allocations()
assert(after==created and afterHooks==hooks,'warm UI object/hook growth')
print('warm_ui_objects='..(after-created)..' warm_hooks='..(afterHooks-hooks))
local ff,pp,cc=f.writes()
print('warm_font_writes='..(ff-fonts)..' checkbox_repaints='..(pp-paints)..' colour_writes='..(cc-colours))
f.setEnabled(false)
Measure('skin_disabled_80_rows',function() w:DefaultRedraw() end,2000)
Measure('skin_disabled_100_settings_enable',function() for _,c in ipairs(checks) do c:Enable() end end,200)
