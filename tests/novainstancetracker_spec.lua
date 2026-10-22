-- Nova Instance Tracker custom logs and reversible Ace options.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local menuBindings, dialogStyles=0,0
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local geometryWrites=0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'NovaInstanceTracker'); factory = fn end
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
    function f:SetFontObject() error('borrowed FontObject assignment') end
    function f:GetFontObject() error('borrowed FontObject access') end
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
    function f:SetText(v) self.text=v end
    function f:SetPoint(...) geometryWrites=geometryWrites+1; self.point={...} end
    function f:ClearAllPoints() geometryWrites=geometryWrites+1;self.point=nil end
    function f:SetAllPoints(p) self.anchor=p end
    function f:SetFrameLevel(v) self.level=v end
    function f:GetFrameLevel() return self.level or 4 end
    function f:EnableMouse(v) self.mouse=v end
    function f:SetWidth(v) self.width=v end
    function f:SetHeight(v) self.height=v end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:SetSize(w,h) geometryWrites=geometryWrites+1;self.width,self.height=w,h end
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


assert(loadfile('EUIAddonSkins/Skins/NovaInstanceTracker.lua'))('EUIAddonSkins',ns)
NIT=nil
assert(factory and not module)
local before=allocated;factory();assert(not module.available() and allocated==before)
NIT={}
UIParent=Object('Frame')
local gui={Release=function(_,widget) widget:OnRelease();return 'native-release'end}
local dialog={OpenFrames={},BlizOptions={NovaInstanceTracker={}}}
function dialog:FeedGroup(id,_,container)self.feeds=(self.feeds or 0)+1;return 'native-feed',container,id end
function dialog:AddToBlizOptions()return 'native-add'end
LibStub=function(id,silent)
 assert(silent)
 if id=='AceConfigDialog-3.0'then return dialog elseif id=='AceGUI-3.0'then return gui end
end

local function Button(parent,name,label)
 local f=CreateFrame('Button',name,parent);f.Text=Text(f);f.Text:SetText(label or 'Action')
 f.normal=f:CreateTexture(nil,'ARTWORK');f.normal:SetTexture('native-button');return f
end
NITInstanceFrame=CreateFrame('ScrollFrame','NITInstanceFrame',UIParent)
local editor=NITInstanceFrame
editor.backdrop={bgFile='native',edgeFile='native-border'}
editor.EditBox=Object('EditBox',editor);editor.EditBox.IsMultiLine=function()return true end
editor.EditBox.text='trade/instance data remains';editor.EditBox.scripts.OnHyperlinkClick=function()return 'native-link'end
editor.fs=Text(editor);editor.fs:SetText('|cFFFF6900NovaInstanceTracker v2.31|r')
editor.legend=editor:CreateTexture(nil,'ARTWORK');editor.legend:SetColorTexture(1,0,0,1)
editor.ScrollBar=Object('Slider',editor);editor.ScrollBar.thumb=editor.ScrollBar:CreateTexture(nil,'ARTWORK')
editor.ScrollBar.thumb:SetSize(20,30)
editor.CloseButton=Button(editor,'NITInstanceFrameClose');editor.CloseButton.scripts.OnClick=function()return 'native-close'end
local actionButton=Button(editor,'NITInstanceFrameRestedButton','Your Characters')
actionButton.scripts.OnClick=function()return 'native-characters'end
local nativeCheck=CreateFrame('CheckButton','NITInstanceFramePvpButton',editor.EditBox)
nativeCheck:SetSize(20,20);nativeCheck.Text=Text(nativeCheck)
nativeCheck.checkedArt=nativeCheck:CreateTexture(nil,'ARTWORK');nativeCheck.disabledArt=nativeCheck:CreateTexture(nil,'ARTWORK')
nativeCheck.scripts.OnClick=function()nativeCheck.checked=not nativeCheck.checked;return 'native-check'end
NIT.instanceFrameSelectAltMenu=CreateFrame('Frame','NITSelectAlt',editor)
NIT.instanceFrameSelectAltMenu.initialize=function()return 'native-alt-menu'end
local dataUpdates=0
NIT.recalcInstanceLineFrames=function()dataUpdates=dataUpdates+1;return 'native-tick'end
editor.scripts.OnUpdate=function()return NIT:recalcInstanceLineFrames()end
NIT.openInstanceLogFrame=function()editor:Show();return 'native-open'end
NIT.createInstanceLineFrame=function(_,id)
 local name=tostring(id)..'NITInstanceLine'
 if _G[name]then return 'native-row',_G[name]end
 local f=CreateFrame('Button',name,editor.EditBox);f.fs=Text(f);f.fs.color={1,.4,.1,1}
 f.fs:SetText('|cff00ff00[Realm]|r Character: XP 123')
 f.texture=f:CreateTexture(nil,'ARTWORK');f.texture:SetColorTexture(.1,.8,.1,.2)
 f.tooltip=Object('Frame',editor);f.tooltip.fs=Text(f.tooltip)
 f.removeButton=Button(f,name..'RB');f.removeButton.scripts.OnClick=function()return 'native-delete'end
 f.scripts.OnClick=function()return 'native-post-stats'end
 return 'native-row',f
