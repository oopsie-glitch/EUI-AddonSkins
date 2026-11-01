-- Host Lua workload. WoW API/EUI primitives are mocked by oneforall_spec.
-- Optional supplied target sources remain external and are never packaged.
unpack = unpack or table.unpack -- WoW/Lua 5.1 global for supplied target sources
ONEFORALL_BENCHMARK=function(c)
    local native=os.getenv('ONEFORALL_NATIVE')=='1'
    local function measure(name,fn,n)
        n=n or 200
        for _=1,(n==1 and 0 or 20)do fn()end
        collectgarbage('collect');collectgarbage('stop')
        local heap=collectgarbage('count');local before=c.counts();local start=os.clock()
        for _=1,n do fn()end
        local elapsed=(os.clock()-start)*1000
        local churn=collectgarbage('count')-heap
        collectgarbage('restart');start=os.clock();collectgarbage('collect')
        local gc=(os.clock()-start)*1000
        local retained=collectgarbage('count')-heap
        local after=c.counts();local fields={}
        for _,k in ipairs({'objects','hooks','reads','children','regions','parent_reads','alpha_reads','vertex_reads','font_reads','geometry','fonts','texture_writes','colours','timers','identity_reads'})do
            fields[#fields+1]=k..'='..(after[k]-before[k])
        end
        local luaCalls,cCalls,skinCalls,top=-1,-1,-1,{} -- -1: cold construction not profiled
        local p95,peak=0,0
        if n>1 then
            luaCalls,cCalls,skinCalls=0,0,0
            local samples={}
            for i=1,100 do start=os.clock();fn();samples[i]=(os.clock()-start)*1000 end
            table.sort(samples);p95,peak=samples[95],samples[100]
            debug.sethook(function(event)
                if event~='call' then return end
                local info=debug.getinfo(2,'Sn')
                if info.what=='C' then cCalls=cCalls+1 else luaCalls=luaCalls+1 end
                if info.source:find('Skins/OneForAll.lua',1,true) or info.source:find('benchmark-adapter.lua',1,true) then
                    skinCalls=skinCalls+1;local key=info.name or '(closure)';top[key]=(top[key]or 0)+1
                end
            end,'c');fn();debug.sethook()
        end
        local names={};for k,v in pairs(top)do names[#names+1]={k,v}end
        table.sort(names,function(a,b)if a[2]==b[2]then return a[1]<b[1]end;return a[2]>b[2]end)
        local leaders={};for i=1,math.min(6,#names)do leaders[#leaders+1]=names[i][1]..':'..names[i][2]end
        print(('OFA_PERF %s %s n=%d ms=%.6f churn_kib=%.3f retained_kib=%.3f gc_ms=%.6f p95_ms=%.6f peak_ms=%.6f lua_calls=%d host_c_calls=%d skin_calls=%d %s top=%s'):format(
            c.client,name,n,elapsed,churn,retained,gc,p95,peak,luaCalls,cCalls,skinCalls,table.concat(fields,' '),table.concat(leaders,',')))
    end
    print(('OFA_LOAD %s ms=%.6f'):format(c.client,c.load_ms))
    measure('install',function()if not native then c.install()end end,1)
    measure('first_open',function()c.A.ToggleUI();c.flush()end,1)
    local root=c.UI.mainWindow
    -- Enable actual Settings/QoL factories with deterministic data providers.
    local function no()return false end
    local function empty()return {}end
    local function noop()end
    c.A.Profiles={Active=function()return 'Default'end,Names=function()return {'Default','Test'}end,
        Switch=noop,New=noop,Copy=noop,Rename=noop,Delete=noop,Export=noop,Import=noop,SendDialog=noop,SetReceive=noop,ReceiveEnabled=no}
    local options={{key='off',label='Off'}};local values={}
    c.A.QoL={Get=function(k)return values[k]end,Set=function(k,v)values[k]=v end,
        LOGO_COLORS={},MM_DIR_OPTIONS=options,CHAT_HIDE_OPTIONS=options,QUALITY_OPTIONS=options,WHO_OPTIONS=options,DUEL_OPTIONS=options,
        GetJunkItems=empty,GetNeverItems=empty,GetBuffReminders=empty,GetCVarSwitch=no,GetCompareShift=no,IsLootFeedUnlocked=no}
    local panels={}
    measure('first_pages',function()
        for _,spec in ipairs(c.UI.panels)do
            if spec==c.settings or spec==c.qol or not c.A.OpenPanel then panels[#panels+1]=spec.create(root)
            else c.A:OpenPanel(spec.key);panels[#panels+1]=c.pages[spec.key]end
        end
        c.flush()
    end,1)
    local gear
    measure('first_gear',function()gear=c.UI.CreateGearPlanner(root);gear:Show();gear:Refresh();c.flush()end,1)
    local gearSlots,checks,navs={},{},{}
    local function collect(f)
        if f.slotName then gearSlots[#gearSlots+1]=f end
        if f.kind=='CheckButton' then checks[#checks+1]=f end
        if f.kind=='Button' and f.key and f.count then navs[#navs+1]=f end
        for _,child in ipairs(f.children)do collect(child)end
    end
    collect(gear);for _,p in ipairs(panels)do collect(p)end
    assert(#gearSlots==19,'nineteen source equipment slots required')
    local list=CreateFrame('Frame',nil,root);local rows={}
    measure('first_list_256',function()
        for i=1,256 do
            local b=CreateFrame('Button',nil,list);b:SetSize(260,30);b.card=c.UI.CardRow(b)
            b.name=c.A.NewFS(b,nil,'OVERLAY','GameFontNormal');b.name:SetText('Item '..i);rows[i]=b
        end
        c.flush()
    end,1)
    for _,p in ipairs(panels)do p:Hide()end
    local ix=0
    measure('reopen',function()c.A.ToggleUI();c.A.ToggleUI();c.flush()end)
    measure('page_switch',function()
        ix=ix%8+1
        if c.A.OpenPanel then c.A:OpenPanel(c.UI.panels[ix].key)
        else for i,p in ipairs(panels)do p:SetShown(i==ix)end end
        c.flush()
    end)
    gear:Show()
    measure('gear_refresh',function()gear:Refresh();c.flush()end)
    measure('gear_select',function()ix=ix%#gearSlots+1;gearSlots[ix]:Click();c.flush()end)
    measure('settings_states',function()
        ix=ix+1;for i=1,math.min(40,#checks)do checks[i]:SetChecked(ix%2==0)end
        c.flush()
    end)
    measure('qol_navigation',function()if #navs>0 then ix=ix%#navs+1;navs[ix]:Click()end;c.flush()end)
    measure('list_40_refresh',function()
        ix=ix+1;for i=1,40 do rows[i].card:SetSelected((i+ix)%7==0)end;c.flush()
    end)
    measure('theme_refresh',function()for _,fn in ipairs(c.looks)do fn()end;c.flush()end,20)
    measure('theme_change_once',function()c.changeLooks();for _,fn in ipairs(c.looks)do fn()end;c.flush()end,1)
    root:Hide()
    measure('closed_icon_update',function()c.A.SetTex(rows[1].icon or gearSlots[1].icon,'Interface\\Icons\\INV_Misc_QuestionMark')end)
    measure('closed_events',function()
        for _,f in ipairs(c.events)do
            if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f,'PLAYER_REGEN_ENABLED')end
        end
    end)
    measure('closed_idle',function()end)
end
