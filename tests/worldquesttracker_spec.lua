-- World Quest Tracker source-shaped DF controls, pooled quest rows and menus.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'WorldQuestTracker'); factory = fn end
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

assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
assert(loadfile('EUIAddonSkins/Skins/WorldQuestTracker.lua'))('EUIAddonSkins',ns)
assert(factory and not module);local before=allocated;factory();assert(not module.available()and before==allocated)
UIParent=Object('Frame')
local actions=0
local function Button(parent)
 local f=Object('Button',parent);f.Text=Text(f)
 f.scripts.OnClick=function()actions=actions+1;return 'native-action',nil,7 end
 return f
end
local function DFControl(parent,kind,method)
 local f=Object(kind,parent);local w={widget=f,type=method};f.MyObject=w
 function w:SetTemplate()return 'template',nil,6 end
 function w:Enable()self.lockdown=false;f:Enable()end
 function w:Disable()self.lockdown=true;f:Disable()end
 if method=='switch'then
  w.checked_texture=f:CreateTexture(nil,'ARTWORK');w.checked_texture:Show();w.label={widget=Text(parent)}
  w.SetAsCheckBox=function()return'checkbox-native'end
 elseif method=='slider'then f.thumb=f:CreateTexture();f.orientation='HORIZONTAL'
 elseif method=='dropdown'then
  f.arrowTexture=f:CreateTexture(nil,'OVERLAY');f.arrowTexture2=f:CreateTexture(nil,'HIGHLIGHT')
  f.dropdownframe=Object('Frame',f);f.dropdownframe:Hide()
 end
 return f,w
end
local nativeRowCount=0
WorldQuestTrackerAddon={WorldMapWidgets={},ZoneWidgetPool={}}
local W=WorldQuestTrackerAddon
function W.GetOrCreateTrackerWidget(index)
 local name='WorldQuestTracker_Tracker'..index
 if _G[name]then return _G[name],nil,3 end
 local f=CreateFrame('Button',name,WorldQuestTrackerScreenPanel_QuestHolder);f.worldQuest=true
 for _,key in ipairs({'RightBackground','roundedBackgroundTexture','BackgroupTexture','Circle','Shadow','Icon','SuperTracked','overlayBorder'})do f[key]=f:CreateTexture()end
 f.Title={widget=Text(f)};f.TimeLeft=Text(f);f.Title.widget.color={1,.25,.1,1}
 f.scripts.OnClick=function()actions=actions+1 end
 f.scripts.OnUpdate=function()return'quest-distance-update'end
 nativeRowCount=nativeRowCount+1
 return f,nil,3
