-- Scrap lazy merchant/visualizer and reversible Sushi widget lifecycles.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local menuBindings, dialogStyles=0,0
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'Scrap'); factory = fn end
ns.RegisterModule = function(id, _, available, install) module = {id=id, available=available, install=install} end
ns.BindPopupList=function(_,_,owner,list) assert(owner==list.dropdown); menuBindings=menuBindings+1 end
ns.RefreshPopupMenusNow=function() end
local popupOwners={}
ns.BindPopupOwner=function(_,_,f) popupOwners[f]=true end
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
    function f:GetDisabledCheckedTexture() return self.disabledArt end
    function f:GetAtlas() return self.atlas end
    function f:SetAtlas(v) self.atlas=v end
    function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
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
    function f:SetGradientAlpha(...) self.gradient={...} end
    function f:SetRotation(v) self.rotation=v end
    function f:SetTexture(v) self.texture=v end
    if kind=='Texture' then function f:GetTexture() return self.texture end end
    function f:SetTexCoord(...) self.coords={...} end
    function f:GetText() return self.text end
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
S.BorderRegion=function(_,t)
    if not t.bordered then t.bordered=true; for i=1,4 do t.edges=t.edges or {}; t.edges[i]=Object('Texture') end end
end
S.SquareIcon=function(t) t:SetTexCoord(0.08,0.92,0.08,0.92) end
S.Font=function(f,r,g,b) assert(not combat); fontWrites=fontWrites+1; f:SetFont(fontFace, f.size, ''); if r then f:SetTextColor(r,g,b,1) end end
S.Panel=function(f) if not f.panel then f.panel=true; f:CreateTexture(nil,'BACKGROUND') end end
S.Shell=function(f) f.shell=true end
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

assert(loadfile('EUIAddonSkins/Skins/Scrap.lua'))('EUIAddonSkins',ns)
Scrap=nil; assert(factory and not module)
local before=allocated; factory(); assert(not module.available() and allocated==before)
UIParent=Object('Frame')
Scrap={}; LibStub=function(_,silent) assert(silent); return nil end
assert(module.available()); module.install(S,module); Flush()
local function Event(name)
    for _,f in ipairs(events) do if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f,'ADDON_LOADED',name) end end
    Flush()
end
local function Button(parent)
    local f=Object('Button',parent); f.Text=Text(f); f.Text.text='Native action'
    f.scripts.OnClick=function() return 'native-action' end; return f
end
local merchant=Button(UIParent); Scrap.Merchant=merchant
merchant.icon=merchant:CreateTexture(nil,'ARTWORK'); merchant.icon:SetTexture('scrap-logo')
merchant.border=merchant:CreateTexture(nil,'BACKGROUND'); merchant.border:SetTexture('native-ornate')
merchant:SetPoint('RIGHT',UIParent,'LEFT',15,2); merchant:SetSize(37,37)
merchant.scripts.OnReceiveDrag=function() return 'native-drag-junk' end
local saleCalls=0
function merchant:UpdateState() self.icon:SetVertexColor(0.4,0.4,0.4,1); return 'native-state' end
function merchant:Sell() saleCalls=saleCalls+1; return 'native-sale' end
local root=CreateFrame('Frame','ScrapVisualizer',UIParent); Scrap.Visualizer=root
root.TitleText=Text(root); root.Inset=Object('Frame',root); root.CloseButton=Button(root)
root.ToggleButton,root.ForgetButton=Button(root),Button(root)
root.Tab1,root.Tab2,root.ParentTab=Button(root),Button(root),Button(UIParent)
root.selectedTab=1; root.Scroll=Object('ScrollFrame',root)
local bar=CreateFrame('Slider','ScrapVisualizerScrollBar',root.Scroll); bar.thumb=bar:CreateTexture(nil,'ARTWORK')
local nativeRows=0
local function Row()
    local row=Button(root.Scroll); row.Icon=row:CreateTexture(); row.Icon:SetTexture('quality-item')
    row.Text.color={0.7,0.2,0.9,1}; row.Stripe=row:CreateTexture(nil,'BACKGROUND'); row.Stripe:Hide()
    row.highlight=row:CreateTexture(nil,'HIGHLIGHT'); row.highlight:SetTexture('native-hover')
    row.scripts.OnEnter=function() return 'native-item-tooltip' end
    return row
end
root.Scroll.buttons={Row(),Row()}
function root.Scroll:update()
    nativeRows=nativeRows+1
    for _,row in ipairs(self.buttons) do row.Text:SetTextColor(0.7,0.2,0.9,1); row.Text:SetText('Epic item'); row.Stripe:Hide() end
    return 'native-scroll'
