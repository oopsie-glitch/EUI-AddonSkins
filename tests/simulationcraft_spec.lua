-- SimulationCraft export-window lifecycle, editor actions and native saved settings.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'Simulationcraft'); factory = fn end
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
assert(loadfile('EUIAddonSkins/Skins/Simulationcraft.lua'))('EUIAddonSkins',ns)
LibStub=nil
assert(not module and factory)
local before=allocated; factory(); assert(not module.available() and before==allocated)
local app
LibStub=function(name,silent)
    assert(name=='AceAddon-3.0' and silent)
    return {GetAddon=function(_,id,quiet) assert(id=='Simulationcraft' and quiet); return app end}
end
assert(not module.available())
UIParent=Object('Frame')
local saved={frame={width=600,height=400,x=42,y=73},closeOnCopy=true,offspecLoadouts=false,unrelated='kept'}
local exports,nativeTextWrites,nativeCopies=0,0,0
local function Button(name,parent)
    local f=CreateFrame('Button',name,parent); f.Text=Text(f); return f
end
local function BuildWindow()
    local f=CreateFrame('Frame','SimcFrame',UIParent); f.backdrop={bgFile='native',edgeFile='native'}
    f.width,f.height=saved.frame.width,saved.frame.height
    local done=Button('SimcFrameButton',f); done.scripts.OnClick=function() f:Hide(); return 'native-done' end
    local sf=CreateFrame('ScrollFrame','SimcScrollFrame',f)
    sf.ScrollBar=CreateFrame('Slider','SimcScrollFrameScrollBar',sf)
    sf.ScrollBar.thumb=Object('Texture'); sf.ScrollBar.native=sf.ScrollBar:CreateTexture(nil,'BACKGROUND')
    sf.ScrollBar.ScrollUpButton=Button('SimcUp',sf.ScrollBar)
    sf.ScrollBar.ScrollDownButton=Button('SimcDown',sf.ScrollBar)
    sf.ScrollBar.ScrollDownButton.scripts.OnClick=function() sf.value=(sf.value or 0)+1; return 'native-down' end
    sf.ScrollBar.scripts.OnValueChanged=function(_,v) sf.value=v; return 'native-scroll' end
    local eb=CreateFrame('EditBox','SimcEditBox',sf); eb.width=540; eb.height=320; eb.focused=true
    eb.scripts.OnEscapePressed=function() f:Hide() end
    eb.scripts.OnKeyUp=function(_,key)
        if key=='C' then
            nativeCopies=nativeCopies+1
            if saved.closeOnCopy then C_Timer.After(0.1,function() f:Hide() end) end
        end
    end
    local resize=CreateFrame('Button','SimcResizeButton',f)
    resize:SetNormalTexture('native-grip'); resize:SetPushedTexture('native-grip-down'); resize:SetHighlightTexture('native-grip-highlight')
    resize.scripts.OnMouseDown=function() f.sizing=true; return 'native-size-start' end
    resize.scripts.OnMouseUp=function()
        f.sizing=false; saved.frame.width=f.width; saved.frame.height=f.height; eb.width=f.width-60
        return 'native-size-save'
    end
    f.scripts.OnMouseUp=function() saved.frame.x=f.x; saved.frame.y=f.y; return 'native-position-save' end
    for _,name in ipairs({'AutomaticClose','SimcOffspecLoadouts'}) do
        local c=CreateFrame('CheckButton',name,f); c:SetSize(32,32); c.Text=Text(c)
        c.checkedArt=Object('Texture'); c.disabledArt=Object('Texture')
        c.checked=name=='AutomaticClose' and saved.closeOnCopy or saved.offspecLoadouts
        c.scripts.OnClick=function(self)
            self.checked=not self.checked
            if name=='AutomaticClose' then saved.closeOnCopy=self.checked
            else saved.offspecLoadouts=self.checked; exports=exports+1; app:GetMainFrame('updated native export') end
            return 'native-checkbox'
        end
    end
    return f
