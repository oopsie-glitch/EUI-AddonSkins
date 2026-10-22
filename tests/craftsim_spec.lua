-- CraftSim GGUI lifecycle, native Settings and semantic data preservation.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local menuBindings, dialogStyles=0,0
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'CraftSim'); factory = fn end
ns.RegisterModule = function(id, _, available, install) module = {id=id, available=available, install=install} end
local boundOwners={}
ns.BindPopupOwner=function(_,_,owner)boundOwners[owner]=true end
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
        if self.kind=='Texture'then self.texture='solid'end
    end
    function f:SetVertexColor(r,g,b,a)
        self.vertex=self.vertex or {}; self.vertex[1],self.vertex[2],self.vertex[3],self.vertex[4]=r,g,b,a
    end
    function f:SetGradientAlpha(...) self.gradient={...} end
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
    function f:SetDrawLayer(layer)self.layer=layer end
    function f:IsShown() return self.shown end
    function f:SetShown(v)self.shown=v end
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
        local old=self.scripts[k]; self.scripts[k]=function(...) local result=old and table.pack(old(...)) or {n=0}; fn(...);return table.unpack(result,1,result.n)end
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
local function ModernDropdown(parent,label)
 -- Retail can expose a DropdownButton as Button; SetupMenu is the API contract.
 local f=Object('Button',parent);f.Text=Text(f);f.Text:SetText(label)
 function f:SetupMenu(fn)self.menuInitializer=fn;return 'native-setup'end
 f.Background=f:CreateTexture(nil,'BACKGROUND');f.Background:SetTexture('native-dropdown-background')
 f.Arrow=f:CreateTexture(nil,'ARTWORK');f.Arrow:SetTexture('native-yellow-arrow')
 f.NineSlice=Object('Frame',f);f.NineSlice.edge=f.NineSlice:CreateTexture(nil,'BORDER')
 f.NineSlice.edge:SetTexture('native-dropdown-outline')
 return f
end
local fontObjectReads,fontObjectAssignments=0,0
local nativeFontObject={name='Native pooled FontObject'}
local function GuardSharedFont(f)
 function f:GetFontObject()fontObjectReads=fontObjectReads+1;return nativeFontObject end
 function f:SetFontObject()
  fontObjectAssignments=fontObjectAssignments+1
  error('unsafe native FontObject reassignment on a pooled control')
 end
