-- TEMPORARY DEVELOPMENT INSTRUMENTATION. Not loaded by any normal manifest.
-- scripts/package_oneforall_trace.py alone inserts this file in a test ZIP.
local _, ns = ...
local BUILD = "@TRACE_BUILD@"
local D = {active=false}
ns.OneForAllTrace = D
local cards, planners, slots, watched = {}, {}, {}, {}
local log, snapshots, last, dropped, serial = {}, {}, {}, 0, 0
local phaseSeen = {}
local attempts = {}
local LIMIT, SNAP_LIMIT = 1024, 12
local unpack = unpack or table.unpack
local function say(s) print("EUI OneForAll trace: "..s) end
local function stack()
    return debugstack and debugstack(3, 7, 0):sub(1, 1100) or "stack unavailable"
end
local function value(v)
    if type(v)=="number" then return ("%.5g"):format(v) end
    return tostring(v)
end
local function values(...)
    local t={}
    for i=1,select("#",...) do t[i]=value(select(i,...)) end
    return table.concat(t,",")
end
local function state(t)
    local p=t:GetParent()
    local ancestors, product, shown={}, 1, true
    for _=1,20 do
        if not p then break end
        product=product*(p.GetAlpha and p:GetAlpha() or 1)
        shown=shown and (not p.IsShown or p:IsShown())
        ancestors[#ancestors+1]=values(p.GetObjectType and p:GetObjectType(),p.GetAlpha and p:GetAlpha(),
            p.IsShown and p:IsShown(),p.GetFrameLevel and p:GetFrameLevel(),p.GetFrameStrata and p:GetFrameStrata())
        p=p.GetParent and p:GetParent()
    end
    local points={}
    for i=1,math.min(t:GetNumPoints(),4) do
        local a,_,b,x,y=t:GetPoint(i);points[i]=values(a,b,x,y)
    end
    return "shown="..value(t:IsShown()).." visible="..value(t:IsVisible())
        .." alpha="..value(t:GetAlpha()).." parentAlpha="..value(product).." parentsShown="..value(shown)
        .." effective="..value(t.GetEffectiveAlpha and t:GetEffectiveAlpha())
        .." layer="..values(t:GetDrawLayer()).." texture="..value(t:GetTexture())
        .." path="..value(t.GetTextureFilePath and t:GetTextureFilePath())
        .." rgba="..values(t:GetVertexColor()).." size="..values(t:GetSize())
        .." blend="..value(t.GetBlendMode and t:GetBlendMode())
        .." desaturated="..value(t.IsDesaturated and t:IsDesaturated())
        .." uv="..values(t:GetTexCoord()).." points="..table.concat(points,";")
        .." ancestors="..table.concat(ancestors,"/")