end
function W.CreateWorldMapSquareButton(name,index,parent)
 local f=CreateFrame('Button','WorldQuestTrackerWorldMapPOI'..name..'POI'..index,parent or WorldQuestTrackerWorldMapPOI)
 f.IsWorldQuestButton=true;f.texture=f:CreateTexture();f.rareBorder=f:CreateTexture();f.trackingBorder=f:CreateTexture()
 f.amountText=Text(f);W.WorldMapWidgets[#W.WorldMapWidgets+1]=f
 return f,nil,4
end
function W.CreateZoneWidget(index,name,parent)
 local f=CreateFrame('Button',name..index,parent or WorldQuestTrackerWorldMapPOI)
 f.Texture=f:CreateTexture();f.TextureCustom=f:CreateTexture();f.RareOverlay=Object('Button',f)
 W.ZoneWidgetPool[#W.ZoneWidgetPool+1]=f
 return f,nil,5
end
local switch,slider,dropdown,ordinary,tabButtons,pages
function W.OpenOptionsPanel()
 if WorldQuestTrackerOptionsPanel then WorldQuestTrackerOptionsPanel:Show();return 'open-existing' end
 local root=CreateFrame('Frame','WorldQuestTrackerOptionsPanel',UIParent)
 WQTOptionsPanelContainer={AllButtons={},AllFrames={}}
 function WQTOptionsPanelContainer:SelectTabByIndex(index)
  for i,page in ipairs(self.AllFrames)do page.shown=i==index end
  for _,button in ipairs(self.AllButtons)do button.leftSelectionIndicator:SetColorTexture(.4,.4,.4,1)end
  self.AllButtons[index].leftSelectionIndicator:SetColorTexture(1,1,0,1)
  return 'select-native',nil,9
 end
 tabButtons,pages=WQTOptionsPanelContainer.AllButtons,WQTOptionsPanelContainer.AllFrames
 for i=1,6 do
  local page=Object('Frame',root);pages[i]=page;if i>1 then page:Hide()end
  local f=Button(root);local w={widget=f,leftSelectionIndicator=f:CreateTexture(),selectedUnderlineGlow=f:CreateTexture()}
  tabButtons[i]=w
  f.scripts.OnClick=function()WQTOptionsPanelContainer:SelectTabByIndex(i);actions=actions+1 end
 end
 switch=DFControl(pages[1],'Button','switch')
 slider=DFControl(pages[2],'Slider','slider')
 dropdown=DFControl(pages[3],'Button','dropdown')
 ordinary=Button(pages[4]);ordinary.MyObject={type='button',widget=ordinary}
 return 'open-native',nil,8
end
WorldQuestTrackerScreenPanel_QuestHolder=CreateFrame('Frame','WorldQuestTrackerScreenPanel_QuestHolder',UIParent)
WorldQuestTrackerWorldMapPOI=CreateFrame('Frame','WorldQuestTrackerWorldMapPOI',UIParent)
WorldQuestTrackerParentTapFrame=CreateFrame('Frame','WorldQuestTrackerParentTapFrame',UIParent)
local toolbar=Button(WorldQuestTrackerParentTapFrame)
local existing=W.GetOrCreateTrackerWidget(1)
local pin=W.CreateWorldMapSquareButton('Test',1)
local foreign=Object('Frame',UIParent)
GameCooltip={Host=foreign,frame1=Object('Frame',UIParent),frame2=Object('Frame',UIParent)}
local menu=GameCooltip
function menu:ShowCooltip()return'menu-native',nil,10 end
function menu:BuildTooltip()return'build-native'end
assert(module.available());module.install(S,module);Flush()
assert(not WorldQuestTrackerOptionsPanel,'skin forced options construction')
assert(existing.Icon.square and existing.RightBackground.alpha==0 and existing.Title.widget.path=='EUI')
assert(existing.Title.widget.color[1]==1 and existing.Title.widget.color[2]==.25,'semantic quest colour lost')
assert(existing.SuperTracked.alpha==1 and existing.overlayBorder.alpha==1 and existing.scripts.OnUpdate()=='quest-distance-update')
assert(pin.texture.square and pin.rareBorder.alpha==1 and pin.trackingBorder.alpha==1)
local a,b,c=W.OpenOptionsPanel();assert(a=='open-native'and b==nil and c==8);Flush()
assert(WorldQuestTrackerOptionsPanel.shell.noTopBar and WorldQuestTrackerOptionsPanel.shell.noAccent)
assert(switch.button and switch.MyObject.checked_texture.color[1]==accent)
assert(slider.thumb.width==8 and slider.thumb.height==14)
assert(dropdown.dropdown and dropdown.arrowTexture.width==10 and ordinary.button)
assert(ordinary.Text.path=='EUI','hidden page not pre-skinned')
local function Click(f)
 local r=table.pack(f.scripts.OnClick(f))
 for _,fn in ipairs(f.postScripts and f.postScripts.OnClick or{})do fn(f)end
 return table.unpack(r,1,r.n)
end
local snapshotObjects,snapshotHooks,snapshotFonts=allocated,hookCount,fontWrites
local snapshotReads=childReads
for i=1,300 do Click(tabButtons[i%6+1].widget)end
Flush()
assert(allocated==snapshotObjects and hookCount==snapshotHooks and fontWrites==snapshotFonts and childReads==snapshotReads,'warm tabs allocate, write fonts or scan hierarchies')
assert(ordinary.Text.color[1]==.9)
assert(tabButtons[1].leftSelectionIndicator.color[1]==accent,'native yellow selection was not replaced')
ordinary:Disable()
for _,fn in ipairs(ordinary.postScripts.OnDisable or{})do fn(ordinary)end
assert(ordinary.Text.color[1]==.5)
ordinary:Enable()
for _,fn in ipairs(ordinary.postScripts.OnEnable or{})do fn(ordinary)end
assert(ordinary.Text.color[1]==.9)
local row,_,ret=W.GetOrCreateTrackerWidget(2);assert(ret==3 and row.Icon.square)
local newpin,_,ret=W.CreateWorldMapSquareButton('Next',2);assert(ret==4 and newpin.texture.square)
local zone,_,ret=W.CreateZoneWidget(3,'Zone');assert(ret==5 and zone.Texture.square)
local mark=switch.MyObject.checked_texture
mark:Hide();switch.MyObject:SetTemplate();assert(not mark:IsShown(),'unchecked value became checked')
mark:Show();switch.MyObject:Disable();assert(mark.color[1]==.4);switch.MyObject:Enable();assert(mark.color[1]==accent)
local entry=Button(dropdown.dropdownframe);dropdown.dropdownframe:Show();Flush();assert(entry.button)
menu:ShowCooltip();assert(not menu.frame1.panel,'foreign cooltip was skinned')
menu.Host=toolbar
local line=Button(menu.frame1);menu:ShowCooltip();assert(menu.frame1.panel and line.button)
local second=Button(menu.frame1);menu:ShowCooltip();assert(second.button,'new pooled menu row missed')
local oldObjects,oldHooks=allocated,hookCount
for i=1,50 do menu:ShowCooltip()end
assert(allocated==oldObjects and hookCount==oldHooks,'menu hooks/layers duplicated')
combat=true
local later=W.GetOrCreateTrackerWidget(4);assert(not later.Icon.square)
local combatPin=W.CreateZoneWidget(4,'Combat');assert(not combatPin.Texture.square)
for _,fn in ipairs(looks)do fn()end;Flush()
combat=false
for _,event in ipairs(events)do if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event,'PLAYER_REGEN_ENABLED')end end
Flush();assert(later.Icon.square and combatPin.Texture.square,'combat-created objects were lost')
accent=.8;fontFace='ChangedFont';for _,fn in ipairs(looks)do fn()end;Flush()
assert(switch.MyObject.checked_texture.color[1]==.8 and ordinary.Text.path=='ChangedFont')
enabled=false
local disabledRow=W.GetOrCreateTrackerWidget(5);assert(not disabledRow.Icon.square)
local before=allocated;menu:ShowCooltip();Flush();assert(allocated==before)
enabled=true;module.refresh();Flush();assert(disabledRow.Icon.square)
assert(#errors==0,table.concat(errors,'\n'))
print('BENCH WorldQuestTracker warm_tabs=300 child_walks=0 font_writes=0 new_objects=0 (mock)')
print('PASS: World Quest Tracker deferred options, hidden pages, native actions, DF checks/sliders/dropdowns, pooled menus/icons, local warm callbacks and combat/toggle/theme recovery')
