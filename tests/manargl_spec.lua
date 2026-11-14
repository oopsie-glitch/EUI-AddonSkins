-- Pinned upstream method bodies can be exercised with MANARGL_SOURCE in Actions.
do
local globals = {"AddonMgrAddonList", "CreateFrame", "hooksecurefunc", "InCombatLockdown",
    "geterrorhandler", "C_AddOns", "C_AddOnProfiler", "Enum", "ADDON_DISABLED", "LibStub", "RED_FONT_COLOR"}
local saved = {}
for _, key in ipairs(globals) do saved[key] = _G[key] end
local calls, hooks, frames, textures, reads, writes = 0, 0, 0, 0, 0, 0
local locked, enabled, active = false, true, {}
local callbacks, events = {}, {}
local menuLookups, styleRegistrations = 0, 0
local function region(kind)
    local f = {kind=kind, alpha=1, text="", scripts={}, regions={}, shown=true}
    function f:GetObjectType() return self.kind end
    function f:GetParent() return self.parent end
    function f:EnableMouse(value) self.mouse=value end
    function f:SetText(v) self.text=v end
    function f:SetTextColor(...) self.color={...} end
    function f:SetVertexColor(...) self.tint={...}; self.tintWrites=(self.tintWrites or 0)+1 end
    function f:SetTexture(path) self.path=path end
    function f:GetTexture() return self.path end
    function f:SetAtlas(atlas) self.atlas=atlas end
    function f:SetDesaturated(flag) self.desaturated=flag end
    function f:SetAlpha(alpha) self.alpha=alpha; writes=writes+1 end
    function f:GetAlpha() return self.alpha end
    function f:SetPoint(...)
        self.point={...}
        if self.point[1]=="TOPLEFT" then self.topLeft=self.point end
    end
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
CreateFrame=function(_, _, parent)
    frames=frames+1
    local f=region("Frame")
    f.parent=parent
    return f
end
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
local builtins={"backdrop","menuBackdrop","modernMenu"}
local nativeMenus, factories = {}, {}
local NativeToggle
local nativeRootOwner
local function AcquireMenu(level)
    if nativeMenus[level] then return nativeMenus[level] end
    local menu=region("Frame")
    menu.styles={}
    for _, style in ipairs(builtins) do menu.styles[style]=region("Frame") end
    for style, factory in pairs(factories) do
        menu.styles[style]=factory(menu)
        menu.styles[style]:Hide()
    end
    menu.activeStyle=menu.styles.backdrop
    menu.shown=false
    menu.reset=function(self) self:ClearAllPoints(); return self end
    menu.scrollChild=region("Frame")
    function menu.scrollChild:SetWidth(width) self.width=width end
    menu.scrollFrame=region("ScrollFrame")
    menu.scrollBar=region("Frame")
    function menu.scrollBar:SetScrollPercentage(value) self.scroll=value end
    menu.searchFrames={}
    nativeMenus[level]=menu
    return menu
end
local function SelectStyle(menu, owner)
    local style=owner.ddDisplayMode
    if style=="menu" then style="modernMenu"
    elseif not menu.styles[style] then style="backdrop" end
    menu.activeStyle:Hide()
    menu.activeStyle=menu.styles[style]
    menu.activeStyle:Show()
end
local function SetDisplayMode(self, style) self.ddDisplayMode=style end
local library={}
function library:CreateMenuStyle(style, factory)
    assert(not locked and not factories[style])
    styleRegistrations=styleRegistrations+1
    factories[style]=factory
    for _, menu in ipairs(nativeMenus) do
        menu.styles[style]=factory(menu)
        menu.styles[style]:Hide()
    end
    return true
end
LibStub=function(name, silent)
    assert(name=="LibSFDropDown-1.5" and silent)
    menuLookups=menuLookups+1
    return library
end
local existingMenu=AcquireMenu(1)
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
for _, field in ipairs({"charSelect","filterBtn","profileBtn","settingsBtn"}) do
    local launcher=root[field]
    launcher.parent=root
    launcher.ddSetDisplayMode=SetDisplayMode
