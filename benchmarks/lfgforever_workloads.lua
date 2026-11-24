-- Appended to the existing source-shaped fixture in a fresh Lua state per trial.
local mode=os.getenv("LFG_AUDIT_MODE") or "candidate"
local rows=20
local originalBuild=build
build=function()
    local r=originalBuild()
    if r.seeded then return r end
    r.seeded=true
    local p=r.Content.FilterPanel
    -- Mirror the native section ownership and ancestor visibility lifecycle.
    p.WhispersSection=frame("Frame",p);p.RatingsSection=frame("Frame",p)
    p.WhisperLog.parent=p.WhispersSection;p.WhispersSection.children={p.WhisperLog}
    p.PlayerRatings.parent=p.RatingsSection;p.RatingsSection.children={p.PlayerRatings}
    for i=#p.children,1,-1 do if p.children[i]==p.WhisperLog or p.children[i]==p.PlayerRatings then table.remove(p.children,i)end end
    p.WhispersSection.shown=false;p.RatingsSection.shown=false
    p.WhisperLog.shown=true;p.PlayerRatings.shown=true
    function p:SetTab(tab)
        self.selected=tab
        if tab=="Whispers"then self.WhispersSection:Show()else self.WhispersSection:Hide()end
        if tab=="Ratings"then self.RatingsSection:Show()else self.RatingsSection:Hide()end
    end
    for _,box in ipairs({r.Content.ListPanel.ScrollBox,p.WhisperLog.ScrollBox,p.PlayerRatings.ScrollBox})do
        for _=1,rows do
            local row=frame("Button",box)
            row.Text=label(row);row.Icon=texture()
            local inside=frame("Frame",row)
            local action=button(inside);action.nativeAction=true
            row.Detail=label(inside);row.Metadata=label(inside)
            box.rows[#box.rows+1]=row
        end
    end
    r:Hide()
    return r
end
local counters={"frames","textures","fontstrings","hooks","listeners","fonts","colors","reads","parents","fontReads","texWrites","pointWrites","backdrops","popup"}
local report={}
local function take()
    local t={};for _,k in ipairs(counters)do t[k]=stats[k]or 0 end;return t
end
local function emit(name,n,ms,alloc,ret,before,after)
    local metrics=after or stats
    local v={name,tostring(n),string.format("%.6f",ms),string.format("%.6f",alloc),string.format("%.6f",ret)}
    for _,k in ipairs(counters)do v[#v+1]=k.."="..tostring((metrics[k]or 0)-(before[k]or 0))end
    report[#report+1]=table.concat(v,"\t")
end
local function measure(name,n,fn)
    local before=take()
    collectgarbage("collect");local heap=collectgarbage("count");collectgarbage("stop")
    local started=os.clock()
    for i=1,n do fn(i)end
    local elapsed=(os.clock()-started)*1000
    local allocated=collectgarbage("count")-heap
    collectgarbage("restart");collectgarbage("collect")
    emit(name,n,elapsed,allocated,collectgarbage("count")-heap,before)
end
emit("definition_registration",1,registrationMS or 0,registrationKiB or 0,registrationRetained or 0,registrationStats or {},registrationAfter or {})
measure("skin_activation",1,function()if mode~="native"then installed.install(S,module)end end)
measure("first_open",1,function()LFGForever_ToggleWindow()end)
local r=LFGForeverFrame;local p=r.Content.FilterPanel
local box=r.Content.ListPanel.ScrollBox
local whispers=p.WhisperLog.ScrollBox;local ratings=p.PlayerRatings.ScrollBox
local function cycleTabs(i)
    local names={"Filters","Whispers","Ratings"}
    p:SetTab(names[(i-1)%3+1])
end
local function refresh(list,i)
    local row=list.rows[(i-1)%#list.rows+1]
    row.data=i
    list:Initialize(row)
end
measure("warm_reopen_filters",1000,function()r:Hide();LFGForever_ToggleWindow()end)
p:SetTab("Whispers")
measure("warm_reopen_whispers",1000,function()r:Hide();LFGForever_ToggleWindow()end)
measure("three_tab_switches",1000,cycleTabs)
p:SetTab("Filters")
measure("search_result_refresh",1000,function(i)refresh(box,i)end)
measure("player_list_refresh",1000,function(i)refresh(box,i+7)end)
p:SetTab("Whispers")
measure("whisper_display",1000,function(i)refresh(whispers,i)end)
p:SetTab("Ratings")
measure("rating_display",1000,function(i)refresh(ratings,i)end)
measure("theme_open",100,function(i)
    accent=i%2==0 and {.9,.5,.2}or{.2,.6,.9}
    for _,fn in ipairs(looks)do fn()end
end)
r:Hide()
measure("theme_closed",100,function(i)
    accent=i%2==0 and {.9,.5,.2}or{.2,.6,.9}
    for _,fn in ipairs(looks)do fn()end
end)
measure("idle_closed",10000,function(i)local _=i+1 end)
local foreign=frame()
measure("foreign_menus_closed",1000,function()manager:OpenMenu(foreign)end)
measure("addon_loads_closed",1000,function()
    for _,f in ipairs(events)do if f.callbacks.ADDON_LOADED and f.scripts.OnEvent then f.scripts.OnEvent(f,"ADDON_LOADED")end end
end)
-- Stress notification boundary, not a claim about native hidden view frequency.
measure("closed_view_notification_stress",1000,function(i)refresh(whispers,i)end)
LFGForever_ToggleWindow()
measure("side_selection",1000,function(i)r.side:SetChecked(i%2==0)end)
measure("theme_then_combat_recovery",100,function()
    combat=true
    for _,fn in ipairs(looks)do fn()end
    combat=false
    for _,f in ipairs(events)do
        if f.callbacks.PLAYER_REGEN_ENABLED and f.scripts.OnEvent then f.scripts.OnEvent(f,"PLAYER_REGEN_ENABLED")end
    end
end)
enabled=false
measure("disabled_native_updates",1000,function(i)refresh(box,i)end)
enabled=true
if module and module.refresh then module.refresh()end
-- Force native reset, re-acquisition and first visibility; same fixture in each mode.
local cold=frame("Button",whispers);cold.Text=label(cold)
r:Hide();whispers.rows[#whispers.rows+1]=cold;whispers:Initialize(cold)
LFGForever_ToggleWindow();p:SetTab("Whispers")
if mode~="native"then assert(cold.Text.path=="eui","deferred row not styled on first show")end
assert(#errors==0,table.concat(errors,"\n"))
local function visual()
    local t=r.Content.TitleText
    local c=p.check.Checked.color or {}
    local v={r.width,r.height,p.check.width,p.check.height,p.check.Checked.width or 0,t.path,t.size,t.color[1],t.color[2],t.color[3],r.side.Icon.alpha,p.star.Unearned.alpha}
    for _,x in ipairs(c)do v[#v+1]=x end
    return table.concat(v,"|")
end
report[#report+1]="VISUAL\t"..visual()
report[#report+1]="INVENTORY\t"..table.concat((function()local out={};for _,k in ipairs(counters)do out[#out+1]=k.."="..tostring(stats[k]or 0)end;return out end)(),"\t")
return table.concat(report,"\n")