end
NIT.createTitleInstanceLineFrame=function()
 if not titleNITInstanceLine then
  titleNITInstanceLine=CreateFrame('Frame','titleNITInstanceLine',editor.EditBox)
  titleNITInstanceLine.fs=Text(titleNITInstanceLine)
  titleNITInstanceLine.fs:SetText('|cffffff00Last hour: 0|r')
 end
 return 'native-title'
end
NIT.createSimpleScrollFrame=function(_,name)
 local f=CreateFrame('Frame',name,UIParent);f.close=Button(f,name..'Close')
 f.scrollChild=Object('Frame',f);f.scrollChild.fs=Text(f.scrollChild)
 return f,'native-second-return'
end
NIT.createLevelLogFrame=function()
 local f=CreateFrame('Frame','NITLevelLogFrame',UIParent);f.simpleLineFrames={};f.scrollChild=Object('Frame',f)
 f.createSimpleLineFrame=function(count)
  if not f.simpleLineFrames[count]then
   local row=Object('Button',f.scrollChild);row.fs=Text(row)
   row.borderFrame=Object('Frame',row);row.borderFrame.backdrop={edgeFile='decorative'}
   row.scripts.OnClick=function()return 'native-level-details'end
   f.simpleLineFrames[count]=row
  end
 end
 return f
end
assert(module.available());module.install(S,module);Flush()
assert(editor.backdrop==nil and editor.legend.alpha==1 and editor.legend.color[1]==1)
assert(editor.fs.path==fontFace and editor.fs.text=='|cFFFF6900NovaInstanceTracker v2.31|r')
assert(editor.EditBox.text=='trade/instance data remains'and editor.EditBox.scripts.OnHyperlinkClick()=='native-link')
assert(editor.CloseButton.close and editor.CloseButton.scripts.OnClick()=='native-close')
assert(actionButton.button and actionButton.scripts.OnClick()=='native-characters')
assert(nativeCheck.width==20 and nativeCheck.checkedArt.width==10 and nativeCheck.scripts.OnClick()=='native-check')
assert(boundOwners[NIT.instanceFrameSelectAltMenu])
local ret,row=NIT:createInstanceLineFrame(1)
assert(ret=='native-row'and row.fs.path==fontFace and row.texture.alpha==1 and row.fs.color[1]==1)
assert(row.scripts.OnClick()=='native-post-stats'and row.removeButton.close and row.removeButton.scripts.OnClick()=='native-delete')
assert(row.tooltip.fs.path==fontFace)
local lockouts,ret=NIT:createSimpleScrollFrame('NRCLockoutsFrame')
assert(ret=='native-second-return'and lockouts.backdrop==nil and lockouts.close.close)
local level=NIT:createLevelLogFrame();level.createSimpleLineFrame(1)
assert(level.simpleLineFrames[1].fs.path==fontFace and level.simpleLineFrames[1].borderFrame.backdrop==nil)
assert(level.simpleLineFrames[1].scripts.OnClick()=='native-level-details')
local fontChildren,fontRegions=childReads,regionReads
editor.fs:SetFont('Native',14,'')
assert(editor.fs.path==fontFace and childReads==fontChildren and regionReads==fontRegions,'title reset triggered a scan or lost theme font')
local c,r,o,h,w=childReads,regionReads,allocated,hookCount,fontWrites
for _=1,1000 do assert(editor.scripts.OnUpdate()=='native-tick')end
assert(dataUpdates==1000 and childReads==c and regionReads==r and allocated==o and hookCount==h and fontWrites==w)
local function Widget(kind,parent)
    local w={type=kind,frame=Object('Frame',parent),children={}}
    w.frame.obj=w; w.OnRelease=function(self) self.releases=(self.releases or 0)+1 end
    return w