end
root.isMainline=os.getenv("MANARGL_AUDIT_CLIENT")~="forever"
if not root.isMainline then root.charSelect.Button=button() end
root.scaleSlider=region("Slider")
local slider=root.scaleSlider
slider.thumb=region("Texture")
slider.thumb:SetAtlas("Minimal_SliderBar_Button")
slider.thumb:SetSize(20,20)
slider.thumb:SetPoint("CENTER")
for _, key in ipairs({"Left","Middle","Right"}) do
    local texture=region("Texture")
    slider[key]=texture
    slider.regions[#slider.regions+1]=texture
end
slider.regions[#slider.regions+1]=slider.thumb
local thumbPoint=slider.thumb.point
local function scaleChanged(self, value)
    root.config.scale=value
    self.thumb.position=value
end
slider:SetScript("OnValueChanged", scaleChanged)
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
    local libSource=Read("LibSFDropDown.lua")
    local start=assert(libSource:find("local style = v.DROPDOWNBUTTON.ddDisplayMode",1,true))
    local finish=assert(libSource:find("menu.activeStyle:Show()",start,true))
    SelectStyle=assert(load("return function(menu, owner) local v={DROPDOWNBUTTON=owner, menuStyle='modernMenu',defaultStyle='backdrop'}\n"
        ..libSource:sub(start,finish+#"menu.activeStyle:Show()"-1).."\nend","@upstream/LibSFDropDown.lua"))()
    local first=assert(libSource:find("function DropDownButtonMixin:ddToggle(",1,true))
    local last=assert(libSource:find("function DropDownButtonMixin:ddRefresh(",first,true))
    local queue=setmetatable({}, {__index=function(_, level) return AcquireMenu(level) end})
    local context={dropDownMenuButtonHeight=18, menuStyle="modernMenu", defaultStyle="backdrop"}
    local chunk=assert(load("local DropDownButtonMixin,v,dropDownMenusList,GetScreenWidth,GetScreenHeight=...\n"
        ..libSource:sub(first,last-1).."\nreturn DropDownButtonMixin.ddToggle","@upstream/LibSFDropDown.lua"))
    NativeToggle=chunk({},context,queue,function() return 1000 end,function() return 700 end)
    nativeRootOwner=context
    local settings=Read("Settings.lua")
    local scaleStart=assert(settings:find("-- scale",1,true))
    local scaleEnd=assert(settings:find("-- settings",scaleStart,true))
    local window=region("Frame")
    window.scaleSlider=region("Slider")
    window.config={scale=125}
    local dragStops=0
    window:SetScript("OnDragStop",function() dragStops=dragStops+1 end)
    function window:GetRight() return 640 end
    function window:GetTop() return 500 end
    local control=window.scaleSlider
    for _, frame in ipairs({window, control}) do
        function frame:GetScript(key) return self.scripts[key] end
        function frame:GetScale() return self.scale or 1 end
        function frame:SetScale(value) self.scale=value end
    end
    function control:SetMinMaxValues(a,b) self.min,self.max=a,b end
    function control:SetValueStep(step) self.step=step end
    function control:GetValue() return self.value end
    function control:SetValue(value)
        value=math.max(self.min, math.min(self.max, value))
        if self.value==value then return end
        self.value=value
        local changed=self:GetScript("OnValueChanged")
        if changed then changed(self,value) end
    end
    local openSlider=assert(load("return function(self, UIParent)\n"..settings:sub(scaleStart,scaleEnd-1).."\nend","@upstream/Settings.lua"))()
    openSlider(window,{})
    assert(control.min==50 and control.max==200 and control.step==1 and control.value==125)
    control:SetValue(50)
    assert(window.config.scale==50 and window.scale==.5 and dragStops==1)
    control:GetScript("OnMouseUp")(control)
    control:SetValue(200)
    assert(window.config.scale==200 and window.scale==2 and dragStops==2)
    control:GetScript("OnMouseWheel")(control,-1)
    assert(window.config.scale==199 and control:GetScale()==1)
    control:GetScript("OnMouseDown")(control,"RightButton")
    control:GetScript("OnMouseUp")(control)
    assert(window.config.scale==100 and control.value==100 and control:GetScale()==1)
    window.config.scale=137
    control:SetScript("OnValueChanged",nil)
    openSlider(window,{})
    assert(window.config.scale==137 and control.value==137)

    local dismissStart=assert(libSource:find("-- CLOSE ON ESC",1,true))
    local dismissEnd=assert(libSource:find("-- DROPDOWN TOGGLE BUTTON",dismissStart,true))
    local popup=region("Frame")
    local underMouse, focus
    local eventsActive={}
    function popup:IsMouseOver() return underMouse end
    function popup:Raise() end
    function popup:EnableKeyboard(value) self.keyboard=value end
    function popup:SetPropagateKeyboardInput(value) self.propagate=value end
    function popup:RegisterEvent(event) eventsActive[event]=true end
    function popup:UnregisterEvent(event) eventsActive[event]=nil end
    local nativeDismiss=assert(load("local menu1,dropDownMenusList,GetBindingKey,GetMouseFoci,InCombatLockdown,DropDownMenuList_OnHide=...\n"
        ..libSource:sub(dismissStart,dismissEnd-1),"@upstream/LibSFDropDown.lua"))
    nativeDismiss(popup,{popup},function() return "ESCAPE" end,function() return {focus} end,
        function() return locked end,function() end)
    popup.scripts.OnShow(popup)
    assert(popup.keyboard and eventsActive.GLOBAL_MOUSE_DOWN)
    popup.scripts.OnKeyDown(popup,"ESCAPE")
    assert(not popup:IsShown() and popup.propagate==false)
    popup:Show()
    underMouse=true
    popup.scripts.OnEvent(popup,"GLOBAL_MOUSE_DOWN","LeftButton")
    assert(popup:IsShown())
    underMouse=false
    focus={LibSFDropDownNoGMEvent=true}
    popup.scripts.OnEvent(popup,"GLOBAL_MOUSE_DOWN","LeftButton")
    assert(popup:IsShown())
    focus=nil
    popup.scripts.OnEvent(popup,"GLOBAL_MOUSE_DOWN","RightButton")
    assert(not popup:IsShown())
    popup.scripts.OnHide(popup)
    assert(next(eventsActive)==nil)
    locked=true
    popup:Show()
    popup.scripts.OnShow(popup)
    assert(not popup.keyboard)
    locked=false
    popup.scripts.OnEvent(popup,"PLAYER_REGEN_ENABLED")
    assert(popup.keyboard)
    print("AUDIT source PASS: scale bounds, wheel, reset, reopening with saved value, Escape, outside click, protected launcher focus, combat keyboard recovery")
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
for _, name in ipairs({"Shell","Inset","CloseButton","EditBox","ScrollBar","Button","Checkbox","Font","Panel"}) do
    S[name]=function(f,options)
        assert(not locked or name=="Panel" and f.parent and f.mouse==false, "wrote cosmetic state in combat")
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
local auditMode=os.getenv("MANARGL_AUDIT_SKIN")
if auditMode then
    assert(NativeToggle and nativeRootOwner)
    local function delta(fn)
        local samples={}
        for trial=1,7 do
            local start=os.clock()
            fn()
            samples[trial]=(os.clock()-start)*1000
        end
        table.sort(samples)
        return samples[4]
    end
    local function report(name, fn)
        print(("AUDIT %s %s %.4f ms"):format(auditMode,name,delta(fn)))
    end
    local function Setup()
        local start=os.clock()
        if auditMode~="native" then
            assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins",ns)
            ns.RegisterSkinDefinition=function(_,fn) fn() end
            assert(loadfile(auditMode))("EUIAddonSkins",ns)
        end
        print(("AUDIT %s initialize-single %.4f ms"):format(auditMode,(os.clock()-start)*1000))
        start=os.clock()
        Show()
        print(("AUDIT %s first-open-single %.4f ms"):format(auditMode,(os.clock()-start)*1000))
    end
    LibStub=function(name, silent)
        assert(name=="LibSFDropDown-1.5" and silent)
        menuLookups=menuLookups+1
        return library
    end
    Setup()
    local dropdowns={root.filterBtn, root.profileBtn, root.charSelect, region("Button")}
    local other=dropdowns[4]
    other.ddDisplayMode="menuBackdrop"
    local function Initialize(_, level, value)
        local popup=AcquireMenu(level)
        popup.width,popup.height=140,60
        popup.value=value
    end
    local submenuAnchor=region("Button")
    function submenuAnchor:GetRight() return self.right or 400 end
    for _, owner in ipairs(dropdowns) do owner.ddInitializeFunc=Initialize end
    local function Open(owner, count)
        NativeToggle(owner,1,nil,owner,"TOPLEFT","BOTTOMLEFT")
        assert(nativeRootOwner.DROPDOWNBUTTON==owner)
        for level=2,count do NativeToggle(owner,level,"submenu",submenuAnchor) end
    end
    local function Close(count)
        for level=count,1,-1 do AcquireMenu(level):Hide() end
    end
    for i=1,3 do
        local owner=dropdowns[i]
        Open(owner,3)
        local mode=owner.ddDisplayMode or "backdrop"
        for level=1,3 do
            local popup=AcquireMenu(level)
            assert(popup.activeStyle==popup.styles[mode])
        end
        submenuAnchor.right=990
        NativeToggle(owner,2,"edge",submenuAnchor)
        assert(AcquireMenu(2).point[1]=="TOPRIGHT")
        submenuAnchor.right=nil
        Open(other,3)
        for level=1,3 do
            local popup=AcquireMenu(level)
            assert(popup.activeStyle==popup.styles.menuBackdrop)
            for name, panel in pairs(popup.styles) do
                if not name:match("^backdrop$") and name~="modernMenu" and panel~=popup.activeStyle then
                    assert(not panel:IsShown())
                end
            end
        end
        Close(3)
    end
    print("AUDIT ownership PASS: native ddToggle, three depths, three Manargl launchers, independent foreign launcher, right-edge submenu flip")
    local function Counts()
        return table.concat({frames,textures,hooks,menuLookups,styleRegistrations,#callbacks},",")
    end
    local function Repeat(fn) for i=1,1000 do fn(i) end end
    local objects=Counts()
    collectgarbage("collect")
    local heap=collectgarbage("count")
    report("reopen",function() Repeat(function() root:Hide(); Show() end) end)
    report("row-rebind",function() Repeat(function() root:normalInit(row,addonNode); root:categoryInit(cat,catNode) end) end)
    report("metrics",function() Repeat(function() root:updatePerformance(); root:updateAddonMetrics(row) end) end)
    report("popup-root-cycle",function() Repeat(function() Open(root.filterBtn,1); Close(1) end) end)
    report("popup-three-depth-handoff",function() Repeat(function() Open(root.profileBtn,3); Open(other,3); Close(3) end) end)
    report("slider-callback",function() Repeat(function(i) slider.scripts.OnValueChanged(slider,50+i%151) end) end)
    report("theme-signal",function() Repeat(function() if callbacks[1] then callbacks[1]() end end) end)
    collectgarbage("collect")
    assert(Counts()==objects, "resource counts grew: "..objects.." -> "..Counts())
    print(("AUDIT %s counts=%s retained-heap-delta=%.3f KiB"):format(auditMode,objects,collectgarbage("count")-heap))
    for _, key in ipairs(globals) do _G[key]=saved[key] end
    return
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
assert(calls==0 and menuLookups==0 and #slider.regions==4)
locked=false
local event=assert(events.PLAYER_REGEN_ENABLED)
event.scripts.OnEvent(event)
assert(root.skin=="Shell" and root.inset.skin=="Inset" and root.searchBox.skin=="EditBox")
assert(root.closeButton.skin=="CloseButton")
local track,edge,grip=slider.regions[5],slider.regions[6],slider.regions[7]
assert(track.height==2 and track.fill[1]==.2 and #slider.regions==7)
assert(slider.Left.alpha==0 and slider.Middle.alpha==0 and slider.Right.alpha==0)
assert(slider:GetThumbTexture()==slider.thumb and slider.thumb.atlas=="Minimal_SliderBar_Button")
assert(slider.thumb.width==20 and slider.thumb.height==20 and slider.thumb.point==thumbPoint)
assert(slider.thumb.alpha==0 and slider.thumb.fill==nil and slider.thumb.tint==nil)
assert(edge.width==8 and edge.height==14 and edge.point[2]==slider.thumb)
assert(edge.fill[1]>grip.fill[1] and grip.topLeft[2]==edge and grip.topLeft[4]==1 and grip.point[2]==edge and grip.point[4]==-1)
assert(menuLookups==1 and styleRegistrations==1)
local style=root.filterBtn.ddDisplayMode
local foreignModes={"menu","menuBackdrop","unregistered-foreign-style"}
local fallbackStyles={"modernMenu","menuBackdrop","backdrop"}
assert(root.profileBtn.ddDisplayMode==style and root.charSelect.ddDisplayMode==style)
assert(root.settingsBtn.ddDisplayMode==nil)
for level, owner in ipairs({root.filterBtn,root.profileBtn,root.charSelect}) do
    local popup=AcquireMenu(level)
    local panel=popup.styles[style]
    assert(panel.parent==popup and panel.skin=="Panel" and panel.opts.inset and panel.mouse==false)
    assert(not panel:IsShown())
    SelectStyle(popup, owner)
    assert(panel:IsShown() and popup.activeStyle==panel)
    SelectStyle(popup, {ddDisplayMode=foreignModes[level]})
    assert(popup.activeStyle==popup.styles[fallbackStyles[level]] and not panel:IsShown())
end
local menuFrames,menuTextures=frames,textures
for _=1,20 do
    for _, owner in ipairs({root.filterBtn,root.profileBtn,root.charSelect}) do
        for level=1,3 do
            local popup=AcquireMenu(level)
            SelectStyle(popup, owner)
            assert(popup.activeStyle==popup.styles[style])
            SelectStyle(popup, {ddDisplayMode="backdrop"})
            assert(popup.activeStyle==popup.styles.backdrop and not popup.styles[style]:IsShown())
        end
    end
end
assert(existingMenu==nativeMenus[1] and frames==menuFrames and textures==menuTextures and styleRegistrations==1)
assert(root.searchBox.searchIcon:GetAlpha()==1 and root.searchBox.scripts.OnTextChanged()=="native-search")
assert(root.filterBtn.skin=="Button" and root.filterBtn.opts[1]=="Arrow" and root.filterBtn.scripts.OnClick()=="native-click")
assert(root.inset.scrollBar.skin=="ScrollBar")
assert(row.check.skin=="Checkbox" and row.check.opts.stockCheck and row.check.CheckedTexture.tint[2]==1)
assert(cat.skin=="Button" and not cat.toggleBtn.skin and cat.title.font=="EUI")
assert(row.loadButton.skin=="Button" and row.icon.path=="native-icon" and row.status.font=="EUI" and lockedRow.check.skin)
assert(root.currentCPU.bottomStr.font=="EUI" and slider.scripts.OnValueChanged==scaleChanged)
slider.scripts.OnValueChanged(slider, 50)
assert(root.config.scale==50 and slider.thumb.position==50)
slider.scripts.OnValueChanged(slider, 200)
assert(root.config.scale==200 and slider.thumb.position==200)
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
assert(#slider.regions==7 and slider.regions[5]==track and slider.regions[6]==edge and slider.regions[7]==grip)
assert(menuLookups==1 and styleRegistrations==1 and slider.scripts.OnValueChanged==scaleChanged)
assert(root.config.scale==200 and writes==warmWrites)
enabled=false; liveCalls=calls
module.refresh(); root:normalInit(addonRow(),addonNode); callbacks[1]()
assert(calls==liveCalls)
print(("BENCH Manargl %s: five-trial median for 1000 pooled row/category and CPU cycles %.3f -> %.3f ms; after first open and three popup depths +%d frames, +%d textures, +%d adapter hooks; warm 0 cosmetic calls/writes, pool reads or allocations")
    :format(source and "pinned-source" or "fixture",before,after,warmFrames,warmArt,warmHooks))
print("PASS: Manargl owned appearance, native state colours/actions, pool reuse, combat, theme deferral and launcher-only menu style and foreign popup reuse")
for _, key in ipairs(globals) do _G[key]=saved[key] end
end
