-- Waypoint UI custom UIKit controls, deferred construction and local rendering.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'WaypointUI'); factory = fn end
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
assert(loadfile('EUIAddonSkins/Skins/WaypointUI.lua'))('EUIAddonSkins',ns)
assert(factory and not module);local before=allocated;factory();assert(not module.available() and allocated==before)
UIParent=Object('Frame')
local logicalReads,nativeActions,nativeRenders=0,0,0
local function UI(parent)
    local f=Object('Frame',parent);f.logical={}
    if parent and parent.logical then parent.logical[#parent.logical+1]=f end
    function f:GetFrameChildren()logicalReads=logicalReads+1;return self.logical end
    function f:_Render()nativeRenders=nativeRenders+1;return 'native-render',42 end
    function f:GetTextureFrame()return self.Background end
    return f
end
local function Art(f)
    local holder=Object('Frame',f);holder.__Texture=holder:CreateTexture(nil,'ARTWORK');holder.__Texture:SetTexture('native-art')
    function holder:GetTextureObject()return self.__Texture end
    f.Background=holder
    function f:background() self.Background.__Texture:SetTexture('native-state-art');self.Background.__Texture:SetAlpha(1);return self end
    return holder
end
local function UIText(parent,semantic)
    local f=UI(parent);f.__Text=Text(f);f.__Text.color=semantic and {1,.2,.1,1} or {1,1,0,1}
    function f:UpdateFont()self.__Text:SetFontObject('Native');return 'native-font' end
    return f
end
local function Button(parent)
    local f=UI(parent);Art(f);f.Text=UIText(f);f.buttonState='NORMAL'
    function f:GetButtonState()return self.buttonState end
    function f:UpdateAnimation()self:background();self.Text.__Text:SetTextColor(1,1,0,1);return 'native-animation' end
    function f:SetEnabled(v)self.enabled=v;self:UpdateAnimation();return 'native-enabled' end
    f.scripts.OnClick=function()nativeActions=nativeActions+1;return 'native-action' end
    return f
end
local function Checkbox(parent)
    local f=UI(parent);Art(f);f.checked=true;f.mouse=true
    function f:GetChecked()return self.checked end
    function f:UpdateAnimation()self:background();return 'native-check' end
    function f:UpdateCheck()return self:UpdateAnimation()end
    function f:SetEnabled(v)self.enabled=v;self:UpdateAnimation();return 'native-enable-check' end
    f.scripts.OnClick=function()self=nil;f.checked=not f.checked;f:UpdateCheck();return 'native-toggle' end
    return f
end
local function Popup(parent)
    local f=UI(parent);Art(f);f.Text=UIText(f);f.data={};f.List=UI(f);f.List.logical={};f.root={preserved=true}
    f.Content=UI(f);f.Content.ButtonContainer=UI(f.Content);f.Content.ButtonContainer.List=f.List
    function f:HandleElementUpdate(element,index,value)element.index=index;element.value=value;return 'native-menu-row' end
    function f:Open(values)self.data=values or self.data;self.shown=true;self.List:RenderElements();return 'native-open',99 end
    function f.List:RenderElements()return 'native-elements' end
    return f
end
WUISettingFrame=UI(UIParent)
WUISettingFrame.Content=UI(WUISettingFrame);WUISettingFrame.Content.Container=UI(WUISettingFrame.Content)
WUISettingFrame.Sidebar=UI(WUISettingFrame);WUISettingFrame.Sidebar.Tab=UI(WUISettingFrame.Sidebar);WUISettingFrame.Sidebar.Footer=UI(WUISettingFrame.Sidebar)
WUISettingFrame.Prompt=Popup(UIParent);WUISettingFrame.SelectionMenu=Popup(WUISettingFrame)
WUISharedPrompt=Popup(UIParent);WUISharedInputPrompt=Popup(UIParent)
WUIWaypointFrame=UI(UIParent);WUIWaypointFrame.Footer=UI(WUIWaypointFrame)
WUIWaypointFrame.Footer.InfoText=UIText(WUIWaypointFrame.Footer,true)
WUIWaypointFrame.Footer.DistanceText=UIText(WUIWaypointFrame.Footer,true)
WUIWaypointFrame.Footer.ArrivalTimeText=UIText(WUIWaypointFrame.Footer,true)
WUIWaypointFrame.Arrow=UI(WUIWaypointFrame);Art(WUIWaypointFrame.Arrow);WUIWaypointFrame.Arrow.angle=.75
local tab,check,action,range,input,swatch,tabButton
local function Build()
    tab=UI(WUISettingFrame.Content.Container);tab.Content=UI(tab);tab.Layout=UI(tab.Content);tab.ScrollBar=UI(tab)
    tab.ScrollBar.Thumb=UI(tab.ScrollBar);Art(tab.ScrollBar.Thumb)
    tab.ScrollBar.Track=UI(tab.ScrollBar);Art(tab.ScrollBar.Track);tab.ScrollBar.HitRect=UI(tab.ScrollBar)
    tab.scroll=.5;tab.ScrollBar.scripts.OnMouseDown=function()tab.scroll=.7;return 'native-scroll' end
    local container=UI(tab.Layout);container.__widgetType=3;container.Background=UI(container);Art(container.Background)
    check=Checkbox(container);action=Button(container)
    range=UI(container);range.RangeThumb=UI(range);Art(range.RangeThumb);range.RangeTrack=UI(range);Art(range.RangeTrack)
    range.ForwardButton=Button(range);range.BackwardButton=Button(range);range.value=.5
    range.scripts.OnValueChanged=function(_,v)range.value=v;return 'native-value' end
    input=UI(container);input.Background=UI(input);Art(input.Background);input.HitRect=UI(input)
    input.Input=UI(input);input.Input.__Text=Text(input.Input);input.Input.__Text.text='native input'
    input.Input.scripts.OnTextChanged=function(_,v)input.value=v;return 'native-input' end
    input.Caret=UI(input);Art(input.Caret);input.Placeholder=UIText(input)
    swatch=UI(container);Art(swatch);swatch.Fill=UI(swatch);Art(swatch.Fill)
    swatch.FillTexture=swatch.Fill:GetTextureFrame();swatch.FillTexture.__Texture.color={.2,.4,.8,1}
    function swatch:OnColorChange(color)self.FillTexture.__Texture.color=color;return 'native-color' end
    tabButton=Button(WUISettingFrame.Sidebar.Tab);tabButton.isSelected=true
    function tabButton:SetSelected(v)self.isSelected=v;self:UpdateAnimation();return 'native-selection' end
end
module.install(S,module);Flush();assert(not tab,'skin forced construction')
Build();local r,x=WUISettingFrame:_Render();Flush()
assert(r=='native-render' and x==42 and check.check and action.button and not WUISettingFrame.panel)
assert(check.Background.__Texture.alpha==0 and check.checked and check.mouse and check.width==16)
local mark
for _,t in ipairs(check.regions)do if t.layer=='OVERLAY' and t.width==8 then mark=t end end
assert(mark and mark.alpha==1 and mark.color[1]==accent)
assert(check.checkFill.width==14 and check.checkFill.height==14 and check.checkBorder.alpha==0)
local edges=0;for _,t in ipairs(check.regions)do if t.layer=='OVERLAY' and (t.width==1 or t.height==1)then edges=edges+1 end end
assert(edges==4 and check.Background.alpha==1,'complete outline or native wrapper preservation failed')
assert(check.scripts.OnClick()=='native-toggle' and not check.checked and mark.alpha==0)
check.enabled=false;check:UpdateAnimation();assert(mark.color[1]==.4)
assert(action.scripts.OnClick()=='native-action' and nativeActions==1)
assert(action:UpdateAnimation()=='native-animation' and action.Background.__Texture.alpha==0 and action.Text.__Text.color[1]==.9)
assert(input.Input.__Text.text=='native input' and input.Caret.Background.__Texture.alpha==1 and input.Placeholder.__Text.alpha==1)
assert(input.Input.scripts.OnTextChanged(nil,'new text')=='native-input' and input.value=='new text')
assert(range.scripts.OnValueChanged(nil,.8)=='native-value' and range.value==.8)
assert(tab.ScrollBar.scripts.OnMouseDown()=='native-scroll' and tab.scroll==.7)
assert(swatch.FillTexture.__Texture.color[3]==.8 and swatch.FillTexture.__Texture.alpha==1 and swatch.Background.__Texture.alpha==0)
assert(swatch:OnColorChange({1,0,1,1})=='native-color' and swatch.FillTexture.__Texture.color[1]==1)
assert(WUIWaypointFrame.Footer.InfoText.__Text.path=='EUI' and WUIWaypointFrame.Footer.InfoText.__Text.color[2]==.2)
assert(WUIWaypointFrame.Arrow.angle==.75 and WUIWaypointFrame.Arrow.Background.__Texture.alpha==1)
local selected
for _,t in ipairs(tabButton.regions)do if t.layer=='OVERLAY' and t.width==2 then selected=t end end
assert(selected and selected.alpha==1 and selected.color[1]==accent)
assert(tabButton:SetSelected(false)=='native-selection' and selected.alpha==0)
-- Pooled menu rows and prompt actions keep all native data/callbacks.
local menu=WUISettingFrame.SelectionMenu
local row=Button(menu.List);row.selected=true
function row:IsSelected()return self.selected end
function row:Row_OnClick()self.selected=not self.selected;self:UpdateAnimation();return 'native-menu-action' end
assert(menu:HandleElementUpdate(row,1,'First')=='native-menu-row' and row.button and row.value=='First')
local open,extra=menu:Open({'First','Second'});assert(open=='native-open' and extra==99 and menu.root.preserved and #menu.data==2)
assert(row:Row_OnClick()=='native-menu-action' and not row.selected)
local promptButton=Button(WUISharedPrompt.List);WUISharedPrompt.List:RenderElements();assert(promptButton.button)
local objects,hooks,writes,logical,children,regions=allocated,hookCount,fontWrites,logicalReads,childReads,regionReads
for i=1,1000 do WUISettingFrame:_Render();tab:_Render();action:UpdateAnimation();check:UpdateCheck();menu:HandleElementUpdate(row,1,'New');menu:Open() end
assert(allocated==objects and hookCount==hooks and fontWrites==writes,'warm updates recreated UI/hooks/fonts')
assert(logicalReads==logical and childReads==children and regionReads==regions,'warm updates rescanned frame hierarchies')
-- Native typography resets are repaired on the one text wrapper, not the root.
assert(action.Text:UpdateFont()=='native-font' and action.Text.__Text.path=='EUI')
fontFace='EUI-next';accent=.75;looks[1]();Flush()
assert(mark.color[1]==.4 and selected.color[1]==.75 and action.Text.__Text.path=='EUI-next' and allocated==objects)
-- Late controls, native rebuilds, protected nodes and combat recovery.
combat=true;local late=Checkbox(tab.Layout);WUISettingFrame:_Render();looks[1]();Flush();assert(not late.check)
combat=false;for _,event in ipairs(events)do if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event,'PLAYER_REGEN_ENABLED')end end
Flush();assert(late.check)
local secure=Checkbox(tab.Layout);secure.protected=true;tab:_Render();assert(not secure.check)
enabled=false;local untouched=Checkbox(tab.Layout);tab:_Render();module.refresh();assert(not untouched.check)
enabled=true;module.refresh();Flush();assert(untouched.check)
assert(WUIWaypointFrame.Footer.InfoText.__Text.color[2]==.2 and WUIWaypointFrame.Arrow.Background.__Texture.alpha==1)
assert(#errors==0,table.concat(errors,'\n'))
print('PASS: Waypoint UI custom settings, complete native actions/state/input/colour semantics, renderer/font repair, menu pooling, prompts, HUD text, lazy construction, combat/protected/disabled guards and bounded hooks')
print('BENCH Waypoint UI mock: 1000 warm settings/tab/hover/check/menu cycles: 0 new UI objects/hooks/font writes or hierarchy walks')