end
local root=Widget('BlizOptionsGroup',UIParent)
dialog.BlizOptions.NovaInstanceTracker.settings=root
local check=Widget('CheckBox',root.frame); root.children={check}
check.checkbg=check.frame:CreateTexture(nil,'BACKGROUND'); check.checkbg:SetTexture('native-check-bg'); check.checkbg:SetSize(24,24)
check.check=check.frame:CreateTexture(nil,'ARTWORK'); check.check:SetTexture('native-tick'); check.check:SetSize(24,24)
check.SetValue=function(self,value) self.checked=value; return 'native-value' end
check.SetDisabled=function(self,value) self.disabled=value; return 'native-disabled' end
check.frame:SetSize(200,24)
check.checkbg:SetPoint('TOPLEFT',check.frame,'TOPLEFT',0,0)
check.text=Text(check.frame); check.text:SetPoint('LEFT',check.checkbg,'RIGHT',0,0)
check.image=check.frame:CreateTexture(nil,'ARTWORK')
check.SetLabel=function(self,value) self.text:SetText(value); self.text:SetPoint('LEFT',self.checkbg,'RIGHT',0,0); return 'native-label' end
check.SetImage=function(self,value) self.image:SetTexture(value); self.text:SetPoint('LEFT',self.image,'RIGHT',1,0); return 'native-image' end
local nativePresses=0
check.frame.scripts.OnMouseDown=function() nativePresses=nativePresses+1; check.text:SetPoint('LEFT',check.checkbg,'RIGHT',1,-1) end
check.frame.scripts.OnMouseUp=function() check:SetValue(not check.checked) end
check.text.color={0.7,0.7,0.7,1}; check.checked=true
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
local popupItem=Widget('Dropdown-Item-Toggle',popup.frame)
popupItem.text=Text(popupItem.frame);popupItem.text.color={0.4,0.5,0.6,1}
popupItem.check=popupItem.frame:CreateTexture(nil,'OVERLAY');popupItem.check:SetTexture('native-menu-tick')
popupItem.highlight=popupItem.frame:CreateTexture(nil,'OVERLAY');popupItem.highlight:SetTexture('native-menu-hover')
popup.items={popupItem}
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

