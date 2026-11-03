-- Separate native data-index cost, using external supplied sources/data only.
-- Item API is deterministic: every queried item is classified as head armour.
-- This intentionally measures source parsing/index work, not actual WoW cache
-- behaviour, item filtering accuracy, rendering or skin overhead.
unpack=unpack or table.unpack
local source=assert(os.getenv('ONEFORALL_SOURCE'))
for _,client in ipairs({'Retail','Forever'})do
    local A={UI={},DUNGEON_REGISTRY={}}
    GetItemInfoInstant=function()return nil,nil,nil,'INVTYPE_HEAD',nil,4,1 end
    UnitClass=function()return 'Warrior','WARRIOR',1 end
    UnitFactionGroup=function()return 'Alliance'end
    UnitRace=function()return 'Human','HUMAN',1 end
    local files=assert(io.open(os.getenv('ONEFORALL_DATA_LIST')))
    local paths={};for line in files:lines()do paths[#paths+1]=line end;files:close()
    local function measure(name,fn,n)
        collectgarbage('collect');collectgarbage('stop');local heap=collectgarbage('count')
        local start=os.clock();for _=1,n do fn()end;local ms=(os.clock()-start)*1000
        local churn=collectgarbage('count')-heap
        collectgarbage('restart');start=os.clock();collectgarbage('collect')
        local gc=(os.clock()-start)*1000
        print(('OFA_PERF %s %s n=%d ms=%.6f churn_kib=%.3f retained_kib=%.3f gc_ms=%.6f'):format(
            client,name,n,ms,churn,collectgarbage('count')-heap,gc))
    end
    measure('native_data_load',function()
        for _,p in ipairs(paths)do assert(loadfile(p))('OneForAll',A)end
        assert(loadfile(source..'/UI/GearPlanner.lua'))('OneForAll',A)
    end,1)
    local index
    measure('native_index_cold',function()index=A.GearIndex()end,1)
    assert(#index>1000,'expected realistic source data volume')
    print(('OFA_PERF %s native_index_size items=%d'):format(client,#index))
    measure('native_index_warm',function()assert(A.GearIndex()==index)end,10000)
end