end
function root:SetTab(id) self.selectedTab=id; self.Scroll:update(); return 'native-tab' end
local nativeShows=0
function root:OnLoad()
    self.numTabs=2
    self:SetScript('OnShow',function() nativeShows=nativeShows+1 end)
    return 'native-load'
end
local savedIcon=merchant.icon; merchant.icon=nil
local nativeMenuClicks=0
function merchant:OnLoad()
    self.icon=savedIcon
    self:SetScript('OnClick',function() nativeMenuClicks=nativeMenuClicks+1 end)
    return 'native-merchant-load'
end
Event('Scrap_Merchant')
assert(not merchant.button and not root.shell,'incomplete modules were styled')
assert(merchant:OnLoad()=='native-merchant-load' and root:OnLoad()=='native-load')
root:Show(); assert(nativeShows==1,'native OnShow lost')
assert(merchant.button and merchant.icon.texture=='scrap-logo' and merchant.border.alpha==0)
assert(merchant.icon.coords[1]==0 and merchant.icon.coords[2]==1 and merchant.icon.width==31 and merchant.icon.point[2]==merchant)
assert(merchant.width==37 and merchant.point[4]==15 and merchant.scripts.OnReceiveDrag()=='native-drag-junk')
assert(merchant:Sell()=='native-sale' and saleCalls==1)
assert(root.shell and root.CloseButton.close and root.Inset.inset and bar.thumb.width==5)
assert(root:SetTab(2)=='native-tab' and root.Tab2.selected and not root.Tab1.selected)
local row=root.Scroll.buttons[1]
assert(row.Text.path=='EUI' and row.Text.color[1]==0.7 and row.Text.color[3]==0.9 and not row.Stripe:IsShown())
assert(row.scripts.OnEnter()=='native-item-tooltip')
local c,r,o,h,w=childReads,regionReads,allocated,hookCount,fontWrites
for i=1,1000 do merchant:UpdateState(); root.Scroll:update() end
assert(childReads==c and regionReads==r and allocated==o and hookCount==h and fontWrites==w,'warm bags/scroll triggered scans or writes')
table.insert(root.Scroll.buttons,Row()); root.Scroll:update(); assert(root.Scroll.buttons[3].Text.path=='EUI')
-- Sushi calls OnReset before its native defaults. Reset clears acquisition calls.
local function Widget(kind,parent)
    local f=Object(kind,parent); f.calls={}
    function f:SetCall(event,fn) self.calls[event]=self.calls[event] or {}; table.insert(self.calls[event],fn); return self end
    function f:Release()
        for _,fn in ipairs(self.calls.OnReset or {}) do fn(self) end
        self.calls={}; self:Hide(); return 'native-release'
    end
    function f:UpdateFont() if self.Text then self.Text:SetFontObject('Native') end; return 'native-font' end
    function f:SetEnabled(v) self.enabled=v; self:UpdateFont(); return 'native-enable' end
    function f:SetSmall(v) self.small=v; self:UpdateFont(); return 'native-small' end
    return f