end
local S = {GetFont=function() return fontFace,'' end, GetAccentColor=function() return accent,0.6,0.8 end,
    GetPanelColor=function() return 0.06,0.06,0.07,0.95 end, OnLooksChanged=function(fn) looks[#looks+1]=fn end}
S.SquareIcon=function(t) t:SetTexCoord(0.08,0.92,0.08,0.92) end
S.Font=function(f,r,g,b) assert(not combat); fontWrites=fontWrites+1;f.fontWrites=(f.fontWrites or 0)+1; f:SetFont(fontFace, f.size, ''); if r then f:SetTextColor(r,g,b,1) end end
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
S.ScrollBar=function(f)
 f.scroll=true
 local thumb=f.Track and f.Track.Thumb or f.GetThumb and f:GetThumb()
 if not thumb then return end
 for _,host in ipairs({f.Track,thumb})do for _,t in ipairs(host.regions)do t:SetAlpha(0)end end
 if not thumb.grip then thumb.grip=thumb:CreateTexture(nil,'ARTWORK');thumb.grip:SetWidth(4)end
 thumb.grip:SetColorTexture(1,1,1,.35);thumb.grip:SetAlpha(1)
end
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
S.Shell=function(f)if not f.shell then f.shell=true;local t=f:CreateTexture(nil,'BACKGROUND');t:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\modern_blizz.png')end end
S.EditBox=function(f) f.input=true end
S.Dropdown=function(f) f.dropdown=true end
S.StateButtonLabel=function(f) f.stateLabel=true end
S.PageButton=function(f,glyph) f.glyph=glyph end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)



CraftSimAPI=nil
assert(loadfile('EUIAddonSkins/Skins/CraftSim.lua'))('EUIAddonSkins',ns)
assert(factory and not module);factory();assert(not module.available())
UIParent=Object('Frame')
local G,CS={},{}
CS.INIT={FRAMES={}};CS.GGUI=G;CS.CONST={FRAMES={MAIN='CraftSimStatistics',POPUP='CraftSimPopup'}}
CS.OPTIONS={Init=function()return 'native-options'end}
CS.CRAFTQ={};CS.SIMULATION_MODE={UI={}}
local dbReads,dataCalls,crafts=0,0,0
CS.DB={OPTIONS={Get=function()dbReads=dbReads+1;return 'native-db'end}}
CS.STATISTICS={UI={Init=function()return 'native-statistics'end,Update=function()dataCalls=dataCalls+1;return 'native-update'end}}
CraftSimAPI={GetCraftSim=function()return CS end}
local function Class(name,constructor)
 local c={}
 function c:new(...)self.isGGUI=true;self.class=c;constructor(self,...)end
 setmetatable(c,{__call=function(_,...)local w=setmetatable({},{__index=c});w:new(...);return w end})
 function c:is(other)return self.class==other end
 function c:Show()self.frame:Show();return 'native-show'end
 function c:SetEnabled(v)if v then self.frame:Enable()else self.frame:Disable()end;return 'native-enabled'end
 G[name]=c;return c
end
Class('Text',function(w,o)w.frame=Text(o.parent);w.frame:SetText(o.text or '');w.text=w.frame end)
Class('Button',function(w,o)
 w.frame=Object('Button',o.parent);w.button=w.frame;w.frame.Text=Text(w.frame);w.frame.Text:SetText(o.label or '')
 w.frame.normal=w.frame:CreateTexture(nil,'ARTWORK');w.frame.normal:SetTexture('native-red-button')
 w.frame.attributes=o.attributes
 w.frame.scripts.OnClick=o.clickCallback or function()crafts=crafts+1;return 'native-craft'end
end)
Class('Frame',function(w,o)
 w.frame=Object('Frame',o.parent or UIParent);w.frame.backdrop={bgFile='black',edgeFile='tooltip-border'}
 w.content=Object('Frame',w.frame);w.frame.content=w.content;w.frameID=o.frameID
 w.title=G.Text{parent=w.frame,text=o.title or 'CraftSim window'}
 w.frame.closeButton=G.Button{parent=w.frame,label=''}
 w.frame.collapseButton=G.Button{parent=w.frame,label=''}
 if o.frameTable then o.frameTable[o.frameID or 'new']=w end
end)
Class('Checkbox',function(w,o)
 w.frame=Object('CheckButton',o.parent);w.frame.checkedArt=w.frame:CreateTexture(nil,'ARTWORK');w.frame.checkedArt:SetTexture('native-check')
 w.frame.disabledArt=w.frame:CreateTexture(nil,'ARTWORK');w.frame.disabledArt:SetTexture('native-disabled')
 w.frame.Text=Text(w.frame);w.frame.Text:SetText('Automatic');w.frame.checked=true
end)
Class('Dropdown',function(w,o)
 w.frame=Object('Frame',o.parent);w.frame.initialize=function()return 'native-list'end
 w.frame.Text=Text(w.frame);w.frame.Text:SetText('Top Profit')
end)
Class('TextInput',function(w,o)
 w.frame=Object('EditBox',o.parent);w.frame.content=o.initialValue or '5';w.frame:SetText(w.frame.content)
 w.frame.scripts.OnTextChanged=function()dataCalls=dataCalls+1 end
end)
Class('Icon',function(w,o)
 w.frame=Object('Button',o.parent);w.frame.Text=Text(w.frame);w.frame.Text:SetText('')
 w.frame.normal=w.frame:CreateTexture(nil,'ARTWORK');w.frame.normal:SetTexture('native-item')
 w.frame.qualityIcon=w.frame:CreateTexture(nil,'OVERLAY');w.frame.qualityIcon:SetTexture('native-quality')
 function w:SetItem(id)self.itemID=id;self.frame.normal:SetTexture('item-'..id);return 'native-item'end
end)
Class('BlizzardTab',function(w,o)
 w.button=Object('Button',o.parent);w.button.Text=Text(w.button);w.button.Text:SetText('Concentration')
 w.content=Object('Frame',o.parent);w.initialTab=o.initialTab
 w.button.scripts.OnClick=function()w.content:Show();return 'native-tab'end
end)
Class('ScrollFrame',function(w,o)
 w.scrollFrame=Object('ScrollFrame',o.parent);w.content=Object('Frame',w.scrollFrame)
 w.scrollBar=Object('Frame',w.scrollFrame);w.scrollBar.Track=Object('Frame',w.scrollBar)
 w.scrollBar.Track.Thumb=Object('Frame',w.scrollBar.Track);w.scrollBar.Track.Thumb.native=w.scrollBar.Track.Thumb:CreateTexture()
 w.scrollBar.Track.native=w.scrollBar.Track:CreateTexture(nil,'BACKGROUND')
 w.scrollBar.Back=Object('Button',w.scrollBar);w.scrollBar.Back.native=w.scrollBar.Back:CreateTexture()
 w.scrollBar.Forward=Object('Button',w.scrollBar);w.scrollBar.Forward.native=w.scrollBar.Forward:CreateTexture()
 if o.accessor then
  w.scrollBar.nativeThumb=w.scrollBar.Track.Thumb;w.scrollBar.Track.Thumb=nil
  if o.accessor=='GetThumb'then function w.scrollBar:GetThumb()return self.nativeThumb end
  else w.scrollBar.Thumb=w.scrollBar.nativeThumb end
 end
 w.borderFrame=Object('Frame',o.parent);w.borderFrame.backdrop={edgeFile='native-border'};w.borderFrame:SetFrameLevel(99)
end)
Class('FrameList',function(w,o)
 if o.reuse then w.frame=o.reuse.frame;w.scrollFrame=o.reuse.scrollFrame;w.rows={};return end
 w.frame=Object('Frame',o.parent);w.rows={};w.rowConstructor=o.rowConstructor
 w.scrollFrame=G.ScrollFrame{parent=w.frame}
 function w:Add(fill)
  local row=self.rows[1]
  if not row then
   local f=Object('Frame',self.scrollFrame.content);row=G.FrameList.Row(f,{},self.rowConstructor,self);self.rows[1]=row
  end
  if fill then fill(row)end
  return row,'native-add'
 end
 function w:UpdateDisplay()dataCalls=dataCalls+1;return 'native-display'end
end)
G.FrameList.Row=Class('Row',function(w,f,columns,constructor,list)
 w.frame=f;w.columns=columns;w.frameList=list
 w.frame.backdrop={bgFile='native-selected'};w.frame.bg={.1,.5,.1,1}
 if constructor then constructor(columns,w)end
end)
-- An existing registry window, with widgets stored on its content as in GGUI.
local pre=G.Frame{parent=UIParent,frameID=CS.CONST.FRAMES.MAIN,frameTable=CS.INIT.FRAMES}
pre.content.check=G.Checkbox{parent=pre.content}
pre.content.action=G.Button{parent=pre.content,label='Scan Recipes'}
pre.content.item=G.Icon{parent=pre.content}
pre.content.tab=G.BlizzardTab{parent=pre.content,initialTab=true}
local profit=G.Text{parent=pre.content,text='|cff00ff00100g|r'};profit.frame.color={.1,.9,.1,1}
local warning=G.Text{parent=pre.content,text='Cannot craft'};warning.frame.color={1,.1,.1,1}
local graph=Object('Frame',pre.content);graph.AddDataSeries=function()dataCalls=dataCalls+1 end
local graphText=Text(graph);graphText:SetText('Graph axes');local graphLine=graph:CreateTexture();graphLine:SetTexture('native-graph-line')
local graphChild=Object('Frame',graph)
pre.content.graph=graph
local initializer={InitFrame=function(_,f)f.nativeInit=true;return 'native-init'end,Resetter=function(_,f)f.nativeReset=true;return 'native-reset'end}
local layout={GetInitializers=function()return {initializer}end}
function layout:AddInitializer()return 'native-new-init'end
local category={};CS.OPTIONS.category=category
SettingsPanel={GetLayout=function(_,c)if c==category then return layout end end,GetCurrentLayout=function()return layout end}
CS.WIDGETS={ContextMenu={Open=function()return 'native-context'end}}
local function MenuFrame()
 local f=Object('Frame',UIParent);f.descriptions={}
 function f:GetOwnerRegion()return self.owner end
 function f:AttachTexture()
  self.fill=self.fill or self:CreateTexture(nil,'BACKGROUND');return self.fill
 end
 function f:EnumerateElementDescriptions(fn)for _,d in ipairs(self.descriptions)do fn(nil,d)end end
 function f:AddCheck(selected)
  local d={initializers={},checkbox=true}
  function d:IsCheckbox()return self.checkbox end
  function d:AddInitializer(fn)self.initializers[#self.initializers+1]=fn end
  local row=Object('Frame',self);row.leftTexture1=row:CreateTexture(nil,'ARTWORK');row.leftTexture1:SetTexture('native-box')
  row.leftTexture2=row:CreateTexture(nil,'ARTWORK');row.leftTexture2:SetTexture('native-tick');row.leftTexture2:SetShown(selected)
  -- Compositor proxies prohibit even looking up SetFont.
  row.Text=setmetatable({}, {__index=function(_,key)assert(key~='SetFont','compositor font access')end})
  function row:GetElementDescription()return d end
  function row:Reinitialize(target)
   self.leftTexture1:SetTexture('native-box');self.leftTexture2:SetTexture('native-tick')
   for _,fn in ipairs(d.initializers)do fn(self,d,target or f)end
  end
  self.descriptions[#self.descriptions+1]=d;return row,d
 end
 return f
end
local menu=MenuFrame();local nativeMenu=menu:CreateTexture(nil,'BACKGROUND')
local checked,checkedDescription=menu:AddCheck(true)
local unchecked=menu:AddCheck(false)
local radio,radioDescription=menu:AddCheck(true)
radioDescription.checkbox=false
function radioDescription:IsRadio()return true end
local customInput=Object('EditBox',unchecked);customInput:SetText('native queue expression')
GuardSharedFont(customInput)
local manager={GetOpenMenu=function(self)return self.list or menu end}
function manager:OpenMenu(owner,list)self.list=list or menu;self.list.owner=owner;self.list:Show();return 'native-open'end
function manager:OpenContextMenu(owner,list)return self:OpenMenu(owner,list)end
Menu={GetManager=function()return manager end}
assert(module.available());module.install(S,module);Flush()
assert(#errors==0,table.concat(errors,'; '))
assert(pre.frame.shell and pre.frame.backdrop==nil)
assert(pre.content.action.frame.Text.path=='EUI')
assert(pre.content.item.frame.normal.alpha==1 and pre.content.item.frame.normal.texture=='native-item')
assert(pre.content.item.frame.qualityIcon.alpha==1)
assert(pre.content.tab.button.tab,'tab role missing: '..tostring(pre.content.tab.button.tab));assert(pre.content.tab.button.scripts.OnClick()=='native-tab')
assert(profit.frame.color[2]==.9 and warning.frame.color[1]==1 and warning.frame.color[2]==.1)
assert(graphText.path=='Native'and graphLine.alpha==1 and not graphChild.walks,'graph data/children were skinned')
assert(dbReads==0 and crafts==0 and dataCalls==0,'skin invoked data or crafting operations')
local gradients=0;for _,t in ipairs(pre.frame.regions)do if t.gradient then gradients=gradients+1 end end
assert(gradients==4,'window lacks lighter centre and darker top/bottom treatment')
-- Construction completion paints only owned new widgets.
local input=G.TextInput{parent=pre.content,initialValue='12'};assert(input.frame.content=='12'and input.frame.path=='EUI')
local dynamic=G.Button{parent=pre.content,label='Equip'};assert(dynamic.frame.Text.path=='EUI')
assert(dynamic.frame.scripts.OnClick()=='native-craft'and crafts==1)
local foreign=G.Frame{parent=UIParent};local foreignButton=G.Button{parent=foreign.content,label='Foreign'}
assert(not foreign.frame.shell and foreignButton.frame.Text.path=='Native')
local list=G.FrameList{parent=pre.content,rowConstructor=function(_,row)
 row.text=G.Text{parent=row.frame,text='Profit'};row.button=G.Button{parent=row.frame,label='Craft'}
end};pre.content.list=list
local row,ret=list:Add();assert(ret=='native-add'and row.text.frame.path=='EUI')
assert(row.frame.bg[2]==.5,'native row selection colour changed')
local a,h,w,c,r=allocated,hookCount,fontWrites,childReads,regionReads
for _=1,1000 do
 list:Add(function(item)item.text.frame:SetText('Updated profit')end)
 list:UpdateDisplay();CS.STATISTICS.UI:Update()
end
assert(allocated==a and hookCount==h and fontWrites==w and childReads==c and regionReads==r,'data updates triggered skin scans or allocations')
assert(dataCalls==2000)
local sharedRow=Object('Frame',UIParent)
local sharedScroll=G.ScrollFrame{parent=sharedRow,accessor='GetThumb'}
sharedRow.Checkbox=Object('CheckButton',sharedRow);sharedRow.Checkbox.checkedArt=sharedRow.Checkbox:CreateTexture(nil,'ARTWORK');sharedRow.Checkbox.checkedArt:SetTexture('native-tick');sharedRow.Checkbox.checked=true
sharedRow.Text=Text(sharedRow);sharedRow.Text:SetText('Show profit')
GuardSharedFont(sharedRow.Text)
sharedRow.Dropdown=Object('DropdownButton',sharedRow);sharedRow.Dropdown.Text=Text(sharedRow.Dropdown)
sharedRow.Dropdown.scripts.OnMouseDown=function()menu.owner=sharedRow.Dropdown;menu:Show();return 'native-settings-dropdown'end
function menu:GetOwnerRegion()return self.owner end
assert(initializer:InitFrame(sharedRow)=='native-init')
assert(sharedRow.Checkbox.checkedArt.alpha==0 and sharedRow.Text.path=='Native','shared Settings font must remain native')
assert(sharedScroll.scrollBar.nativeThumb.native.alpha==0 and sharedScroll.scrollBar.Track.native.alpha==0)
assert(sharedRow.Dropdown.scripts.OnMouseDown()=='native-settings-dropdown'and nativeMenu.alpha==0)
menu:Hide();assert(nativeMenu.alpha==1)
local checkHost=sharedRow.Checkbox.children[1];assert(checkHost and checkHost.mark.color[1]==accent)
enabled=false;assert(initializer:Resetter(sharedRow)=='native-reset')
assert(sharedRow.Checkbox.checkedArt.alpha==1 and sharedRow.Text.path=='Native'and not checkHost.shown)
assert(sharedScroll.scrollBar.nativeThumb.native.alpha==1 and sharedScroll.scrollBar.Track.native.alpha==1,'pooled scrollbar art not restored')
sharedRow.Checkbox:SetChecked(false);assert(not checkHost.shown)
enabled=true;initializer:InitFrame(sharedRow);assert(checkHost.shown)
local objs,hooks=allocated,hookCount
for _=1,100 do initializer:Resetter(sharedRow);initializer:InitFrame(sharedRow)end
assert(allocated==objs and hookCount==hooks,'Settings row recycling duplicated objects/hooks')
local nc,nr=childReads,regionReads
for _=1,100 do for _,f in ipairs(events)do if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f,'ADDON_LOADED','Foreign')end end end
assert(childReads==nc and regionReads==nr,'unrelated addon load scanned windows')
assert(CS.WIDGETS.ContextMenu.Open()=='native-context'and nativeMenu.alpha==0)
menu:Hide();assert(nativeMenu.alpha==1)
assert(not boundOwners[UIParent],'global UIParent menu owner was registered')
fontFace='NewEUI';accent=.8;module.refresh();Flush()
assert(dynamic.frame.Text.path=='NewEUI'and checkHost.mark.color[1]==.8)
combat=true;local during=G.Button{parent=pre.content,label='During combat'};assert(during.frame.Text.path=='Native')
combat=false;module.refresh();assert(during.frame.Text.path=='NewEUI')
enabled=false;local disabled=G.Button{parent=pre.content,label='Disabled skin'};assert(disabled.frame.Text.path=='Native')
enabled=true;module.refresh();assert(disabled.frame.Text.path=='NewEUI')
assert(dbReads==0 and crafts==1 and dataCalls==2000)
assert(#errors==0,table.concat(errors,'; '))
print('PASS: CraftSim registry, owned GGUI construction/rows/tabs/icons, native data/graphs/actions, Settings pool cleanup, menus, themes and combat/disabled guards')
print('BENCH CraftSim 1000 row data/display/module update cycles: skin hierarchy_reads=0 font_writes=0 new_UI_objects=0 new_hooks=0 (mock)')
-- Warm windows and completed tab changes must not rediscover other modules.
pre.frame:Show();pre.frame:Show()
local a2,h2,w2,c2,r2=allocated,hookCount,fontWrites,childReads,regionReads
for _=1,1000 do pre.frame:Show();pre.content.tab.content:Hide();pre.content.tab.content:Show()end
assert(allocated==a2 and hookCount==h2 and fontWrites==w2 and childReads==c2 and regionReads==r2,'warm window/tab paths scanned or allocated')
assert(pre.content.tab.button.selected==true)
local c3,r3=childReads,regionReads
assert(pre.content.item:SetItem(42)=='native-item')
assert(pre.content.item.frame.normal.texture=='item-42'and pre.content.item.frame.normal.coords[1]==.08)
assert(childReads==c3 and regionReads==r3,'item update scanned a hierarchy')
local protected=Object('Button',pre.content);protected.protected=true;protected.Text=Text(protected)
local attributes={type1='macro',macrotext='/cast Craft'}
local macro=G.Button{parent=pre.content,label='Craft',attributes=attributes}
module.refresh();assert(protected.Text.path=='Native'and macro.frame.attributes==attributes)
local newWindow=G.Frame{parent=UIParent,frameTable=CS.INIT.FRAMES,frameID='NewCraftSimModule'}
local newCheck=G.Checkbox{parent=newWindow.content}
assert(newWindow.frame.shell and newCheck.frame.checkedArt.alpha==0)
assert(foreignButton.frame.Text.path=='Native')
assert(#errors==0,table.concat(errors,'; '))
print('BENCH CraftSim 1000 warm window/tab cycles: hierarchy_reads=0 font_writes=0 new_UI_objects=0 new_hooks=0 (mock)')
print('PASS: icon refresh stays local; protected/macro actions, lazy registry windows and foreign GGUI controls remain isolated')

local beforeFont=fontWrites
for _=1,500 do dynamic.frame.scripts.OnEnter(dynamic.frame);dynamic.frame.scripts.OnLeave(dynamic.frame)end
assert(fontWrites==beforeFont,'unchanged hover rewrote fonts')
dynamic.frame.Text:SetFontObject();assert(dynamic.frame.Text.path=='NewEUI','native label font reset was not repaired')
assert(#errors==0,table.concat(errors,'; '))
print('PASS: shared Settings dropdown ownership/restoration and local hover/font-object repair')

-- Raised scroll/quality outlines must not receive an opaque covering panel.
local border=list.scrollFrame.borderFrame
pre.frame:Show()
assert(border.level==99 and border.backdrop==nil and #border.regions==0,'raised border got a fill over queue rows')
assert(row.frame.bg[2]==.5 and row.text.frame:GetAlpha()==1,'queue selection/data were obscured')
local transparent=Object('Frame',pre.content)
transparent.backdrop={bgFile='white',edgeFile='border'};transparent.bg={1,1,1,0}
module.refresh();assert(transparent.backdrop.bgFile=='white'and transparent.backdrop.edgeFile==nil and transparent.bg[4]==0 and #transparent.regions==0,'transparent border acquired an opaque fill')
local filled=Object('Frame',pre.content);filled.backdrop={bgFile='white',edgeFile='border'}
module.refresh();assert(#filled.regions==0 and filled.backdrop.bgFile=='white'and filled.bg[4]==1,'generic panel acquired skin art or lost native fill')

-- Both MinimalScrollBar accessors and direct-thumb fallback retain native hit areas.
for _,accessor in ipairs({'Track','GetThumb','Thumb'})do
 local scroll=G.ScrollFrame{parent=pre.content,accessor=accessor~='Track'and accessor or nil}
 local bar=scroll.scrollBar;local thumb=bar.Track.Thumb or bar.nativeThumb
 local tw,th,bw,bh=thumb.width,thumb.height,bar.width,bar.height
 assert(thumb.native.alpha==0 and bar.Track.native.alpha==0,'native scrollbar art survived '..accessor)
 assert(tw==16 and th==20 and bw==16 and bh==20,'scrollbar hit area resized')
 local up,down
 for _,t in ipairs(bar.Back.regions)do if t.rotation then up=t end end
 for _,t in ipairs(bar.Forward.regions)do if t.rotation then down=t end end
 assert(up and up.rotation==math.pi and down and down.rotation==0,'vertical scrollbar arrows point sideways')
 local before=allocated;module.refresh();assert(allocated==before,'scrollbar refresh duplicated UI objects')
 assert(thumb.width==tw and thumb.height==th and bar.width==bw and bar.height==bh)
end

-- Modern menu markers repaint on native row initialization without touching fonts/state.
manager:OpenMenu(dynamic.frame,menu)
assert(checked.leftTexture1.width==12 and checked.leftTexture2.width==7)
assert(checked.leftTexture2.shown and not unchecked.leftTexture2.shown,'skin changed native checked visibility')
assert(checked.leftTexture2.color[1]==accent and checked.leftTexture1.texture=='solid')
assert(radio.leftTexture1.width==12 and radio.leftTexture2.width==7 and radio.leftTexture2.shown)
assert(customInput.path=='Native'and customInput.text=='native queue expression','embedded menu input font/value changed')
assert(#customInput.regions>=5,'embedded menu input lacks texture styling')
checked:Reinitialize();assert(checked.leftTexture1.texture=='solid'and checked.leftTexture2.texture=='solid')
local na,nh=allocated,hookCount
for _=1,100 do manager:OpenMenu(dynamic.frame,menu);checked:Reinitialize()end
assert(allocated==na and hookCount==nh and #checkedDescription.initializers==1,'menu reuse duplicated hooks/layers')
local sub=MenuFrame();local subcheck=sub:AddCheck(true)
checked:Reinitialize(sub)
-- The inherited initializer paints its target row, including ownerless submenus.
for _,fn in ipairs(checkedDescription.initializers)do fn(subcheck,checkedDescription,sub)end
assert(subcheck.leftTexture1.texture=='solid'and subcheck.leftTexture2.width==7)
sub:Hide();menu:Hide()
assert(checked.leftTexture1.texture=='native-box'and checked.leftTexture1.width==16)
assert(customInput.path=='Native','embedded menu input not restored')
assert(checked.leftTexture2.texture=='native-tick'and checked.leftTexture2.shown)
manager:OpenMenu(foreignButton.frame,menu)
assert(nativeMenu.alpha==1 and checked.leftTexture1.texture=='native-box','foreign menu reuse inherited styling')
menu:Hide();combat=true;manager:OpenMenu(dynamic.frame,menu)
assert(nativeMenu.alpha==1 and checked.leftTexture1.texture=='native-box');menu:Hide();combat=false
enabled=false;manager:OpenMenu(dynamic.frame,menu);assert(nativeMenu.alpha==1);menu:Hide();enabled=true

-- Non-registry list dialogs and composite GGUI controls are covered lazily.
for _,id in ipairs({'CRAFT_LIST_NAME_POPUP','CRAFT_LIST_IMPORT_POPUP'})do
 local popup=G.Frame{parent=UIParent,frameID=id}
 local text=G.TextInput{parent=popup.content,initialValue='keep native list string'}
 local check=G.Checkbox{parent=popup.content}
 local nativeInput=Object('EditBox',popup.content);nativeInput:SetText('native appended input')
 popup.frame:Show()
 assert(popup.frame.shell and text.frame.path==fontFace and check.frame.checkedArt.alpha==0)
 assert(text.frame.text=='keep native list string')
 assert(nativeInput.path==fontFace and nativeInput.text=='native appended input','first show missed appended controls')
end

local nested=Object('Frame',pre.content);local lateNative=Object('CheckButton',nested)
lateNative.checkedArt=lateNative:CreateTexture();lateNative.checkedArt:SetTexture('late-check')
CS.STATISTICS.UI:Init();Flush()
assert(lateNative.checkedArt.alpha==0,'completed UI initialization missed nested native controls')

-- Remaining composite constructors used by modules retain their values/actions.
Class('SpellIcon',function(w,o)
 w.frame=Object('Button',o.parent);w.frame.normal=w.frame:CreateTexture();w.frame.normal:SetTexture('native-spell')
end)
Class('ScrollingMessageFrame',function(w,o)
 w.frame=Object('ScrollingMessageFrame',o.parent);w.frame.message='|cff00ff00Crafted item|r'
 w.scrollBar=Object('Frame',w.frame);w.scrollBar.Track=Object('Frame',w.scrollBar)
 w.scrollBar.Track.Thumb=Object('Frame',w.scrollBar.Track);w.scrollBar.Track.Thumb.native=w.scrollBar.Track.Thumb:CreateTexture()
end)
Class('ItemSelector',function(w,o)
 w.icon=G.Icon{parent=o.parent};w.button=w.icon.frame
 w.selectionFrame=G.Frame{parent=o.parent}
end)
for _,name in ipairs({'CheckboxSelector','FilterButton'})do
 Class(name,function(w,o)w.frame=ModernDropdown(o.parent,o.label or name)end)
end
module.refresh()
local spell=G.SpellIcon{parent=pre.content};assert(spell.frame.normal.coords[1]==.08 and spell.frame.normal.alpha==1)
local log=G.ScrollingMessageFrame{parent=pre.content}
assert(log.frame.path==fontFace and log.frame.message=='|cff00ff00Crafted item|r'and log.scrollBar.Track.Thumb.native.alpha==0)
local selector=G.ItemSelector{parent=pre.content}
assert(selector.selectionFrame.frame.shell and selector.icon.frame.normal.alpha==1)
for _,name in ipairs({'CheckboxSelector','FilterButton'})do
 local control=G[name]{parent=pre.content}
 assert(control.frame.Background.alpha==0 and control.frame.Arrow.alpha==0 and control.frame.NineSlice.edge.alpha==0)
 assert(manager:OpenContextMenu(control.frame,menu)=='native-open')
 assert(nativeMenu.alpha==0 and checked.leftTexture1.texture=='solid');menu:Hide()
end

-- Shared text export restores native cosmetics on foreign reuse, even disabled.
CS.UTIL={ShowTextCopyBox=function(_,text)
 if not KethoEditBox then
  KethoEditBox=Object('Frame',UIParent);KethoEditBox.backdrop={bgFile='dialog',edgeFile='border'}
  KethoEditBoxEditBox=Object('EditBox',KethoEditBox)
  function KethoEditBoxEditBox:IsMultiLine()return true end
  KethoEditBoxEditBox.path='NativeExportFont'
  GuardSharedFont(KethoEditBoxEditBox)
  KethoEditBox.scroll=Object('Slider',KethoEditBox);KethoEditBox.scroll.thumb=KethoEditBox.scroll:CreateTexture()
 end
 KethoEditBoxEditBox:SetText(text);KethoEditBoxEditBox:HighlightText();KethoEditBox:Show()
 return 'native-export',text
end}
module.refresh()
local export,value=CS.UTIL:ShowTextCopyBox('exact export data')
assert(export=='native-export'and value=='exact export data')
assert(KethoEditBox.backdrop==nil and KethoEditBox.scroll.thumb.alpha==0)
assert(KethoEditBoxEditBox.path=='NativeExportFont'and KethoEditBoxEditBox.text=='exact export data'and KethoEditBoxEditBox.selections==1)
local ea,eh=allocated,hookCount
for _=1,100 do CS.UTIL:ShowTextCopyBox('exact export data')end
assert(allocated==ea and hookCount==eh,'export reuse duplicated UI objects/hooks')
enabled=false;KethoEditBox:Show()
assert(KethoEditBox.backdrop.bgFile=='dialog'and KethoEditBox.scroll.thumb.alpha==1,'foreign export did not restore')
enabled=true;CS.UTIL:ShowTextCopyBox('last export');KethoEditBox:Hide()
assert(KethoEditBox.backdrop.bgFile=='dialog'and KethoEditBox.scroll.thumb.alpha==1)
assert(#errors==0,table.concat(errors,'; '))
print('PASS: raised transparent queue/quality borders, three scrollbar variants, vertical arrows, managed menu checks/submenus/reuse, craft-list popups and shared exports')

-- A list border may look like a filled panel before its wrapper is known.
-- No fill may be created even BEFORE its wrapper becomes available; later
-- structural classification and theme changes must keep that invariant.
local lateContainer=Object('Frame',pre.content)
local lateScroll=Object('ScrollFrame',lateContainer)
local lateBorder=Object('Frame',lateContainer);lateBorder:SetFrameLevel(99)
lateBorder.backdrop={bgFile='template-white',edgeFile='template-border'}
local lateRow=Object('Frame',lateScroll);local lateText=Text(lateRow);lateText:SetText('Visible queued recipe')
module.refresh()
assert(#lateBorder.regions==0,'generic discovery created a covering fill before wrapper discovery')
local completedList=G.FrameList{parent=pre.content,reuse={frame=lateContainer,scrollFrame={scrollFrame=lateScroll}}}
assert(#lateBorder.regions==0 and lateBorder.backdrop==nil,'late list border retained covering skin texture')
module.refresh();module.refresh()
assert(#lateBorder.regions==0 and lateRow.alpha==1 and lateText.alpha==1 and lateText.text=='Visible queued recipe')
assert(lateBorder.level==99 and lateScroll:GetFrameLevel()==4,'fix changed native list stacking')
assert(filled.backdrop.bgFile=='white'and filled.bg[4]==1,'ordinary panel background was removed')

HelpPlate=Object('Frame',pre.content);HelpPlate.backdrop={bgFile='tutorial-shade',edgeFile='tutorial-glow'}
local tutorialText=Text(HelpPlate);tutorialText:SetText('Queued recipes are listed here')
local tutorialChild=Object('Frame',HelpPlate)
module.refresh()
assert(HelpPlate.backdrop.bgFile=='tutorial-shade'and #HelpPlate.regions==1)
assert(tutorialText.path=='Native'and not tutorialChild.walks,'shared tutorial overlay was adopted as skin content')
assert(#errors==0,table.concat(errors,'; '))
print('PASS: generic list discovery cannot create covering fills before or after wrapper discovery; shared tutorial overlays stay native')

-- Cross-window decoration policy: test layered anonymous frames with native
-- data art at several levels/opacities, rather than assuming every backdrop
-- is a panel. These shapes occur in scans, pricing, logs and simulation UIs.
local decorations={}
for _,level in ipairs({5,50,200})do
 for _,alpha in ipairs({0,.5,1})do
  local f=Object('Frame',pre.content);f:SetFrameLevel(level)
  local sourceBackdrop={bgFile='native-fill',edgeFile='native-outline',edgeSize=16,tile=true}
  f.backdrop=sourceBackdrop;f.bg={.12,.24,.36,alpha};f:SetSize(300,160);f:SetPoint('TOPLEFT',pre.content,'TOPLEFT',10,-15)
  local semantic=f:CreateTexture(nil,'ARTWORK');semantic:SetTexture('native-result-status')
  local value=Text(f);value:SetText('|cff00ff00Native result|r')
  f.scripts.OnMouseDown=function()return 'native-select'end
  decorations[#decorations+1]={frame=f,source=sourceBackdrop,semantic=semantic,value=value,alpha=alpha,level=level}
 end
end
local editable=G.TextInput{parent=pre.content,initialValue='100'}
local invalid=Object('Frame',editable.frame)
local validationBackdrop={edgeFile='native-validation',edgeSize=25}
invalid.backdrop=validationBackdrop;invalid:SetSize(45,32);invalid:SetFrameLevel(200)
function invalid:SetValid(valid)
 self:SetShown(not valid);if not valid then self:SetBackdropBorderColor(1,0,0,.5)end
end
invalid:SetValid(false)
local quality=Object('Frame',pre.content)
local progress=Object('StatusBar',quality);progress.value=75;progress.minimum=0;progress.maximum=100
progress.fill=progress:CreateTexture(nil,'ARTWORK');progress.fill:SetTexture('native-quality-fill')
progress.fill:SetVertexColor(.2,.8,.1,1)
local qualityOutline=Object('Frame',quality);qualityOutline.backdrop={edgeFile='native-quality-outline'}
qualityOutline:SetFrameLevel(100)
for _=1,3 do module.refresh()end
for _,entry in ipairs(decorations)do
 local f=entry.frame
 assert(#f.regions==2,'anonymous frame acquired new background layers')
 assert(f.backdrop.bgFile=='native-fill'and f.backdrop.edgeFile==nil)
 assert(entry.source.edgeFile=='native-outline'and entry.source.edgeSize==16,'shared native backdrop table was mutated')
 assert(f.bg[1]==.12 and f.bg[2]==.24 and f.bg[3]==.36 and f.bg[4]==entry.alpha and f:GetFrameLevel()==entry.level)
 assert(f.width==300 and f.height==160 and f.point[4]==10 and f.point[5]==-15)
 assert(entry.semantic.texture=='native-result-status'and entry.semantic.alpha==1)
 assert(entry.value.text=='|cff00ff00Native result|r'and entry.value.alpha==1)
 assert(f.scripts.OnMouseDown()=='native-select')
end
assert(invalid.backdrop==validationBackdrop and invalid.shown and invalid.edge[1]==1 and invalid.edge[4]==.5)
assert(#invalid.regions==0 and invalid.width==45 and invalid.height==32,'validation marker covered the numeric input')
invalid:SetValid(true);assert(not invalid.shown);invalid:SetValid(false);assert(invalid.shown)
assert(editable.frame.text=='100'and progress.value==75 and progress.minimum==0 and progress.maximum==100)
assert(progress.fill.texture=='native-quality-fill'and progress.fill.alpha==1 and progress.fill.vertex[2]==.8)
assert(#qualityOutline.regions==0 and qualityOutline.backdrop==nil)
assert(#errors==0,table.concat(errors,'; '))
print('PASS: anonymous decorations at nine level/opacity combinations add no skin fills; native data art, hit targets, validation errors and quality-meter values stay intact')

-- The four reported controls share SetupMenu but need not report their object
-- type as DropdownButton. Raw control-panel/sort buttons and GGUI selectors
-- must receive the same styling without replacing native menus or geometry.
local modernControls={}
for _,label in ipairs({'CraftSim 27.0.7','Expansion Filter','Simulate Buffs','Sort By'})do
 local f=ModernDropdown(pre.content,label);f:SetSize(180,25);f:SetPoint('TOPLEFT',pre.content,'TOPLEFT',20,-30)
 f:SetupMenu(function()return 'native-configuration'end)
 f.scripts.OnClick=function()
  manager:OpenMenu(UIParent,menu);return 'native-dropdown-action',label
 end
 modernControls[#modernControls+1]=f
end
module.refresh()
for _,f in ipairs(modernControls)do
 assert(f.Background.alpha==0 and f.Arrow.alpha==0 and f.NineSlice.edge.alpha==0,'modern template art survived')
 assert(f.width==180 and f.height==25 and f.point[4]==20 and f.point[5]==-30,'dropdown geometry changed')
 assert(f.Text.path==fontFace and f.menuInitializer()=='native-configuration')
 local result,label=f.scripts.OnClick(f)
 assert(result=='native-dropdown-action'and label==f.Text.text and nativeMenu.alpha==0,'owned UIParent context not styled synchronously')
 menu:Hide();assert(nativeMenu.alpha==1)
 f:Disable();assert(f.Text.color[1]==.5);f:Enable();assert(f.Text.color[1]==.92)
 -- Native templates can reset their art on interaction; local repaint wins.
 f.Background:SetAlpha(1);f.Arrow:SetAlpha(1);f.NineSlice.edge:SetAlpha(1)
 f.scripts.OnEnter(f)
 assert(f.Background.alpha==0 and f.Arrow.alpha==0 and f.NineSlice.edge.alpha==0)
end
local foreignModern=ModernDropdown(foreign.content,'Foreign modern selector')
module.refresh();assert(foreignModern.Background.alpha==1 and foreignModern.Arrow.alpha==1)
manager:OpenMenu(UIParent,menu)
assert(nativeMenu.alpha==1,'unrelated UIParent menu was adopted')
modernControls[1]:Enable();modernControls[1].scripts.OnEnter(modernControls[1])
assert(nativeMenu.alpha==1,'state/hover update adopted an unrelated UIParent menu');menu:Hide()

-- Warm before measuring. Native menu contents may be restyled, but no owned
-- windows/lists may be traversed or UI/hook/font resources recreated.
for _,f in ipairs(modernControls)do f.scripts.OnClick(f);menu:Hide()end
local ma,mh,mw=allocated,hookCount,fontWrites
local function ButtonFontWrites()
 local total=0;for _,f in ipairs(modernControls)do total=total+(f.Text.fontWrites or 0)end;return total
end
local buttonWrites=ButtonFontWrites()
local pw,lw,nw=pre.frame.walks,list.frame.walks,newWindow.frame.walks
local priorData,priorDB,priorCrafts=dataCalls,dbReads,crafts
for _=1,250 do
 for _,f in ipairs(modernControls)do
  f:Disable();f:Enable();f.scripts.OnEnter(f);f.scripts.OnLeave(f)
  f.scripts.OnClick(f);menu:Hide()
 end
end
assert(allocated==ma and hookCount==mh and ButtonFontWrites()==buttonWrites,'modern dropdown interaction duplicated UI/hooks/button fonts')
assert(pre.frame.walks==pw and list.frame.walks==lw and newWindow.frame.walks==nw,'dropdown callback scanned addon windows')
assert(dataCalls==priorData and dbReads==priorDB and crafts==priorCrafts,'skin performed data/crafting operations')
local pooledFontWrites=fontWrites-mw
assert(pooledFontWrites==0,'pooled menu input fonts were modified')
enabled=false;local off=ModernDropdown(pre.content,'Disabled skin');module.refresh();assert(off.Background.alpha==1)
enabled=true;combat=true;local locked=ModernDropdown(pre.content,'Combat');module.refresh();assert(locked.Background.alpha==1)
combat=false;module.refresh();assert(off.Background.alpha==0 and locked.Background.alpha==0)
assert(#errors==0,table.concat(errors,'; '))
print('BENCH CraftSim 1000 modern dropdown state/hover/menu cycles: owned_window_scans=0 button_font_writes=0 new_UI_objects=0 new_hooks=0; pooled_menu_font_writes='..pooledFontWrites..' (mock; shared fonts remain native)')
print('PASS: SetupMenu Button variants, four dropdowns, native actions/geometry/disabled state, synchronous UIParent context ownership, foreign isolation and combat deferral')
assert(fontObjectReads==0 and fontObjectAssignments==0,'pooled font-object inheritance was touched')
assert(customInput.path=='Native'and sharedRow.Text.path=='Native')
print('PASS: pooled menu/Settings inputs perform zero GetFontObject/SetFontObject operations across menu reinitialization, reuse, theme changes and release')