end
app={GetMainFrame=function(_,text)
    if not SimcFrame then BuildWindow() end
    nativeTextWrites=nativeTextWrites+1
    SimcEditBox:SetText(text); SimcEditBox:HighlightText()
    return SimcFrame,'native-extra-return'
end,GetSimcProfile=function() error('skinning invoked character export') end}
assert(module.available()); module.install(S,module); Flush()
assert(not SimcFrame, 'skin forced lazy window construction')
local text='warrior="Native"\n# Checksum: 9abc\nitems=19019||bonus_id=1'
local frame,extra=app:GetMainFrame(text); Flush()
assert(extra=='native-extra-return' and frame==SimcFrame and frame.panel and not frame.backdrop)
assert(frame.width==600 and frame.height==400 and saved.frame.x==42 and saved.frame.y==73)
assert(SimcEditBox.text==text and SimcEditBox.selections==1 and nativeTextWrites==1 and SimcEditBox.focused)
assert(SimcEditBox.path=='EUI' and not SimcEditBox.input and SimcEditBox.width==540)
assert(SimcFrameButton.button and AutomaticClose.check and SimcOffspecLoadouts.check)
assert(AutomaticClose.checkedArt.width==10 and AutomaticClose.checkFill.width==14 and AutomaticClose.width==32)
assert(SimcScrollFrame.ScrollBar.thumb.width==5 and SimcScrollFrame.ScrollBar.thumb.height==20 and SimcScrollFrame.ScrollBar.width==16)
assert(SimcScrollFrame.ScrollBar.ScrollUpButton.glyph=='^' and SimcScrollFrame.ScrollBar.ScrollDownButton.glyph=='v')
assert(SimcScrollFrame.ScrollBar.ScrollDownButton.scripts.OnClick()=='native-down' and SimcScrollFrame.value==1)
assert(SimcScrollFrame.ScrollBar.scripts.OnValueChanged(nil,42)=='native-scroll' and SimcScrollFrame.value==42)
assert(SimcResizeButton.normal.alpha==0 and SimcResizeButton.pushed.alpha==0)
assert(SimcResizeButton.scripts.OnMouseDown()=='native-size-start' and frame.sizing)
frame.width=700; frame.height=420
assert(SimcResizeButton.scripts.OnMouseUp()=='native-size-save' and not frame.sizing)
assert(saved.frame.width==700 and saved.frame.height==420 and SimcEditBox.width==640)
frame.x,frame.y=99,123; assert(frame.scripts.OnMouseUp()=='native-position-save' and saved.frame.x==99)
assert(AutomaticClose.scripts.OnClick(AutomaticClose)=='native-checkbox' and not saved.closeOnCopy)
frame:Show(); SimcEditBox.scripts.OnKeyUp(nil,'C'); Flush(); assert(frame.shown and nativeCopies==1)
AutomaticClose.scripts.OnClick(AutomaticClose); SimcEditBox.scripts.OnKeyUp(nil,'C'); Flush()
assert(not frame.shown and nativeCopies==2)
SimcOffspecLoadouts.scripts.OnClick(SimcOffspecLoadouts); assert(saved.offspecLoadouts and exports==1)
assert(SimcEditBox.text=='updated native export' and nativeTextWrites==2 and SimcEditBox.selections==2)
assert(SimcFrameButton.scripts.OnClick()=='native-done' and not frame.shown)
frame:Show(); SimcEditBox.scripts.OnEscapePressed(); assert(not frame.shown)
local objects,hooks,writes,paints=allocated,hookCount,fontWrites,checkboxPaints
for i=1,1000 do app:GetMainFrame(text); frame:Show() end
assert(allocated==objects and hookCount==hooks and fontWrites==writes and checkboxPaints==paints,
    'warm exports or shows recreate UI/hooks or repaint controls')
assert(nativeTextWrites==1002 and SimcEditBox.selections==1002)
fontFace='EUI-new'; accent=0.75; looks[1](); Flush()
assert(SimcEditBox.path=='EUI-new' and AutomaticClose.checkedArt.color[1]==0.75 and allocated==objects)
assert(saved.offspecLoadouts and saved.closeOnCopy and saved.unrelated=='kept')
-- A delayed frame replacement and foreign generic global must be handled safely.
local oldFrame=frame
SimcFrame=nil; frame=BuildWindow()
local foreign=CreateFrame('CheckButton','AutomaticClose',UIParent); foreign.checkedArt=Object('Texture')
app:GetMainFrame(text); assert(frame.panel and not foreign.check)
assert(not oldFrame.protected)
-- Disabled skins and combat must perform no writes, even for soft border updates.
enabled=false; SimcFrame=nil; frame=BuildWindow(); app:GetMainFrame(text); assert(not frame.panel)
enabled=true; combat=true; module.refresh(); Flush(); assert(not frame.panel)
combat=false
for _,event in ipairs(events) do
    if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event,'PLAYER_REGEN_ENABLED') end
end
assert(frame.panel)
combat=true; looks[1](); Flush(); combat=false
for _,event in ipairs(events) do
    if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event,'PLAYER_REGEN_ENABLED') end
end
Flush()
local modern=BuildWindow()
SimcScrollFrame.ScrollBar=CreateFrame('Frame',nil,SimcScrollFrame)
SimcScrollFrame.ScrollBar.Back=CreateFrame('Button',nil,SimcScrollFrame.ScrollBar)
SimcScrollFrame.ScrollBar.Forward=CreateFrame('Button',nil,SimcScrollFrame.ScrollBar)
SimcScrollFrame.ScrollBar.Back.scripts.OnClick=function() return 'modern-back' end
-- Older versions can lack the offspec checkbox or resize control entirely.
SimcOffspecLoadouts=nil; SimcResizeButton=nil
module.refresh(); Flush()
assert(modern.panel and SimcScrollFrame.ScrollBar.scroll and SimcScrollFrame.ScrollBar.Back.glyph=='^'
    and SimcScrollFrame.ScrollBar.Forward.glyph=='v')
assert(SimcScrollFrame.ScrollBar.Back.scripts.OnClick()=='modern-back')
local protected=BuildWindow(); protected.protected=true; module.refresh(); Flush(); assert(not protected.panel)
assert(#errors==0,table.concat(errors,'\n'))
print('PASS: SimulationCraft lazy UI, native export/copy/selection, resize/position/settings, clean checks, scroll arrows, themes, foreign/protected frames and disabled/combat gates')
print('BENCH SimulationCraft: 1000 warm exports/shows create 0 UI objects/hooks and cause 0 font writes/checkbox repaints')
