-- World Quest Tab pooled UI, native EUI cooperation and bounded refreshes.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'WorldQuestTab'); factory = fn end
ns.RegisterModule = function(id, _, available, install) module = {id=id, available=available, install=install} end
geterrorhandler = function() return function(e) errors[#errors+1] = e end end
InCombatLockdown = function() return combat end
C_Timer = {After = function(_, fn) timers[#timers+1] = fn end}
hooksecurefunc = function(owner, key, callback)
    hookCount = hookCount + 1
    local original = owner[key]
    owner[key] = function(...)
        local values = table.pack(original(...)); callback(...); return table.unpack(values,1,values.n)
    end
end
local function Flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 10, 'refresh loop')
    end
    assert(#errors == 0, table.concat(errors, '\n'))
end
local function Object(kind, parent)
    allocated = allocated + 1
    local f = {kind=kind or 'Frame', parent=parent, regions={}, children={}, scripts={}, shown=true, alpha=1,
        path='Native', size=13, flags='', color={0.2,0.8,0.1,1}, width=16, height=20}
    function f:GetObjectType() return self.kind end
    function f:IsForbidden() return false end
    function f:IsProtected() return self.protected end
    function f:GetChildren() childReads=childReads+1; self.walks=(self.walks or 0)+1; return table.unpack(self.children) end
    function f:GetNumChildren() return #self.children end
    function f:GetNumRegions() return #self.regions end
    function f:GetName() return self.name end
    function f:GetNormalTexture() return self.normal end
    function f:GetPushedTexture() return self.pushed end
    function f:GetDisabledTexture() return self.disabled end
    function f:SetNormalTexture(value) self.normal=self.normal or self:CreateTexture(nil,'ARTWORK'); self.normal:SetTexture(value) end
    function f:SetPushedTexture(value) self.pushed=self.pushed or self:CreateTexture(nil,'ARTWORK'); self.pushed:SetTexture(value) end
    function f:SetChecked(value) self.checked=value end
    function f:GetChecked() return self.checked end
    function f:HighlightText() self.selections=(self.selections or 0)+1 end
    function f:GetParent() parentReads=parentReads+1; return self.parent end
    function f:GetBackdrop() return self.backdrop end
    function f:LockHighlight() self.locked=true end
    function f:UnlockHighlight() self.locked=false end
    function f:IsHighlightLocked() return self.locked == true end
    function f:SetHighlightTexture(v)
        if type(v)=='table' then self.highlight=v
        elseif not self.highlight then self.highlight=self:CreateTexture(nil,'HIGHLIGHT') end
        self.highlight.texture=v
    end
    function f:GetRegions() regionReads=regionReads+1; return table.unpack(self.regions) end
    function f:GetFont() return self.path,self.size,self.flags end
    function f:SetFont(path,size,flags) self.path,self.size,self.flags=path,size,flags end
    function f:GetText() return self.text end
    function f:SetFontObject() self.path='Native'; self.size=15; self.flags='' end
    function f:GetTextColor() return table.unpack(self.color) end
    function f:SetTextColor(r,g,b,a) self.color[1],self.color[2],self.color[3],self.color[4]=r,g,b,a end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(v) self.alpha=v end
    function f:SetColorTexture(r,g,b,a)
        colourWrites=colourWrites+1; self.color[1],self.color[2],self.color[3],self.color[4]=r,g,b,a
    end
    function f:SetVertexColor(r,g,b,a)
        self.vertex=self.vertex or {}; self.vertex[1],self.vertex[2],self.vertex[3],self.vertex[4]=r,g,b,a
    end
    function f:SetTexture(v) self.texture=v end
    function f:SetRotation(v) self.rotation=v end
    function f:SetAtlas(v) self.atlas=v end
    function f:GetElementData() return self.elementData end
    if kind=='Texture' then function f:GetTexture() return self.texture end end
    function f:SetTexCoord(...) self.coords={...} end
    function f:SetText(v) self.text=v end
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.point=nil end
    function f:SetAllPoints(p) self.anchor=p end
    function f:SetFrameLevel(v) self.level=v end
    function f:GetFrameLevel() return self.level or 4 end
    function f:EnableMouse(v) self.mouse=v end
    function f:SetWidth(v) self.width=v end
    function f:SetHeight(v) self.height=v end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:SetSize(w,h) self.width,self.height=w,h end
    function f:GetDrawLayer() return self.layer end
    function f:IsShown() return self.shown end
    function f:Show() self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end; for _,fn in ipairs(self.postScripts and self.postScripts.OnShow or {}) do fn(self) end end
    function f:Hide() self.shown=false end
    function f:IsEnabled() return self.enabled ~= false end
    function f:GetFontString() return self.Text end
    function f:GetHighlightTexture() return self.highlight end
    function f:GetThumbTexture() return self.thumb end
    function f:GetOrientation() return self.orientation or 'VERTICAL' end
    function f:GetCheckedTexture() return self.checkedArt end
    function f:GetDisabledCheckedTexture() return self.disabledArt end
    function f:Enable() self.enabled=true end
    function f:Disable() self.enabled=false end
    function f:RegisterEvent(e) self.events=self.events or {}; self.events[e]=true end
    function f:SetScript(k, fn) self.scripts[k]=fn end
    function f:HookScript(k, fn)
        self.postScripts=self.postScripts or {}; self.postScripts[k]=self.postScripts[k] or {}
        table.insert(self.postScripts[k],fn)
    end
    function f:CreateTexture(_,layer)
        local t=Object('Texture'); t.layer=layer; self.regions[#self.regions+1]=t; return t
    end
    function f:CreateFontString()
        local t=Object('FontString'); t.parent=self; self.regions[#self.regions+1]=t; return t
    end
    function f:RegisterObject(o) self.Objects=self.Objects or {}; self.Objects[#self.Objects+1]=o end
    function f:SetBackdrop(v) self.backdrop=v end
    if parent then parent.children[#parent.children+1]=f end
    return f
end
CreateFrame = function(kind,name,parent) local f=Object(kind,parent); f.name=name; if name then _G[name]=f end; events[#events+1]=f; return f end
local function Text(parent)
    local f=Object('FontString'); f.parent=parent; parent.regions[#parent.regions+1]=f; return f
end
local S = {GetFont=function() return fontFace,'' end, GetAccentColor=function() return accent,0.6,0.8 end,
    GetPanelColor=function() return 0.06,0.06,0.07,0.95 end, OnLooksChanged=function(fn) looks[#looks+1]=fn end}
S.Font=function(f,r,g,b) assert(not combat); fontWrites=fontWrites+1; f:SetFont(fontFace, f.size, ''); if r then f:SetTextColor(r,g,b,1) end end
S.Panel=function(f) if not f.panel then for _,r in ipairs(f.regions)do if r.kind=='Texture'then r:SetAlpha(0)end end; f.panel=true; f:CreateTexture(nil,'BACKGROUND') end end
S.Inset=function(f) f.inset=true end
S.FadeNineSlice=function(f) f.faded=true end
S.Tab=function(f)
    f.tab=true
    if not f.tabFill then
        f.tabFill=f:CreateTexture(nil,'BACKGROUND')
        f.tabText=f:CreateFontString(); f.tabText:SetTextColor(1,1,0,1)
    end
end
S.SetTabSelection=function(f,v) f.selected=v end
S.ScrollBar=function(f) f.scroll=true end
S.CloseButton=function(f)
    f.close=true
    if not f.closeGlyph then f.closeGlyph=f:CreateTexture(nil,'OVERLAY') end
end
S.Checkbox=function(f)
    checkboxPaints=checkboxPaints+1
    if f.check then return end
    f.check=true; f.checkFill=f:CreateTexture(nil,'BACKGROUND'); f.checkHover=f:CreateTexture(nil,'HIGHLIGHT')
    f.checkBorder=Object('Frame',f)
end
S.Button=function(f)
    f.button=true
    if not f.buttonBorder then
        f.buttonBorder=Object('Frame',f)
        for i=1,4 do local edge=f.buttonBorder:CreateTexture(nil,'BORDER'); edge.width=1; edge.height=20 end
    end
end
S.EditBox=function(f) f.input=true end
S.Dropdown=function(f) f.dropdown=true end
S.StateButtonLabel=function(f) f.stateLabel=true end
S.PageButton=function(f,glyph) f.glyph=glyph end
S.SquareIcon=function(t) t.square=true; t:SetTexCoord(.08,.92,.08,.92) end

S.Shell=function(f,options)
    f.shell=options
    for _,region in ipairs(f.regions) do if region.kind=='Texture' then region:SetAlpha(0) end end
end

ns.BindPopupOwner=function(_,_,owner) owner.menuBound=true end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
assert(loadfile('EUIAddonSkins/Skins/WorldQuestTab.lua'))('EUIAddonSkins',ns)
assert(factory and not module);local before=allocated;factory();assert(not module.available() and allocated==before)
UIParent=Object('Frame')
local enumReads,registrations,nativeClicks=0,0,0
ScrollBoxListMixin={Event={OnInitializedFrame='Initialized'}}
local function ScrollBox(parent)
    local box=Object('Frame',parent);box.active={};box.callbacks={}
    function box:RegisterCallback(event,fn,owner)
        registrations=registrations+1;self.callbacks[event]=self.callbacks[event] or {};table.insert(self.callbacks[event],{fn=fn,owner=owner})
    end
    function box:Emit(frame,data)for _,entry in ipairs(self.callbacks.Initialized or {})do entry.fn(entry.owner,frame,data)end end
    function box:EnumerateFrames() enumReads=enumReads+1;return ipairs(self.active) end
    return box
end
local function Texture(parent,key)
    local t=parent:CreateTexture(nil,'ARTWORK');t:SetTexture('native-'..key);parent[key]=t;return t
end
local function Button(parent,key)
    local f=Object('Button',parent);parent[key]=f;f.Text=Text(f)
    f.scripts.OnClick=function()nativeClicks=nativeClicks+1;return 'native-click' end
    return f
end
local function Highlight(parent,key)
    local f=Object('Frame',parent);parent[key]=f
    for _,name in ipairs({'Left','Center','Right'})do Texture(f,name)end
    return f
end
local function Quest(parent)
    local f=Object('Button',parent)
    f.CenterContent=Object('Frame',f);f.CenterContent.Title=Text(f.CenterContent)
    f.CenterContent.Title.text='|cffff0000Invalid quest|r';f.CenterContent.Title.color={.8,.6,.2,1}
    local bottom=Object('Frame',f.CenterContent);f.CenterContent.BottomRow=bottom
    bottom.Time=Text(bottom);bottom.Time.color={1,0,0,1};bottom.Time.text='2m';bottom.Extra=Text(bottom);bottom.ZoneSeparator=Text(bottom)
    f.RightContent=Object('Frame',f);f.RightContent.Rewards=Object('Frame',f.RightContent);Texture(f.RightContent.Rewards,'Icon')
    Texture(f,'QualityBg');Texture(f,'FavoriteBg');Highlight(f,'Highlight');Highlight(f,'TrackedBorder')
    f.TrackedBorder.alpha=.9;f.scripts.OnClick=function()return 'native-quest',123 end
    f.timer={remaining=123};f.width=300;f.height=44
    return f
end
local function Setting(parent,template)
    local f=Object('Frame',parent);f.elementData={template=template};f.Label=Text(f);f.Label.text='Native label';f.BgHighlight=Texture(f,'BgHighlight')
    function f:IsDisabled()return self.disabled==true end
    function f:UpdateState() self.Label:SetFontObject('GameFontNormal');return 'native-state' end
    return f
end
WQT_ListContainer=Object('Frame',UIParent);Texture(WQT_ListContainer,'Background');WQT_ListContainer.BorderFrame=Object('Frame',WQT_ListContainer)
local top=Object('Frame',WQT_ListContainer);WQT_ListContainer.TopBar=top
Button(top,'SortDropdown');Button(top,'FilterDropdown');Button(top,'SearchToggle');Texture(top.SearchToggle,'Icon')
top.SearchBox=Object('EditBox',top);top.SearchBox.text='a native query';top.SearchBox.Instructions=Text(top.SearchBox)
Button(WQT_ListContainer,'SettingsButton');Texture(WQT_ListContainer.SettingsButton,'Icon')
WQT_ListContainer.ScrollBar=Object('Frame',WQT_ListContainer);Button(WQT_ListContainer.ScrollBar,'Back');Button(WQT_ListContainer.ScrollBar,'Forward')
WQT_ListContainer.BorderContainer=Object('Frame',WQT_ListContainer)
local questBox=ScrollBox(WQT_ListContainer.BorderContainer);WQT_ListContainer.BorderContainer.QuestScrollBox=questBox
local quest=Quest(questBox);questBox.active={quest}
WQT_SettingsFrame=Object('Frame',UIParent);Texture(WQT_SettingsFrame,'Background');WQT_SettingsFrame.BorderFrame=Object('Frame',WQT_SettingsFrame)
WQT_SettingsFrame.ScrollBar=Object('Frame',WQT_SettingsFrame);WQT_SettingsFrame.TitleText=Text(WQT_SettingsFrame);Button(WQT_SettingsFrame,'CloseButton')
local settingBox=ScrollBox(WQT_SettingsFrame);WQT_SettingsFrame.ScrollBox=settingBox
local check=Setting(settingBox,'WQT_SettingCheckboxTemplate');check.CheckBox=Object('CheckButton',check)
check.CheckBox.mouse=false;check.CheckBox.checked=true;check.CheckBox.checkedArt=Texture(check.CheckBox,'checkedArt');check.CheckBox.disabledArt=Texture(check.CheckBox,'disabledArt')
check.scripts.OnClick=function()check.CheckBox.checked=not check.CheckBox.checked;return 'native-check' end
local slider=Setting(settingBox,'WQT_SettingSliderTemplate');slider.TextBox=Object('EditBox',slider);slider.TextBox.text='0.75'
slider.SliderWithSteppers=Object('Frame',slider);slider.SliderWithSteppers.Slider=Object('Slider',slider.SliderWithSteppers)
slider.SliderWithSteppers.Slider.orientation='HORIZONTAL';slider.SliderWithSteppers.Slider.thumb=Texture(slider.SliderWithSteppers.Slider,'thumb')
Button(slider.SliderWithSteppers,'Back');Button(slider.SliderWithSteppers,'Forward')
slider.SliderWithSteppers.Slider.value=.75;slider.SliderWithSteppers.Slider.minimum=0;slider.SliderWithSteppers.Slider.maximum=1
slider.SliderWithSteppers.Slider.scripts.OnValueChanged=function(_,v)slider.SliderWithSteppers.Slider.value=v;return 'native-slider' end
local dropdown=Setting(settingBox,'WQT_SettingDropDownTemplate');Button(dropdown,'Dropdown')
local category=Setting(settingBox,'WQT_SettingCategoryTemplate');category.isExpanded=true
for _,key in ipairs({'BGLeft','BGMiddle','BGRight','HighlightLeft','HighlightMiddle','HighlightRight'})do Texture(category,key)end
category.scripts.OnClick=function() category.isExpanded=not category.isExpanded;category:UpdateState();return 'native-category' end
local confirm=Setting(settingBox,'WQT_SettingConfirmButtonTemplate')
for _,key in ipairs({'Button','ButtonConfirm','ButtonDecline'})do Button(confirm,key)end
local picker=Setting(settingBox,'WQT_SettingColorTemplate');Button(picker,'Picker');Texture(picker.Picker,'Color');Button(picker,'ResetButton');Texture(picker.ResetButton,'Icon')
local preview=Setting(settingBox,'WQT_SettingsQuestListPreviewTemplate');Texture(preview,'Background');preview.Preview=Quest(preview)
settingBox.active={check,slider,dropdown,category,confirm,picker,preview}
WQT_QuestMapTab=Object('Frame',UIParent);Texture(WQT_QuestMapTab,'Icon');Texture(WQT_QuestMapTab,'IconOverlay');WQT_QuestMapTab.height=66
WQT_FlightMapContainer=Object('Frame',UIParent);WQT_WorldMapContainer=Object('Frame',UIParent)
WQT_FlightMapContainerButton=Object('Button',UIParent);Texture(WQT_FlightMapContainerButton,'Icon');Texture(WQT_FlightMapContainerButton,'Arrow')
WQT_GameTooltip=Object('GameTooltip',UIParent);local tipText=Text(WQT_GameTooltip);tipText.text='|cff00ff00Native reward|r'
local mapPin=Object('Button',UIParent);Texture(mapPin,'Icon')
WQT_ShoppingTooltip1=Object('GameTooltip',UIParent);WQT_ShoppingTooltip2=Object('GameTooltip',UIParent)
local compareText=Text(WQT_ShoppingTooltip1);compareText.text='Native comparison';Texture(WQT_ShoppingTooltip1,'Icon')
-- Native EUI skin can finish in the same dispatch cycle. Our queued setup runs
-- after it; it must not shrink tabs twice or replace native callbacks/settings.
module.install(S,module);assert(WQT_ListContainer.Background.alpha~=0)
local nativeRegistry={enabled=true}
S.Button(WQT_QuestMapTab,{'Icon','IconOverlay'});WQT_QuestMapTab.height=52
questBox:RegisterCallback('Initialized',function(_,f) f.TrackedBorder.alpha=.12 end,nativeRegistry)
settingBox:RegisterCallback('Initialized',function(_,f) f.nativeCallback=true end,nativeRegistry)
Flush()
assert(WQT_QuestMapTab.height==52 and WQT_QuestMapTab.Icon.square and WQT_QuestMapTab.Icon.alpha==1)
assert(nativeRegistry.enabled and #questBox.callbacks.Initialized==2 and #settingBox.callbacks.Initialized==2)
assert(WQT_ListContainer.Background.alpha==0 and WQT_SettingsFrame.Background.alpha==0)
assert(WQT_ListContainer.BorderFrame.alpha==0 and WQT_SettingsFrame.CloseButton.close)
assert(top.SortDropdown.dropdown and top.FilterDropdown.dropdown and top.SortDropdown.menuBound)
assert(top.SearchBox.text=='a native query' and top.SearchBox.Instructions.alpha==1 and top.SearchBox.width==16)
assert(quest.CenterContent.Title.path=='EUI' and quest.CenterContent.Title.color[1]==.8)
assert(quest.CenterContent.BottomRow.Time.color[1]==1 and quest.CenterContent.BottomRow.Time.color[2]==0)
assert(quest.timer.remaining==123 and quest.width==300 and quest.RightContent.Rewards.Icon.texture=='native-Icon')
assert(quest.Highlight.alpha==.12 and quest.TrackedBorder.Left.color[1]==accent and quest.menuBound)
assert(quest.scripts.OnClick()=='native-quest' and check.scripts.OnClick()=='native-check' and not check.CheckBox.checked)
assert(check.CheckBox.check and check.CheckBox.mouse==false and check.CheckBox.checkedArt.width==8)
assert(slider.SliderWithSteppers.Slider.thumb.width==8 and slider.SliderWithSteppers.Slider.thumb.height==14)
assert(slider.SliderWithSteppers.Back.glyph=='<' and slider.SliderWithSteppers.Forward.glyph=='>')
assert(slider.SliderWithSteppers.Slider.value==.75 and slider.TextBox.text=='0.75')
assert(slider.SliderWithSteppers.Slider.scripts.OnValueChanged(nil,.6)=='native-slider')
assert(confirm.Button.button and confirm.ButtonConfirm.button and confirm.ButtonDecline.button)
assert(picker.Picker.Color.alpha==1 and picker.ResetButton.Icon.alpha==1)
assert(WQT_GameTooltip.panel and tipText.path=='Native' and tipText.text=='|cff00ff00Native reward|r' and not mapPin.button)
assert(WQT_ShoppingTooltip1.panel and WQT_ShoppingTooltip2.panel and compareText.path=='Native' and WQT_ShoppingTooltip1.Icon.alpha==1)
assert(category.BGLeft.alpha==0 and category.BGRight.alpha==0)
assert(category.scripts.OnClick()=='native-category' and not category.isExpanded and category.Label.path=='EUI')
check.disabled=true;assert(check:UpdateState()=='native-state' and check.Label.color[1]==.5 and check.Label.path=='EUI')
local objects,hooks,writes,children,regions,enums,registered=allocated,hookCount,fontWrites,childReads,regionReads,enumReads,registrations
for i=1,1000 do questBox:Emit(quest,{questInfo={questID=i}});settingBox:Emit(check,check.elementData) end
assert(allocated==objects and hookCount==hooks and fontWrites==writes,'warm acquired frames recreated UI/hooks/fonts')
assert(childReads==children and regionReads==regions and enumReads==enums and registrations==registered,'warm callbacks scanned windows or duplicated registrations')
assert(check.nativeCallback and quest.TrackedBorder.alpha==.12)
-- Native font-object resets are repaired locally, once per reset; other controls
-- are not repainted, and no traversal/object creation is needed.
writes=fontWrites
for i=1,100 do check:UpdateState() end
assert(fontWrites-writes==100 and allocated==objects and childReads==children and regionReads==regions and enumReads==enums)
fontFace='EUI-new';accent=.75;looks[1]();Flush()
assert(quest.CenterContent.Title.path=='EUI-new' and quest.CenterContent.BottomRow.Time.color[2]==0)
assert(check.CheckBox.checkedArt.color[1]==.75 and top.SearchBox.path=='EUI-new' and allocated==objects)
local new=Quest(questBox);questBox.active={quest,new};questBox:Emit(new,{questInfo={questID=5}})
assert(new.CenterContent.Title.path=='EUI-new' and new.menuBound)
-- New controls acquired in combat must be discovered after combat ends.
combat=true;local late=Setting(settingBox,'WQT_SettingButtonTemplate');Button(late,'Button')
settingBox.active[#settingBox.active+1]=late;settingBox:Emit(late,late.elementData);looks[1]();Flush();assert(not late.Button.button)
combat=false;for _,frame in ipairs(events)do if frame.events and frame.events.PLAYER_REGEN_ENABLED then frame.scripts.OnEvent(frame,'PLAYER_REGEN_ENABLED')end end
Flush();assert(late.Button.button)
enabled=false;local foreign=Quest(questBox);questBox:Emit(foreign,{});module.refresh();assert(not foreign.menuBound)
enabled=true;local secure=Quest(questBox);secure.protected=true;questBox:Emit(secure,{});assert(not secure.menuBound)
local registrationCount=registrations;module.refresh();Flush();assert(registrations==registrationCount)
assert(#errors==0,table.concat(errors,'\n'))
print('PASS: World Quest Tab pooled quest/settings callbacks, native EUI cooperation, semantic timers/rewards, clean controls, native actions/returns/layout, theme changes, protected/disabled frames and combat recovery')
print('BENCH World Quest Tab mock: 1000 warm quest/settings initializations: 0 new UI objects/hooks/font writes/hierarchy scans; 100 native label-font resets repaired locally without scans')
