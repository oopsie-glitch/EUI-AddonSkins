-- Auctionator on the modern auction house: native tab row, EUI zone seams, results
-- washes, pooled rows/icons, money inputs, labels and warm idempotence.
-- Specs share one Lua state: drop the legacy AuctionFrame and earlier mocks.
for _, name in ipairs({'AuctionFrame', 'AuctionFrameTab1', 'AuctionFrameTab2', 'AuctionFrameTab3', 'LibStub',
    'AuctionatorTabs_Shopping', 'AuctionatorConfigLazyFrame', 'AuctionatorConfigLoadedFrame', 'AuctionatorDialog1',
    'AuctionatorTabContainerMixin', 'AuctionatorExportTextFrameMixin'}) do _G[name] = nil end
local timers, modules, events, created, looks, hookCount = {}, {}, {}, 0, {}, 0
local hierarchyReads, geometryWrites, colorWrites = 0, 0, 0
local enabled, combat, fontFace = true, false, 'eui-font'
local ns = {IsEnabled = function() return enabled end, AttachAccent = function() end}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) error(e) end end
NORMAL_FONT_COLOR = {GetRGB = function() return 1, 0.82, 0 end}
PixelUtil = {GetNearestPixelSize = function() return 0.5 end}
C_Texture = {GetAtlasInfo = function(atlas) return (atlas == 'UI-RefreshButton' or atlas == 'auctionhouse-itemicon-empty') and {} or nil end}
hooksecurefunc = function(obj, key, callback)
    hookCount = hookCount + 1
    local original = obj[key]
    obj[key] = function(...)
        local result = table.pack(original(...)); callback(...); return table.unpack(result, 1, result.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 20, 'refresh loop')
    end
end
local function anchors(o)
    function o:ClearAllPoints() geometryWrites=geometryWrites+1;self.points = {} end
    function o:SetPoint(...) geometryWrites=geometryWrites+1;self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function o:GetNumPoints() return #(self.points or {}) end
    function o:GetPoint(i) return table.unpack(self.points[i]) end
    function o:SetAllPoints(rel) self.all = rel or true end
