-- Hekili recommendation lifecycle and reversible Ace options.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local menuBindings, dialogStyles=0,0
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'Hekili'); factory = fn end
ns.RegisterModule = function(id, _, available, install) module = {id=id, available=available, install=install} end
ns.BindPopupList=function(_,_,owner,list) assert(owner==list.dropdown); menuBindings=menuBindings+1 end
ns.RefreshPopupMenusNow=function() end
local minimapBindings=0
ns.BindPopupOwner=function(_,_,f) assert(f==HekiliMenu); minimapBindings=minimapBindings+1 end
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

assert(loadfile('EUIAddonSkins/Skins/Hekili.lua'))('EUIAddonSkins',ns)
Hekili=nil
assert(factory and not module)
local before=allocated; factory(); assert(not module.available() and before==allocated)
UIParent=Object('Frame')
local function Button(parent)
    local f=Object('Button',parent); f.Text=Text(f); f.Text.color={0.9,0.9,0.9,1}
    f.scripts.OnClick=function() return 'native-action' end; return f
end
local gui={Release=function(_,widget) if widget.OnRelease then widget:OnRelease() end; widget.frame:Hide(); return 'native-release' end}
local dialog={OpenFrames={},BlizOptions={}}
function dialog:FeedGroup(id,_,container) return 'native-feed',container,id end
function dialog:Open(id) self.opens=(self.opens or 0)+1; return 'native-open',9 end
LibStub=function(id,silent)
    assert(silent)
    if id=='AceConfigDialog-3.0' then return dialog elseif id=='AceGUI-3.0' then return gui end
end
HekiliMenu=Object('Frame',UIParent)
function HekiliMenu:GetChildren() error('minimap owner recursively scanned') end
Hekili={DisplayPool={}}
function Hekili:CreateButton(displayID,index)
    local display=self.DisplayPool[displayID]
    local b=display.Buttons[index] or CreateFrame('Button','Hekili_'..displayID..'_B'..index,display)
    b.display,b.index=displayID,index
    b.Texture=b.Texture or b:CreateTexture(nil,'ARTWORK'); b.Texture:SetTexture('spell')
    b.texCoords={0.2,0.8,0.1,0.9}; b.Texture:SetTexCoord(table.unpack(b.texCoords))
    b.Backdrop=b.Backdrop or Object('Frame',b); b.Backdrop:SetAlpha(1)
    for _,key in ipairs({'Caption','Keybinding','Targets','DelayText'}) do
        b[key]=b[key] or Text(b); b[key]:SetFont('Native',17,'OUTLINE'); b[key]:SetTextColor(0.8,0.2,0.1,1)
    end
    b.Cooldown=b.Cooldown or Object('Cooldown',b); b.Cooldown.value=27
    b.Icon=b.Icon or b:CreateTexture(nil,'OVERLAY'); b.Icon:SetTexture('native-cycle')
    b.Empowerment=b.Empowerment or b:CreateTexture(nil,'OVERLAY'); b.Empowerment:SetTexture('native-glow')
    b:SetPoint('CENTER',display,'CENTER',12,15); b:SetSize(45,35)
    return b, 'native-created'
end
function Hekili:CreateDisplay(id)
    local d=self.DisplayPool[id] or Object('Frame',UIParent); self.DisplayPool[id]=d; d.Buttons=d.Buttons or {}
    for i=1,3 do d.Buttons[i]=self:CreateButton(id,i) end
    return d,'native-display'
end
function Hekili:CreateCustomDisplay(id) return self:CreateDisplay(id) end
function Hekili:BuildUI() self:CreateDisplay('Primary'); return 'native-build' end
function Hekili:OpenConfiguration() return 'native-config' end
Hekili:BuildUI()
assert(module.available()); module.install(S,module); Flush(); assert(minimapBindings==1)
local primary=Hekili.DisplayPool.Primary.Buttons[1]
assert(primary.Texture.coords[1]==0.2 and primary.Texture.coords[3]==0.1)
assert(primary.Backdrop.alpha==0 and primary.Texture.bordered and primary.Caption.path=='EUI')
assert(primary.Caption.size==17 and primary.Caption.color[1]==0.8 and primary.Caption.color[2]==0.2)
assert(primary.width==45 and primary.height==35 and primary.point[4]==12 and primary.Cooldown.value==27)
assert(primary.Icon.texture=='native-cycle' and primary.Empowerment.texture=='native-glow')
local c,r,o,h,w=childReads,regionReads,allocated,hookCount,fontWrites
for i=1,1000 do
    primary.Texture:SetTexCoord(table.unpack(primary.texCoords)); primary.Texture:SetVertexColor(0.4,0.4,0.4,1)
    primary.Cooldown.value=i; primary.Caption:SetText(i)
