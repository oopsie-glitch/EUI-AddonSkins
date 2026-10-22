-- HekiLight native Settings and public slot-state lifecycle.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local menuBindings, dialogStyles=0,0
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'HekiLight'); factory = fn end
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

assert(loadfile('EUIAddonSkins/Skins/HekiLight.lua'))('EUIAddonSkins',ns)
HekiLightST=nil
assert(factory and not module)
local before=allocated; factory(); assert(not module.available() and allocated==before)
UIParent=Object('Frame')
-- The loader can activate at ADDON_LOADED before HekiLight's own handler has
-- populated its public state. Its completed builder supplies the actual UI.
HekiLightST={}
local panel,content,section,body,slider,check,action,swatch,dropdown,scrollbar
local nativeRefreshes,nativeClicks=0,0
BuildSettingsPanel=function()
    panel=Object('Frame',UIParent); panel.name='HekiLight'
    local title=Text(panel); title.text='HekiLight'
    local scroll=CreateFrame('ScrollFrame','HekiLightScrollFrame',panel)
    content=Object('Frame',scroll); body=Object('Frame',content)
    section=Object('Button',content); section.header=Text(section); section.header.text='|cffffcc00Appearance|r'
    section.toggle=Text(section); section.toggle.text='-'; section.backdrop={bgFile='native',edgeFile='box'}
    section.scripts.OnClick=function() body:Show(); section.toggle:SetText('+'); return 'native-section' end
    slider=Object('Slider',body); slider.orientation='HORIZONTAL'; slider.thumb=slider:CreateTexture(nil,'ARTWORK')
    slider.thumb:SetTexture('native-thumb'); slider.backdrop={bgFile='native',edgeFile='native'}
    slider.value=1
    slider.scripts.OnValueChanged=function(_,value) slider.value=value; return 'native-slider' end
    check=Object('CheckButton',body); check.text=Text(check); check.text.text='Show keybind'
    check:SetSize(32,32); check.checkedArt=check:CreateTexture(nil,'ARTWORK'); check.disabledArt=check:CreateTexture(nil,'ARTWORK')
    check.checkedArt:Show(); check.disabledArt:Hide()
    check.scripts.OnClick=function() check.checked=not check.checked; return 'native-check' end
    action=Object('Button',panel); action.Text=Text(action); action.Text.text='Reset to Defaults'
    action.scripts.OnClick=function() nativeClicks=nativeClicks+1; return 'native-reset' end
    swatch=Object('Button',body); swatch.backdrop={bgFile='swatch'}; swatch.bg={0.9,0.2,0.7,1}
    swatch.scripts.OnClick=function() nativeClicks=nativeClicks+1; return 'native-picker' end
    dropdown=CreateFrame('Frame','HekiLightIgnoreDropdown',body); dropdown.initialize=function() return 'native-menu' end
    dropdown.Button=Object('Button',dropdown); dropdown.Button.scripts.OnClick=function() return 'native-arrow' end
    scrollbar=Object('Slider',scroll); scrollbar.thumb=scrollbar:CreateTexture(nil,'ARTWORK'); scrollbar.thumb:SetTexture('native-scroll')
    scroll.ScrollBar=scrollbar
    panel.scripts.OnShow=function() check:SetChecked(true); slider.scripts.OnValueChanged(slider,2) end
    local display=CreateFrame('Frame','HekiLightDisplay',UIParent); display:SetSize(190,64)
    display:SetPoint('CENTER',UIParent,'CENTER',22,40); display.scripts.OnDragStart=function() return 'native-drag' end
    display.editBanner=Text(display)
    HekiLightST.display=display; HekiLightST.slots={}
    for i=1,5 do
        local frame=Object('Frame',display); frame:SetSize(64,64); frame.backdrop={edgeFile='ornate'}
        local icon=frame:CreateTexture(nil,'ARTWORK'); icon:SetTexture('spell-'..i); icon:SetTexCoord(0.08,0.92,0.08,0.92)
        local key=Text(frame); key:SetFont('Native',14,'OUTLINE'); key.color={1,0.82,0,1}
        HekiLightST.slots[i]={frame=frame,iconTexture=icon,keybindText=key,editLabel=Text(frame)}
    end
    local proc=Object('Frame',UIParent); proc.backdrop={edgeFile='ornate'}
    proc.iconTexture=proc:CreateTexture(); proc.iconTexture:SetTexture('proc')
    proc.keybindText=Text(proc); proc.keybindText:SetFont('Native',14,'OUTLINE')
    proc.editLabel=Text(proc); proc.lockLabel=Text(proc)
    proc.scripts.OnDragStart=function() return 'native-proc-drag' end
    proc:Hide(); HekiLightST.procAlertFrame=proc
    HekiLightST.Refresh=function()
        nativeRefreshes=nativeRefreshes+1
        for _,slot in ipairs(HekiLightST.slots) do slot.iconTexture:SetVertexColor(1,0.4,0.4,1); slot.keybindText:SetText('1') end
    end
    HekiLightST.ApplyKeybindStyle=function()
        for _,slot in ipairs(HekiLightST.slots) do slot.keybindText:SetFont('Native',18,'THICKOUTLINE'); slot.keybindText:SetTextColor(0.1,0.8,0.4,1) end
    end
    return 'native-builder',panel