end
local function add(s, caller)
    if #log>=LIMIT then dropped=dropped+1;return end
    serial=serial+1
    log[#log+1]=("%04d %.3f %s\n%s"):format(serial,GetTime and GetTime() or 0,s,caller or "")
end
local function regions(slot)
    local out={}
    for i,t in ipairs(slot.card.border.pieces or {}) do out[#out+1]={t,"border"..i} end
    local fill=slot.card.fill and slot.card.fill.pieces
    if fill and fill[#fill] then out[#out+1]={fill[#fill],"fill"} end
    if slot.icon then out[#out+1]={slot.icon,"icon"} end
    return out
end
local function capture(label)
    if #snapshots>=SNAP_LIMIT then say("Snapshot limit reached; export or start a new capture.");return end
    local data={}
    for _,s in ipairs(slots) do
        local q=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[s.q]
        data["slot"..s.slot]="quality="..value(s.q).." expected="..(q and values(q.r,q.g,q.b) or "empty/unknown")
        for _,r in ipairs(regions(s)) do data["slot"..s.slot.."."..r[2]]=state(r[1]) end
    end
    snapshots[#snapshots+1]={label=label,data=data}
    return data
end
local function observe(t, label, slot)
    if watched[t] then return end
    watched[t]=true
    for _,method in ipairs({"SetAlpha","SetVertexColor","SetTexture","SetColorTexture","SetDrawLayer",
            "Show","Hide","SetShown","SetParent","SetPoint","ClearAllPoints","SetAllPoints","SetSize","SetWidth","SetHeight","SetTexCoord","SetBlendMode","SetDesaturated"}) do
        if type(t[method])=="function" then
            hooksecurefunc(t,method,function(_, ...)
                if not D.active or #log>=LIMIT then
                    if D.active then dropped=dropped+1 end
                    return
                end
                local current=state(t)
                local args=values(...)
                local setters=attempts[t]
                if not setters then setters={};attempts[t]=setters end
                -- A solid-colour texture has no public base-RGBA getter on
                -- older clients. Preserve changed setter arguments even when
                -- GetTexture()/vertex readback looks identical. Also exposes
                -- writes immediately repaired by the existing skin hooks.
                if last[t]~=current or setters[method]~=args then
                    setters[method]=args
                    last[t]=current
                    add("slot"..value(slot.slot).."."..label.." "..method.." args="..args
                        .." q="..value(slot.q).." "..current,stack())
                end
            end)
        end
    end
end
local function phase(s)
    if D.active then
        if #log<LIMIT then add("PHASE "..s,stack()) else dropped=dropped+1 end
        -- Keep room for explicit before/after/reopen captures. Repeated native
        -- refreshes still appear as ordered events, without duplicate dumps.
        if not phaseSeen[s] and #snapshots<6 then phaseSeen[s]=true;capture(s) end
    end
end
local function bind(f)
    if planners[f] then return end
    planners[f]=true
    -- Only completed Card references registered by this adapter; no UI walk.
    for owner in pairs(cards) do
        if owner.slotName and type(owner.slot)=="number" then
        local p=owner
        for _=1,20 do
            if p==f then
                if owner.slotName and type(owner.slot)=="number" then
                    slots[#slots+1]=owner
                    for _,r in ipairs(regions(owner)) do observe(r[1],r[2],owner) end
                    owner:HookScript("OnMouseDown",function() phase("before-mousedown slot"..owner.slot) end)
                    owner:HookScript("OnClick",function() phase("after-click slot"..owner.slot) end)
                    -- Ancestor state can hide a perfectly valid texture. Watch
                    -- only this finite ancestry, shared by the existing slots.
                    local parent=owner
                    for _=1,20 do
                        if not parent or parent==UIParent then break end
                        if not watched[parent] then
                            watched[parent]=true
                            local observed=parent
                            for _,method in ipairs({"SetAlpha","Show","Hide","SetShown","SetFrameLevel","SetFrameStrata","SetParent","DisableDrawLayer","EnableDrawLayer"}) do
                                if type(observed[method])=="function" then
                                    hooksecurefunc(observed,method,function(_, ...)
                                        if D.active and #log<LIMIT then add("PARENT "..method.." args="..values(...),stack()) end
                                    end)
                                end
                            end
                            observed:HookScript("OnShow",function() phase("ancestor OnShow") end)
                            observed:HookScript("OnHide",function() if D.active and #log<LIMIT then add("ancestor OnHide",stack()) end end)
                        end
                        parent=parent:GetParent()
                    end
                end
                break
            end
            p=p and p:GetParent()
            if not p then break end
        end
        end
    end
    table.sort(slots,function(a,b)return a.slot<b.slot end)
    for _,name in ipairs({"paintSlots","Refresh"}) do
        if type(f[name])=="function" then hooksecurefunc(f,name,function(...) phase("GearPlanner."..name) end) end
    end
    phase("completed factory")
end
function D.Card(card,owner)
    -- Slot identity is assigned after Card returns. Remember just native
    -- equipment-sized candidates until the completed planner confirms them.
    if owner and owner.GetWidth and owner:GetWidth()==38 and owner:GetHeight()==38 then
        cards[owner]=card
        if D.active and not owner.card then add("Card creation 38x38 border="..state(card.border.pieces[1]),stack()) end
    end
end
local known={}
function D.Planner(f)
    if not f or type(f.paintSlots)~="function" then return end
    known[f]=true
    if D.active then bind(f) end
end
local function report()
    local version,build,date,interface
    if GetBuildInfo then version,build,date,interface=GetBuildInfo() end
    local lines={"EUI OneForAll LIVE TRACE v1 | development build "..BUILD,
        "Client="..values(version,build,date,interface).." project="..value(WOW_PROJECT_ID),
        "OneForAll="..value((C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)
            and (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)("OneForAll","Version")),
        "slots="..#slots.." events="..#log.." dropped="..dropped.." snapshots="..#snapshots,
        "No names, item links, chat or inventory IDs collected. Native caller paths may appear."}
    for _,entry in ipairs(log) do lines[#lines+1]=entry end
    for _,snapshot in ipairs(snapshots) do
        lines[#lines+1]="SNAPSHOT "..snapshot.label
        local keys={};for key in pairs(snapshot.data) do keys[#keys+1]=key end;table.sort(keys)
        for _,key in ipairs(keys) do lines[#lines+1]=key.." "..snapshot.data[key] end
    end
    local before,after
    for _,snapshot in ipairs(snapshots) do
        if snapshot.label=="before" then before=snapshot.data end
        if snapshot.label=="after" then after=snapshot.data end
    end
    lines[#lines+1]="COMPARE before -> after"
    if before and after then
        local keys={};for key in pairs(before) do keys[#keys+1]=key end;table.sort(keys)
        local n=0
        for _,key in ipairs(keys) do if before[key]~=after[key] then
            n=n+1;lines[#lines+1]=key.."\nBEFORE "..before[key].."\nAFTER "..value(after[key])
        end end
        lines[#lines+1]="Changed entries="..n
    else lines[#lines+1]="Run before and after commands to compare." end
    return table.concat(lines,"\n")
end
local window,box
local function export()
    if InCombatLockdown and InCombatLockdown() then say("Export outside combat.");return end
    D.active=false
    if not window then
        window=CreateFrame("Frame","EUIAddonSkinsOFATraceExport",UIParent,"BasicFrameTemplateWithInset")
        window:SetSize(820,540);window:SetPoint("CENTER");window:SetFrameStrata("DIALOG")
        window.TitleText:SetText("OneForAll trace — Ctrl+A, Ctrl+C; Escape closes")
        local scroll=CreateFrame("ScrollFrame",nil,window,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",12,-34);scroll:SetPoint("BOTTOMRIGHT",-32,12)
        box=CreateFrame("EditBox",nil,scroll);box:SetMultiLine(true);box:SetAutoFocus(false)
        box:SetFont("Fonts\\FRIZQT__.TTF",11,"");box:SetWidth(760);box:SetMaxLetters(0)
        box:SetScript("OnEscapePressed",function()window:Hide()end)
        scroll:SetScrollChild(box)
    end
    window:Show();box:SetText(report());box:HighlightText();box:SetFocus()
end
function D.Command(action)
    action=(action or ""):lower():match("^%s*(%S*)")
    if action=="start" then
        if InCombatLockdown and InCombatLockdown() then say("Start outside combat.");return end
        log,snapshots,last,dropped,serial,phaseSeen,attempts={},{},{},0,0,{},{}
        D.active=true
        for f in pairs(known) do bind(f) end
        add("START",stack());capture("start")
        say("Capturing. Open Gear Planner, then /euiskins ofatrace before.")
    elseif action=="stop" then D.active=false;say("Stopped; log retained until /reload or start.")
    elseif action=="before" or action=="after" or action=="snapshot" then
        if not D.active then say("Run start first.");return end
        if capture(action) then say(action.." captured ("..#slots.." slots).") end
    elseif action=="export" or action=="compare" then export()
    else say((D.active and "ON" or "OFF").." | "..#slots.." slots, "..#log.." events, "..dropped
        .." dropped | start, before, after, snapshot, compare/export, stop") end
end
-- Command wrapping exists only in this explicit development ZIP. Existing
-- /euiskins commands and arguments pass through unchanged.
local original=SlashCmdList.EUIADDONSKINS
SlashCmdList.EUIADDONSKINS=function(message)
    local command,action=(message or ""):match("^%s*(%S+)%s*(.-)%s*$")
    if command and command:lower()=="ofatrace" then return D.Command(action) end
    return original(message)
end
