-- RCLootCouncil source-shaped factories, loot pooling and shared options lifecycle.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local menuBindings, dialogStyles=0,0
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'RCLootCouncil'); factory = fn end
ns.RegisterModule = function(id, _, available, install) module = {id=id, available=available, install=install} end
ns.BindPopupList=function(_,_,owner,list) assert(owner==list.dropdown); menuBindings=menuBindings+1 end
ns.RefreshPopupMenusNow=function() end
ns.StyleTextureDialog=function(_,_,popup,active) dialogStyles=dialogStyles+1; popup.styled=active end
MSA_ToggleDropDownMenu=function() return 'native-menu' end
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
    function f:SetParent(p) self.parent=p end
    function f:GetParent() parentReads=parentReads+1; return self.parent end
    function f:GetBackdrop() return self.backdrop end
    function f:GetBackdropColor() return table.unpack(self.bg or {0.2,0.2,0.2,1}) end
    function f:GetBackdropBorderColor() return table.unpack(self.edge or {0.5,0.1,0.8,1}) end
    function f:SetBackdropColor(...) self.bg={...} end
    function f:SetBackdropBorderColor(...) self.edge={...} end
    function f:GetVertexColor() return table.unpack(self.vertex or {1,1,1,1}) end
    function f:GetTexCoord() return table.unpack(self.coords or {0,1,0,1}) end
    function f:GetNumPoints() return self.point and 1 or 0 end
    function f:GetPoint() return table.unpack(self.point or {}) end
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
    function f:SetRotation(v) self.rotation=v end
    function f:SetTexture(v) self.texture=v end
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
    function f:Show() self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
    function f:Hide() self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
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
        local old=self.scripts[k]; self.scripts[k]=function(...) if old then old(...) end; fn(...) end
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
S.SquareIcon=function(t) t:SetTexCoord(0.08,0.92,0.08,0.92) end
S.Font=function(f,r,g,b) assert(not combat); fontWrites=fontWrites+1; f:SetFont(fontFace, f.size, ''); if r then f:SetTextColor(r,g,b,1) end end
S.Panel=function(f) if not f.panel then f.panel=true; f:CreateTexture(nil,'BACKGROUND') end end
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
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
assert(loadfile('EUIAddonSkins/Skins/RCLootCouncil.lua'))('EUIAddonSkins',ns)
RCLootCouncil=nil
assert(factory and not module)
local allocationBefore=allocated; factory()
assert(not module.available() and allocationBefore==allocated, 'missing target must not allocate frames')
UIParent=Object('Frame')
local registry, targets = {}, {}
local app={UI={private={Embed=function(_,object) return object end}}}
function app.UI:GetCreatedFramesOfType(kind) return registry[kind] or {} end
function app:IterateModules() return pairs(targets) end
local function Register(kind,object)
    app.UI.private:Embed(object)
    registry[kind]=registry[kind] or {}; table.insert(registry[kind],object)
    return object
end
local function Button(parent)
    local f=Object('Button',parent); f.Text=Text(f)
    f.Text.color={0.9,0.9,0.9,1}
    return Register('RCButton',f)
end
local function Icon(parent)
    local f=Object('Button',parent); f:SetNormalTexture('item-texture')
    f.backdrop={bgFile='native',edgeFile='thick',edgeSize=18}
    f.SetBorderColor=function(self,color) self:SetBackdropBorderColor(table.unpack(color)); return 'native-border' end
    return Register('IconBordered',f)
end
local function RCFrame(name)
    local f=CreateFrame('Frame',name,UIParent)
    f:SetSize(450,325); f.position='saved'; f.scale=1.1
    f.content=Object('Frame',f); f.content.backdrop={bgFile='native',edgeFile='native'}
    f.title=Object('Frame',f); f.title.backdrop={bgFile='native',edgeFile='native'}; f.title.text=Text(f.title)
    function f:Update() self.content:SetBackdrop({bgFile='new-profile'}); self.title:SetBackdrop({bgFile='new-profile'}); return 'native-update' end
    function f:Minimize() self.content:Hide(); self.minimized=true; return 'native-minimize' end
    function f:Maximize() self.content:Show(); self.minimized=false; return 'native-maximize' end
    return Register('RCFrame',f)