end
assert(childReads==c and regionReads==r and allocated==o and hookCount==h and fontWrites==w,'recommendation updates triggered styling')
local b,ret=Hekili:CreateButton('Primary',4)
assert(ret=='native-created' and b.Texture.bordered and b.Caption.path=='EUI','new button not styled before parent assignment')
Hekili.DisplayPool.Primary.Buttons[4]=b
local custom,ret=Hekili:CreateCustomDisplay('Custom')
assert(ret=='native-display' and custom.Buttons[1].Texture.bordered)
assert(Hekili:BuildUI()=='native-build' and primary.Caption.path=='EUI' and primary.Backdrop.alpha==0)
local masque=Hekili.DisplayPool.Primary.Buttons[2]; masque.__MSQ_NormalTexture=masque:CreateTexture()
masque.Backdrop:SetAlpha(0.7); module.refresh(); assert(masque.Backdrop.alpha==0.7,'Masque frame overwritten')
local function Widget(kind,parent)
    local w={type=kind,frame=Object('Frame',parent),children={}}
    w.frame.obj=w; w.OnRelease=function(self) self.releases=(self.releases or 0)+1 end
    return w
end
local root=Widget('Frame',UIParent)
dialog.OpenFrames.Hekili=root
local tree=Widget('TreeGroup',root.frame); root.children={tree}
tree.treeframe=Object('Frame',tree.frame); tree.buttons={}
for i=1,2 do
    local row=Button(tree.treeframe); row.obj=tree; row.text=row.Text; row.selected=i==1
    row.treeline={disabled=false}; row.toggle=Button(row); row.toggle:SetNormalTexture(130838); row.toggle.scripts.OnClick=function() return 'native-expand' end; row.icon=row:CreateTexture(nil,'OVERLAY'); row.icon:SetTexture('native-category')
    row.highlight=row:CreateTexture(nil,'HIGHLIGHT'); row.highlight:SetTexture('native-selection'); tree.buttons[i]=row
end
function tree:RefreshTree()
    for _,b in ipairs(self.buttons) do b.toggle:SetNormalTexture(b.expanded and 130821 or 130838); b.text:SetFont('Native',13,''); b.text:SetTextColor(1,0.8,0,1) end
    return 'native-tree'
end
local check=Widget('CheckBox',root.frame); table.insert(root.children,check)
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
local media=Widget('LSM30_Sound',root.frame); table.insert(root.children,media)
media.frame.label=Text(media.frame); media.frame.label.color={1,0.82,0,1}
media.frame.text=Text(media.frame); media.frame.text.text='Horn'
for _,k in ipairs({'DLeft','DMiddle','DRight'}) do media.frame[k]=media.frame:CreateTexture(nil,'ARTWORK'); media.frame[k]:SetTexture('native-lsm-border') end
media.frame.dropButton=Object('Button',media.frame); media.frame.dropButton:SetNormalTexture('native-down')
media.soundbutton=Object('Button',media.frame); media.soundbutton.obj=media
media.speaker=media.soundbutton:CreateTexture(nil,'BACKGROUND'); media.speaker:SetTexture('native-speaker')
media.soundbutton.scripts.OnClick=function() return 'native-sound-preview' end
local mediaPopup=Object('Frame',UIParent); mediaPopup.backdrop={bgFile='native-media',edgeFile='ornate'}
local mediaRow=Object('Button',mediaPopup); mediaRow.obj=media; mediaRow.text=Text(mediaRow)
mediaRow.text.color={1,1,1,1}; mediaRow.highlight=mediaRow:CreateTexture(nil,'HIGHLIGHT'); mediaRow.highlight:SetTexture('native-highlight')
mediaRow.scripts.OnClick=function() return 'native-sound-choice' end
mediaRow.check=mediaRow:CreateTexture(nil,'ARTWORK'); mediaRow.check:SetTexture('native-tick'); mediaRow.check:Show()
mediaPopup.contentRepo={mediaRow}
mediaPopup.slider=Object('Slider',mediaPopup); mediaPopup.slider.thumb=mediaPopup.slider:CreateTexture(); mediaPopup.slider.thumb:SetTexture('media-thumb'); mediaPopup.slider.thumb:SetSize(20,28)
mediaPopup:Hide()
local mediaToggles=0
media.frame.dropButton.scripts.OnClick=function()
    mediaToggles=mediaToggles+1
    if media.dropdown then mediaPopup:Hide(); media.dropdown=nil else media.dropdown=mediaPopup; mediaPopup:Show() end
    return 'native-media-toggle'