end
local function texture(layer, w, h)
    created = created + 1
    local t = {kind = 'Texture', layer = layer, alpha = 1, w = w or 16, h = h or 16, masks = {}}
    anchors(t)
    function t:GetPoint(i)
        if self.all then return 'TOPLEFT',self.all,'TOPLEFT',0,0 end
        local point=self.points and self.points[i]
        if not point then return end
        if type(point[2])=='number' then return point[1],self.parent,point[1],point[2],point[3] end
        return table.unpack(point)
    end
    function t:ClearAllPoints() geometryWrites=geometryWrites+1;self.points={};self.all=nil end
    function t:GetObjectType() return self.kind end
    function t:GetDrawLayer() return self.layer end
    function t:IsShown() return self.shown ~= false end
    function t:SetDrawLayer(layer) self.layer = layer end
    function t:GetTexture() return self.path end
    function t:SetTexture(p) self.path = p end
    function t:GetAtlas() return self.atlas end
    function t:SetAtlas(a) self.atlas = a end
    function t:SetColorTexture(...) colorWrites=colorWrites+1;self.color = {...} end
    function t:SetVertexColor(...) self.vertex = {...} end
    function t:GetVertexColor() return table.unpack(self.vertex or {1, 1, 1, 1}) end
    function t:SetDesaturated(v) self.desaturated = v end
    function t:SetAlpha(a) self.alpha = a; self.alphaWrites=(self.alphaWrites or 0)+1 end
    function t:GetAlpha() return self.alpha end
    function t:GetSize() return self.w, self.h end
    function t:SetSize(w, h) self.w, self.h = w, h end
    function t:GetHeight() return self.h end
    function t:SetHeight(h) self.h = h end
    function t:SetWidth(w) self.w = w end
    function t:SetShown(v) self.shown = v end
    function t:Hide() self.shown = false end
    function t:Show() self.shown = true end
    function t:SetTexCoord(...) self.crop = {...}; self.texCoordWrites=(self.texCoordWrites or 0)+1 end
    function t:GetNumMaskTextures() return #self.masks end
    function t:GetMaskTexture(i) return self.masks[i] end
    function t:AddMaskTexture(m) self.masks[#self.masks + 1] = m end
    function t:RemoveMaskTexture(m) for i, v in ipairs(self.masks) do if v == m then table.remove(self.masks, i) end end end
    return t
end
local function fontString(text, r, g, b)
    local fs = {text = text, color = {r or 1, g or 1, b or 1}}
    function fs:GetObjectType() return 'FontString' end
    function fs:GetText() return self.text end
    function fs:GetTextColor() return table.unpack(self.color) end
    function fs:SetTextColor(...) self.color = {...} end
    function fs:SetJustifyH(v) self.justifyH = v end
    function fs:SetJustifyV(v) self.justifyV = v end
    return fs
end
local function frame(kind, parent, name)
    created = created + 1
    local f = {kind = kind or 'Frame', children = {}, regions = {}, scripts = {}, shown = true, alpha = 1, w = 100, h = 24, name = name}
    anchors(f)
    function f:GetObjectType() return self.kind end
    function f:GetName() return self.name end
    function f:IsForbidden() return self.forbidden end
    function f:IsProtected() return self.protected end
    function f:GetParent() return self.parent end
    function f:GetChildren() hierarchyReads=hierarchyReads+1;return table.unpack(self.children) end
    function f:GetRegions() hierarchyReads=hierarchyReads+1;return table.unpack(self.regions) end
    function f:GetNumChildren() return #self.children end
    function f:GetNumRegions() return #self.regions end
    function f:GetFrameLevel() return 4 end
    function f:SetFrameLevel(v) self.level = v end
    function f:GetEffectiveScale() return 1 end
    function f:SetSize(w,h) geometryWrites=geometryWrites+1;self.w,self.h=w,h end
    function f:EnableMouse(value) self.mouse=value end
    function f:GetHeight() return self.h end
    function f:SetHeight(h) self.h = h end
    function f:GetWidth() return self.w end
    function f:SetWidth(w) self.w = w end
    function f:SetAlpha(a) self.alpha = a end
    function f:GetAlpha() return self.alpha end
    function f:IsShown() return self.shown end
    function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function f:SetHitRectInsets(...) self.hit = {...} end
    function f:HookScript(key, fn) local old = self.scripts[key]; self.scripts[key] = function(...) local r=old and table.pack(old(...))or{n=0}; fn(...);return table.unpack(r,1,r.n) end end
    function f:SetScript(key, fn) self.scripts[key] = fn end
    function f:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
    function f:CreateTexture(_, layer)
        local t = texture(layer); t.parent=self; self.regions[#self.regions + 1] = t; return t
    end
    function f:CreateMaskTexture()
        local t = texture('BORDER'); t.kind='MaskTexture'
        self.regions[#self.regions+1]=t;return t
    end
    function f:GetFontString() return self.label end
    function f:GetNormalTexture() return self.normal end
    function f:SetJustifyH(v) self.justifyH = v end
    function f:SetJustifyV(v) self.justifyV = v end
    function f:SetTextInsets(...) self.insets = {...}; self.insetWrites = (self.insetWrites or 0) + 1 end
    function f:GetID() return self.id end
    function f:GetLeft() return self.l end
    function f:GetRight() return self.r end
    function f:GetTop() return self.t end
    function f:GetBottom() return self.b end
    if parent then f.parent = parent; parent.children[#parent.children + 1] = f end
    return f
end
CreateFrame = function(kind, name, parent)
    local f = frame(kind, parent, name)
    if name then _G[name] = f end
    if not parent then events[#events + 1] = f end
    return f
end
local S = {OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
function S.Shell(f) f.shell = true end
function S.Panel(f, opts) f.panel = true; f.panelOptions = opts end
function S.Inset(f)
    f.inset = true
    for _, region in ipairs(f.regions) do
        if region.kind == 'Texture' then region:SetAlpha(0) end
    end
end
function S.Tab(f, opts)
    if not f.tab then f.plate = f:CreateTexture(nil, 'BACKGROUND') end
    f.tab = true; if opts and opts.darkActive then f.darkActive = true end
end
function S.SetTabSelection(f, v) f.selected = v end
function S.EditBox(f, opts)
    if f.input then return end -- Public primitive is idempotent.
    f.padInput = opts and opts.padInput
    f.input = (f.input or 0) + 1; f.soft = f.soft or (opts and opts.noBorder)
    -- Like the engine: strip template art, including unnamed coin textures.
    for _, region in ipairs(f.regions) do if region.kind == 'Texture' then region:SetAlpha(0) end end
end
function S.Button(f, keepKeys)
    f.button = true
    -- Model EUI's texture strip and theme registry; item art must be kept.
    local keep = {}; for _, key in ipairs(keepKeys or {}) do keep[f[key] or false] = true end
    f.keepKeys = keepKeys
    for _, region in ipairs(f.regions) do
        if region.kind == 'Texture' and not keep[region] then region:SetAlpha(0) end
    end
end
function S.ScrollBar(f) f.scroll = true end
function S.SquareIcon(icon, owner) icon.square = (icon.square or 0) + 1; icon.owner = owner end
function S.White(fs) fs.color = {1, 1, 1} end
function S.GetAccentColor() return 0.1, 0.8, 0.6 end
function S.Dropdown(f) f.dropdown = true end
function S.GetFont() return fontFace, '' end
function S.Font(f, r, g, b)
    f.fontFace = fontFace; f.fontWrites = (f.fontWrites or 0) + 1
    if r then f:SetTextColor(r, g, b) end
end
for _, key in ipairs({'FadeNineSlice', 'CloseButton', 'Checkbox', 'StateButtonLabel', 'PageButton'}) do S[key] = function() end end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)



-- Cheap Upgrades' builders own stable pools; skin only completed owned trees.
ns.RegisterSkinDefinition = function(_, fn) fn() end
local writes, selectionWrites = 0, 0
local popupCalls=0
ns.BindPopupList=function(_,_,owner,list)assert(list:GetOwnerRegion()==owner);popupCalls=popupCalls+1 end
local nativeSelection = S.SetTabSelection
S.SetTabSelection = function(...) selectionWrites=selectionWrites+1;return nativeSelection(...) end
local previousFont = S.Font
S.Font = function(...) writes = writes + 1; return previousFont(...) end
S.CloseButton = function(f) f.closedArt = true end
local oldFrame = frame
local function visible(f, v)
    f.shown = v
    local fn = f.scripts[v and 'OnShow' or 'OnHide']
    if fn then fn(f) end
end
local function text(parent)
    local fs=fontString('native',0.2,0.7,0.4)
    fs.color[4]=0.8
    fs.face,fs.height,fs.flags='native',12,'OUTLINE'
    function fs:GetFont() return self.face,self.height,self.flags end
    function fs:SetFont(face,h,flags) assert(h>0);self.face,self.height,self.flags=face,h,flags end
    local originalFont=S.Font
    parent.regions[#parent.regions+1]=fs
    return fs
end
local originalFont = S.Font
S.Font = function(fs,r,g,b) fs:SetFont(fontFace,fs.height,'');originalFont(fs,r,g,b) end
local cells, labels = {}, {}
CheapUpgrades = {Options = {}}
local CU=CheapUpgrades
function CU:CreateUI()
    if CheapUpgradesFrame then return end
    CheapUpgradesFrame=frame()
    local root=CheapUpgradesFrame
    root.CloseButton=frame('Button',root)
    root.CloseButton.normal=texture()
    local button=frame('Button',root)
    local edit=frame('EditBox',root)
    local check=frame('CheckButton',root)
    local dd=frame('DropdownButton',root)
    function dd:OnMenuOpened(menu)self.menu=menu end
    for _,f in ipairs({button,edit,check,dd}) do text(f) end
    for i=1,24 do
        local c=frame('Button',root)
        c.group={key=i};c.icon=c:CreateTexture(nil,'ARTWORK')
        c.border=c:CreateTexture(nil,'BORDER');c.sel=c:CreateTexture(nil,'BACKGROUND')
        c.badge=c:CreateTexture(nil,'OVERLAY')
        c.border:SetVertexColor(0.2,0.6,1,1)
        cells[i]=c;labels[i]=text(c)
    end
    self.controls={button,edit,check,dd}
end
function CU:AttachAHButton()
    self:CreateUI()
    CheapUpgradesAHFrame=CheapUpgradesAHFrame or frame()
    self.ahTabs={lib={DoesIDExist=function(_,id)return self.tabs and self.tabs[id]~=nil end,GetButton=function(_,id) return self.tabs[id] end}}
    self.tabs=self.tabs or {CheapUpgrades_upgrades=frame('Button'),CheapUpgrades_alts=frame('Button')}
end
function CU:ShowUI() self:CreateUI();visible(CheapUpgradesFrame,true) end
function CU:RefreshUI() self.nativeUpdates=(self.nativeUpdates or 0)+1 end
function CU.Options:CreatePanel()
    if self.pages then return end
    self.pages={types=frame(),weights=frame(),reasons=frame(),ah=frame(),display=frame()}
    for _,p in pairs(self.pages)do self:BuildPage(p)end
end
function CU.Options:BuildPage(page) page.check=frame('CheckButton',page) end
function CU.Options:Open()
    self:CreatePanel()
    self.window=self.window or frame()
    self.tabs=self.tabs or {}
end
function CU.Options:AskSpec() self.specAsk=self.specAsk or frame() end
function CU.Options:ShowPage(key) for k,p in pairs(self.pages)do visible(p,k==key)end end
assert(loadfile('EUIAddonSkins/Skins/CheapUpgrades.lua'))('EUIAddonSkins',ns)
local m=modules.CheapUpgrades
assert(m and m.available())
CheapUpgrades=nil;assert(not m.available());CheapUpgrades=CU
m.install(S,m)
local initialHooks=hookCount
assert(CheapUpgradesFrame==nil,'skin eagerly initialized the target')
CU:ShowUI();CU:AttachAHButton();CU.Options:Open();CU.Options:AskSpec()
assert(CheapUpgradesFrame.shell and CheapUpgradesAHFrame.panel)
assert(CU.Options.window.shell and CU.Options.specAsk.shell)
assert(CU.tabs.CheapUpgrades_upgrades.tab and CU.tabs.CheapUpgrades_alts.tab)
local liveState=CU.ahTabs
CheapUpgradesAHTab_upgrades=frame('Button')
CU.ahTabs={lib={DoesIDExist=function()return false end,GetButton=function()error('uninitialized native tab library')end}}
CU:ShowUI();assert(CheapUpgradesAHTab_upgrades.tab)
CU.ahTabs=liveState
assert(CU.controls[1].button and CU.controls[2].input and CU.controls[4].dropdown)
assert(CheapUpgradesFrame.CloseButton.closedArt)
for _,c in ipairs(cells)do
    assert(c.icon.square==1 and not c.button,'data cells treated as ordinary buttons')
    assert(c.border.alpha==1 and c.badge.alpha==1 and c.sel.alpha==1)
    assert(c.border.vertex[3]==1,'rarity colour overwritten')
end
for _,fs in ipairs(labels)do assert(fs.face==fontFace and fs.height==12 and fs.color[4]==0.8)end
local dropdown=CU.controls[4]
local popup={GetOwnerRegion=function()return dropdown end}
dropdown:OnMenuOpened(popup);assert(popupCalls==1 and dropdown.menu==popup)
dropdown:OnMenuOpened({GetOwnerRegion=function()return {}end});assert(popupCalls==1)
local selection = selectionWrites
local count, hooks, color, geometry, font, reads = created,hookCount,colorWrites,geometryWrites,writes,hierarchyReads
collectgarbage('collect');local memory=collectgarbage('count')
local started=os.clock()
for i=1,1000 do
    visible(CheapUpgradesFrame,false);CU:ShowUI()
    CU:RefreshUI()
end
local elapsed=(os.clock()-started)*1000
collectgarbage('collect')
assert(created==count and hookCount==hooks,'warm objects/hooks grew')
assert(writes==font and colorWrites==color and geometryWrites==geometry,'warm repaint')
assert(hierarchyReads==reads,'warm tree scanning')
assert(selectionWrites==selection,'redundant tab selection writes')
assert(collectgarbage('count')-memory<4,'warm retained state grew')
-- Theme update while hidden paints on the next show, not on a scan/scoring update.
visible(CheapUpgradesFrame,false);fontFace='next-font';m.refresh()
assert(labels[1].face~='next-font')
CU:ShowUI();assert(labels[1].face=='next-font')
-- Native zero/inherited fonts are not assigned arbitrary heights.
labels[1].height=0;labels[1].face='native';m.refresh()
assert(labels[1].face=='native')
combat=true;fontFace='combat-font';m.refresh();assert(labels[2].face~='combat-font')
combat=false
for _,e in ipairs(events)do if e.events and e.events.PLAYER_REGEN_ENABLED then e.scripts.OnEvent(e)end end
assert(labels[2].face=='combat-font')
enabled=false
local before=created;local beforeWrites=writes
CU:ShowUI();CU:RefreshUI();m.refresh()
assert(created==before and writes==beforeWrites,'disabled skin did work')
enabled=true
print(string.format('CheapUpgrades: lazy builders, semantic art, warm/disabled/combat: PASS; 1000 warm opens+native updates %.3f ms; new objects=0, new hooks=0, hierarchy reads=0',elapsed))