end
targets.voting={GetFrame=function(self)
    if self.frame then return self.frame end
    self.frame=RCFrame('DefaultRCLootCouncilFrame')
    self.frame.vote=Button(self.frame.content)
    self.frame.vote.scripts.OnClick=function() self.votes=(self.votes or 0)+1; return 'native-vote',nil,17 end
    self.frame.icon=Icon(self.frame.content)
    self.frame.response=Text(self.frame.content); self.frame.response.color={0.1,1,0.2,1}
    self.frame.tip=Object('GameTooltip',self.frame.content); self.frame.tip.label=Text(self.frame.tip)
    return self.frame
end}
targets.loot={EntryManager={entries={}},GetFrame=function(self)
    if not self.frame then self.frame=RCFrame('DefaultRCLootFrame') end
    return self.frame
end}
function targets.loot.EntryManager:GetEntry(item)
    if self.entries[item] then return self.entries[item], 'existing' end
    local e={frame=Object('Frame',targets.loot:GetFrame().content)}
    e.icon=Icon(e.frame); e.button=Button(e.frame)
    e.button.scripts.OnClick=function() item.response='MS'; return 'native-response' end
    e.note=Object('EditBox',e.frame); e.note.text='native note'
    e.timer=Object('StatusBar',e.frame); e.timer.value=30
    e.timer.scripts.OnUpdate=function(_,elapsed) e.timer.value=e.timer.value-elapsed end
    e.roll=Object('Button',e.frame); e.roll:SetNormalTexture('native-dice')
    self.entries[item]=e; return e, 'new'
end
function targets.voting.SetCellVote(_,cell)
    cell.voteBtn=cell.voteBtn or Button(cell); return false,'native-cell'
end
function targets.voting.SetCellGear(_,cell)
    cell:SetNormalTexture('gear'); return 'native-gear'
end
local gui={Release=function(_,widget) if widget.OnRelease then widget:OnRelease() end; widget.frame:Hide(); widget.frame:SetParent(UIParent); return 'native-release' end}
local dialog={OpenFrames={},BlizOptions={RCLootCouncil={}}}
function dialog:FeedGroup(id,_,container) self.feeds=(self.feeds or 0)+1; return 'native-feed',container,id end
LibStub=function(id,silent) assert(silent); if id=='AceConfigDialog-3.0' then return dialog elseif id=='AceGUI-3.0' then return gui end end
RCLootCouncil=app
assert(module.available()); module.install(S,module); Flush()
local voting=targets.voting:GetFrame(); voting:Show()
assert(voting.response.path=='EUI', 'the completed first show must be styled before the queued fallback')
Flush()
assert(voting.content.backdrop==nil and voting.title.backdrop==nil)
assert(not voting.panel and voting.position=='saved' and voting.scale==1.1 and voting.width==450)
assert(voting.title.text.path=='EUI' and voting.title.text.color[1]==accent)
assert(voting.response.path=='EUI' and voting.response.color[2]==1, 'response colours must survive: '..voting.response.path..' / '..table.concat(voting.response.color,','))
assert(voting.tip.label.path=='Native', 'shared tooltip text must be untouched')
assert(voting.icon.normal.coords[1]==0.08 and voting.icon.backdrop.edgeSize==1)
assert(voting.icon:SetBorderColor({1,0.7,0.1,1})=='native-border' and voting.icon.edge[2]==0.7)
local a,b,c=voting.vote.scripts.OnClick()
assert(a=='native-vote' and b==nil and c==17 and targets.voting.votes==1)
assert(voting:Minimize()=='native-minimize' and not voting.content.shown and voting.title.shown)
assert(voting:Maximize()=='native-maximize' and voting.content.shown)
assert(voting:Update()=='native-update' and voting.content.backdrop==nil)
local item={id=123}; local entry,source=targets.loot.EntryManager:GetEntry(item); Flush()
assert(source=='new' and entry.button.button and entry.note.input and entry.note.text=='native note')
assert(entry.button.scripts.OnClick()=='native-response' and item.response=='MS')
assert(entry.roll.normal.texture=='native-dice' and not entry.roll.button)
entry.timer.scripts.OnUpdate(entry.timer,0.25); assert(entry.timer.value==29.75)
local entry2,source2=targets.loot.EntryManager:GetEntry(item); assert(entry2==entry and source2=='existing')
local cell=Object('Button',voting.content)
assert(targets.voting.SetCellVote(nil,cell)==false and cell.voteBtn.button)
local gear=Object('Button',voting.content)
assert(targets.voting.SetCellGear(nil,gear)=='native-gear' and gear.normal.coords[1]==0.08)
local protected=Object('Button',voting.content); protected.protected=true; protected.Text=Text(protected)
module.refresh(); assert(not protected.button and protected.Text.path=='Native')
local beforeHooks,beforeObjects,beforeWalks,beforeFonts=hookCount,allocated,childReads,fontWrites
for i=1,100 do targets.voting:GetFrame(); voting:Show() end
Flush()
assert(hookCount==beforeHooks and allocated==beforeObjects and childReads==beforeWalks and fontWrites==beforeFonts,
    'warm windows must not allocate, duplicate hooks or recursively rescan')