end
local binding=Widget('Keybinding',root.frame); table.insert(root.children,binding)
binding.button=Object('Button',binding.frame); binding.button.obj=binding; binding.button.Text=Text(binding.button)
binding.button:SetNormalTexture('native-red-button'); binding.key='CTRL-A'
binding.msgframe=Object('Frame',UIParent); binding.msgframe.Text=Text(binding.msgframe); binding.msgframe:Hide()
binding.button.scripts.OnClick=function() binding.waiting=true; binding.msgframe:Show(); return 'native-key-capture' end
binding.button.scripts.OnKeyDown=function(_,key) binding.key=key; binding.waiting=false; binding.msgframe:Hide(); return 'native-bind' end
root.closebutton=Object('Button',root.frame); root.closebutton:SetNormalTexture('native-close')
root.closebutton.scripts.OnClick=function() return 'native-close-action' end
assert(dialog:Open('Hekili')=='native-open')
local replacedFeeds=0
dialog.FeedGroup=function(self,id,_,container) replacedFeeds=replacedFeeds+1; return 'native-feed',container,id end
for _,event in ipairs(events) do if event.events and event.events.ADDON_LOADED then event.scripts.OnEvent(event,'ADDON_LOADED','LibraryUpgrade') end end
local sr,container,id=dialog:FeedGroup('Hekili',{},root)
assert(sr=='native-feed' and container==root and id=='Hekili')
assert(tree.buttons[1].text.path=='EUI' and tree.buttons[1].text.color[1]==accent)
assert(tree.buttons[1].icon.alpha==1 and tree.buttons[1].icon.texture=='native-category')
local pageWalks=check.frame.walks
assert(tree:RefreshTree()=='native-tree' and tree.buttons[1].text.path=='EUI')
assert(check.frame.walks==pageWalks,'navigation refresh scanned content')
assert(tree.buttons[1].toggle.normal.alpha==0 and tree.buttons[1].toggle.scripts.OnClick()=='native-expand')
tree.buttons[1].expanded=true; tree:RefreshTree()
local expandGlyph
for _,r in ipairs(tree.buttons[1].toggle.regions) do if r.texture and type(r.texture)=='string' and r.texture:find('eui%-arrow') then expandGlyph=r end end
assert(expandGlyph and expandGlyph.rotation==0)


assert(media.frame.DLeft.alpha==0 and media.speaker.alpha==1 and media.frame.label.color[1]==0.86)
assert(media.soundbutton.scripts.OnClick()=='native-sound-preview')
media.frame.dropButton.scripts.OnClick()
assert(mediaToggles==1 and mediaPopup.backdrop==nil and mediaRow.text.path=='EUI')
assert(mediaPopup.slider.thumb.width==20 and mediaPopup.slider.thumb.height==28 and mediaPopup.slider.thumb.alpha==0)
assert(mediaRow.scripts.OnClick()=='native-sound-choice' and mediaRow.check:IsShown())
media.frame.dropButton.scripts.OnClick(); assert(mediaToggles==2 and media.dropdown==nil)
assert(mediaPopup.backdrop.edgeFile=='ornate' and mediaRow.text.path=='Native' and mediaPopup.slider.thumb.alpha==1,'media popup cleanup leaked')
assert(binding.button.normal.alpha==0 and binding.button.Text.color[1]==0.92)
binding.button.scripts.OnClick(); assert(binding.waiting and binding.msgframe.styled)
assert(binding.button.scripts.OnKeyDown(binding.button,'SHIFT-B')=='native-bind' and binding.key=='SHIFT-B')
local stableReads,stableRegions,stableObjects,stableHooks,stableFonts=childReads,regionReads,allocated,hookCount,fontWrites
for i=1,100 do
    for _,event in ipairs(events) do if event.events and event.events.ADDON_LOADED then event.scripts.OnEvent(event,'ADDON_LOADED','UnrelatedAddon') end end
