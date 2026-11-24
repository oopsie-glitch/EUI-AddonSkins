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



local source=os.getenv('CHEAP_AHTAB_SOURCE')
if source then
    ns.RegisterSkinDefinition=function(_,fn)fn()end
    assert(loadfile('EUIAddonSkins/Skins/Auctionator.lua'))('EUIAddonSkins',ns)
    -- Run the pinned library, including native CreateTab and selection callbacks.
    local lib={}
    LibStub=setmetatable({NewLibrary=function()return lib end},{__call=function()return lib end})
    GetBuildInfo=function()return '1.0','', '',16001 end
    WOW_PROJECT_ID,WOW_PROJECT_MAINLINE=1,1
    PanelTemplates_DeselectTab=function(t)t.nativeSelected=false end
    PanelTemplates_SelectTab=function(t)t.nativeSelected=true end
    PanelTemplates_TabResize=function(t)t:SetSize(90,24)end
    local nativeCreate=CreateFrame
    CreateFrame=function(...)
        local f=nativeCreate(...)
        function f:IsObjectType(kind)return kind=='Frame' or kind==self.kind end
        function f:SetText(t)self.text=t end
        function f:Hide()self.shown=false end
        function f:Show()self.shown=true end
        return f
    end
    AuctionHouseFrame=CreateFrame('Frame')
    AuctionHouseFrame.Tabs={CreateFrame('Button'),CreateFrame('Button'),CreateFrame('Button')}
    function AuctionHouseFrame:SetDisplayMode(mode)self.mode=mode end
    function AuctionHouseFrame:SetTitle(title)self.title=title end
    Auctionator={Tabs={State={knownTabs={}}}}
    AuctionatorAHTabsContainer={Tabs={}}
    assert(loadfile(source))()
    local before={}
    local function add(id,auctionator)
        local view=CreateFrame('Frame',nil,AuctionHouseFrame)
        lib:CreateTab(id,view,id)
        local tab=lib:GetButton(id)
        if auctionator then table.insert(AuctionatorAHTabsContainer.Tabs,tab)end
        before[tab]={points=tab.points,height=tab.h,hit=tab.hit}
        return tab
    end
    local order=os.getenv('CHEAP_TAB_ORDER')or'before'
    if order=='before'then add('CheapUpgrades_upgrades');add('CheapUpgrades_alts')end
    add('Auctionator_Shopping',true);add('Auctionator_Selling',true)
    modules.Auctionator.install(S,modules.Auctionator);flush()
    if order=='after'then add('CheapUpgrades_upgrades');add('CheapUpgrades_alts');flush()end
    -- A second consumer adds a tab after the skins are active.
    local last=lib.internalState.Tabs[#lib.internalState.Tabs]
    local extra=add('another-consumer')
    flush()
    assert(extra.points[1][2]==last)
    for tab,state in pairs(before)do
        assert(tab.points==state.points,'COMPATIBILITY: native complete-row anchor replaced')
        assert(tab.h==state.height and tab.hit==state.hit,'COMPATIBILITY: native geometry replaced')
    end
    for id in pairs(lib.internalState.usedIDs)do
        lib:SetSelected(id);flush()
        assert(lib:GetButton(id).nativeSelected and lib:GetButton(id).frameRef.shown)
    end
    local objects,hooks=created,hookCount
    for i=1,1000 do
        lib:SetSelected('Auctionator_Shopping');flush()
        lib:SetSelected('another-consumer');flush()
    end
    assert(created==objects and hookCount==hooks,'shared tab lifecycle grew')
    print('Pinned LibAHTab: '..order..' load order, independent third-party skin, dynamic consumer, native selection, 2000 switches: PASS')
end