root.closebutton=Object('Button',root.frame);root.closebutton.Text=Text(root.closebutton);root.closebutton:SetNormalTexture('native-close')
root.closebutton.scripts.OnClick=function()return 'native-close-action'end
local tree=Widget('TreeGroup',root.frame);table.insert(root.children,tree)
tree.treeframe=Object('Frame',tree.frame);tree.treeframe.backdrop={bgFile='native-tree',edgeFile='decorative'}
local treeRow=Object('Button',tree.treeframe);treeRow.obj=tree;treeRow.treeline={};treeRow.text=Text(treeRow)
treeRow.toggle=Object('Button',treeRow);treeRow.toggle:SetNormalTexture(130821)
treeRow.highlight=treeRow:CreateTexture(nil,'HIGHLIGHT');tree.buttons={treeRow}
function tree:RefreshTree()self.calls=(self.calls or 0)+1;treeRow.text.path='Native';return 'native-tree'end
root.frame:Hide()
root.frame.scripts.OnShow=function()dialog:FeedGroup('NovaInstanceTracker',{},root)end
module.refresh();root.frame:Show();Flush()
assert(check.checkbg.width==14 and check.check.width==8 and check.text.point[4]==6)
assert(root.closebutton.Text.path=='Native'and not root.closebutton.close,'labelled Close button became an X')
assert(action.text.color[1]==.92 and action.frame.scripts.OnClick()=='native-option')
assert(dropdown.button.scripts.OnClick()=='native-dropdown')
local boundedEdges=0
for _,art in ipairs(dropdown.dropdown.regions)do
 if art.layer=='BORDER'and art.point and art.point[2]==dropdown.button_cover then boundedEdges=boundedEdges+1 end
end
assert(boundedEdges==4,'selector border used oversized decorative bounds')
assert(scroll.scrollbar.thumb.alpha==0 and down.scripts.OnClick()=='native-step')
assert(tree.treeframe.backdrop==nil and treeRow.toggle.normal.alpha==0)
assert(tree:RefreshTree()=='native-tree')
treeRow.selected=true;tree:RefreshTree();assert(treeRow.highlight.color[1]==accent)
assert(not treeRow.button,'sidebar was styled as an action button')
treeRow.toggle:SetNormalTexture(130838);tree:RefreshTree()
local expandedMark
for _,art in ipairs(treeRow.toggle.regions)do if art.rotation then expandedMark=art end end
assert(expandedMark and expandedMark.rotation==-math.pi/2,'collapsed sidebar indicator is wrong')
assert(popup:Open()=='native-open')
assert(popup.frame.backdrop==nil and popupItem.check.width==8 and popupItem.check.color[1]==accent)
popup.frame:Hide();assert(popup.frame.backdrop.bgFile=='native-popup' and popupItem.check.texture=='native-menu-tick'and popupItem.text.path=='Native')
for _=1,20 do popup:Open();popup.frame:Hide()end
local o,h,w=allocated,hookCount,fontWrites
for _=1,1000 do
 dialog:FeedGroup('NovaInstanceTracker',{},root)
 editor:Show()
end
assert(allocated==o and hookCount==h and fontWrites==w,'warm page/show allocated or rewrote fonts')
local c,r=childReads,regionReads
for _=1,100 do
 for _,frame in ipairs(events)do if frame.events and frame.events.ADDON_LOADED then frame.scripts.OnEvent(frame,'ADDON_LOADED','ForeignAddon')end end