end
assert(module.available()); module.install(S,module); Flush()
local a,p=BuildSettingsPanel(); assert(a=='native-builder' and p==panel)
assert(check.check and check.checkedArt.width==8 and check.checkedArt.color[1]==accent and check.checkedArt:IsShown() and not check.disabledArt:IsShown())
assert(check.width==32 and check.height==32 and check.text.path=='EUI')
assert(section.header.text=='Appearance' and section.header.color[1]==accent and section.backdrop==nil)
assert(slider.thumb.width==8 and slider.thumb.height==14 and slider.backdrop==nil)
assert(scrollbar.thumb.width==5 and popupOwners[dropdown] and dropdown.Button.scripts.OnClick()=='native-arrow')
assert(action.button and swatch.bg[1]==0.9 and swatch.backdrop.bgFile=='swatch')
action.scripts.OnClick(); assert(swatch.scripts.OnClick()=='native-picker' and nativeClicks==2)
assert(slider.scripts.OnValueChanged(slider,1.5)=='native-slider' and slider.value==1.5)
assert(check.scripts.OnClick()=='native-check')
assert(section.scripts.OnClick()=='native-section')
local first=HekiLightST.slots[1]
assert(first.frame.backdrop==nil and first.iconTexture.bordered and first.keybindText.path=='EUI')
assert(first.frame.width==64 and HekiLightST.display.point[4]==22 and HekiLightST.display.scripts.OnDragStart()=='native-drag')
assert(first.iconTexture.coords[1]==0.08 and first.keybindText.size==14 and first.keybindText.flags=='OUTLINE' and first.keybindText.color[2]==0.82)
assert(HekiLightST.procAlertFrame.iconTexture.bordered and not HekiLightST.procAlertFrame:IsShown())
HekiLightST.ApplyKeybindStyle()
assert(first.keybindText.path=='EUI' and first.keybindText.size==18 and first.keybindText.flags=='THICKOUTLINE' and first.keybindText.color[2]==0.8)
Flush()
local c,r,o,h,w=childReads,regionReads,allocated,hookCount,fontWrites
for i=1,1000 do HekiLightST.Refresh() end
assert(nativeRefreshes==1000 and childReads==c and regionReads==r and allocated==o and hookCount==h and fontWrites==w,'suggestions triggered skin work')
for i=1,100 do panel:Show(); section.scripts.OnClick(); check.scripts.OnClick(); slider.scripts.OnValueChanged(slider,i) end
Flush()
assert(childReads==c and regionReads==r and allocated==o and hookCount==h and fontWrites==w,'warm options traversed or allocated')
-- A native action adds rows inside a known container, without rebuilding Settings.
local newRow,newAction
local oldAction=action.scripts.OnClick
action.scripts.OnClick=function()
    newRow=Object('Frame',panel); newAction=Object('Button',newRow); newAction.Text=Text(newAction)
    oldAction(); return 'native-add'
end
assert(action.scripts.OnClick()=='native-add'); Flush(); assert(newAction.button and newAction.Text.path=='EUI')
-- Native OnShow may populate an already-existing section body before our callback.
local oldShow=panel.scripts.OnShow
panel.scripts.OnShow=function()
    local row=Object('Frame',body); row.label=Text(row); row.label.text='New ignored spell'
    oldShow(); assert(row.label.path=='EUI','new descendant row missed on show')
end
panel:Show(); Flush()
accent=0.75; fontFace='EUI-new'; for _,fn in ipairs(looks) do fn() end; Flush()
assert(check.checkedArt.color[1]==0.75 and first.keybindText.path=='EUI-new' and first.keybindText.flags=='THICKOUTLINE')
combat=true; local old=fontWrites; module.refresh(); assert(fontWrites==old)
combat=false; for _,f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f) end end; Flush()
enabled=false; c,r,o,h,w=childReads,regionReads,allocated,hookCount,fontWrites
module.refresh(); action.scripts.OnClick(); HekiLightST.Refresh(); Flush()
-- The native action allocated a row; the disabled skin must leave it untouched.
assert(not newAction.button and newAction.Text.path=='Native' and childReads==c and regionReads==r and hookCount==h and fontWrites==w)
assert(#errors==0,table.concat(errors,'\n'))
HekiLightST,HekiLightDisplay,HekiLightScrollFrame,BuildSettingsPanel=nil,nil,nil,nil
print('BENCH HekiLight suggestion_updates=1000 skin_hierarchy_reads=0 new_objects=0; warm_settings=100 hierarchy_reads=0 new_hooks=0')
print('PASS: HekiLight native Settings, compact checks/sliders/scrollbar, dynamic rows, public slots/proc display, keybind customization, native actions, load order, theme/combat/disable')