local function Widget(kind,parent)
    local w={type=kind,frame=Object('Frame',parent),children={}}
    w.frame.obj=w; w.OnRelease=function(self) self.releases=(self.releases or 0)+1 end
    return w
end
local root=Widget('BlizOptionsGroup',UIParent)
dialog.BlizOptions.RCLootCouncil.settings=root
local check=Widget('CheckBox',root.frame); root.children={check}
check.checkbg=check.frame:CreateTexture(nil,'BACKGROUND'); check.checkbg:SetTexture('native-check-bg'); check.checkbg:SetSize(24,24)
check.check=check.frame:CreateTexture(nil,'ARTWORK'); check.check:SetTexture('native-tick'); check.check:SetSize(24,24)
check.SetValue=function(self,value) self.checked=value; return 'native-value' end
check.SetDisabled=function(self,value) self.disabled=value; return 'native-disabled' end
check.text=Text(check.frame); check.text.color={0.7,0.7,0.7,1}; check.checked=true
local action=Widget('Button',root.frame); action.frame.kind='Button'; action.frame.Text=Text(action.frame)
action.text=action.frame.Text; action.text.color={1,0.82,0,1}
action.SetDisabled=function(self,value) self.disabled=value; if value then self.frame:Disable() else self.frame:Enable() end; return 'native-button-state' end
action.Fire=function(self,event) if self.events and self.events[event] then return self.events[event]() end; return 'native-fire' end
table.insert(root.children,action)
action.frame.scripts.OnClick=function() return 'native-option' end
local dropdown=Widget('Dropdown',root.frame); table.insert(root.children,dropdown)
dropdown.dropdown=Object('Frame',dropdown.frame); dropdown.button=Object('Button',dropdown.dropdown)
dropdown.button.normal=dropdown.button:CreateTexture(nil,'ARTWORK'); dropdown.button.normal:SetTexture('native-arrow')
dropdown.button.scripts.OnClick=function() return 'native-dropdown' end
dropdown.button_cover=Object('Button',dropdown.frame)
dropdown.nativeArt=dropdown.dropdown:CreateTexture(nil,'ARTWORK'); dropdown.nativeArt:SetTexture('native-selector-border')
dropdown.text=Text(dropdown.dropdown); dropdown.text.color={0.1,0.7,1,1}
local popup={type='Dropdown-Pullout',frame=Object('Frame',UIParent),items={},userdata={obj=dropdown}}
popup.frame.obj=popup; popup.frame.backdrop={bgFile='native-popup',edgeFile='ornate'}
popup.Open=function(self) self.frame:Show(); return 'native-open',17 end
local popupItem={text=Text(popup.frame)}; popupItem.text.color={0.4,0.5,0.6,1}; popup.items={popupItem}
dropdown.pullout=popup
local inline=Widget('InlineGroup',root.frame); table.insert(root.children,inline)
local inlineBorder=Object('Frame',inline.frame); inlineBorder.backdrop={bgFile='native-inline',edgeFile='bevelled'}
inline.content=Object('Frame',inlineBorder); inline.titletext=Text(inline.frame)
local scroll=Widget('ScrollFrame',root.frame); table.insert(root.children,scroll)
scroll.scrollbar=CreateFrame('Slider','ActualAceScrollbar',scroll.frame); scroll.scrollbar.obj=scroll
scroll.scrollbar.thumb=scroll.scrollbar:CreateTexture(nil,'ARTWORK'); scroll.scrollbar.thumb:SetTexture('native-thumb'); scroll.scrollbar.thumb:SetSize(20,28)
local up=CreateFrame('Button','ActualAceScrollbarScrollUpButton',scroll.scrollbar); up:SetNormalTexture('native-up')
local down=CreateFrame('Button','ActualAceScrollbarScrollDownButton',scroll.scrollbar); down:SetNormalTexture('native-down')
down.scripts.OnClick=function() return 'native-step' end
local tabs=Widget('TabGroup',root.frame); table.insert(root.children,tabs)
tabs.tabs={Object('Button',tabs.frame),Object('Button',tabs.frame)}
for i,tab in ipairs(tabs.tabs) do tab.Text=Text(tab); tab.selected=i==1 end
root.closebutton=Object('Button',root.frame); root.closebutton:SetNormalTexture('native-close')
root.closebutton.scripts.OnClick=function() return 'native-close-action' end
local sr,container,id=dialog:FeedGroup('RCLootCouncil',{},root)
assert(sr=='native-feed' and container==root and id=='RCLootCouncil')
assert(check.check.width==8 and check.checkbg.width==14 and check.checked and check.text.path=='EUI')
assert(action.frame.scripts.OnClick()=='native-option')
assert(action.text.color[1]==0.92 and action.text.color[4]==1, 'enabled Version Check-style buttons must be readable')
assert(action:SetDisabled(true)=='native-button-state' and action.text.color[1]==0.5)
action:SetDisabled(false); action.text:SetTextColor(0.05,0.05,0.01,1)
assert(action.text.color[1]==0.92, 'native text resets must not leave enabled actions dark')
action.frame:SetFrameLevel(40); action.frame:SetParent(inline.content)
assert(#action.frame.children==0, 'action backgrounds must stay behind text without frame-level child overlays')
assert(inlineBorder.backdrop==nil and inline.titletext.color[1]==accent)
assert(dropdown.nativeArt.alpha==0 and dropdown.text.color[3]==1, 'selector art is removed while quality colours survive')
assert(up.normal.alpha==0 and down.normal.alpha==0 and down.scripts.OnClick()=='native-step')
assert(scroll.scrollbar.thumb.width==20 and scroll.scrollbar.thumb.height==28 and scroll.scrollbar.thumb.alpha==0, 'visual grip must preserve native drag dimensions')
local opened,openValue=popup:Open()
assert(opened=='native-open' and openValue==17 and popup.frame.backdrop==nil and popupItem.text.path=='EUI')
popup.frame:Hide()
assert(popup.frame.backdrop.edgeFile=='ornate' and popupItem.text.path=='Native' and popupItem.text.color[1]==0.4)
popup:Open(); popup.userdata.obj={}; popup:Open()
assert(popupItem.text.path=='Native' and popup.frame.backdrop.edgeFile=='ornate', 'foreign popup reuse restores native styling')
popup.userdata.obj=dropdown
dialog.popup=Object('Frame',UIParent); dialog.popup.text=Text(dialog.popup)
action.events={OnClick=function() dialog.popup:Show(); return 'native-confirm' end}
assert(action:Fire('OnClick')=='native-confirm' and dialog.popup.styled and dialog.popup.text.path=='Native')
check:OnRelease(); action:OnRelease(); dropdown:OnRelease(); tabs:OnRelease(); inline:OnRelease(); scroll:OnRelease(); root:OnRelease()
assert(check.check.texture=='native-tick' and check.check.width==24 and check.checkbg.texture=='native-check-bg')
assert(check.text.path=='Native' and action.frame.Text.path=='Native', 'pool release must restore native fonts')
assert(action.text.color[1]==1 and action.text.color[2]==0.82 and inlineBorder.backdrop.edgeFile=='bevelled')
assert(up.normal.alpha==1 and down.normal.alpha==1 and scroll.scrollbar.thumb.alpha==1)
local nativeWidgets=allocated
dialog:FeedGroup('AnotherAddon',{},root); check.frame:Show()
assert(check.text.path=='Native' and allocated==nativeWidgets, 'other addons must not trigger the skin')
dialog:FeedGroup('RCLootCouncil',{},root)
assert(check.check.width==8, 'owned pool reacquisition restores skin art')
local actionFill; for _,r in ipairs(action.frame.regions) do if r.layer=='BACKGROUND' then actionFill=r end end
assert(actionFill and actionFill.alpha==1 and actionFill.anchor==action.frame)
assert(dropdown.button.scripts.OnClick()=='native-dropdown' and dropdown.button.normal.alpha==0)
assert(root.closebutton.scripts.OnClick()=='native-close-action' and root.closebutton.normal.alpha==0)
local beforeStateWalks,beforeStateObjects=childReads,allocated
for i=1,100 do check:SetValue(i%2==0); check:SetDisabled(i%2==0) end
assert(childReads==beforeStateWalks and allocated==beforeStateObjects and check.check.width==8)
assert(check.check.color[1]==0.45 and check.checked==true)
local callbacks=hookCount
for i=1,40 do dialog:FeedGroup('RCLootCouncil',{},root) end
assert(hookCount==callbacks and allocated==nativeWidgets, 'repeated page feeds must reuse skin objects and hooks')
local beforeLabels,beforeLabelObjects=childReads,allocated
for i=1,100 do action:SetDisabled(i%2==0); action.text:SetTextColor(0.1,0.1,0.1,1) end
assert(action.text.color[1]==0.5 and childReads==beforeLabels and allocated==beforeLabelObjects, 'button state repairs must stay local')
action:SetDisabled(false)
local menu=CreateFrame('Frame','RCLootCouncil_VotingFrame_FilterMenu',UIParent)
MSA_DROPDOWNMENU_OPEN_MENU=menu
MSA_DropDownList1=Object('Button',UIParent); MSA_DropDownList1.dropdown=menu
assert(MSA_ToggleDropDownMenu()=='native-menu' and menuBindings==1)
MSA_DROPDOWNMENU_OPEN_MENU=CreateFrame('Frame','ForeignMenu',UIParent)
MSA_ToggleDropDownMenu(); assert(menuBindings==1)
accent=0.75; fontFace='EUI-new' ; for _,fn in ipairs(looks) do fn() end; Flush()
assert(voting.title.text.color[1]==0.75 and voting.response.path=='EUI-new' and voting.response.color[2]==1)
combat=true
local combatFrame=RCFrame('CombatCreated'); local combatButton=Button(combatFrame.content)
Flush(); assert(not combatButton.button)
combat=false
for _,event in ipairs(events) do if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event) end end
Flush(); assert(combatButton.button)
enabled=false
local disabled=RCFrame('DisabledCreated'); local disabledButton=Button(disabled.content)
Flush(); assert(not disabledButton.button)
check:OnRelease(); assert(check.text.path=='Native', 'disabled cleanup still restores shared widgets')
action.OnRelease=nil -- Stock AceGUI Button has no OnRelease method.
assert(gui:Release(action)=='native-release' and action.text.path=='Native' and action.text.color[1]==1)
action:SetDisabled(false); action.text:SetTextColor(0.2,0.3,0.4,1)
assert(action.text.color[1]==0.2, 'released foreign buttons must not inherit active label hooks')
assert(#errors==0,table.concat(errors,'\n'))
print('BENCH RCLootCouncil warm opens=100 recursive_reads=0 new_objects=0 new_hooks=0; checkbox_state_calls=200 recursive_reads=0 new_objects=0 (mock)')
print('PASS: RCLootCouncil factories, dynamic loot/vote actions, native timers, minimising, warm-window caching, shared widget restoration, themes, combat and disabled gating')
