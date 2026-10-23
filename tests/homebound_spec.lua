-- Home Bound owned UI, native actions/artwork and refresh performance.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local secureCallbacks = {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local geometryWrites=0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'HomeBound'); factory = fn end
ns.RegisterModule = function(id, _, available, install) module = {id=id, available=available, install=install} end
geterrorhandler = function() return function(e) errors[#errors+1] = e end end
InCombatLockdown = function() return combat end
C_Timer = {After = function(_, fn)
    assert(type(fn)=='function' and not secureCallbacks[fn], 'C_Timer.After rejects securely hooked callbacks')
    timers[#timers+1] = fn
end}
hooksecurefunc = function(owner, key, callback)
    hookCount = hookCount + 1
    local original = owner[key]
    owner[key] = function(...)
        local values = table.pack(original(...)); callback(...); return table.unpack(values,1,values.n)
    end
    secureCallbacks[owner[key]] = true
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
    function f:GetBackdropColor() return table.unpack(self.bg or {.1,.1,.1,.9}) end
    function f:SetBackdropColor(...) self.bg={...} end
    function f:GetBackdropBorderColor() return table.unpack(self.border or {.3,.3,.3,1}) end
    function f:SetBackdropBorderColor(...) self.border={...} end
    function f:GetScrollChild() return self.scrollChild end
    function f:EnableRegenerateOnResponse() self.regenerate=true end
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
    function f:SetFontObject() error('unsafe FontObject assignment') end
    function f:GetFontObject() error('unsafe FontObject capture') end
    function f:GetTextColor() return table.unpack(self.color) end
    function f:SetTextColor(r,g,b,a) self.color[1],self.color[2],self.color[3],self.color[4]=r,g,b,a end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(v) self.alpha=v end
    function f:SetShown(v) if v then self:Show() else self:Hide() end end
    function f:SetRotation(v) self.rotation=v end
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
    function f:SetPoint(...) geometryWrites=geometryWrites+1;self.point={...} end
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
        local old=self.scripts[k]; self.scripts[k]=function(...) local r=old and table.pack(old(...)) or {n=0};fn(...);return table.unpack(r,1,r.n) end
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
S.Shell=function(f)
 if f.shell then return end
 f.shell=true
 for _,t in ipairs(f.regions)do if t.kind=='Texture'then t:SetAlpha(0)end end
 S.Panel(f)
end
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
local popupBinds=0
ns.BindPopupOwner=function() end
ns.BindPopupList=function(_,_,owner,list) popupBinds=popupBinds+1;list.boundOwner=owner end
assert(loadfile('EUIAddonSkins/Skins/HomeBound.lua'))('EUIAddonSkins',ns)
assert(factory and not module);factory();assert(not module.available())
UIParent=Object('Frame')
HB_MainFrame=CreateFrame('Frame','HB_MainFrame',UIParent)
HB_MainFrame.backdrop={bgFile='native-main',edgeFile='native-border'}
local close=Object('Button',HB_MainFrame);close.width,close.height=28,28
close.normal=close:CreateTexture(nil,'ARTWORK');close.normal:SetTexture(123456)
function close:GetPoint()return 'TOPRIGHT',HB_MainFrame,'TOPRIGHT',-2,-2 end
close.scripts.OnClick=function()HB_MainFrame:Hide();return 'native-close'end
local title=Text(HB_MainFrame);title:SetText('Home Bound');title.color={1,.82,0,1}
HB_MainFrame.art=HB_MainFrame:CreateTexture(nil,'BACKGROUND');HB_MainFrame.art:SetTexture('native-gradient')
HB_FilterButton=CreateFrame('DropdownButton','HB_FilterButton',HB_MainFrame)
HB_FilterButton.SetupMenu=function() return 'native-setup' end
HB_FilterButton.OnMenuOpened=function() return 'native-menu-open' end
HB_SearchBox=CreateFrame('EditBox','HB_SearchBox',HB_MainFrame);HB_SearchBox:SetText('search-kept')
local scroll=Object('ScrollFrame',HB_MainFrame);scroll.ScrollBar=Object('Frame',scroll)
scroll.ScrollBar.Track={Thumb=Object('Frame',scroll.ScrollBar)}
scroll.ScrollBar.Back=Object('Button',scroll.ScrollBar);scroll.ScrollBar.Forward=Object('Button',scroll.ScrollBar)
local list=Object('Frame',scroll);scroll.scrollChild=list
local dataCalls=0
BuildUI=function() dataCalls=dataCalls+1;list:SetHeight(100);return 'native-build' end
local nativeBuildUI=BuildUI
local function Tab(name,selected)
 local f=CreateFrame('Button','HB_Tab_'..name,HB_MainFrame);f.id=name:lower()
 f.backdrop={bgFile='native-tab',edgeFile='native-edge'}
 f.border=selected and {1,.82,0,1} or {.3,.3,.3,1}
 f.icon=f:CreateTexture(nil,'ARTWORK');f.icon:SetTexture('native-tab-icon')
 f.caption=Text(f);f.caption:SetText(name)
 f.scripts.OnClick=function()f:SetBackdropBorderColor(1,.82,0,1);return BuildUI()end
 return f
end
local tab=Tab('Decor',true);local bpTab=Tab('Blueprints',false)
local row=Object('Button',list);row.isLine=true;row.text=Text(row);row.text:SetText('Unlockable')
row.text.color={.2,1,.2,1};row.dot=row:CreateTexture(nil,'OVERLAY');row.dot:SetTexture('native-collected')
row.scripts.OnClick=function() return 'native-favorite' end
HB_ConfigFrame=CreateFrame('Frame','HB_ConfigFrame',UIParent)
local check=Object('CheckButton',HB_ConfigFrame);check:SetSize(32,32);check.Text=Text(check);check:SetChecked(true)
check.checkedArt=check:CreateTexture(nil,'ARTWORK');check.disabledArt=check:CreateTexture(nil,'ARTWORK')
check.scripts.OnClick=function()check.checked=not check.checked;return 'native-setting'end
HB_RewardFrame=CreateFrame('Frame','HB_RewardFrame',UIParent)
local preview=HB_RewardFrame:CreateTexture(nil,'ARTWORK');preview:SetTexture('native-reward-preview')
local model=Object('PlayerModel',HB_RewardFrame);model.scripts.OnUpdate=function()return 'native-rotation'end
HB_SmallPreviewFrame=CreateFrame('Frame','HB_SmallPreviewFrame',UIParent)
local smallImage=HB_SmallPreviewFrame:CreateTexture(nil,'ARTWORK');smallImage:SetTexture('native-thumbnail')
local menu={OpenMenu=function()return 'native-open'end,GetOpenMenu=function(self)return self.list end}
Menu={GetManager=function()return menu end}
Settings={RegisterCanvasLayoutCategory=function()return 'native-category'end}
local scale=Object('Frame',HB_ConfigFrame)
scale.Slider=Object('Slider',scale);scale.Slider.orientation='HORIZONTAL'
scale.Slider.width,scale.Slider.height=200,20
scale.Slider.thumb=scale.Slider:CreateTexture(nil,'ARTWORK');scale.Slider.thumb:SetSize(20,20)
scale.Slider.scripts.OnValueChanged=function(_,v)scale.value=v;return 'native-scale'end
scale.Back=Object('Button',scale);scale.Forward=Object('Button',scale)
assert(module.available());module.install(S,module);Flush()
-- HomeBound 1.60 main.lua:2721 schedules this callback directly after either
-- ACHIEVEMENT_EARNED or QUEST_TURNED_IN. The completed list hook must also style
-- rows added by that delayed native builder.
local previousData=dataCalls
for _,event in ipairs({'ACHIEVEMENT_EARNED','QUEST_TURNED_IN'}) do
    local replacement=Object('Button',list);replacement.isLine=true
    replacement.text=Text(replacement);replacement.text:SetText(event)
    C_Timer.After(.5,BuildUI);Flush()
    assert(replacement.text.path=='EUI', 'timer-driven new row stayed native')
end
assert(dataCalls==previousData+2, 'native timer must run the builder exactly once per event')
assert(BuildUI==nativeBuildUI, 'skin must not replace or securely hook a native timer callback')
local checkHost
for _,child in ipairs(check.children)do if child.mark then checkHost=child end end
local grip
for _,t in ipairs(scale.Slider.regions)do if t.width==6 and t.height==14 then grip=t end end
assert(checkHost and checkHost.width==22 and checkHost.height==22 and checkHost.mouse==false)
assert(checkHost.hover.width==14 and checkHost.hover.height==14,'hover exceeds visible checkbox')
assert(checkHost.mark.width==8 and checkHost.mark.height==8)
assert(grip and scale.Slider.thumb.alpha==0 and scale.Slider.thumb.width==20 and scale.Slider.thumb.height==20)
assert(scale.Slider.width==200 and scale.Slider.height==20,'native slider geometry changed')
assert(scale.Slider.scripts.OnValueChanged(scale.Slider,1.2)=='native-scale'and scale.value==1.2)
assert(scale.Back.glyph=='<'and scale.Forward.glyph=='>')
assert(HB_MainFrame.panel and close.close and HB_FilterButton.dropdown and HB_FilterButton.regenerate)
assert(checkHost.check and checkHost.mark.color[1]==accent and check.width==32 and check.height==32)
assert(check.checkedArt.alpha==0 and check.disabledArt.alpha==0)
assert(scroll.ScrollBar.scroll and HB_SearchBox.text=='search-kept')
assert(tab.icon.alpha==1 and tab.caption.color[1]==accent and not bpTab.selected)
assert(preview.alpha==1 and smallImage.alpha==1 and not model.walks and model.scripts.OnUpdate()=='native-rotation')
assert(row.dot.alpha==1 and row.text.color[2]==1 and row.scripts.OnClick()=='native-favorite')
local gallery,right,hero,card,manifest,manifestRow
local function Blueprints()
 HB_BlueprintsFrame=CreateFrame('Frame','HB_BlueprintsFrame',HB_MainFrame)
 gallery=Object('Frame',HB_BlueprintsFrame);gallery.backdrop={bgFile='native-gallery',edgeFile='native-border'}
 right=Object('Frame',HB_BlueprintsFrame);right.backdrop={bgFile='native-detail',edgeFile='native-border'}
 local galleryScroll=Object('ScrollFrame',gallery);galleryScroll.ScrollBar=Object('Frame',galleryScroll)
 local cards=Object('Frame',galleryScroll);galleryScroll.scrollChild=cards
 card=Object('Button',cards);card.bp={title='Blueprint'};card.backdrop={bgFile='native-card',edgeFile='native-card-border'}
 card.thumb=card:CreateTexture(nil,'ARTWORK');card.thumb:SetTexture('native-blueprint-thumb')
 card.title=Text(card);card.score=Text(card);card.score.color={1,.2,.2,1}
 card.scripts.OnClick=function()card:SetBackdropBorderColor(1,.82,0,1);return 'native-select'end
 local details=Object('Frame',right)
 hero=details:CreateTexture(nil,'ARTWORK');hero:SetTexture('native-hero-screenshot')
 local heroButton=Object('Button',details);heroButton.scripts.OnClick=function()return 'native-fullscreen'end
 local box=Object('EditBox',details);box:SetText('BlueprintShareCode')
 local import=Object('Button',details);import.Text=Text(import);import:Disable();import.Text:SetText('Import')
 local mf=Object('ScrollFrame',details);mf.ScrollBar=Object('Frame',mf)
 manifest=Object('Frame',mf);mf.scrollChild=manifest
 HB_BlueprintFullscreenFrame=CreateFrame('Frame','HB_BlueprintFullscreenFrame',UIParent)
 HB_BlueprintFullscreenFrame.image=HB_BlueprintFullscreenFrame:CreateTexture(nil,'ARTWORK')
 HB_BlueprintFullscreenFrame.image:SetTexture('native-full-image')
 HB_BlueprintFullscreenFrame.bg=HB_BlueprintFullscreenFrame:CreateTexture(nil,'BACKGROUND');HB_BlueprintFullscreenFrame.bg:SetColorTexture(0,0,0,.9)
 return box,import,heroButton
end
local box,import,heroButton=Blueprints()
for _,event in ipairs(events)do if event.scripts.OnEvent then event.scripts.OnEvent(event,'ADDON_LOADED','HomeBound_Blueprints')end end
Flush()
assert(card.thumb.alpha==1 and hero.alpha==1 and card.score.color[1]==1 and card.score.color[2]==.2)
assert(box.text=='BlueprintShareCode'and import.enabled==false and heroButton.scripts.OnClick()=='native-fullscreen')
assert(HB_BlueprintFullscreenFrame.image.alpha==1 and HB_BlueprintFullscreenFrame.bg.color[4]==.9)
assert(card.scripts.OnClick(card)=='native-select');Flush();assert(card.score.color[2]==.2)
manifestRow=Object('Button',manifest);manifestRow.qtyText=Text(manifestRow);manifestRow.qtyText.color={1,.2,.2,1}
manifestRow.nameText=Text(manifestRow);manifestRow.scripts.OnClick=function()return 'native-link'end
manifest:SetHeight(80);Flush()
assert(manifestRow.qtyText.path=='EUI'and manifestRow.qtyText.color[2]==.2 and manifestRow.scripts.OnClick()=='native-link')
-- A raised item rarity frame must not gain an opaque skin fill.
local container=Object('Frame',HB_RewardFrame);container.borderFrame=Object('Frame',container)
container.borderFrame.backdrop={edgeFile='native-rarity',edgeSize=2}
container.borderFrame.border={.8,.2,.8,1}
local icon=Object('Button',container.borderFrame);icon.image=icon:CreateTexture(nil,'ARTWORK');icon.image:SetTexture('native-epic-item')
module.refresh();Flush()
assert(container.borderFrame.backdrop.edgeFile=='native-rarity'and not container.borderFrame.panel and icon.image.alpha==1)
-- Restrict the popup styling to HomeBound's filter chain; never style foreign
-- compositor text or call its restricted font accessors.
local popup=Object('Frame');popup.GetOwnerRegion=function()return HB_FilterButton end
local desc={IsCheckbox=function()return true end,AddInitializer=function(self,fn)self.init=fn end}
local menuRow=Object('Frame',popup);menuRow.leftTexture1=menuRow:CreateTexture();menuRow.leftTexture2=menuRow:CreateTexture()
menuRow.GetElementDescription=function()return desc end
popup.EnumerateElementDescriptions=function(_,fn)fn(nil,desc)end
menu.list=popup;menu:OpenMenu();assert(popup.boundOwner==HB_FilterButton and menuRow.leftTexture2.color[1]==accent)
local foreign=Object('Frame');popup.GetOwnerRegion=function()return foreign end
local before=popupBinds;menu:OpenMenu();assert(popupBinds==before)
-- Repeated native BuildUI/list/gallery updates do not recreate skin resources
-- or revisit completed options/models/fullscreen art.
BuildUI();manifest:SetHeight(80);Flush()
local a,h,fw,c,r=allocated,hookCount,fontWrites,childReads,regionReads
local mainWalks=HB_MainFrame.walks;local optionsWalks=HB_ConfigFrame.walks
for _=1,1000 do row:Hide();row:Show();assert(BuildUI()=='native-build');manifest:SetHeight(80)end
assert(#timers<=1,'pooled row shows scheduled separate timer batches')
Flush()
assert(allocated==a and hookCount==h and fontWrites==fw,'warm refresh allocated skin objects/hooks/fonts')
assert(childReads==c and regionReads==r,'warm list refresh traversed stable hierarchy')
assert(HB_MainFrame.walks==mainWalks and HB_ConfigFrame.walks==optionsWalks)
local beforeData=dataCalls
fontFace='NextTheme';accent=.65;module.refresh();Flush()
assert(tab.caption.path=='NextTheme'and tab.caption.color[1]==accent and dataCalls==beforeData)
combat=true;local late=Object('Button',manifest);late.qtyText=Text(late);manifest:SetHeight(90)
assert(late.qtyText.path=='Native')
combat=false;for _,event in ipairs(events)do if event.scripts.OnEvent then event.scripts.OnEvent(event,'PLAYER_REGEN_ENABLED')end end
Flush();assert(late.qtyText.path=='EUI' or late.qtyText.path=='NextTheme')
enabled=false;local off=Object('CheckButton',HB_ConfigFrame);module.refresh();assert(not off.check)
assert(#errors==0,table.concat(errors,'; '))
print('PASS: HomeBound main/options/late Blueprints, native data/actions/previews/rarity/manifest colours, owned menus, combat/theme/toggles and 1000 warm list cycles')


-- Native hit rectangles and value callbacks remain unchanged while visual
-- state updates stay local, including disabled/checked and hover combinations.
enabled=true;module.refresh();Flush()
check:SetChecked(true);check:Enable()
assert(check.scripts.OnClick(check)=='native-setting'and not checkHost.mark:IsShown())
assert(check.scripts.OnClick(check)=='native-setting'and checkHost.mark:IsShown())
check.scripts.OnEnter(check);assert(checkHost.hover.alpha==1)
check.scripts.OnLeave(check);assert(checkHost.hover.alpha==0)
check:SetChecked(false);assert(not checkHost.mark:IsShown())
check:SetChecked(true);check:Disable();assert(checkHost.mark:IsShown()and checkHost.mark.color[1]==.4)
check.scripts.OnEnter(check);assert(checkHost.hover.alpha==0,'disabled checkbox has an enabled highlight')
check:Enable();assert(checkHost.mark.color[1]==accent)
local a,h,c,r,g,colors,fonts=allocated,hookCount,childReads,regionReads,geometryWrites,colourWrites,fontWrites
for _=1,1000 do
 check:SetChecked(true);check:Enable()
 scale.Slider.scripts.OnValueChanged(scale.Slider,1)
end
assert(allocated==a and hookCount==h and childReads==c and regionReads==r)
assert(geometryWrites==g and colourWrites==colors and fontWrites==fonts,'unchanged state reset checkbox geometry/artwork')
local thumbPoint=scale.Slider.thumb.point
scale.Slider.thumb:Hide();assert(not grip:IsShown())
scale.Slider.thumb:Show();assert(grip:IsShown()and scale.Slider.thumb.point==thumbPoint)
assert(check.width==32 and check.height==32 and scale.Slider.thumb.width==20)
assert(#errors==0,table.concat(errors,'; '))
print('BENCH HomeBound 1000 stable checkbox/slider callbacks: hierarchy reads=0 UI_objects=0 hooks=0 geometry_writes=0 texture_colour_writes=0 font_writes=0 (mock)')
