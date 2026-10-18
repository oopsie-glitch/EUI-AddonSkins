-- Native-control fixtures: actions, geometry, status colours, redraws and reuse.
local enabled, combat, accent, timers, events = true, false, 0.4, {}, {}
local ns = {IsEnabled = function() return enabled end, AttachAccent = function(_, f) f.accent = true end}
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) error(e) end end
hooksecurefunc = function(object, name, callback)
    local original = object[name]
    object[name] = function(...)
        local values = table.pack(original(...)); callback(...); return table.unpack(values, 1, values.n)
    end
end
local function texture(kind, parent)
    local t = {kind = kind or 'Texture', alpha = 1, path = 'native', parent = parent, points = {}}
    function t:GetObjectType() return self.kind end
    function t:Show() self.hidden = false end
    function t:Hide() self.hidden = true end
    function t:GetName() return self.name end
    function t:GetWidth() return self.width or 0 end
    function t:GetHeight() return self.height or 0 end
    function t:GetTexture() return self.path end
    function t:SetTexture(v) self.path = v end
    function t:GetAlpha() return self.alpha end
    function t:SetAlpha(v) self.alpha = v end
    function t:GetDrawLayer() return self.layer or 'ARTWORK' end
    function t:SetColorTexture(...) self.color = {...}; self.path = 'solid' end
    function t:SetVertexColor(...) self.color = {...} end
    function t:SetPoint(...) self.points[#self.points + 1] = {...} end
    function t:SetAllPoints() end
    function t:ClearAllPoints() self.points = {} end
    function t:SetShown(v) self.shown = v end
    function t:GetVertexColor() return table.unpack(self.color or {1, 1, 1, 1}) end
    function t:SetSize(w, h) self.width, self.height = w, h end
    function t:SetHeight(h) self.height = h end
    function t:SetWidth(w) self.width = w end
    function t:SetTexCoord(...) self.crop = {...} end
    function t:GetNumMaskTextures() return self.masked and 1 or 0 end
    function t:SetText(s) assert(self.font, "FontString:SetText(): Font not set"); self.text = s end
    function t:GetText() return self.text end
    function t:GetStringWidth()
        self.measureCalls=(self.measureCalls or 0)+1
        local width=#(self.text or '')*(self.font=='eui' and 8 or 4)
        return self.width and self.width>0 and math.min(self.width,width) or width
    end
    function t:GetUnboundedStringWidth()
        self.measureCalls=(self.measureCalls or 0)+1
        return #(self.text or '')*(self.font=='eui' and 8 or 4)
    end
    function t:SetJustifyH(value)self.justifyH=value end
    function t:GetFont() return self.font, self.font and 12, '' end
    function t:SetFont(v) self.font = v; self.fontWrites = (self.fontWrites or 0) + 1 end
    function t:SetFontObject(v) self.font = v end
    function t:SetTextColor(...) self.textColor = {...} end
    function t:GetTextColor() return table.unpack(self.textColor or {1, 1, 1, 1}) end
    function t:GetParent() return self.parent end
    return t
end
local function frame(kind, name, parent)
    local f = {kind = kind or 'Frame', name = name, parent = parent, regions = {}, children = {}, hooks = {}}
    function f:GetObjectType() return self.kind end
    function f:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function f:ClearAllPoints() self.points = {} end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:SetWidth(w) self.width = w end
    function f:GetID() return self.id end
    function f:IsShown() return not self.hidden end
    function f:Show() self.hidden = false end
    function f:Hide() self.hidden = true end
    function f:IsEnabled() return not self.disabled end
    function f:Enable() self.disabled = false end
    function f:Disable() self.disabled = true end
    function f:SetChecked(v) self.checked = v end
    function f:GetChecked() return self.checked end
    function f:GetName() return self.name end
    function f:GetParent() return self.parent end
    function f:IsForbidden() return self.forbidden end
    function f:IsProtected() return self.protected end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:HookScript(event, fn) local old = self.hooks[event]; self.hooks[event] = function(...) if old then old(...) end; fn(...) end end
    function f:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
    function f:SetScript(e, fn) self.hooks[e] = fn end
    function f:GetBackdrop() return self.backdrop end
    function f:SetBackdrop(b) assert(not combat); self.backdrop = b; self.color, self.border = {0, 0, 0, 1}, {0, 0, 0, 1} end
    function f:GetBackdropColor() return table.unpack(self.color) end
    function f:GetBackdropBorderColor() return table.unpack(self.border) end
    function f:SetBackdropColor(...) self.color = {...} end
    function f:SetBackdropBorderColor(...) self.border = {...} end
    function f:CreateTexture() local t = texture(nil, self); self.regions[#self.regions + 1] = t; return t end
    function f:CreateFontString(_, _, template) local t = texture('FontString', self); t.font = template; self.regions[#self.regions + 1] = t; return t end
    function f:GetNormalTexture() return self.normal end
    function f:GetWidth() return 24 end
    function f:GetHeight() return 24 end
    function f:GetFontString() return self.label end
    if parent then parent.children[#parent.children + 1] = f end
    if name then _G[name] = f end
    return f
end
CreateFrame = function(kind, name, parent) local f = frame(kind, name, parent); events[#events + 1] = f; return f end
local S = {GetAccentColor = function() return accent, 0.6, 0.7 end}
function S.Font(t, r, g, b) t:SetFont('eui'); if r then t:SetTextColor(r, g, b) end end
function S.Button(f, keys)
    local keep = {}; for _, key in ipairs(keys or {}) do keep[f[key] or false] = true end
    for _, t in ipairs(f.regions) do if t.kind == 'Texture' and not keep[t] then t:SetAlpha(0) end end
    if not f.pixelBorder then
        f.pixelBorder = frame('Frame', nil, f)
        for i = 1, 4 do
            local edge = f.pixelBorder:CreateTexture(); edge.layer = 'BORDER'; edge:SetSize(1, 24)
            edge:SetColorTexture(1, 1, 1, 1)
        end
    end
    f.button = true
end
function S.SquareIcon(t, parent) if t:GetNumMaskTextures() > 0 then return end; t:SetTexCoord(0.08, 0.92, 0.08, 0.92); t.borderParent = parent end
function S.PageButton(f, label) f.glyph = label end
function S.ScrollBar(f) f.scroll = true end
function S.Panel(f, options) f.panel = true; f.panelOptions = options end
function S.Shell(f, options) f.shell = true; f.shellOptions = options end
function S.Tab(f) f.tab = true end
function S.SetTabSelection(f, selected) f.selected = selected end
function S.CloseButton(f) f.close = true end
function S.Checkbox(f) f.checkbox = true end
function S.EditBox(f, options) f.input = true; f.inputOptions = options end
function S.Dropdown(f) f.dropdown = true end
function S.FadeNineSlice() end
SetPortraitTexture = function(t) t:SetTexture('player-face') end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
local modules, menus, looks = {}, {}, {}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
ns.BindPopupOwner = function(_, _, owner) if owner then menus[owner] = true end end
S.GetPanelColor = function() return 0.03, 0.03, 0.04, 0.95 end
S.GetFont = function() return 'eui', '' end
S.OnLooksChanged = function(fn) looks[#looks + 1] = fn end
S.Panel = function(f, options) assert(not f.protected and not combat); f.panel = true; f.panelOptions = options end

-- RestedXP-specific fixtures supplement the shared helper tests above.
local oldFrame = frame
frame = function(kind, name, parent)
    local f = oldFrame(kind,name,parent)
    f.color,f.border={0,0,0,1},{1,1,1,1}
    function f:GetFrameLevel() return 6 end
    function f:GetWidth() return self.width or 24 end
    function f:SetFrameLevel(n) self.level=n end
    function f:SetAllPoints(target) self.allPoints=target end
    function f:EnableMouse(value) self.mouse=value end
    function f:GetAlpha() return self.alpha or 1 end
    function f:SetAlpha(value) self.alpha=value end
    function f:SetHeight(value) self.height=value end
    function f:GetTextInsets() return table.unpack(self.insets or {0,0,3,3}) end
    function f:SetTextInsets(...) self.insets={...} end
    function f:GetJustifyV() return self.justify or 'TOP' end
    function f:SetJustifyV(value) self.justify=value end
    function f:GetFont() return self.font or 'native-font',12,'' end
    function f:SetFont(value) self.font=value end
    function f:GetTextColor() return table.unpack(self.textColor or {1,.82,0,1}) end
    function f:SetTextColor(...) self.textColor={...} end
    function f:GetOrientation() return self.orientation or 'HORIZONTAL' end
    function f:GetThumbTexture() return self.thumb end
    function f:Hide()
        self.hidden=true
        if self.hooks.OnHide then self.hooks.OnHide(self) end
        for _,child in ipairs(self.children) do if child.hooks.OnHide then child.hooks.OnHide(child) end end
    end
    return f
end
CreateFrame=function(kind,name,parent) local f=frame(kind,name,parent);events[#events+1]=f;return f end
local function art(parent,layer)
    local t=parent:CreateTexture();t.layer=layer or 'ARTWORK'
    function t:IsShown() return not self.hidden end
    function t:GetTexCoord() return table.unpack(self.crop or {0,1,0,1}) end
    return t
end
local function label(parent,text)
    local t=parent:CreateFontString(nil,'OVERLAY','native-font');t:SetText(text or 'Label');return t
end
local objects, scans, writes=0,0,0
local function surface(f,method)
    assert(not combat and not f.protected, 'unsafe visual creation')
    objects=objects+1;f.skinMethod=method
    f.fill=art(f,'BACKGROUND');f.fill:SetColorTexture(.04,.04,.045,1)
    f.markerMethod=method
end
S.Panel=function(f,opts) surface(f,'Panel');f.panelOptions=opts end
S.Button=function(f) surface(f,'Button') end
S.Dropdown=function(f) surface(f,'Dropdown');f.arrow=art(f,'OVERLAY');f.arrow:SetPoint('RIGHT',f,'RIGHT',-6,0) end
S.EditBox=function(f,opts) surface(f,'EditBox');f.inputOptions=opts end
S.PageButton=function(f,glyph) surface(f,'PageButton');f.glyph=glyph end
S.CloseButton=function(f)surface(f,'CloseButton')end
local realFont=S.Font
S.Font=function(...)writes=writes+1;return realFont(...)end
local function flush()
    local count=0
    while #timers>0 do
        local batch=timers;timers={}
        for _,fn in ipairs(batch)do fn()end
        count=count+1;assert(count<20,'refresh loop')
    end
end
local function widget(kind,parent)
    local w={type=kind,frame=frame('Frame',nil,parent and parent.frame),children={},parent=parent,userdata={appName='RestedXP Guides'}}
    if parent then parent.children[#parent.children+1]=w end
    return w
end
UIParent=frame('Frame')
local root=widget('BlizOptionsGroup');root.frame.icon=art(root.frame);root.frame.icon:SetTexture('RXP logo')
local tabs=widget('TabGroup',root);tabs.border=frame('Frame',nil,tabs.frame)
tabs.border.backdrop={edgeFile='native'};tabs.border.color={.1,.1,.1,1};tabs.border.border={1,1,1,1}
local tab=frame('Button',nil,tabs.frame);tab.Text=label(tab,'General');tab.selected=true;tab.native=art(tab,'BORDER');tabs.tabs={tab}
tabs.BuildTabs=function()return 'build-native' end
local page=widget('SimpleGroup',tabs)
local heading=widget('Heading',page);heading.label=label(heading.frame,'Features');heading.line=art(heading.frame)
local checkbox=widget('CheckBox',page);checkbox.checkbg=art(checkbox.frame);checkbox.check=art(checkbox.frame);checkbox.text=label(checkbox.frame,'Enabled')
checkbox.SetValue=function(self,value)self.checked=value;self.check:SetShown(value);self.check.hidden=not value;return 'check-native' end
checkbox:SetValue(true)
local button=widget('Button',page);button.text=label(button.frame,'Apply');button.native=art(button.frame);button.frame.hooks.OnClick=function()button.clicks=(button.clicks or 0)+1;return 'button-native'end
local slider=widget('Slider',page);slider.slider=frame('Slider',nil,slider.frame);slider.slider.thumb=art(slider.slider);slider.slider.thumb:SetSize(30,30)
slider.slider.backdrop={edgeFile='native'};slider.slider.color={0,0,0,1};slider.slider.border={1,1,1,1}
slider.editbox=frame('EditBox',nil,slider.frame);slider.editbox.value='100%';slider.editbox.width=70;slider.editbox.height=14
slider.label=label(slider.frame,'Scale');slider.lowtext=label(slider.slider,'20%');slider.hightext=label(slider.slider,'200%')
local dropdown=widget('Dropdown',page);dropdown.dropdown=frame('Frame',nil,dropdown.frame);dropdown.dropdown.native=art(dropdown.dropdown)
dropdown.button=frame('Button',nil,dropdown.frame);dropdown.button.native=art(dropdown.button)
dropdown.text=label(dropdown.frame,'Custom');dropdown.label=label(dropdown.frame,'Theme')
dropdown.button_cover=frame('Button',nil,dropdown.frame)
dropdown.frame.hooks.OnMouseDown=function()dropdown.clicks=(dropdown.clicks or 0)+1 end
dropdown.button.hooks.OnClick=dropdown.frame.hooks.OnMouseDown
dropdown.button_cover.hooks.OnClick=dropdown.frame.hooks.OnMouseDown
local popup={frame=frame('Frame',nil,UIParent),userdata={obj=dropdown},items={}};dropdown.pullout=popup
popup.frame.backdrop={edgeFile='native'};popup.frame.color={0,0,0,1};popup.frame.border={1,1,1,1}
popup.Open=function(self)self.frame.hidden=false;return 'open-native'end
popup.OnRelease=function(self)self.frame:Hide();return 'release-native'end
local itemFrame=frame('Frame',nil,popup.frame)
popup.items[1]={text=label(itemFrame,'Option'),check=art(itemFrame)}
popup.items[1].text:SetTextColor(.5,.5,.5,.8)
local swatch=widget('ColorPicker',page);swatch.color=art(swatch.frame);swatch.color:SetVertexColor(1,.2,.1,.7)
local foreign=widget('Button');foreign.userdata.appName='Other addon';foreign.text=label(foreign.frame);foreign.native=art(foreign.frame)
local dialog={BlizOptions={['RestedXP Guides']={['']=root}},OpenFrames={}}
dialog.FeedGroup=function(_,app,_,container)return 'feed-native',nil,container end
dialog.Open=function(_,app,container)return 'open-native'end
local previousLibStub=LibStub
LibStub=function(name)if name=='AceConfigDialog-3.0' then return dialog end end
local targetPerf=frame('Frame',nil,UIParent)
targetPerf.backdrop={bgFile='native',edgeFile='native'};targetPerf.color={.1,.1,.1,.85}
targetPerf.title=frame('Frame',nil,targetPerf);targetPerf.title.text=label(targetPerf.title,'Active Targets')
targetPerf.title.text.width=24 -- simulate a stale width left by the old face
targetPerf.UpdateVisuals=function(self)
    self.title.text:SetFont('native-font');self.title:SetSize(self.title.text:GetStringWidth()+10,19)
    return 'target-visuals'
end
local targetCalls=0
local targetApi={activeTargetFrame=targetPerf,UpdateTargetFrame=function()targetCalls=targetCalls+1;return 'target-native'end,
    RenderTargetFrameBackground=function(self)self.activeTargetFrame:SetBackdropColor(.1,.1,.1,.85);return 'background-native'end}
local v2Ui={ApplyFrameBackdrop=function(_,f,_,bg)f.backdrop={bgFile='native'};f.color=bg;return 'backdrop-native'end}
RXP={v2={state={},GetTheme=function()return {}end,GetGuideWindow=function(self)return self.state.guideWindow,nil,'getter-tail'end},targeting=targetApi,ui={v2=v2Ui},title='RestedXP Guides',LoadActiveTheme=function()return {font='original',background={.1,.1,.1,1}}end}
assert(loadfile('EUIAddonSkins/Skins/RXPGuides.lua'))('EUIAddonSkins',ns)
local m=modules.RXPGuides
local arrow=frame('Frame',nil,UIParent);arrow:SetSize(32,32);arrow:SetPoint('TOP',UIParent,'TOP',0,-20)
arrow.texture=art(arrow);arrow.text=label(arrow,'Step 2\n(71yd)')
local textureWrites,rotations=0,0
local nativeSetTexture=arrow.texture.SetTexture
arrow.texture.SetTexture=function(self,value)textureWrites=textureWrites+1;nativeSetTexture(self,value)end
arrow.texture.GetTexCoord=function(self)return table.unpack(self.crop or {0,1,0,1})end
arrow.texture.SetRotation=function(self,value)self.rotation=value;rotations=rotations+1 end
arrow.texture:SetRotation(.75)
arrow.UpdateVisuals=function(self)self.texture:SetTexture('native-arrow');return 'visual-native'end
RXP.arrowFrame=arrow
RXP.DrawArrow=function(self)
    self.texture:SetRotation(.5);self.text:SetText('Step 3\n(32yd)');self.distance=32
    return 'direction-native'
end
RXP.SetupArrow=function()
    arrow:UpdateVisuals();arrow.text:SetFont('native-font');arrow.hooks.OnUpdate=RXP.DrawArrow
    return 'setup-native',nil,'setup-tail'
end
arrow.hooks.OnMouseDown=function()return 'drag-native'end
arrow.hooks.OnUpdate=RXP.DrawArrow
local nativeDraw=RXP.DrawArrow
local baseScan=ns.CreateSkinHelper
ns.CreateSkinHelper=function(...)
    local h=baseScan(...);local scan=h.Scan
    h.Scan=function(...)scans=scans+1;return scan(...)end
    return h
end
m.install(S,m);flush()
local arrowPath='Interface\\AddOns\\EUIAddonSkins\\Media\\NavigationArrow.tga'
assert(arrow.texture.crop[1]==0 and arrow.texture.crop[2]==1 and arrow.texture.crop[3]==0 and arrow.texture.crop[4]==1,
    'pointer canvas was cropped or stretched')
assert(arrow.texture.path==arrowPath and arrow.texture.color[1]==accent and arrow.texture.rotation==.75,
    'arrow artwork/accent changed its bearing')
assert(arrow.text.font=='eui' and arrow.text.text=='Step 2\n(71yd)' and arrow.width==32 and arrow.height==32,
    'arrow changed label content, size or positioning')
assert(arrow.hooks.OnMouseDown()=='drag-native' and arrow.hooks.OnUpdate==nativeDraw and RXP.DrawArrow==nativeDraw,
    'arrow skin replaced native movement or per-frame callbacks')
local aw,ar,ao,af=textureWrites,rotations,objects,writes
for i=1,100 do assert(arrow.hooks.OnUpdate(arrow)=='direction-native')end
assert(textureWrites==aw and rotations==ar+100 and objects==ao and writes==af and #timers==0,
    'native direction updates trigger skin work')
assert(arrow.text.text=='Step 3\n(32yd)' and arrow.distance==32)
local setup,empty,tail=RXP.SetupArrow()
assert(setup=='setup-native' and empty==nil and tail=='setup-tail' and arrow.texture.path==arrowPath and arrow.text.font=='eui')
assert(arrow:UpdateVisuals()=='visual-native' and arrow.texture.path==arrowPath,'native theme reset lost arrow styling')
assert(targetPerf.title.width==#'Active Targets'*8+12 and targetPerf.title.text.text=='Active Targets'
    and targetPerf.width>=targetPerf.title.width+10,'initial target title clipped before first click')
assert(root.frame.icon.alpha==1 and root.frame.icon.path=='RXP logo','branding changed')
assert(button.native.alpha==0 and button.text.font=='eui' and heading.line.alpha==0)
assert(checkbox.checkbg.alpha==0 and checkbox.checked and checkbox.check.hidden==false)
assert(tab.native.alpha==0 and tab.Text.textColor[1]==accent,'selected tab lacks accent')
assert(slider.slider.thumb.alpha==0 and slider.slider.thumb.width==30,'native grip geometry changed')
assert(slider.editbox.insets[1]==6 and slider.editbox.insets[3]==0 and slider.editbox.justify=='MIDDLE'
    and slider.editbox.width==70 and slider.editbox.value=='100%','numeric input geometry/value changed')
assert(swatch.color.alpha==1 and swatch.color.color[2]==.2,'semantic swatch changed')
local out,empty,tail=dialog:FeedGroup('RestedXP Guides',{},page,root,{})
assert(out=='feed-native' and empty==nil and tail==page)
assert(button.frame.hooks.OnClick()=='button-native' and button.clicks==1)
dropdown.button.hooks.OnClick();dropdown.button_cover.hooks.OnClick();assert(dropdown.clicks==2,'dropdown handler lost')
button.disabled=true;button.text:SetTextColor(.5,.5,.5,.1)
dialog:FeedGroup('RestedXP Guides',{},page,root,{})
assert(button.text.textColor[1]==.5 and button.text.textColor[4]==1,'disabled label remained nearly invisible')
button.disabled=false
dialog:FeedGroup('RestedXP Guides',{},page,root,{})
local total=objects;local feedHook=dialog.FeedGroup;local initialWrites=writes
for i=1,25 do dialog:FeedGroup('RestedXP Guides',{},page,root,{})end
flush();assert(objects==total and dialog.FeedGroup==feedHook and scans==0,'page navigation allocates layers/hooks or scans guide')
assert(writes==initialWrites,'unchanged navigation rewrites fonts')
dialog:FeedGroup('Other addon',{},foreign,foreign,{})
assert(foreign.native.alpha==1 and foreign.text.font=='native-font','foreign options styled')
assert(popup:Open()=='open-native' and popup.frame:GetBackdrop()==nil and popup.items[1].text.font=='eui')
assert(popup.items[1].text.textColor[1]==.5 and popup.items[1].text.textColor[4]==.8,'disabled menu colour changed')
local popupObjects=objects
popup:OnRelease();assert(popup.frame:GetBackdrop().edgeFile=='native' and popup.items[1].text.font=='native-font')
for i=1,10 do popup:Open();popup:OnRelease()end
assert(objects==popupObjects,'reopening menu allocates more layers')
popup.userdata.obj=foreign;popup:Open()
assert(popup.frame:GetBackdrop().edgeFile=='native' and popup.items[1].text.font=='native-font','pooled menu leaked')
popup.userdata.obj=dropdown
button.frame:Hide();assert(button.native.alpha==1 and button.text.font=='native-font','pooled button not restored')
button.userdata={} -- standalone AceGUI users do not necessarily inject appName
button.parent=nil;button.frame.hidden=false
if button.frame.hooks.OnShow then button.frame.hooks.OnShow(button.frame)end
assert(button.native.alpha==1,'pooled button restyled for another addon')
button.userdata.appName='RestedXP Guides';button.parent=page;dialog:FeedGroup('RestedXP Guides',{},page,root,{})
assert(button.native.alpha==0)
combat=true
local late=widget('Button',page);late.text=label(late.frame,'Late');late.native=art(late.frame)
dialog:FeedGroup('RestedXP Guides',{},page,root,{})
assert(late.native.alpha==1,'new control modified during combat')
combat=false
for _,f in ipairs(events)do if f.events and f.events.PLAYER_REGEN_ENABLED then f.hooks.OnEvent(f,'PLAYER_REGEN_ENABLED')end end
flush();assert(late.native.alpha==0,'combat-deferred options lost')
accent=.8;for _,fn in ipairs(looks)do fn()end;flush()
assert(tab.Text.textColor[1]==.8 and arrow.texture.color[1]==.8,'theme refresh lost selected accent/arrow tint')
arrow:SetSize(48,48);arrow:UpdateVisuals()
assert(arrow.width==48 and arrow.height==48,'arrow skin overrode native scale setting')
combat=true
arrow:UpdateVisuals();assert(arrow.texture.path=='native-arrow','arrow themed during combat')
combat=false
for _,f in ipairs(events)do if f.events and f.events.PLAYER_REGEN_ENABLED then f.hooks.OnEvent(f,'PLAYER_REGEN_ENABLED')end end
flush();assert(arrow.texture.path==arrowPath,'combat-deferred arrow styling lost')
enabled=false;for _,fn in ipairs(looks)do fn()end;flush()
assert(button.native.alpha==1 and slider.slider.thumb.alpha==1 and slider.editbox.insets[3]==3,'disable did not restore native pooled controls')
assert(button.frame.hooks.OnClick()=='button-native' and checkbox:SetValue(false)=='check-native')
arrow:UpdateVisuals();assert(arrow.texture.path=='native-arrow','disabled skin still restyled arrow')
-- Known guide/item visuals remain local and never enroll secure action frames.
enabled=true
local guide=frame('Frame',nil,UIParent);guide.backdrop={edge={},guideName={},bottom={}}
guide.BottomFrame=frame('Frame',nil,guide);guide.BottomFrame.backdrop={bgFile='native',edgeFile='native'}
guide.GuideName=frame('Frame',nil,guide);guide.GuideName.backdrop={bgFile='native',edgeFile='native'}
guide.GuideName.icon=art(guide.GuideName);guide.GuideName.text=label(guide.GuideName,'Guide')
local step=frame('Frame',nil,guide);step.backdrop={bgFile='native',edgeFile='native'}
guide.CurrentStepFrame={framePool={step}}
local check=frame('CheckButton',nil,step);check.checked=true
check.normal=art(check);check.checkedArt=art(check);check.normal:SetTexture('native box')
check.GetCheckedTexture=function(self)return self.checkedArt end
local skip=check.SetChecked
local iconFrame=frame('Frame',nil,UIParent);iconFrame.backdrop={bgFile='native',edgeFile='native'}
iconFrame.title=frame('Frame',nil,iconFrame);iconFrame.title.text=label(iconFrame.title,'Active Items')
iconFrame.title.backdrop={bgFile='native',edgeFile='native'}
iconFrame.UpdateVisuals=function(self)
    self:SetBackdropColor(.1,.1,.1,.4) -- native V1 hard-coded opacity
    self.title.text:SetFont('native-font');self.title:SetSize(self.title.text:GetStringWidth()+10,19)
    return 'item-native'
end
iconFrame.UpdateFrame=function()return 'item-update' end
local secure=frame('Button',nil,iconFrame);secure.protected=true;secure.icon=art(secure);secure.hooks.OnClick=function()return 'use-native'end
iconFrame.buttonList={secure}
RXP.activeItemFrame=iconFrame;RXP.RXPFrame=guide
RXP.settings={profile={activeTheme='Custom'}}
modules.RXPGuides.refresh();flush()
assert(guide.GuideName.points[1][3]=='TOPLEFT' and guide.GuideName.points[1][5]==0,'guide header still overlaps list')
assert(guide.GuideName.icon.alpha==0 and guide.GuideName.text.points[1][4]==6
    and guide.GuideName.text.points[2][4]==-6 and guide.GuideName.text.justifyH=='CENTER','logo was not removed and title centered')
assert(check.checkedArt.color[1]==accent and check.checked and check.SetChecked==skip,'guide completion/skip action changed')
check.normal:SetAlpha(1);assert(check.normal.alpha==0,'native guide checkbox chrome reappeared')
assert(iconFrame.skinMethod==nil and iconFrame.children[#iconFrame.children].skinMethod=='Panel','item container not styled separately')
assert(secure.skinMethod==nil and secure.hooks.OnClick()=='use-native' and secure.width==nil,'secure item action changed')
local function panelOf(f)
    for _,child in ipairs(f.children)do if child.skinMethod=='Panel' then return child end end
end
local targetLayer,itemLayer=panelOf(targetPerf),panelOf(iconFrame)
assert(targetLayer.alpha==.85 and itemLayer.alpha==targetLayer.alpha,'active backgrounds differ')
assert(iconFrame.title.width==#'Active Items'*8+12 and iconFrame.title.text.text=='Active Items','initial item title clipped')
assert(targetPerf:UpdateVisuals()=='target-visuals' and targetPerf.title.width==#'Active Targets'*8+12,'native redraw clipped target title')
assert(iconFrame:UpdateVisuals()=='item-native' and iconFrame.title.width==#'Active Items'*8+12,'native redraw clipped item title')
flush()
local measureUnbounded=targetPerf.title.text.GetUnboundedStringWidth
targetPerf.title.text.GetUnboundedStringWidth=nil
targetPerf.title.text:SetText('Aktiva mål');targetPerf.title.text:SetWidth(24)
targetPerf:UpdateVisuals();flush()
assert(targetPerf.title.text.text=='Aktiva mål' and targetPerf.title.width==#'Aktiva mål'*8+12,
    'legacy width fallback truncated or replaced localized title')
targetPerf.title.text.GetUnboundedStringWidth=measureUnbounded
targetPerf.title.text:SetText('Active Targets');targetPerf:UpdateVisuals();flush()
targetPerf:SetBackdropColor(.1,.1,.1,.65)
assert(targetLayer.alpha==.65 and itemLayer.alpha==.65,'matching item opacity did not follow target changes synchronously')
iconFrame:SetBackdrop(nil);assert(itemLayer.alpha==0 and targetLayer.alpha==.65,'hidden item background restored')
iconFrame:SetBackdrop({bgFile='native',edgeFile='native'});iconFrame:SetBackdropColor(.1,.1,.1,.4)
assert(itemLayer.alpha==targetLayer.alpha,'native item opacity reset broke matching')
targetPerf:SetBackdrop(nil)
assert(targetLayer.alpha==0 and itemLayer.alpha==.65,'target hide-background incorrectly hides/restores item background')
targetPerf:SetBackdrop({bgFile='native',edgeFile='native'});targetPerf:SetBackdropColor(.1,.1,.1,.65)
assert(iconFrame.UpdateFrame()=='item-update');flush()
local count=objects
for i=1,20 do iconFrame.UpdateFrame()end
flush();assert(objects==count,'item refresh creates new visual objects')
combat=true
local more=art(secure);secure.icon=more
iconFrame.UpdateFrame();flush();assert(not more.crop,'secure icon modified during combat')
combat=false
for _,f in ipairs(events)do if f.events and f.events.PLAYER_REGEN_ENABLED then f.hooks.OnEvent(f,'PLAYER_REGEN_ENABLED')end end
flush()
scans=0
local stableObjects,stableWrites,stableMeasures=objects,writes,targetPerf.title.text.measureCalls
for i=1,100 do assert(targetApi:UpdateTargetFrame()=='target-native')end
flush()
assert(scans==0 and objects==stableObjects and writes==stableWrites,'target data updates scan guide or allocate/style controls')
assert(targetPerf.title.text.measureCalls==stableMeasures,'target data updates repeatedly measure title')
print('BENCH rxp_target_burst scans='..scans..' callbacks='..targetCalls)
scans=0
for i=1,100 do assert(targetApi:RenderTargetFrameBackground()=='background-native')end
flush();assert(scans==0 and objects==stableObjects and writes==stableWrites,'target background burst restyled guide/options')
assert(targetPerf.title.text.measureCalls==stableMeasures,'background bursts repeatedly measure unchanged titles')
print('BENCH rxp_target_background_burst scans='..scans..' callbacks=100')
scans=0
for i=1,100 do assert(v2Ui:ApplyFrameBackdrop(guide.BottomFrame,{}, {.1,.1,.1,.8})=='backdrop-native')end
flush();assert(scans==0 and objects==stableObjects,'known V2 background updates scan guide')
print('BENCH rxp_known_backdrop_burst scans='..scans..' callbacks=100')
-- A genuinely new V2 control still triggers one completed discovery pass.
local discovered=frame('Frame',nil,guide);discovered.backdrop={bgFile='native'}
v2Ui:ApplyFrameBackdrop(discovered,{}, {.1,.1,.1,.8});flush()
assert(scans==1,'new V2 background lost discovery/coalescing')
local v2Window={frame=frame('Frame',nil,UIParent)}
v2Window.guideNameFrame=frame('Frame',nil,v2Window.frame)
v2Window.guideNameFrame.backdrop={bgFile='native',edgeFile='native'}
v2Window.iconLogo=art(v2Window.guideNameFrame);v2Window.classIcon=art(v2Window.guideNameFrame)
v2Window.title=label(v2Window.guideNameFrame,'Guide V2');v2Window.subtitle=label(v2Window.guideNameFrame,'Subtitle')
v2Window.settingsButton=frame('Button',nil,v2Window.guideNameFrame);v2Window.settingsButton.width=21
v2Window.guideSelectButton=frame('Button',nil,v2Window.guideNameFrame);v2Window.guideSelectButton.width=21
v2Window.UpdateFrameLayout=function(self)self.title:ClearAllPoints();self.title:SetPoint('TOPLEFT',self.guideNameFrame,'TOPLEFT',42,-6);return 'layout-native'end
v2Window.RefreshLayout=function()return 'refresh-native'end
RXP.v2.state.guideWindow=v2Window
m.refresh();flush()
assert(v2Window.iconLogo.alpha==0 and v2Window.classIcon.alpha==0 and v2Window.title.justifyH=='CENTER','V2 guide branding/title missed')
assert(v2Window:UpdateFrameLayout()=='layout-native' and v2Window.title.points[1][4]==62 and v2Window.title.points[2][4]==-62,
    'V2 layout reset centering or overlapped native control space')
scans=0
for i=1,100 do local w,empty,tail=RXP.v2:GetGuideWindow();assert(w==v2Window and empty==nil and tail=='getter-tail')end
flush();assert(scans==0,'reading the existing V2 guide triggers scans')
for i=1,100 do assert(v2Window:RefreshLayout()=='refresh-native')end
flush();assert(scans==1,'V2 resize burst did not stay within one guide-window scan')
print('BENCH rxp_v2_known_getter scans=0 callbacks=100; layout scans='..scans..' callbacks=100')
ns.CreateSkinHelper=baseScan;LibStub=previousLibStub
print('PASS: RXP page-local options, native actions/values/branding, dropdown pool cleanup, input alignment, no warm objects/font writes, themes, disabled state and combat deferral')
