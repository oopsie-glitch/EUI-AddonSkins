-- Deterministic adapter-only workload. Native map data/rendering and LibDD
-- row construction are intentionally not timed as if this were a WoW client.
ATLAS_BENCHMARK = function(c)
    local native = {dropdown_initializers=0, map_refreshes=0, legend_refreshes=0}
    c.A.ScrollBar_Update=function()native.legend_refreshes=native.legend_refreshes+1;return 'scroll',nil,4 end
    c.A.RefreshMap=function(self)
        native.map_refreshes=native.map_refreshes+1
        self:ScrollBar_Update() -- actual upstream RefreshMap nests this call
        return 'map',nil,8
    end
    c.root.scripts.OnShow=function()
        native.dropdown_initializers=native.dropdown_initializers+6 -- two selectors × three sizes upstream
    end
    c.complete()
    collectgarbage('collect')
    local start=os.clock();c.install();local cold=(os.clock()-start)*1000
    start=os.clock();c.root:Hide();c.root:Show();local first=(os.clock()-start)*1000
    assert(#c.errors==0,table.concat(c.errors,'; '))
    local workloads={
        reopen=function()c.root:Hide();c.root:Show()end,
        map=function()c.A:RefreshMap()end,
        legend=function()c.A:ScrollBar_Update()end,
        closed_load=function()
            for _,f in ipairs(c.events)do
                if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f,'ADDON_LOADED','UnrelatedAddon')end
            end
        end,
    }
    print(string.format('ATLAS_COLD %s %.6f %.6f',c.client,cold,first))
    for _,name in ipairs({'reopen','map','legend','closed_load'})do
        local fn=workloads[name]
        if name=='closed_load' then c.root:Hide()end
        for _=1,100 do fn()end
        collectgarbage('collect');collectgarbage('stop')
        local heap=collectgarbage('count');local counts=c.counts();start=os.clock()
        for _=1,1000 do fn()end
        local elapsed=(os.clock()-start)*1000
        local churn=collectgarbage('count')-heap
        collectgarbage('restart');collectgarbage('collect')
        local retained=collectgarbage('count')-heap
        local after=c.counts();local fields={}
        for _,key in ipairs({'objects','hooks','hierarchy_reads','font_writes','geometry_writes','texture_writes','color_writes'})do
            fields[#fields+1]=key..'='..(after[key]-counts[key])
        end
        local calls,skinCalls,top=0,0,{}
        debug.sethook(function(event)
            if event~='call' then return end
            calls=calls+1
            local info=debug.getinfo(2,'Sn')
            if info and info.source:match('[/\\]Atlas%.lua$')then
                skinCalls=skinCalls+1;local key=info.name or '(closure)';top[key]=(top[key]or 0)+1
            end
        end,'c')
        fn();debug.sethook()
        local names={};for key,count in pairs(top)do names[#names+1]={key,count}end
        table.sort(names,function(a,b)return a[2]>b[2]end)
        local leaders={};for i=1,math.min(6,#names)do leaders[#leaders+1]=names[i][1]..'='..names[i][2]end
        print(string.format('ATLAS_PERF %s %s %.6f %.3f %.3f calls=%d skin_calls=%d %s top=%s',
            c.client,name,elapsed,churn,retained,calls,skinCalls,table.concat(fields,' '),table.concat(leaders,',')))
        assert(#c.errors==0,table.concat(c.errors,'; '))
    end
    assert(native.dropdown_initializers>0 and native.map_refreshes>0 and native.legend_refreshes>0)
end