end
assert(childReads==c and regionReads==r,'unrelated addon load traversed hierarchy')
local late=Widget('Button',root.frame);late.frame.kind='Button';late.frame.Text=Text(late.frame);late.text=late.frame.Text
root.children[#root.children+1]=late;dialog:FeedGroup('NovaInstanceTracker',{},root)
assert(late.text.path=='Native'and late.text.color[1]==.92,'newly built option missed styling')
local foreign=Widget('Button',UIParent);foreign.frame.kind='Button';foreign.frame.Text=Text(foreign.frame)
dialog:FeedGroup('ForeignAddon',{},foreign);assert(foreign.frame.Text.path=='Native')
assert(gui:Release(check)=='native-release')
assert(check.checkbg.texture=='native-check-bg'and check.checkbg.width==24 and check.check.texture=='native-tick')
check:SetValue(false);assert(check.checkbg.width==24,'released checkbox restyled foreign widget')
dialog:FeedGroup('NovaInstanceTracker',{},root);assert(check.checkbg.width==14)
enabled=false;gui:Release(dropdown);assert(dropdown.nativeArt.alpha==1)
local skipped=Widget('Button',root.frame);skipped.frame.kind='Button';skipped.frame.Text=Text(skipped.frame)
root.children[#root.children+1]=skipped;dialog:FeedGroup('NovaInstanceTracker',{},root);assert(skipped.frame.Text.path=='Native')
enabled=true;combat=true;dialog:FeedGroup('NovaInstanceTracker',{},root);assert(skipped.frame.Text.path=='Native')
combat=false;module.refresh();assert(skipped.frame.Text.path=='Native'and skipped.frame.Text.color[1]==.92)
fontFace='NewEUI';accent=.8;for _,fn in ipairs(looks)do fn()end
assert(action.text.path=='Native'and check.check.color[1]==.8)
local stand=Widget('Frame',UIParent);stand.titletext=Text(stand.frame);stand.frame.backdrop={bgFile='native-standalone'}
dialog.OpenFrames.NovaInstanceTracker=stand;dialog:FeedGroup('NovaInstanceTracker',{},stand)
assert(stand.frame.backdrop==nil)
local translucent=false
for _,art in ipairs(stand.frame.regions)do
 if art.layer=='BACKGROUND'and art.color[4]==.8 and art.alpha==1 then translucent=true end
 assert(not art.gradient,'standalone options retained a second background gradient')
end
assert(translucent and stand.frame.alpha==1,'standalone opacity faded foreground controls')
assert(#errors==0,table.concat(errors,'; '))
print('PASS: NovaInstanceTracker canvas/standalone options, local tree updates, native logs, rows, links, actions/status colours, pooled menus/restoration, dynamic controls, themes and combat/disabled guards')
print('BENCH NovaInstanceTracker 1000 warm options feeds/editor shows: new_UI_objects=0 new_hooks=0 font_writes=0; unrelated_addon_loads=100 hierarchy_reads=0 (mock)')

-- Stress realistic reuse paths, rather than only feeding unchanged widgets.
local allocations,hooks=allocated,hookCount
for _=1,500 do
 assert(popup:Open()=='native-open')
 assert(popupItem.check.width==8)
 popup.frame:Hide()
 assert(popupItem.check.texture=='native-menu-tick'and popupItem.text.path=='Native')
end
assert(allocated==allocations and hookCount==hooks,'pullout reuse grew UI objects or hooks')
for _=1,250 do
 gui:Release(check);gui:Release(action);gui:Release(dropdown)
 dialog:FeedGroup('NovaInstanceTracker',{},root)
 assert(check.checkbg.width==14 and action.text.color[1]==.92)
end
assert(allocated==allocations and hookCount==hooks,'page-control recycling grew UI objects or hooks')
local beforeChildren,beforeRegions,beforeFonts=childReads,regionReads,fontWrites
for i=1,1000 do
 check:SetValue(i%2==0)
 action:SetDisabled(i%2==0)
end
assert(childReads==beforeChildren and regionReads==beforeRegions and fontWrites==beforeFonts,
 'value/disabled callbacks scanned a page or rewrote fonts')
local otherWalks=action.frame.walks
for _=1,250 do tree:RefreshTree() end
assert(action.frame.walks==otherWalks,'sidebar refresh scanned unrelated action controls')
assert(allocated==allocations and hookCount==hooks,'sidebar refresh grew UI objects or hooks')
for _=1,25 do module.refresh() end
assert(allocated==allocations and hookCount==hooks,'theme refresh grew UI objects or hooks')
enabled=false
beforeChildren,beforeRegions,beforeFonts=childReads,regionReads,fontWrites
for _=1,1000 do dialog:FeedGroup('NovaInstanceTracker',{},root);editor:Show()end
assert(childReads==beforeChildren and regionReads==beforeRegions and fontWrites==beforeFonts,
 'disabled skin performed styling work')
enabled=true
assert(editor.EditBox.text=='trade/instance data remains')
assert(#errors==0,table.concat(errors,'; '))
print('BENCH NovaInstanceTracker mock stress: 500 pullout reopen cycles + 250 pooled-control rebuilds + 250 tree refreshes + 25 theme refreshes: new_UI_objects=0 new_hooks=0')
print('BENCH NovaInstanceTracker 1000 value/disabled cycles: hierarchy_reads=0 font_writes=0; 1000 disabled feeds/editor shows: hierarchy_reads=0 font_writes=0 (mock)')

-- Stable checkbox setters keep native checked visibility and avoid cosmetic
-- geometry/colour churn; label/image callbacks retain their own layout repair.
check:SetDisabled(false);check:SetValue(true)
local geo,colors=geometryWrites,colourWrites
for _=1,1000 do check:SetValue(true);check:SetDisabled(false)end
assert(geometryWrites==geo and colourWrites==colors,'stable check state rewrote cosmetic geometry/colours')
-- Observe native recreated controls without traversing unrelated windows.
local viewWalks=editor.walks
for id=2,101 do
 local _,fresh=NIT:createInstanceLineFrame(id)
 assert(fresh.fs.path==fontFace and fresh.removeButton.close)
end
assert(editor.walks==viewWalks,'new row creation rescanned the whole log')
-- Model and protected descendants stay outside the skin's walk.
local secure=Object('Button',editor);secure.protected=true;secure.Text=Text(secure)
local model=Object('ModelScene',editor);local modelControl=Object('Button',model);modelControl.Text=Text(modelControl)
module.refresh()
assert(not secure.button and not secure.walks and not model.walks and not modelControl.button)
print('BENCH NovaInstanceTracker mock: 1000 native timer updates: skin scans/objects/font writes=0; 100 new rows: whole-log scans=0; 1000 stable check setters: geometry/colour writes=0')

-- A native title is created below the cached EditBox after the window itself.
local mainReads,editReads=editor.walks,editor.EditBox.walks
assert(NIT:createTitleInstanceLineFrame()=='native-title')
assert(titleNITInstanceLine.fs.path==fontFace and titleNITInstanceLine.fs.text=='|cffffff00Last hour: 0|r')
assert(editor.walks==mainReads and editor.EditBox.walks==editReads,'title discovery scanned ancestors')
local function Background(frame)
 local fill
 for _,region in ipairs(frame.regions)do
  if region.layer=='BACKGROUND'and region.anchor==frame and region.color[4]==.8 then fill=region end
  assert(not region.gradient,'native window retained a stacked gradient')
 end
 assert(fill and frame.alpha==1,'window lacks a translucent background or faded its foreground')
 return fill
end
local bg=Background(editor);Background(lockouts);Background(level)
assert(editor.fs.alpha==1 and editor.legend.alpha==1 and nativeCheck.alpha==1)
local c,r,o,h,w,g=childReads,regionReads,allocated,hookCount,fontWrites,geometryWrites
for _=1,1000 do NIT:openInstanceLogFrame();NIT:createTitleInstanceLineFrame();editor.scripts.OnUpdate()end
assert(childReads==c and regionReads==r and allocated==o and hookCount==h and fontWrites==w and geometryWrites==g,
 'warm native open/title/timer cycle performed new skin work')
assert(Background(editor)==bg,'background was recreated')
fontFace='ThirdTheme';module.refresh()
assert(Background(editor)==bg and bg.color[4]==.8 and editor.fs.alpha==1)
-- Restoring a shared standalone window returns its native backdrop/alpha.
assert(gui:Release(stand)=='native-release')
assert(stand.frame.backdrop.bgFile=='native-standalone'and stand.frame.alpha==1)
assert(bg.alpha==1 and #errors==0,table.concat(errors,'; '))
print('BENCH NovaInstanceTracker transparent alpha: 1000 warm open/title/timer cycles: hierarchy reads, UI objects, hooks, font/geometry writes=0; foreground alpha=1; local title discovery and pool restoration pass')
