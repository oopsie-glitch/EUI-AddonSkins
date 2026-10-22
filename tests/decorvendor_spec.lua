-- Home Bound owned UI, native actions/artwork and refresh performance.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local geometryWrites=0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'DecorVendor'); factory = fn end
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
assert(loadfile('EUIAddonSkins/Skins/DecorVendor.lua'))('EUIAddonSkins',ns)
assert(factory and not module);factory();assert(not module.available())
DVD={ADDON_NAME='Unrelated'};assert(not module.available())
local app={ADDON_NAME='DecorVendor',currentTab='vendors',activeWidgets={},bottomTabs={}}
DVD=app;assert(module.available())
UIParent=Object('Frame')
local function Button(parent,label)
 local f=Object('Button',parent);f.Text=Text(f);f.Text:SetText(label or 'Action')
 f.normal=f:CreateTexture(nil,'ARTWORK');f.normal:SetTexture('native-red-button')
 return f
end
app.frame=CreateFrame('Frame','DV_MainFrame',UIParent)
app.frame.backdrop={bgFile='native-main',edgeFile='native-edge'}
app.titleBar=CreateFrame('Frame','DV_TitleBar',app.frame)
app.sidebar=Object('Frame',app.frame);app.sidebarFilters=Object('Frame',app.sidebar)
app.contentArea=Object('Frame',app.frame);app.listPanel=Object('Frame',app.contentArea)
app.scrollChild=Object('Frame',app.listPanel)
app.previewPanel=Object('Frame',app.contentArea);app.modelBox=Object('Frame',app.previewPanel)
app.modelBox.modelBg=app.modelBox:CreateTexture(nil,'BACKGROUND');app.modelBox.modelBg:SetTexture('native-ornate-model-background')
app.modelScene=Object('ModelScene',app.modelBox)
app.modelScene.scripts.OnUpdate=function()return 'native-rotation'end
app.modelControls=Object('Frame',app.modelBox);local camera=Button(app.modelControls,'Rotate')
camera.scripts.OnClick=function()return 'native-camera'end
app.itemContainer=Object('Frame',app.previewPanel);local status=Text(app.itemContainer);status.color={1,.2,.2,1}
local search=Object('EditBox',app.titleBar);search:SetText('search-kept');search.width=250
local customBorder=Object('Frame',search);customBorder.backdrop={edgeFile='native-blue-outline'}
local settingsButton=Button(app.titleBar,'Settings');settingsButton.scripts.OnClick=function()return 'native-settings'end
app.tabBar=Object('Frame',app.frame)
for _,id in ipairs({'vendors','professions'})do
 local tab=Object('Button',app.tabBar);tab.id=id;tab.text=Text(tab);tab.text:SetText(id)
 tab.bg=tab:CreateTexture(nil,'BACKGROUND');tab.accent=tab:CreateTexture(nil,'ARTWORK');tab.icon=tab:CreateTexture(nil,'ARTWORK')
 tab.icon:SetTexture('native-tab-icon');app.bottomTabs[#app.bottomTabs+1]=tab
end
app.RefreshTabVisuals=function()
 for _,tab in ipairs(app.bottomTabs)do tab.bg:SetColorTexture(.1,.05,.2,1);tab.text:SetTextColor(1,.82,0,1)end
 return 'native-tabs'
end
local header=Object('Button',app.scrollChild);header.isUniversalHeader=true
header.bg=header:CreateTexture(nil,'BACKGROUND');header.accent=header:CreateTexture(nil,'ARTWORK')
header.text=Text(header);header.text:SetText('Midnight')
header.progress=Text(header);header.progress.color={.4,1,.4,1}
header.scripts.OnClick=function()return 'native-collapse'end
header.scripts.OnEnter=function()header.bg:SetColorTexture(.2,.1,.3,1)end
header.scripts.OnLeave=function()header.bg:SetColorTexture(.1,.05,.2,1)end
local tile=Object('Button',app.scrollChild);tile.slotBg=tile:CreateTexture(nil,'BACKGROUND')
tile.slotBg:SetTexture('native-gold-slot');tile.hoverBg=tile:CreateTexture(nil,'BACKGROUND')
tile.icon=tile:CreateTexture(nil,'ARTWORK');tile.icon:SetTexture('native-portrait')
tile.collected=tile:CreateTexture(nil,'OVERLAY');tile.collected:SetTexture('native-collected')
tile.scripts.OnClick=function()return 'native-waypoint'end
app.activeWidgets={header,tile}
local dataCalls=0
app.BuildVendorUI=function()dataCalls=dataCalls+1;return 'native-build'end
app.BuildVendorFilters=function()return 'native-filters'end
app.CreateOptionsPanel=function()return 'native-options'end
app.ApplyFontSettings=function()return 'native-font-option'end
app.ShowVendorPopup=function()return 'native-vendor'end
app.ShowReagentsPopup=function()return 'native-reagents'end
app.OpenMainUI=function()return 'native-open'end
Settings={RegisterCanvasLayoutCategory=function()return 'native-category'end,
 RegisterCanvasLayoutSubcategory=function()return 'native-subcategory'end}
DV_ConfigFrame=CreateFrame('Frame','DV_ConfigFrame',UIParent)
local check=Object('CheckButton',DV_ConfigFrame);check:SetSize(32,32);check.Text=Text(check)
check.checkedArt=check:CreateTexture(nil,'ARTWORK');check.disabledArt=check:CreateTexture(nil,'ARTWORK')
check.scripts.OnClick=function()check.checked=not check.checked;return 'native-toggle'end
local sideCheck=Object('CheckButton',app.sidebarFilters);sideCheck:SetSize(20,20);sideCheck.label=Text(sideCheck)
sideCheck.label.color={.1,1,.3,1};sideCheck.customBg=Object('Frame',sideCheck)
sideCheck.customBg.backdrop={bgFile='native',edgeFile='native-blue'}
sideCheck.checkedArt=sideCheck:CreateTexture(nil,'ARTWORK');sideCheck.disabledArt=sideCheck:CreateTexture(nil,'ARTWORK')
local scale=Object('Frame',DV_ConfigFrame);scale.Slider=Object('Slider',scale);scale.Slider.orientation='HORIZONTAL'
scale.Slider.thumb=scale.Slider:CreateTexture(nil,'ARTWORK');scale.Slider.thumb:SetSize(20,20)
scale.Slider.scripts.OnValueChanged=function(_,v)scale.value=v;return 'native-scale'end
scale.Back=Button(scale);scale.Forward=Button(scale)
local subcategory={};app.optionsCategory={GetSubcategories=function()return {subcategory}end}
local donations=Object('Frame',UIParent);donations.parent='Decor Vendor';local credit=Text(donations);credit:SetText('Author credit kept')
SettingsPanel={GetLayout=function(_,category)
 return {GetFrame=function()return category==subcategory and donations or DV_ConfigFrame end}
end,DisplayCategory=function()return 'native-category-display'end}
module.install(S,module);Flush()
assert(app.frame.shell and app.sidebar.regions[1]and not app.modelScene.walks)
assert(not app.modelControls.walks and not camera.button and camera.scripts.OnClick()=='native-camera')
assert(app.modelBox.modelBg.alpha==0 and app.modelScene.scripts.OnUpdate()=='native-rotation')
assert(status.color[1]==1 and status.color[2]==.2 and search.text=='search-kept')
assert(customBorder.border[1]==.22 and header.progress.color[2]==1)
assert(tile.icon.alpha==1 and tile.collected.alpha==1 and tile.slotBg.texture=='native-gold-slot')
assert(settingsButton.button and settingsButton.scripts.OnClick()=='native-settings')
assert(app.bottomTabs[1].accent.alpha==1 and app.bottomTabs[2].accent.alpha==0)
assert(app.RefreshTabVisuals()=='native-tabs'and app.bottomTabs[1].text.color[1]==accent)
app.currentTab='professions';app.RefreshTabVisuals();assert(app.bottomTabs[1].accent.alpha==0 and app.bottomTabs[2].accent.alpha==1)
local host;for _,f in ipairs(check.children)do if f.mark then host=f end end
assert(host and host.width==22 and host.hover.width==14 and check.width==32)
assert(check.scripts.OnClick(check)=='native-toggle'and host.mark:IsShown())
assert(not sideCheck.customBg:IsShown()and sideCheck.label.color[2]==1)
assert(credit.text=='Author credit kept'and credit.path=='EUI')
assert(scale.Slider.thumb.width==20 and scale.Slider.thumb.alpha==0)
assert(scale.Slider.scripts.OnValueChanged(scale.Slider,1.1)=='native-scale'and scale.value==1.1)
local gallery={cards={}}
app.Gallery=gallery
function gallery.CreateFrame()
 local f=CreateFrame('Frame','DecorVendorGalleryFrame',UIParent);gallery.frame=f
 f.sidebar=Object('Frame',f);f.sidebar.filterContent=Object('Frame',f.sidebar)
 f.preview=Object('Frame',f);f.preview.modelBox=Object('Frame',f.preview)
 f.preview.modelBg=f.preview.modelBox:CreateTexture(nil,'BACKGROUND');f.preview.modelBg:SetTexture('native-ornate-preview')
 f.preview.corbelLeft=f.preview.modelBox:CreateTexture(nil,'OVERLAY');f.preview.corbelRight=f.preview.modelBox:CreateTexture(nil,'OVERLAY')
 f.preview.modelScene=Object('ModelScene',f.preview.modelBox)
 f.preview.controls=Object('Frame',f.preview.modelBox);f.preview.rotate=Button(f.preview.controls,'Rotate');f.preview.rotate.scripts.OnClick=function()return 'native-gallery-camera'end
 f.titleBar=Object('Frame',f);f.titleBar.background=f.titleBar:CreateTexture(nil,'BACKGROUND');f.titleBar.background:SetTexture('native-wood-header')
 f.closeBtn=Button(f.titleBar);f.closeBtn.normal:SetTexture(123456)
 f.preview.watermarkFrame=Object('Frame',f.preview)
 f.preview.watermark=f.preview.watermarkFrame:CreateTexture(nil,'ARTWORK');f.preview.watermark:SetTexture('native-logo')
 f.preview.actionButton=Button(f.preview,'Navigate');f.preview.actionButton.scripts.OnClick=function()return 'native-navigate'end
 f.preview.sourceButton=Button(f.preview,'Source');f.preview.sourceButton:Disable()
 f.bottom=Object('Frame',f);f.scrollChild=Object('Frame',f)
 return 'native-gallery-create'
end
function gallery.RefreshGrid()return 'native-gallery-grid'end
function gallery.BuildSidebarContent(parent)return 'native-gallery-sidebar'end
function gallery.ShowItem()return 'native-preview'end
function gallery.UpdateActionButton()return 'native-availability'end
-- Late optional Gallery table installs its own completed-UI hooks on refresh.
module.refresh();assert(gallery.CreateFrame()=='native-gallery-create');Flush()
local gp=gallery.frame.preview
assert(gp.modelBg.alpha==0 and gp.corbelLeft.alpha==0 and gp.watermark.alpha==1)
assert(not gp.modelScene.walks and not gp.controls.walks and not gp.rotate.button and gp.actionButton.button)
assert(gp.rotate.scripts.OnClick()=='native-gallery-camera'and gallery.frame.closeBtn.close)
assert(gallery.frame.titleBar.background.alpha==0)
assert(gp.actionButton.scripts.OnClick()=='native-navigate'and gp.sourceButton.enabled==false)
local lateCard=Object('Button',gallery.frame.scrollChild);lateCard.slotBg=lateCard:CreateTexture(nil,'BACKGROUND')
lateCard.hoverBg=lateCard:CreateTexture(nil,'BACKGROUND');lateCard.icon=lateCard:CreateTexture(nil,'ARTWORK')
lateCard.collected=lateCard:CreateTexture(nil,'OVERLAY');gallery.cards={lateCard}
assert(gallery.RefreshGrid()=='native-gallery-grid'and lateCard.icon.alpha==1 and lateCard.collected.alpha==1)
local newCheck=Object('CheckButton',gallery.frame.sidebar.filterContent);newCheck.label=Text(newCheck)
newCheck.checkedArt=newCheck:CreateTexture(nil,'ARTWORK');newCheck.disabledArt=newCheck:CreateTexture(nil,'ARTWORK')
assert(gallery.BuildSidebarContent(gallery.frame.sidebar.filterContent)=='native-gallery-sidebar')
local newHost;for _,f in ipairs(newCheck.children)do if f.mark then newHost=f end end;assert(newHost)
-- Warm native data refresh, check state and camera loops cannot scan unrelated
-- settings/windows, duplicate skin objects/hooks or write fonts/geometry.
app.BuildVendorUI();gallery.RefreshGrid();Flush();check:SetChecked(true);check:Enable()
local a,h,fw,g,c,r=allocated,hookCount,fontWrites,geometryWrites,childReads,regionReads
local main,settings,preview=app.frame.walks,DV_ConfigFrame.walks,app.modelBox.walks
local before=dataCalls
for _=1,1000 do
 assert(app.BuildVendorUI()=='native-build')
 gallery.RefreshGrid();check:SetChecked(true);check:Enable()
 assert(app.modelScene.scripts.OnUpdate()=='native-rotation')
end
Flush()
assert(allocated==a and hookCount==h and fontWrites==fw and geometryWrites==g)
assert(childReads==c and regionReads==r,'stable refresh scanned widget hierarchy/artwork')
assert(app.frame.walks==main and DV_ConfigFrame.walks==settings and app.modelBox.walks==preview)
assert(dataCalls==before+1000)
fontFace='ThemeTwo';accent=.7;module.refresh();Flush()
assert(app.bottomTabs[2].text.path=='ThemeTwo'and host.mark.color[1]==accent)
combat=true;local locked=Object('CheckButton',app.sidebarFilters);app.BuildVendorFilters();assert(#locked.children==0)
combat=false;for _,f in ipairs(events)do if f.scripts.OnEvent then f.scripts.OnEvent(f,'PLAYER_REGEN_ENABLED')end end
Flush()
enabled=false;local off=Object('CheckButton',app.sidebarFilters);app.BuildVendorFilters();module.refresh();assert(#off.children==0)
assert(#errors==0,table.concat(errors,'; '))
print('PASS: Decor Vendor independent window/gallery/Settings styling, current active rows, native actions/markers/previews/models/fonts, late construction, theme/combat/toggles and 1000 warm refreshes')
