-- Pinned upstream method bodies can be exercised with MANARGL_SOURCE in Actions.
do
local globals = {"AddonMgrAddonList", "CreateFrame", "hooksecurefunc", "InCombatLockdown",
    "geterrorhandler", "C_AddOns", "C_AddOnProfiler", "Enum", "ADDON_DISABLED", "LibStub", "RED_FONT_COLOR"}
local saved = {}
for _, key in ipairs(globals) do saved[key] = _G[key] end
local calls, hooks, frames, textures, reads, writes = 0, 0, 0, 0, 0, 0
local locked, enabled, active = false, true, {}
local callbacks, events = {}, {}
local function region(kind)
    local f = {kind=kind, alpha=1, text="", scripts={}, regions={}, shown=true}
    function f:GetObjectType() return self.kind end
    function f:SetText(v) self.text=v end
    function f:SetTextColor(...) self.color={...} end
    function f:SetVertexColor(...) self.tint={...} end
    function f:SetTexture(path) self.path=path end
    function f:SetAtlas(atlas) self.atlas=atlas end
    function f:SetDesaturated(flag) self.desaturated=flag end
    function f:SetAlpha(alpha) self.alpha=alpha; writes=writes+1 end
    function f:GetAlpha() return self.alpha end
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.point=nil end
    function f:SetHeight(value) self.height=value end
    function f:SetSize(w,h) self.width,self.height=w,h end
    function f:SetColorTexture(...) self.fill={...}; writes=writes+1 end
    function f:SetShown(value) self.shown=value end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:SetChecked(value) self.checked=value end
    function f:GetFontString() return self.label end
    function f:GetOrientation() return "HORIZONTAL" end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetThumbTexture() return self.thumb end
    function f:CreateTexture()
        textures=textures+1
        local t=region("Texture")
        self.regions[#self.regions+1]=t
        return t
    end
    function f:HookScript(key, fn)
        hooks=hooks+1
        local old=self.scripts[key]
        self.scripts[key]=function(...) if old then old(...) end; fn(...) end
    end
    function f:SetScript(key, fn) self.scripts[key]=fn end
    function f:RegisterEvent(event) events[event]=self end
    return f
end
CreateFrame=function() frames=frames+1; return region("Frame") end
hooksecurefunc=function(owner,key,fn)
    hooks=hooks+1
    local native=owner[key]
    owner[key]=function(...)
        local result=table.pack(native(...))
        fn(...)
        return table.unpack(result,1,result.n)
    end
end
InCombatLockdown=function() return locked end
geterrorhandler=function() return function(message) error(message) end end
LibStub=function() error("adapter must not access shared dropdown libraries") end
local function button()
    local f=region("Button")
    f.label=region("FontString")
    f.scripts.OnClick=function() return "native-click" end
    return f
end
local function addonRow()
    local f=button()
    f.title,f.status,f.icon,f.lock,f.select=region("FontString"),region("FontString"),region("Texture"),region("Texture"),region("Texture")
    f.check=region("CheckButton")
    f.check.CheckedTexture=region("Texture")
    f.loadButton=button()
    return f
end
local function categoryRow()
    local f=button()
    f.title,f.icon,f.highlight=region("FontString"),region("Texture"),region("Texture")
    f.toggleBtn=button()
    f.toggleBtn.bg,f.toggleBtn.check=region("Texture"),region("Texture")
    f.updateState=function(self) self.icon:SetAtlas("native-expanded") end
    return f
end
local function node(name, category)
    return {GetData=function() return {name=name,category=category} end}
end
local root=region("Frame")
root.shown=false
root.config={showIcon=true,showVersion=false,cpuUpdate=1,cpuAccuracy=2}
root.locked={}
root.charGUID="Player-Test"
root.inset=region("Frame")
root.inset.scrollBar=region("EventFrame")
root.searchBox=region("EditBox")
root.searchBox.searchIcon=region("Texture")
root.searchBox.scripts.OnTextChanged=function() return "native-search" end
root.closeButton=button()
root.settingsBtn=button()
root.settingsBtn.icon=region("Texture")
root.profileBtn=button()
root.profileBtn.Arrow=region("Texture")
root.filterBtn=button()
root.filterBtn.Arrow=region("Texture")
root.charSelect=button()
root.charSelect.Arrow=region("Texture")
root.charSelect.Icon=region("Texture")
root.isMainline=true
root.scaleSlider=region("Slider")
root.scaleSlider.thumb, root.scaleSlider.regions[1]=region("Texture"),region("Texture")
root.TitleContainer={TitleText=region("FontString")}
root.performance=region("Frame")
for _, key in ipairs({"enableAll","disableAll","okay","cancel","currentCPU","averageCPU","peakCPU","encounterCPU"}) do
    root[key]=button()
    root[key].topStr,root[key].bottomStr=region("FontString"),region("FontString")
end
root.onShow=function() end
root.scripts.OnShow=function(self)
    self.view={GetFrames=function() reads=reads+1; return active end}
    self:SetScript("OnShow", self.onShow)
end
local mode="enabled"
local function renderRow(_,f)
    local value=mode=="enabled" and 1 or .5
    f.title:SetTextColor(value,value,value)
    f.icon:SetTexture("native-icon")
    f.check:SetChecked(mode~="disabled")
    f.check.CheckedTexture:SetVertexColor(0,1,0)
    f.check:SetShown(mode~="locked")
end
root.normalInit=renderRow
root.categoryInit=function(_,f)
    f.toggleBtn.check:SetAtlas("native-mark")
    f:updateState()
end
root.updatePerformance=function(self) self.currentCPU.bottomStr:SetText("|cffff111180%|r") end
root.updateAddonMetrics=function(_,f) f.status:SetText("0.01%") end
root.isAddonLoadOnDemand=function() return true end
AddonMgrAddonList=root
local source=os.getenv("MANARGL_SOURCE")
if source then
    local function Read(file)
        local handle=assert(io.open(source.."/"..file,"r"))
        local contents=handle:read("*a"); handle:close()
        return contents
    end
    local native=Read("AddonMrgl.lua")
    local i=assert(native:find("function listFrame:normalInit",1,true))
    local j=assert(native:find("function listFrame:updateList",i,true))
    local loadable, reason
    Enum={AddOnEnableState={None=0,All=2}, AddOnProfilerMetric={RecentAverageTime=1}}
    C_AddOns={
        GetAddOnInfo=function(name) return name, "Native |cff00ff00"..name.."|r" end,
        GetAddOnMetadata=function(_,key) if key=="IconTexture" then return "native-icon" end end,
        IsAddOnLoadable=function()
            loadable,reason=mode~="disabled",mode=="disabled" and "DISABLED" or nil
            return loadable,reason
        end,
        IsAddOnLoaded=function() return mode~="disabled" end,
        GetAddOnEnableState=function() return mode=="disabled" and 0 or 1 end,
    }
    ADDON_DISABLED="Disabled"
    C_AddOnProfiler={IsEnabled=function() return true end,GetApplicationMetric=function() return 0 end,
        GetAddOnMetric=function() return 0 end,GetOverallMetric=function() return 0 end}
    assert(load(Read("Profiler.lua"),"@upstream/Profiler.lua"))()
    root.currentStr="%s"
    root:setCpuAccuracyStr()
    local prelude='local listFrame = AddonMgrAddonList; local L = setmetatable({}, {__index=function(_,k) return k end}); local DISABLED, DEMAND_LOADED, DEP_DEMAND_LOADED, DEP_DISABLED = "DISABLED", "DEMAND_LOADED", "DEP_DEMAND_LOADED", "DEP_DISABLED"\n'
    assert(load(prelude..native:sub(i,j-1),"@upstream/AddonMrgl.lua"))()
    -- Native strings use Blizzard's extension to format; the fixture leaves
    -- application totals at zero so host Lua can run the real idle path.
end

local S={}
for _, name in ipairs({"Shell","Inset","CloseButton","EditBox","ScrollBar","Button","Checkbox","Font"}) do
    S[name]=function(f,options)
        assert(not locked, "wrote cosmetic state in combat")
        calls=calls+1; f.skin=name; f.opts=options
        if name=="EditBox" and f.searchIcon then f.searchIcon:SetAlpha(0) end
        if name=="Font" then f.font="EUI" end
    end
end
S.GetAccentColor=function() return .2,.7,.6 end
S.OnLooksChanged=function(fn) callbacks[#callbacks+1]=fn end
local ns={IsEnabled=function() return enabled end}
local module={}
ns.RegisterModule=function(id,label,available,install)
    assert(id=="AddonMrgl" and label=="Addon Manargl" and available())
    install(S,module)
end
local function Show()
    root.shown=true
    root.scripts.OnShow(root)
end
local row,cat=addonRow(),categoryRow()
local addonNode=node("AddonA")
local catNode=node("Category",{"AddonA",sName="Category"})
root:normalInit(row,addonNode); root:categoryInit(cat,catNode)
active={row,cat}
if source then root:normalInit(row,addonNode); root:categoryInit(cat,catNode) end
local function StableWork()
    for _=1,1000 do
        root:normalInit(row,addonNode)
        root:categoryInit(cat,catNode)
        root:updatePerformance()
        root:updateAddonMetrics(row)
    end
end
local function Benchmark()
    local samples={}
    for n=1,5 do
        local start=os.clock()
        StableWork()
        samples[n]=(os.clock()-start)*1000
    end
    table.sort(samples)
    return samples[3]
end
local before=Benchmark()
assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins",ns)
local definitions=0
ns.RegisterSkinDefinition=function(id,fn)
    definitions=definitions+1
    assert(id=="AddonMrgl")
    fn()
end
assert(loadfile("EUIAddonSkins/Skins/AddonMrgl.lua"))("EUIAddonSkins",ns)
assert(definitions==1 and frames==1 and calls==0 and reads==0 and textures==0 and hooks==4)
local lockedRow=addonRow()
locked=true
root:normalInit(lockedRow,addonNode)
assert(calls==0)
active[3]=lockedRow
Show()
assert(calls==0)
locked=false
local event=assert(events.PLAYER_REGEN_ENABLED)
event.scripts.OnEvent(event)
assert(root.skin=="Shell" and root.inset.skin=="Inset" and root.searchBox.skin=="EditBox")
assert(root.closeButton.skin=="CloseButton" and root.scaleSlider.thumb.fill)
assert(root.searchBox.searchIcon:GetAlpha()==1 and root.searchBox.scripts.OnTextChanged()=="native-search")
assert(root.filterBtn.skin=="Button" and root.filterBtn.opts[1]=="Arrow" and root.filterBtn.scripts.OnClick()=="native-click")
assert(root.inset.scrollBar.skin=="ScrollBar")
assert(row.check.skin=="Checkbox" and row.check.opts.stockCheck and row.check.CheckedTexture.tint[2]==1)
assert(cat.skin=="Button" and not cat.toggleBtn.skin and cat.title.font=="EUI")
assert(row.loadButton.skin=="Button" and row.icon.path=="native-icon" and row.status.font=="EUI" and lockedRow.check.skin)
assert(root.currentCPU.bottomStr.font=="EUI" and root.scaleSlider.scripts.OnValueChanged==nil)
assert(root.settingsBtn.opts[1]=="icon" and root.charSelect.opts[1]=="Arrow")
assert(cat.opts[1]=="icon" and cat.opts[2]=="highlight")
local warmCalls,warmHooks,warmFrames,warmArt,warmReads,warmWrites=calls,hooks,frames,textures,reads,writes
local after=Benchmark()
assert(calls==warmCalls and hooks==warmHooks and frames==warmFrames and textures==warmArt and reads==warmReads and writes==warmWrites)
mode="disabled"; root:normalInit(row,addonNode)
assert(not row.check.checked and row.title.color[1]==.5 and row.title.font=="EUI")
mode="locked"; root.locked.AddonA=true; root:normalInit(row,addonNode)
assert(not row.check.shown)
local late=addonRow(); mode="enabled"; root.locked.AddonA=nil
root:normalInit(late,addonNode)
assert(late.check.skin=="Checkbox")
root:Hide(); local liveCalls=calls
callbacks[1](); assert(calls==liveCalls)
-- On reopen the original initializer has already been replaced in WoW.
root:Hide(); Show()
assert(calls>liveCalls and frames==warmFrames and textures==warmArt and hooks==warmHooks)
enabled=false; liveCalls=calls
module.refresh(); root:normalInit(addonRow(),addonNode); callbacks[1]()
assert(calls==liveCalls)
print(("BENCH Manargl %s: five-trial median for 1000 pooled row/category and CPU cycles %.3f -> %.3f ms; first open +%d frames, +%d textures, +%d adapter hooks; warm 0 cosmetic calls/writes, pool reads or allocations")
    :format(source and "pinned-source" or "fixture",before,after,warmFrames,warmArt,warmHooks))
print("PASS: Manargl owned appearance, native state colours/actions, pool reuse, combat, theme deferral and no library hooks")
for _, key in ipairs(globals) do _G[key]=saved[key] end
end