end
assert(childReads==stableReads and regionReads==stableRegions and allocated==stableObjects and hookCount==stableHooks and fontWrites==stableFonts,'unchanged libraries caused options work')
local popupObjects,popupHooks=allocated,hookCount
for i=1,20 do media.frame.dropButton.scripts.OnClick(); media.frame.dropButton.scripts.OnClick() end
assert(allocated==popupObjects and hookCount==popupHooks and mediaPopup.backdrop.edgeFile=='ornate','media popup reuse grew/leaked styling')
print('BENCH Hekili recommendation_updates=1000 hierarchy_reads=0 font_writes=0; media_reopen=20 new_UI_objects=0 new_hooks=0')
assert(check.check.width==8 and check.checkbg.width==14 and check.checked and check.text.path=='EUI')
assert(check.checkbg.point[4]==5 and check.checkbg.point[5]==-5 and check.frame.width==200 and check.frame.height==24)
assert(check.text.point[2]==check.checkbg and check.text.point[4]==6)
assert(check:SetLabel('Only use in raids')=='native-label' and check.text.point[4]==6)
check.frame.scripts.OnMouseDown(check.frame)
assert(nativePresses==1 and check.text.point[4]==6 and check.text.point[5]==0, 'native pressed text must not overlap the flat square')
local checkedBefore=check.checked
check.frame.scripts.OnMouseUp(check.frame); assert(check.checked~=checkedBefore and check.text.point[4]==6)
assert(check:SetImage('native-class-icon')=='native-image' and check.text.point[2]==check.image and check.text.point[4]==6)
check:SetImage(nil); check:SetValue(true)
assert(action.frame.scripts.OnClick()=='native-option')
assert(action.text.color[1]==0.92 and action.text.color[4]==1, 'enabled action buttons must be readable')
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
check:OnRelease(); action:OnRelease(); dropdown:OnRelease(); tabs:OnRelease(); inline:OnRelease(); scroll:OnRelease(); media:OnRelease(); binding:OnRelease(); tree:OnRelease(); root:OnRelease()
assert(expandGlyph.alpha==0 and tree.buttons[1].toggle.normal.alpha==1)
assert(tree.buttons[1].text.path=='Native' and tree.buttons[1].highlight.texture=='native-selection')
assert(check.check.texture=='native-tick' and check.check.width==24 and check.checkbg.texture=='native-check-bg')
assert(check.text.point[4]==0 and check.checkbg.point[4]==0 and check.checkbg.point[5]==0,
    'pool release must restore native checkbox and label anchors')
assert(check.text.path=='Native' and action.frame.Text.path=='Native', 'pool release must restore native fonts')
assert(action.text.color[1]==1 and action.text.color[2]==0.82 and inlineBorder.backdrop.edgeFile=='bevelled')
assert(media.frame.DLeft.alpha==1 and media.frame.label.color[1]==1 and binding.button.normal.alpha==1,'new widget styles leaked on release')
assert(up.normal.alpha==1 and down.normal.alpha==1 and scroll.scrollbar.thumb.alpha==1)
local nativeWidgets=allocated
dialog:FeedGroup('AnotherAddon',{},root); check.frame:Show()
assert(check.text.path=='Native' and allocated==nativeWidgets, 'other addons must not trigger the skin')
dialog:FeedGroup('Hekili',{},root)
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
for i=1,40 do dialog:FeedGroup('Hekili',{},root) end
assert(hookCount==callbacks and allocated==nativeWidgets, 'repeated page feeds must reuse skin objects and hooks')
local beforeLabels,beforeLabelObjects=childReads,allocated
for i=1,100 do action:SetDisabled(i%2==0); action.text:SetTextColor(0.1,0.1,0.1,1) end
assert(action.text.color[1]==0.5 and childReads==beforeLabels and allocated==beforeLabelObjects, 'button state repairs must stay local')
action:SetDisabled(false)

check:SetDisabled(false)
accent=0.75; fontFace='EUI-new'; for _,fn in ipairs(looks) do fn() end; Flush()
assert(primary.Caption.path=='EUI-new' and primary.Caption.color[2]==0.2 and check.check.color[1]==0.75)
combat=true
local oldCalls=fontWrites; module.refresh(); Hekili:BuildUI(); Flush()
assert(fontWrites==oldCalls,'combat styling occurred')
combat=false; for _,event in ipairs(events) do if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event) end end; Flush()
enabled=false
gui.Release=function(_,widget) widget.frame:Hide(); return 'native-release' end
for _,event in ipairs(events) do if event.events and event.events.ADDON_LOADED then event.scripts.OnEvent(event,'ADDON_LOADED','LibraryUpgrade') end end
check:OnRelease(); action.OnRelease=nil
assert(gui:Release(action)=='native-release' and check.text.path=='Native' and action.text.path=='Native')
action:SetDisabled(false); action.text:SetTextColor(0.2,0.3,0.4,1); assert(action.text.color[1]==0.2)
local objects=allocated; module.refresh(); Hekili:BuildUI(); Flush(); assert(allocated==objects)
assert(#errors==0,table.concat(errors,'\n'))
Hekili,HekiliMenu=nil,nil
print('PASS: Hekili named/custom displays, native geometry/cooldowns/indicators, options/menus, Ace replacement/pool restoration, themes/combat/disable')
