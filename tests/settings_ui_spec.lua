-- Phase 1 owns only its canvas. Simulate native events and slider writes,
-- including the OnValueChanged events that SetValue can fire during binding.
do
local saved = {}
for _,key in ipairs({"CreateFrame","Settings","C_AddOns","GetAddOnInfo","InterfaceOptions_AddCategory",
    "InterfaceOptionsFrame_OpenToCategory","InCombatLockdown","EUIAddonSkinsDB","UIParent","SlashCmdList"}) do
    saved[#saved+1]={key,_G[key]}
end
local function Setup(modern, oldInfo, db)
    local h={frames={},categories={},counts={frames=0,art=0,info=0,writes=0},
        installed={Details=true,RXPGuides=true},targetsEnabled=true,combat=false}
    EUIAddonSkinsDB=db;SlashCmdList={}
    local function object(kind,parent)
        local f={kind=kind,parent=parent,shown=true,scripts={},events={},enabled=true,text="",width=640,height=440}
        function f:SetPoint(...) self.point={...};h.counts.writes=h.counts.writes+1 end
        function f:ClearAllPoints() self.point=nil end
        function f:SetAllPoints(target) self.allPoints=target end
        function f:SetSize(w,ht)
            local changed=self.width~=w or self.height~=ht
            self.width,self.height=w,ht
            if changed and self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,w,ht) end
        end
        function f:SetWidth(w) self.width=w end
        function f:SetHeight(ht) self.height=ht end
        function f:GetWidth() return self.width end
        function f:GetHeight() return self.height end
        function f:GetStringHeight() return math.ceil(#self.text/math.max(1,math.floor(self.width/6)))*12 end
        function f:SetJustifyH() end
        function f:SetWordWrap() end
        function f:SetColorTexture(...) self.color={...};h.counts.writes=h.counts.writes+1 end
        function f:SetTextColor(...) self.color={...};h.counts.writes=h.counts.writes+1 end
        function f:SetText(value)
            self.text=value;h.counts.writes=h.counts.writes+1
            if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,true) end
        end
        function f:GetText() return self.text end
        function f:SetEnabled(value) self.enabled=value end
        function f:Enable() self.enabled=true end
        function f:Disable() self.enabled=false end
        function f:SetChecked(value) self.checked=value;h.counts.writes=h.counts.writes+1 end
        function f:GetChecked() return self.checked end
        function f:SetValue(value)
            self.value=value;h.counts.writes=h.counts.writes+1
            if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
        end
        function f:SetMinMaxValues(a,b) self.min,self.max=a,b end
        function f:SetValueStep(value) self.step=value end
        function f:SetThumbTexture() end
        function f:SetOrientation() end
        function f:SetObeyStepOnDrag() end
        function f:EnableMouse() end
        function f:SetAutoFocus(value) self.autoFocus=value end
        function f:ClearFocus() self.focus=false end
        function f:SetHighlightTexture(texture) self.highlight=texture end
        function f:SetScrollChild(child) self.child=child end
        function f:SetVerticalScroll(v) self.scroll=v end
        function f:GetVerticalScroll() return self.scroll or 0 end
        function f:GetVerticalScrollRange() return math.max(0,self.child.height-self.height) end
        function f:RegisterEvent(event) self.events[event]=true end
        function f:UnregisterEvent(event) self.events[event]=nil end
        function f:UnregisterAllEvents() self.events={} end
        function f:SetScript(event, fn) self.scripts[event]=fn end
        function f:HookScript(event,fn)
            local old=self.scripts[event]
            self.scripts[event]=function(...) if old then old(...) end;fn(...) end
        end
        function f:Show()
            if self.shown then return end
            self.shown=true
            if self.scripts.OnShow then self.scripts.OnShow(self) end
        end
        function f:Hide()
            if not self.shown then return end
            self.shown=false
            if self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        function f:SetShown(v) if v then self:Show() else self:Hide() end end
        function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function f:CreateTexture()
            h.counts.art=h.counts.art+1
            return object("Texture",self)
        end
        function f:CreateFontString()
            h.counts.art=h.counts.art+1
            return object("FontString",self)
        end
        return f
    end
    UIParent=object("Root")
    CreateFrame=function(kind,name,parent)
        local f=object(kind,parent)
        f.name=name
        if kind=="Slider" then f.SetEnabled=nil end -- also exercise legacy slider Enable/Disable
        h.frames[#h.frames+1]=f;h.counts.frames=h.counts.frames+1
        return f
    end
    local function Info(id) h.counts.info=h.counts.info+1; if h.installed[id] then return id end end
    C_AddOns=not oldInfo and {GetAddOnInfo=Info} or nil
    GetAddOnInfo=oldInfo and Info or nil
    InCombatLockdown=function() return h.combat end
    local function Open(f)
        if h.opened and h.opened~=f then h.opened:Hide() end
        h.opened=f
        f:Show()
    end
    local function Register(f)
        f:Hide()
        h.categories[#h.categories+1]=f
        local id=#h.categories
        return {GetID=function()return id end}
    end
    Settings=modern and {RegisterCanvasLayoutCategory=Register,RegisterAddOnCategory=function()end,
        OpenToCategory=function(id) Open(h.categories[id]) end} or nil
    InterfaceOptions_AddCategory=Register
    InterfaceOptionsFrame_OpenToCategory=Open
    local ns={skinCatalogByID={
        Details={targets={"Details"}},RXPGuides={targets={"RXPGuides"}},
        Fixture={targets={"Fixture"}},Empty={targets={"Empty"}},
    },modules={{id="Details",active=true},{id="RXPGuides",active=true},{id="Fixture",active=true}}}
    ns.IsEnabled=function() return not (EUIAddonSkinsDB and EUIAddonSkinsDB.disabled) end
    ns.TargetEnabled=function() return h.targetsEnabled end
    assert(loadfile("EUIAddonSkins/DetailsSettings.lua"))("EUIAddonSkins",ns)
    assert(loadfile("EUIAddonSkins/SettingsUI.lua"))("EUIAddonSkins",ns)
    function h:Event(event, ...)
        for _,f in ipairs(self.frames) do
            if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f,event,...) end
        end
    end
    function h:Find(predicate,visible)
        local result={}
        for _,f in ipairs(self.frames) do
            if (not visible or f:IsVisible()) and predicate(f) then result[#result+1]=f end
        end
        return result
    end
    function h:Press(f)
        assert(f and f.enabled and f:IsVisible(), "clicked invisible or disabled frame")
        f.scripts.OnClick(f)
    end
    h.ns=ns
    h:Event("PLAYER_LOGIN")
    return h
end

for _,oldInfo in ipairs({false,true}) do
    local db={details={menus=false,meter=true,tiny=false,backups={keep=true}},
        rxp={arrow=false},restedXP={opacity=0},unrelated={kept=true}}
    local h=Setup(true,oldInfo,db)
    local ns=h.ns
    local root=h.categories[1]
    assert(#h.categories==1 and h.counts.frames==3 and h.counts.art==0 and h.counts.info==0,
        "canvas allocated controls or queried targets at login")
    local startup=h.counts.frames
    local calls=0;ns.DetailsSettingsChanged=function() calls=calls+1 end
    local arrowCalls=0;ns.RXPSettingsChanged=function() arrowCalls=arrowCalls+1 end
    SlashCmdList.EUIDETAILS()
    assert(h.opened==root and #h.categories==1,"Details shortcut did not open modular canvas")
    local function Checks() return h:Find(function(f)return f.kind=="CheckButton" end,true) end
    local function Buttons(label)
        return h:Find(function(f)return f.kind=="Button" and f.label and f.label.text==label end,true)
    end
    local function Search()
        return h:Find(function(f)return f.name=="EUIAddonSkinsSearch" end,true)[1]
    end
    local function Choose(label) h:Press(Buttons(label)[1]) end
    local check=Checks()
    assert(#check==3 and not check[1].checked and check[2].checked and not check[3].checked)
    assert(calls==0 and arrowCalls==0 and not db.settingsUI and db.restedXP.opacity==0,"opening wrote preferences")
    local firstShow=h.counts.frames
    ns.SetDetailsSetting("meter",false) -- same entry point as native quick menu
    assert(not check[2].checked and calls==1,"quick menu and modular checkbox did not synchronize")
    check[2]:SetChecked(true);h:Press(check[2])
    assert(db.details.meter and calls==2 and db.details.backups.keep)
    local search=assert(Search())
    search:SetText("xP")
    assert(#Buttons("Details!")==0 and #Buttons("RestedXP")==1 and #Checks()==3,"search changed active detail")
    search.scripts.OnEnterPressed(search)
    check=Checks()
    assert(#check==1 and not check[1].checked and db.settingsUI.lastAddonID=="RXPGuides")
    check[1]:SetChecked(true);h:Press(check[1])
    assert(db.rxp.arrow and arrowCalls==1 and db.restedXP.opacity==0)
    ns.SetRXPSetting("arrow",false)
    assert(not check[1].checked and arrowCalls==2)
    search:SetText("no such addon")
    assert(#Buttons("RestedXP")==0 and #Checks()==1,"empty filter disposed the selected controls")
    search:SetText("")
    h.combat=true;h:Event("PLAYER_REGEN_DISABLED")
    assert(not Checks()[1].enabled)
    check[1]:SetChecked(true);check[1].scripts.OnClick(check[1])
    assert(not db.rxp.arrow and arrowCalls==2,"combat wrote preferences")
    h.combat=false;h:Event("PLAYER_REGEN_ENABLED")
    assert(Checks()[1].enabled and not Checks()[1].checked)
    h.targetsEnabled=false;h:Event("ADDON_LOADED","RXPGuides")
    assert(#Buttons("RestedXP")==1 and not Checks()[1].enabled,"installed inactive addon disappeared")
    h.targetsEnabled=true;h:Event("ADDON_LOADED","RXPGuides")
    assert(Checks()[1].enabled)

    root:SetSize(340,440)
    local list=h:Find(function(f)return f.name=="EUIAddonSkinsSidebarScroll" end,true)[1]
    local detail=h:Find(function(f)return f.name=="EUIAddonSkinsOptionsScroll" end,true)[1]
    assert(list.point[4]==detail.point[4] and -list.point[5]+list.height < -detail.point[5],
        "narrow settings columns overlap")
    root:SetSize(700,510)
    assert(detail.point[4]>list.point[4]+list.width,"wide settings columns overlap")
    local warmFrames,warmArt=h.counts.frames,h.counts.art
    local started=os.clock()
    for _=1,200 do
        Choose("Details!");Choose("RestedXP")
        root:Hide();root:Show()
        assert(#Checks()==1)
    end
    local elapsed=(os.clock()-started)*1000
    assert(h.counts.frames==warmFrames and h.counts.art==warmArt,"navigation grew the widget pool")
    root:Hide()
    local reads,writes=h.counts.info,h.counts.writes
    for _=1,1000 do
        h:Event("ADDON_LOADED","RXPGuides")
        ns.SettingsPreferenceChanged("RXPGuides","arrow")
    end
    assert(next(root.events)==nil and h.counts.info==reads and h.counts.writes==writes,"closed panel did work")
    assert(not db.rxp.arrow and db.unrelated.kept)
    print(string.format("BENCH Settings canvas (%s addon API): %d login frames, %d first-show additions, %d frames/%d regions settled, 200 navigation/reopen cycles %.3f ms; zero new objects, closed reads or writes",
        oldInfo and "legacy" or "modern",startup,firstShow-startup,warmFrames,warmArt,elapsed))
    root:Show();assert(#Checks()==1,"last valid selection not retained")
    Choose("Legacy options")
    assert(h.opened.name=="EUI AddonSkins (Legacy)" and #h.categories==2,"legacy fallback was not available")
    SlashCmdList.EUIDETAILS();assert(h.opened==root and #Checks()==3 and #h.categories==2)
    h.installed.Details=false;h.installed.RXPGuides=false;h:Event("ADDON_LOADED","Details")
    assert(#Checks()==0 and #Buttons("Details!")==0 and #Buttons("RestedXP")==0,"absent providers leaked into sidebar")

    -- Future renderer types are exercised by a synthetic provider only.
    local value,choice,actions,sets=75,"a",0,0
    h.installed.Fixture=true;h.installed.Empty=true
    ns.RegisterSettingsProvider("Empty",{label="Empty",options={}})
    assert(#Buttons("Empty")==0,"empty provider appeared")
    ns.RegisterSettingsProvider("Fixture",{label="Fixture",options={
        {kind="slider",key="value",label="Opacity",min=0,max=100,step=1,get=function()return value end,
            set=function(v)value=v;sets=sets+1;ns.SettingsPreferenceChanged("Fixture","value")end},
        {kind="choice",key="choice",label="Choice",values={{value="a",label="Alpha"},{value="b",label="Beta"}},
            get=function()return choice end,set=function(v)choice=v;sets=sets+1;ns.SettingsPreferenceChanged("Fixture","choice")end},
    },reset={kind="action",label="Reset fixture",run=function()actions=actions+1;value=75 end}})
    local slider=h:Find(function(f)return f.kind=="Slider" end,true)[1]
    assert(slider.value==75 and sets==0,"slider binding fired a setter")
    slider:SetValue(0);assert(value==0 and sets==1 and slider.value==0)
    Choose("Alpha");assert(choice=="b" and sets==2 and #Buttons("Beta")==1)
    Choose("Reset fixture");assert(actions==1 and value==75 and slider.value==75 and sets==2)
    root:Hide();slider:SetValue(10)
    assert(value==75 and sets==2,"stale hidden binding saved a value")
    local loaded=Setup(true,oldInfo,db)
    loaded.ns.OpenAddonSettings()
    assert(#loaded:Find(function(f)return f.kind=="CheckButton" end,true)==1,
        "saved last selection did not survive a fresh session")
end
local legacy=Setup(false,true,nil)
SlashCmdList.EUIDETAILS()
assert(#legacy.categories==1 and legacy.opened.name=="EUI AddonSkins" and legacy.opened.menus,
    "legacy client lost original panel")
assert(not EUIAddonSkinsDB,"legacy category construction materialized preferences")
for _,entry in ipairs(saved) do _G[entry[1]]=entry[2] end
print("PASS: modular settings registry, lazy canvas, navigation, shared setters, renderer types, and fallback")
end
