-- Phase 1 owns only its canvas. Simulate native events and slider writes,
-- including the OnValueChanged events that SetValue can fire during binding.
do
local saved = {}
for _,key in ipairs({"CreateFrame","Settings","C_AddOns","GetAddOnInfo","IsAddOnLoaded","LoadAddOn","InterfaceOptions_AddCategory",
    "InterfaceOptionsFrame_OpenToCategory","InCombatLockdown","EUIAddonSkinsDB","UIParent","SlashCmdList","EllesmereUI"}) do
    saved[#saved+1]={key,_G[key]}
end
local function Setup(modern, oldInfo, db)
    local h={frames={},categories={},counts={frames=0,art=0,info=0,writes=0},
        installed={Details=true,RXPGuides=true},loaded={Details=true,RXPGuides=true},disabled={},combat=false}
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
        function f:GetBottom() return self.bottom or 200 end
        function f:GetEffectiveScale() return self.scale or self.parent and self.parent:GetEffectiveScale() or 1 end
        function f:SetFrameStrata(value) self.strata=value end
        function f:SetClampedToScreen(value) self.clamped=value end
        function f:IsMouseOver() return self.mouseOver==true end
        function f:EnableKeyboard(value) self.keyboard=value end
        function f:SetPropagateKeyboardInput(value) self.propagate=value end
        function f:SetTexture(value) self.texture=value end
        function f:SetRotation(value) self.rotation=value end
        function f:SetVertexColor(...) self.vertex={...} end
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
        function f:GetValue() return self.value end
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
        function f:SetVerticalScroll(v)
            local changed=self:GetVerticalScroll()~=v
            self.scroll=v
            if changed and self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self,v) end
        end
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
            self.textures=self.textures or {}
            local texture=object("Texture",self)
            self.textures[#self.textures+1]=texture
            return texture
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
    local function Loaded(id) h.counts.info=h.counts.info+1; return h.loaded[id] end
    local function ForceLoad() error("opening settings force-loaded an addon") end
    C_AddOns=not oldInfo and {GetAddOnInfo=Info,IsAddOnLoaded=Loaded,LoadAddOn=ForceLoad} or nil
    GetAddOnInfo=oldInfo and Info or nil
    IsAddOnLoaded=oldInfo and Loaded or nil
    LoadAddOn=ForceLoad
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
    ns.IsEnabled=function(module) return not (EUIAddonSkinsDB and EUIAddonSkinsDB.disabled or module and module.disabled) end
    ns.TargetEnabled=function(entry) return not h.disabled[entry.targets[1]] end
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
    assert(#root.textures==1 and not root.textures[1].allPoints,"settings canvas covers the native background")
    for _, control in ipairs(check) do
        assert(not control.parent.textures,"setting row painted a card behind the text")
    end
    local sidebar=h:Find(function(f) return f.name=="EUIAddonSkinsSidebarScroll" end,true)[1]
    assert(not sidebar.textures and not sidebar.child.textures,"sidebar covers the native background")
    assert(Buttons("Details!")[1].fill:IsVisible() and Buttons("Details!")[1].fill.color[4]<0.4
        and not Buttons("RestedXP")[1].fill:IsVisible(),"sidebar selection is opaque or paints unselected rows")
    ns.SetDetailsSetting("meter",false) -- same entry point as native quick menu
    assert(not check[2].checked and calls==1,"quick menu and modular checkbox did not synchronize")
    check[2]:SetChecked(true);h:Press(check[2])
    assert(db.details.meter and calls==2 and db.details.backups.keep)
    local search=assert(Search())
    search:SetText("xP")
    assert(#Buttons("Details!")==0 and #Buttons("RestedXP")==1 and #Checks()==3,"search changed active detail")
    search.scripts.OnEnterPressed(search)
    assert(Buttons("RestedXP")[1].fill:IsVisible(),"sidebar selection highlight did not follow search")
    check=Checks()
    assert(#check==1 and not check[1].checked and db.settingsUI.lastAddonID=="RXPGuides")
    check[1]:SetChecked(true);h:Press(check[1])
    assert(db.rxp.arrow and arrowCalls==1 and db.restedXP.opacity==0)
    ns.SetRXPSetting("arrow",false)
    assert(not check[1].checked and arrowCalls==2)
    search:SetText("no such addon")
    assert(#Buttons("RestedXP")==0 and #Checks()==1,"empty filter disposed the selected controls")
    Choose("×")
    assert(search:GetText()=="" and #Buttons("Details!")==1,"clear search did not restore entries")
    h.combat=true;h:Event("PLAYER_REGEN_DISABLED")
    assert(not Checks()[1].enabled)
    check[1]:SetChecked(true);check[1].scripts.OnClick(check[1])
    assert(not db.rxp.arrow and arrowCalls==2,"combat wrote preferences")
    h.combat=false;h:Event("PLAYER_REGEN_ENABLED")
    assert(Checks()[1].enabled and not Checks()[1].checked)
    h.disabled.RXPGuides=true; ns.SettingsAvailabilityChanged("RXPGuides")
    assert(#Buttons("RestedXP")==0 and #Checks()==3,"disabled addon stayed visible or selection did not fall back")
    assert(db.settingsUI.lastAddonID=="RXPGuides","temporary fallback overwrote saved selection")
    h.disabled.RXPGuides=nil; h.loaded.RXPGuides=false
    ns.SettingsAvailabilityChanged("RXPGuides")
    assert(#Buttons("RestedXP")==0 and not ns.OpenAddonSettings("RXPGuides"),"load-on-demand addon appeared before loading")
    h.loaded.RXPGuides=true; ns.modules[2].active=false
    ns.SettingsAvailabilityChanged("RXPGuides")
    assert(#Buttons("RestedXP")==0,"registered provider without an active module appeared")
    ns.modules[2].active=true; ns.SettingsAvailabilityChanged("RXPGuides")
    assert(#Buttons("RestedXP")==1 and #Checks()==3,"late activation displaced valid selection or failed to list")
    Choose("RestedXP")
    assert(Checks()[1].enabled)

    root:SetSize(340,440)
    local list=h:Find(function(f)return f.name=="EUIAddonSkinsSidebarScroll" end,true)[1]
    local detail=h:Find(function(f)return f.name=="EUIAddonSkinsOptionsScroll" end,true)[1]
    assert(list.point[4]==detail.point[4] and -list.point[5]+list.height < -detail.point[5],
        "narrow settings columns overlap")
    root.width,root.height=700,510
    h:Event("UI_SCALE_CHANGED")
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
        h:Event("UI_SCALE_CHANGED")
        ns.SettingsPreferenceChanged("RXPGuides","arrow")
        ns.SettingsAvailabilityChanged("RXPGuides")
    end
    assert(next(root.events)==nil and h.counts.info==reads and h.counts.writes==writes,"closed panel did work")
    assert(not db.rxp.arrow and db.unrelated.kept)
    print(string.format("BENCH Settings canvas (%s addon API): %d login frames, %d first-show additions, %d frames/%d regions settled, 200 navigation/reopen cycles %.3f ms; zero new objects, closed reads or writes",
        oldInfo and "legacy" or "modern",startup,firstShow-startup,warmFrames,warmArt,elapsed))
    root:Show();assert(#Checks()==1,"last valid selection not retained")
    Choose("Legacy options")
    assert(h.opened.name=="EUI AddonSkins (Legacy)" and #h.categories==2,"legacy fallback was not available")
    SlashCmdList.EUIDETAILS();assert(h.opened==root and #Checks()==3 and #h.categories==2)
    h.installed.Details=false;h.installed.RXPGuides=false;ns.SettingsAvailabilityChanged()
    assert(#Checks()==0 and #Buttons("Details!")==0 and #Buttons("RestedXP")==0,"absent providers leaked into sidebar")

    -- Future renderer types are exercised by a synthetic provider only.
    local value,choice,actions,sets=75,"a",0,0
    h.installed.Fixture=true;h.installed.Empty=true
    h.loaded.Fixture=true;h.loaded.Empty=true
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
-- Phase 2 uses the real provider declarations with adapter-owned fixture handlers.
local appearanceDB = {rxp={arrow=false}, restedXP={style="forever", opacity=0}, kiwiFarm={useEUIFont=false}}
local app = Setup(true,false,appearanceDB)
local ns = app.ns
local writes = 0
EllesmereUI = {IS_FOREVER=false}
local rxp = ns.modules[2]
rxp.settingsAppearance = {
    get=function(key) return key=="style" and (appearanceDB.restedXP.style or "auto") or appearanceDB.restedXP.opacity end,
    set=function(key,value) appearanceDB.restedXP[key]=value; writes=writes+1; ns.SettingsPreferenceChanged("RXPGuides",key) end,
    effectiveStyle=function() return EllesmereUI.IS_FOREVER and appearanceDB.restedXP.style=="forever" and "EUI Forever" or "EUI Standard" end,
    reset=function() appearanceDB.restedXP={}; writes=writes+1 end,
}
ns.skinCatalogByID.KiwiFarm={targets={"KiwiFarm"}}
app.installed.KiwiFarm=true;app.loaded.KiwiFarm=true
local kiwiValues = {opacitySource="native", backgroundOpacity=60, backgroundStyle="soft", menuOpacity=95, accent=false,
    useEUIFont=appearanceDB.kiwiFarm.useEUIFont}
local kiwi = {id="KiwiFarm",active=true,settingsAppearance={
    get=function(key) return kiwiValues[key] end,
    set=function(key,value) kiwiValues[key]=value; writes=writes+1; ns.SettingsPreferenceChanged("KiwiFarm","backgroundOpacity") end,
    reset=function() end,
}}
table.insert(ns.modules,kiwi)
local function Controls(kind)
    return app:Find(function(f) return f.kind==kind end,true)
end
local function Click(label)
    local buttons=app:Find(function(f)
        return f.kind=="Button" and not f.choice and f.label and f.label.text==label
            and (label~="KiwiFarm" or f.id=="KiwiFarm")
    end,true)
    assert(#buttons==1,"missing or duplicate button: "..label)
    app:Press(buttons[1])
end
assert(ns.OpenAddonSettings("RXPGuides"))
assert(writes==0 and appearanceDB.restedXP.style=="forever" and Controls("Slider")[1]:GetValue()==0)
local function Popup()
    return app:Find(function(f) return f.events.GLOBAL_MOUSE_DOWN end,true)[1]
end
local function MenuItem(popup,label)
    for _,item in ipairs(popup.items) do
        if item:IsVisible() and item.label.text==label then return item end
    end
end
local function ChooseStyle(saved, choice)
    Click(saved)
    local popup=assert(Popup())
    app:Press(assert(MenuItem(popup,choice)))
    assert(not Popup() and not popup.row and next(popup.events)==nil,"selection retained popup state")
    for _, item in ipairs(popup.items) do assert(not item.choice and not item:IsVisible()) end
end
Click("EUI Forever")
local popup=assert(Popup())
assert(popup.keyboard and popup.propagate and popup.clamped)
assert(MenuItem(popup,"Automatic") and MenuItem(popup,"EUI Standard") and not MenuItem(popup,"EUI Forever"))
assert(not MenuItem(popup,"Automatic").mark:IsVisible() and not MenuItem(popup,"EUI Standard").mark:IsVisible())
assert(writes==0 and appearanceDB.restedXP.style=="forever", "opening changed the unsupported saved style")
popup.scripts.OnKeyDown(popup,"A")
assert(Popup()==popup and popup.propagate,"unrelated key swallowed")
popup.scripts.OnKeyDown(popup,"ESCAPE")
assert(not Popup() and not popup.propagate and writes==0,"Escape did not dismiss without saving")
Click("EUI Forever")
popup.mouseOver=true; app:Event("GLOBAL_MOUSE_DOWN","LeftButton")
assert(Popup()==popup,"inside click dismissed")
popup.mouseOver=false
popup.row.control.mouseOver=true; app:Event("GLOBAL_MOUSE_DOWN","LeftButton")
assert(Popup()==popup,"owner mouse down dismissed before click handler")
popup.row.control.mouseOver=false
app:Event("GLOBAL_MOUSE_DOWN","RightButton")
assert(not Popup() and writes==0,"outside click did not dismiss without saving")

ChooseStyle("EUI Forever","EUI Standard")
assert(appearanceDB.restedXP.style=="standard","dropdown did not allow direct selection")
Click("EUI Standard")
assert(MenuItem(popup,"EUI Standard").mark:IsVisible())
rxp.settingsAppearance.set("style","auto")
assert(MenuItem(popup,"Automatic").mark:IsVisible() and not MenuItem(popup,"EUI Standard").mark:IsVisible(),
    "native change failed to update the selection")
assert(popup.row.description.text=="Effective: EUI Standard")
app.combat=true; app:Event("PLAYER_REGEN_DISABLED")
assert(not Popup())
app.combat=false; app:Event("PLAYER_REGEN_ENABLED")
EllesmereUI.IS_FOREVER=true
ChooseStyle("Automatic","EUI Forever")
assert(appearanceDB.restedXP.style=="forever")
app.opened:SetSize(330,400); app.opened.scale=.8
Click("EUI Forever")
assert(popup.row.description.text=="Effective: EUI Forever" and MenuItem(popup,"EUI Forever").mark:IsVisible())
assert(popup:GetWidth()==popup.row.control:GetWidth() and popup:GetWidth()>=118)
local owner=popup.row.control
owner.bottom=1
Click("EUI Forever"); assert(not Popup(),"owner click did not toggle popup")
Click("EUI Forever"); assert(popup.point[1]=="BOTTOMRIGHT","scaled popup failed to open above the lower screen edge")
owner.bottom=nil
app:Event("UI_SCALE_CHANGED"); assert(not Popup(),"scale change kept stale popup anchors")
Click("EUI Forever")
local detailScroll=app:Find(function(f) return f.name=="EUIAddonSkinsOptionsScroll" end,true)[1]
detailScroll:SetVerticalScroll(1)
assert(not Popup(),"scroll kept detached popup")
Click("EUI Forever"); app.opened:Hide()
assert(not Popup() and next(popup.events)==nil,"closing canvas left an input listener")
app.opened:Show()
local warmFrames,warmArt,warmWrites=app.counts.frames,app.counts.art,writes
local warmStart=os.clock()
for _=1,200 do
    Click("EUI Forever")
    assert(Popup()==popup)
    app:Event("GLOBAL_MOUSE_DOWN","LeftButton")
end
assert(app.counts.frames==warmFrames and app.counts.art==warmArt and writes==warmWrites)
print(string.format("BENCH Skin Style dropdown: %d frames/%d regions settled, 200 open/dismiss cycles %.3f ms; zero new objects or preference writes",
    warmFrames,warmArt,(os.clock()-warmStart)*1000))
local slider = Controls("Slider")[1]
assert(not slider.parent.textures and #slider.textures==1 and slider.textures[1]:GetHeight()==3
    and slider:GetHeight()==18, "slider track changed its hitbox or painted a card")
for _,percent in ipairs({75,100,0}) do
    slider:SetValue(percent)
    assert(appearanceDB.restedXP.opacity==percent)
end
rxp.settingsAppearance.set("opacity",75)
assert(Controls("Slider")[1]:GetValue()==75,"native change failed to refresh panel")
Click("Reset"); assert(appearanceDB.rxp.arrow==false and not appearanceDB.restedXP.style)
Click("KiwiFarm")
assert(#Controls("Slider")==2 and not Controls("Slider")[1].enabled)
assert(#Controls("CheckButton")==2 and not Controls("CheckButton")[1].checked)
local source = app:Find(function(f)
    return f.kind=="Button" and f.label and f.label.text=="KiwiFarm" and f.id~="KiwiFarm"
end,true)[1]
app:Press(source)
assert(kiwiValues.opacitySource=="custom" and Controls("Slider")[1].enabled)
app.combat=true; app:Event("PLAYER_REGEN_DISABLED")
local before=writes
Controls("Slider")[1]:SetValue(25)
assert(writes==before)
app.combat=false; app:Event("PLAYER_REGEN_ENABLED")
-- Exercise all visible kinds repeatedly with both integrations installed.
app.opened:SetSize(395,400)
app:Event("UI_SCALE_CHANGED")
assert(Controls("Slider")[1]:GetValue()==60)
for _,label in ipairs({"RestedXP","Details!","KiwiFarm"}) do Click(label) end
local frames, art = app.counts.frames, app.counts.art
local started = os.clock()
for _=1,200 do
    Click("RestedXP"); Click("Details!"); Click("KiwiFarm")
    app.opened:Hide(); app.opened:Show()
end
assert(app.counts.frames==frames and app.counts.art==art and writes==before,"warm cycling allocated or wrote a preference")
print(string.format("BENCH Phase 2 appearance: %d frames/%d regions settled, 200 three-provider navigation/reopen cycles %.3f ms; zero new objects or preference writes",
    frames, art, (os.clock()-started)*1000))
-- The combined build registers Spy only when its adapter has activated.
ns.skinCatalogByID.Spy={targets={"Spy"}}
app.installed.Spy=true
local spyValues = {style="auto", opacity=75}
local spy = {id="Spy",active=true,settingsAppearance={
    get=function(key) return spyValues[key] end,
    set=function(key,value) spyValues[key]=value; ns.SettingsPreferenceChanged("Spy",key) end,
    effectiveStyle=function() return spyValues.style=="forever" and EllesmereUI.IS_FOREVER and "EUI Forever" or "EUI Standard" end,
    supportsForever=function() return EllesmereUI.IS_FOREVER end,
    reset=function() spyValues.style="auto"; spyValues.opacity=75; ns.SettingsPreferenceChanged("Spy") end,
}}
table.insert(ns.modules,spy)
ns.SettingsAvailabilityChanged("Spy")
assert(not ns.OpenAddonSettings("Spy"), "installed load-on-demand Spy opened before load")
app.loaded.Spy=true
ns.SettingsAvailabilityChanged("Spy")
Click("Spy")
assert(#Controls("Slider")==1 and Controls("Slider")[1]:GetValue()==75 and #Controls("CheckButton")==0)
EllesmereUI.IS_FOREVER=false
Click("Automatic")
assert(Popup()==popup and not MenuItem(popup,"EUI Forever"), "Spy offered unsupported Forever")
app:Press(assert(MenuItem(popup,"EUI Standard")))
assert(spyValues.style=="standard")
spy.settingsAppearance.set("style","forever")
Click("EUI Forever")
assert(not MenuItem(popup,"EUI Forever") and spyValues.style=="forever", "saved native preference was overwritten")
app:Event("GLOBAL_MOUSE_DOWN","LeftButton")
EllesmereUI.IS_FOREVER=true
ChooseStyle("EUI Forever","Automatic")
ChooseStyle("Automatic","EUI Forever")
Controls("Slider")[1]:SetValue(0); assert(spyValues.opacity==0)
spy.settingsAppearance.set("opacity",100)
assert(Controls("Slider")[1]:GetValue()==100)
Click("Reset"); assert(spyValues.style=="auto" and Controls("Slider")[1]:GetValue()==75)
assert(appearanceDB.rxp.arrow==false and appearanceDB.kiwiFarm.useEUIFont==false)

local combinedFrames, combinedArt = app.counts.frames, app.counts.art
local combinedWrites, combinedStart = writes, os.clock()
for _=1,200 do
    Click("RestedXP"); Click("Spy")
    app.opened:Hide(); app.opened:Show()
end
local combinedElapsed = (os.clock()-combinedStart)*1000
assert(app.counts.frames==combinedFrames and app.counts.art==combinedArt and writes==combinedWrites,
    "Spy/RestedXP navigation allocated or saved preferences")
app.opened:Hide()
local closedReads, closedWrites = app.counts.info, app.counts.writes
for _=1,1000 do
    ns.SettingsPreferenceChanged("Spy","style")
    ns.SettingsPreferenceChanged("RXPGuides","opacity")
    ns.SettingsAvailabilityChanged("Spy")
end
assert(next(app.opened.events)==nil and app.counts.info==closedReads and app.counts.writes==closedWrites,
    "closed combined panel processed notifications")
print(string.format("BENCH Combined Spy/RestedXP: %d frames/%d regions settled, 200 navigation/reopen cycles %.3f ms; zero new objects or preference writes, zero closed reads or writes",
    combinedFrames, combinedArt, combinedElapsed))

local legacy=Setup(false,true,nil)
SlashCmdList.EUIDETAILS()
assert(#legacy.categories==1 and legacy.opened.name=="EUI AddonSkins" and legacy.opened.menus,
    "legacy client lost original panel")
assert(not EUIAddonSkinsDB,"legacy category construction materialized preferences")
for _,entry in ipairs(saved) do _G[entry[1]]=entry[2] end
print("PASS: modular settings registry, lazy canvas, navigation, shared setters, renderer types, and fallback")
end