end
local group=Widget('Frame',UIParent); group.Children={}
function group:UpdateChildren() return 'native-children' end
group.Update=group.UpdateChildren; group.SetChildren=group.UpdateChildren
Scrap.Options={Main=group}
local check=Widget('CheckButton',group); check.Text=Text(check); check.checked=true
check.normal=check:CreateTexture(nil,'ARTWORK'); check.normal:SetTexture('native-checkbox'); check.normal:SetSize(26,26)
check.checkedArt=check:CreateTexture(nil,'ARTWORK'); check.checkedArt:SetTexture('native-check'); check.checkedArt:SetSize(26,26)
check.disabledArt=check:CreateTexture(nil,'ARTWORK'); check.disabledArt:SetTexture('native-disabled'); check.disabledArt:Hide()
local toggleCalls=0
check.scripts.OnClick=function() toggleCalls=toggleCalls+1; check:SetChecked(not check:GetChecked()); return 'native-input' end
local action=Widget('Button',group); action.Text=Text(action); action.normal=action:CreateTexture(nil,'ARTWORK'); action.normal:SetTexture('native-red')
action.scripts.OnClick=function() return 'native-keybindings' end
local slider=Widget('Slider',group); slider.Label=Text(slider); slider.thumb=slider:CreateTexture(); slider.thumb:SetTexture('native-thumb'); slider.thumb:SetSize(20,28)
slider.Edit=Widget('EditBox',slider); slider.Edit.Bg=Object('Frame',slider.Edit); slider.Edit.Bg.backdrop={edgeFile='native-edit'}
slider.value=25; slider.scripts.OnValueChanged=function(_,v) slider.value=v; return 'native-threshold' end
local header=Widget('Button',group); header.Text=Text(header); header.Line=header:CreateTexture(); header.Line:SetTexture('native-line'); header.Line:Show()
local expand=Widget('Button',group); expand.Text=Text(expand); expand.Right=expand:CreateTexture(); expand.Right:SetAtlas('native-collapsed')
function expand:SetChecked(value) self.Right:SetAtlas(value and 'native-expanded' or 'native-collapsed'); return 'native-expanded-state' end
function expand:GetChecked() return self.Right:GetAtlas()=='native-expanded' end
group.Children={check,action,slider,header,expand}
Event('Scrap_Config')
assert(check.normal.width==14 and check.checkedArt.width==8 and check.checkedArt.color[1]==accent and check.checked)
assert(header.Text.color[1]==0.92 and expand.Text.color[1]==0.92,'options headings must be neutral')
assert(not check.disabledArt:IsShown() and check.width==16 and header.Line:IsShown() and header.Line.alpha==0)
assert(action.normal.alpha==0 and action.Text.color[1]==0.92 and action.scripts.OnClick()=='native-keybindings')
assert(slider.thumb.width==8 and slider.Edit.Bg.backdrop==nil and slider.Edit.path=='EUI')
assert(slider.scripts.OnValueChanged(slider,60)=='native-threshold' and slider.value==60)
assert(expand.Right.alpha==0 and expand:SetChecked(true)=='native-expanded-state' and expand:GetChecked(),'native expand atlas state changed')
assert(check:SetEnabled(false)=='native-enable' and check.Text.color[1]==0.5)
assert(check:SetEnabled(true)=='native-enable' and check.Text.color[1]==0.92)
c,r,o,h,w=childReads,regionReads,allocated,hookCount,fontWrites
for i=1,100 do check.scripts.OnClick(); group:UpdateChildren(); group:Show() end
assert(toggleCalls==100 and childReads==c and allocated==o and hookCount==h and fontWrites==w,'unchanged options repainted')
check:Release(); action:Release(); slider.Edit:Release(); slider:Release(); header:Release(); expand:Release()
assert(check.normal.texture=='native-checkbox' and check.normal.width==26 and check.checkedArt.texture=='native-check' and check.Text.path=='Native')
assert(action.normal.alpha==1 and action.Text.path=='Native' and slider.thumb.width==20 and slider.Edit.Bg.backdrop.edgeFile=='native-edit')
assert(header.Line.alpha==1 and expand.Right.alpha==1 and expand.Right.atlas=='native-collapsed')
local foreign=Object('Frame',UIParent); check:SetParent(foreign); check:SetEnabled(false)
assert(check.Text.path=='Native','pooled font hook affected another addon')
check.calls={}; check:SetParent(group); group.Children={check}; group:UpdateChildren()
assert(check.normal.width==14 and #check.calls.OnReset==1)
check:Release(); assert(check.normal.width==26)
local poolObjects,poolHooks=allocated,hookCount
for i=1,40 do
    check.calls={}; check:Show(); group:UpdateChildren()
    assert(#check.calls.OnReset==1 and check.normal.width==14)
    check:Release(); assert(check.normal.texture=='native-checkbox' and check.normal.width==26)
end
assert(allocated==poolObjects and hookCount==poolHooks,'pool reacquisition grew objects/hooks')
check.calls={}; group:UpdateChildren(); enabled=false
check:Release(); assert(check.normal.texture=='native-checkbox' and check.Text.path=='Native','disabled cleanup leaked')
enabled=true
-- Dropdowns use a shared Sushi pool but only Scrap's merchant is eligible.
local drop=Widget('Frame',merchant); drop.Children={}; drop.bg=Object('Frame',drop); drop.bg.backdrop={edgeFile='native-popup'}
function drop:UpdateChildren() return 'native-popup-children' end
drop.Update=drop.UpdateChildren; drop.SetChildren=drop.UpdateChildren
local entry=Widget('CheckButton',drop); entry.Text=Text(entry); entry.Arrow=Object('Button',entry)
entry.Text.text='Options  |A:worldquest-icon-engineering:12:12|a'
entry.Highlight=entry:CreateTexture(nil,'HIGHLIGHT'); entry.Highlight:SetTexture('native-menu-hover')
entry.scripts.OnClick=function() return 'native-menu-action' end
drop.Children={entry}
LibStub=function(id,silent) assert(silent); if id=='Sushi-3.2' then return {Dropdown={Current=drop}} end end
merchant.scripts.OnClick(); Flush()
assert(entry.Text.text=='Options','native decorative icon remained')
entry.isTitle=1; entry:SetEnabled(false); assert(entry.Text.color[1]==0.92,'menu title should remain readable')
entry.isTitle=nil; entry:SetEnabled(true)
entry.Text:SetText('Help  |T516770:13:13:0:0:64:64:14:50:14:50|t'); assert(entry.Text.text=='Help')
assert(nativeMenuClicks==1,'native merchant OnClick was overwritten')
assert(drop.bg.backdrop==nil and entry.Text.path=='EUI' and entry.scripts.OnClick()=='native-menu-action')
entry:Release(); assert(entry.Text.text:find('|T516770:',1,true),'native menu label not restored'); drop:Release(); assert(drop.bg.backdrop.edgeFile=='native-popup' and entry.Text.path=='Native')
drop:SetParent(foreign); drop.Children={entry}; entry:SetParent(drop); drop.calls={}; entry.calls={}
drop:UpdateChildren(); assert(entry.Text.path=='Native' and drop.bg.backdrop.edgeFile=='native-popup')
-- CustomTutorials owns one frame per embedded addon, never a shared global scan.
local tutorial=Object('Frame',UIParent); tutorial.TitleText=Text(tutorial); tutorial.text=Text(tutorial)
tutorial.text.text='Drag |cffffcc00items|r here'; tutorial.Inset=Object('Frame',tutorial)
tutorial.NineSlice=Object('Frame',tutorial); tutorial.CloseButton=Button(tutorial)
tutorial.prev,tutorial.next=Button(tutorial),Button(tutorial)
tutorial.prev.scripts.OnClick=function() return 'native-prev' end
tutorial.next.scripts.OnClick=function() return 'native-next' end
tutorial.images={tutorial:CreateTexture(nil,'ARTWORK')}; tutorial.images[1]:SetTexture('native-instruction-art')
tutorial.shine=Object('Frame',UIParent); tutorial.flash={running=true}
Scrap.Tutorials={}
local tutorialLib={frames={[Scrap.Tutorials]=tutorial}}
function Scrap.Tutorials:RegisterTutorials() return 'native-register' end
function Scrap.Tutorials:TriggerTutorial() self.index=(self.index or 0)+1; tutorial:Show(); return 'native-trigger' end
function Scrap.Tutorials:Restart() return self:TriggerTutorial() end
local oldLib=LibStub
LibStub=function(id,silent) if id=='CustomTutorials-2.1' then return tutorialLib end; return oldLib(id,silent) end
S.RemovePortrait=function(f) f.portraitRemoved=true end
local oldShell=S.Shell
S.Shell=function(f,...) oldShell(f,...); if f==tutorial then for _,t in ipairs(f.images) do t:SetAlpha(0) end end end
Event('Scrap_Config')
assert(tutorial.shell and tutorial.portraitRemoved and tutorial.CloseButton.close and tutorial.Inset.inset and tutorial.NineSlice.faded)
assert(tutorial.images[1].alpha==1 and tutorial.images[1].texture=='native-instruction-art' and tutorial.text.text=='Drag |cffffcc00items|r here')
assert(tutorial.prev.scripts.OnClick()=='native-prev' and tutorial.next.scripts.OnClick()=='native-next')
assert(Scrap.Tutorials:RegisterTutorials()=='native-register' and Scrap.Tutorials:TriggerTutorial()=='native-trigger')
c,r,o,h,w=childReads,regionReads,allocated,hookCount,fontWrites
for i=1,100 do Scrap.Tutorials:TriggerTutorial() end
assert(childReads==c and regionReads==r and allocated==o and hookCount==h and fontWrites==w,'warm tutorial re-skinned')
header.calls={}; header:Show(); group.Children={header}; group:UpdateChildren()
assert(header.Text.color[1]==0.92)
accent=0.75; fontFace='EUI-new'; for _,fn in ipairs(looks) do fn() end; Flush()
assert(header.Text.color[1]==0.92,'options heading regained accent')
assert(row.Text.path=='EUI-new' and row.Text.color[3]==0.9)
combat=true; w=fontWrites; module.refresh(); root.Scroll:update(); assert(fontWrites==w)
combat=false; for _,f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f,'PLAYER_REGEN_ENABLED') end end; Flush()
enabled=false; c,r,o,h,w=childReads,regionReads,allocated,hookCount,fontWrites
module.refresh(); Event('Scrap_Config'); root.Scroll:update(); check:SetEnabled(true); Flush()
assert(childReads==c and regionReads==r and allocated==o and hookCount==h and fontWrites==w)
assert(#errors==0,table.concat(errors,'\n'))
Scrap,ScrapVisualizer,ScrapVisualizerScrollBar=nil,nil,nil
print('BENCH Scrap bag/list_updates=1000 hierarchy_reads=0 font_writes=0; warm_options=100 new_UI_objects=0 new_hooks=0')
print('PASS: Scrap lazy modules, merchant native actions/geometry, list qualities/tabs, Sushi pooling/foreign reuse, checks/inputs/expand/menu actions, themes/combat/disable')
