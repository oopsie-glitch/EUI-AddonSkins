-- Host Lua simulation. Timings include simplified native mocks, not WoW API/FPS cost.
GRM_PERF_FIXTURE=true
GRM_SKIN_PATH=os.getenv('GRM_SKIN_PATH')
local f=assert(loadfile('tests/grm_spec.lua'))()
GRM_PERF_FIXTURE=nil
local labels={}
local audit=f.Named('Frame','GRM_BenchmarkAudit',f.root)
for i=1,100 do
    local row=f.Named('Frame','GRM_BenchmarkRow'..i,audit)
    for j=1,5 do labels[#labels+1]=f.Text(row) end
end
f.module.refresh(); f.Flush()
f.root.scripts.OnShow(f.root)
local function SnapshotDiff(a,b)
    local fields={}
    for _,key in ipairs({'objects','hooks','fonts','checks','children','regions','parents'}) do
        fields[#fields+1]=key..'='..(b[key]-a[key])
    end
    return table.concat(fields,' ')
end
local function Measure(name,fn,count)
    local samples={}
    for trial=1,7 do
        collectgarbage('collect'); collectgarbage('stop')
        local before=f.counts(); local memory=collectgarbage('count'); local start=os.clock()
        for i=1,count do fn(i) end
        local elapsed=os.clock()-start; local growth=collectgarbage('count')-memory
        local after=f.counts(); collectgarbage('restart')
        assert(before.objects==after.objects and before.hooks==after.hooks,'warm object/hook growth')
        samples[trial]={elapsed,growth,SnapshotDiff(before,after)}
    end
    table.sort(samples,function(a,b) return a[1]<b[1] end)
    local v=samples[4]
    print(string.format('%s iterations=%d median_ms=%.3f temporary_KiB=%.3f %s',name,count,v[1]*1000,v[2],v[3]))
end
Measure('warm_window_show',function() f.root.scripts.OnShow(f.root) end,2000)
Measure('warm_main_tab_switch',function(i)
    local page=i%2==0 and f.root.GRM_LogFrame or f.root.GRM_OptionsFrame
    page:Show()
end,2000)
Measure('audit_500_class_or_good_colours',function()
    for i,text in ipairs(labels) do
        if i%2==0 then text:SetTextColor(1,0.96,0.41,1) else text:SetTextColor(0,0.77,0.063,1) end
    end
end,100)
Measure('native_settings_refresh',function() assert(GRM_UI.BuildLogFrames()=='native-state-return') end,100)
Measure('pooled_dropdown_rebuild',function() GRM_UI.BuildDropDownOptions({'One','Two'},f.menu,f.selector) end,1000)
f.setEnabled(false)
Measure('disabled_main_tab_switch',function(i)
    local page=i%2==0 and f.root.GRM_LogFrame or f.root.GRM_OptionsFrame
    page:Show()
end,2000)
