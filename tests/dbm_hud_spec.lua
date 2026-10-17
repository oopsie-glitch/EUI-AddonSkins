-- HUD lifecycle regression: actual shared helper/scoped adapter, no GUI loaded.
local timers, modules, frames, looks, errors = {}, {}, {}, {}, {}
local enabled, combat, accent, secret = true, false, 0.2, false
local created, hooks, fontWrites, childReads, textWrites = 0, 0, 0, 0, 0
local gradientMode = 'modern'
CreateColor = function(r, g, b, a) return {r = r, g = g, b = b, a = a} end
DBM_GUI, DBM_GUI_OptionsFrame, DBM_GUI_OptionsFrameList, DBM_GUI_DropDown, DBT = nil, nil, nil, nil, nil
DBM = {}
InCombatLockdown = function() return combat end
C_Secrets = {ShouldAurasBeSecret = function() return secret end}
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
hooksecurefunc = function(obj, key, fn)
    hooks = hooks + 1
    local old = obj[key]
    obj[key] = function(...)
        local result = table.pack(old(...)); fn(...); return table.unpack(result, 1, result.n)
    end
end
local function flush()
    local n = 0
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
        n = n + 1; assert(n < 12, 'HUD refresh loop')
    end
end
local function object(kind, name, parent)
    created = created + 1
    local o = {kind = kind, name = name, parent = parent, regions = {}, children = {}, scripts = {}, events = {}, shown = true, alpha = 1,
        color = {1, 1, 1, 1}, size = 16, font = 'native', points = {}, w = 195, h = 20}
    function o:GetObjectType() return self.kind end
    function o:GetName() return self.name end
    function o:GetParent() return self.parent end
    function o:SetMovable(v) self.movable = v end
    function o:RegisterForDrag(...) self.dragButtons = {...} end
    function o:StartMoving() self.moving = true end
    function o:StopMovingOrSizing() self.moving = false end
    function o:GetCenter() return self.cx or 500, self.cy or 400 end
    function o:GetLeft() return self.left or 0 end
    function o:GetTop() return self.top or 768 end
    function o:SetSpacing(v) self.spacing = v end
    function o:GetEffectiveScale() return self.scale or 1 end
    function o:IsForbidden() return self.forbidden end
    function o:IsProtected() return self.protected end
    function o:SetPoint(...) self.points[#self.points + 1] = {...} end
    function o:SetAllPoints(v) self.all = v end
    function o:SetHeight(v) self.h = v end
    function o:SetSize(w, h) self.w, self.h = w, h end
    function o:ClearAllPoints() self.points = {} end
    function o:GetNumPoints() return #self.points end
    function o:GetPoint(i) return table.unpack(self.points[i]) end
    function o:GetBlendMode() return self.blend or 'BLEND' end
    function o:GetShadowColor() return table.unpack(self.shadow or {0,0,0,1}) end
    function o:GetShadowOffset() return table.unpack(self.shadowOffset or {0,0}) end
    function o:GetJustifyH() return self.justifyH or 'LEFT' end
    function o:GetJustifyV() return self.justifyV or 'MIDDLE' end
    function o:CanWordWrap() return self.wordWrap ~= false end
    function o:CanNonSpaceWrap() return self.nonSpaceWrap ~= false end
    function o:SetChecked(v) self.checked = v end
    function o:GetChecked() return self.checked end
    function o:SetOrientation(v) self.orientation = v end
    function o:GetOrientation() return self.orientation end
    function o:SetMinMaxValues(a,b) self.minValue, self.maxValue = a,b end
    function o:SetValueStep(v) self.step = v end
    function o:SetThumbTexture(path) self.thumb = self:CreateTexture(); self.thumb:SetTexture(path) end
    function o:GetThumbTexture() return self.thumb end
    function o:SetValue(v) self.value = v; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end end
    function o:Hide() self.shown = false end
    function o:SetBackdrop(v) self.backdrop = v end
    function o:SetShadowColor(...) self.shadow = {...} end
    function o:SetShadowOffset(...) self.shadowOffset = {...} end
    function o:SetWidth(v) self.w = v end
    function o:GetWidth()
        local a, b = self.points[1], self.points[2]
        if self.kind == 'StatusBar' and a and b and (a[1] == 'BOTTOMLEFT' and b[1] == 'BOTTOMRIGHT' or a[1] == 'TOPLEFT' and b[1] == 'TOPRIGHT') and a[2] == b[2] then
            return a[2]:GetWidth() + b[4] - a[4]
        end
        return self.w
    end
    function o:GetHeight() return self.h end
    function o:GetTexture() return self.path end
    function o:SetTexture(v) self.path = v; self.filePath = nil end
    function o:GetTextureFilePath() return self.filePath or self.path end
    function o:SetBlendMode(v) self.blend = v end
    if gradientMode == 'modern' then
        function o:SetGradient(direction, bottom, top) self.gradient = {direction, bottom, top} end
    elseif gradientMode == 'legacy' then
        function o:SetGradientAlpha(...) self.gradientAlpha = {...} end
    end
    function o:SetColorTexture(...) self.fillColor = {...} end
    function o:GetVertexColor() return table.unpack(self.color) end
    function o:SetVertexColor(...) self.color = {...} end
    function o:SetAlpha(v) self.alpha = v; self.alphaWrites = (self.alphaWrites or 0) + 1 end
    function o:GetAlpha() return self.alpha end
    function o:SetIgnoreParentAlpha(value) self.ignoreParentAlpha = value end
    function o:GetEffectiveAlpha()
        if self.ignoreParentAlpha or not self.parent then return self.alpha end
        return self.alpha * self.parent:GetEffectiveAlpha()
    end
    function o:GetNumMaskTextures() return self.masked and 1 or 0 end
    function o:SetTexCoord(...) self.crop = {...} end
    function o:GetTexCoord()
        if self.privateCoords then return table.unpack(self.privateCoords) end
        local c = self.crop or {0,1,0,1}
        if #c == 8 then return table.unpack(c) end
        return c[1],c[3],c[1],c[4],c[2],c[3],c[2],c[4]
    end
    function o:SetShown(v) self.shown = v end
    function o:IsShown() return self.shown end
    function o:IsVisible() return self.shown end
    function o:GetFont() return self.font, self.size, '' end
    function o:GetText() return self.text end
    function o:SetText(v)
        self.text = v; textWrites = textWrites + 1
        if self.kind == 'Button' and not self.label then self.label = self:CreateFontString() end
        if self.kind == 'Button' then self.label.text = v end
    end
    function o:SetFontObject(v) self.font, self.fontObject = v, v end
    function o:GetFontObject() return self.fontObject or 'native-object' end
    function o:SetWordWrap(v) self.wordWrap = v end
    function o:SetNonSpaceWrap(v) self.nonSpaceWrap = v end
    function o:SetJustifyH(v) self.justifyH = v end
    function o:SetJustifyV(v) self.justifyV = v end
    function o:GetTextColor() return table.unpack(self.color) end
    function o:SetTextColor(...) self.color = {...} end
    function o:GetFontString() return self.label end
    function o:SetFont(path, size) self.font, self.size = path, size; fontWrites = fontWrites + 1 end
    function o:SetBackdropBorderColor(...) self.borderColor = {...} end
    function o:EnableMouse(v) self.mouse = v end
    function o:RegisterEvent(e) self.events[e] = true end
    function o:SetScript(k, fn) self.scripts[k] = fn end
    function o:HookScript(k, fn) local old = self.scripts[k]; self.scripts[k] = function(...) if old then old(...) end; fn(...) end end
    function o:GetChildren() childReads = childReads + 1; return table.unpack(self.children) end
    function o:GetRegions() return table.unpack(self.regions) end
    function o:CreateFontString(name)
        local text = object('FontString', name, self); self.regions[#self.regions + 1] = text; return text
    end
    function o:SetEnabled(value) self.enabled = value end
    function o:CreateTexture(name, layer, _, sublevel)
        local t = object('Texture', name, self); t.layer, t.sublevel = layer, sublevel; self.regions[#self.regions + 1] = t; return t
    end
    function o:GetStatusBarTexture() return self.fill end
    function o:SetStatusBarTexture(v) self.fill.path = v end
    function o:SetStatusBarColor(r,g,b,a)
        -- Native C setters need not invoke the Lua SetVertexColor hook.
        self.fill.color = {r,g,b,a == nil and 1 or a}
    end
    if name then _G[name] = o end
    if parent and kind ~= 'Texture' and kind ~= 'FontString' then parent.children[#parent.children + 1] = o end
    return o
end
CreateFrame = function(kind, name, parent)
    local f = object(kind, name, parent); frames[#frames + 1] = f; return f
end
local previousUIParent = UIParent
UIParent = CreateFrame('Frame')
local ns = {IsEnabled = function() return enabled end}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
local S = {GetAccentColor = function() return accent, 0.6, 0.7 end,
    GetFont = function() return 'eui', '' end, OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
function S.Font(f) local _, size = f:GetFont(); f:SetFont('eui', size) end
function S.SquareIcon(t) t:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
assert(loadfile('EUIAddonSkins/Accent.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Skins/DBM.lua'))('EUIAddonSkins', ns)
assert(modules.DBM.available(), 'HUD must activate without forcing DBM-GUI to load')
modules.DBM.install(S, modules.DBM); flush()
assert(not DBM_GUI and not DBM_GUI_OptionsFrame)
local function event(name)
    for _, f in ipairs(frames) do if f.events[name] and f.scripts.OnEvent then f.scripts.OnEvent(f, name) end end
    flush()
end
local pool, nextID, iteratorCalls = {}, 0, 0
local prototype = {}
function prototype:ApplyStyle()
    local prefix = self.frame.name .. 'Bar'
    local options = DBT.Options
    _G[prefix]:SetHeight(self.enlarged and options.HugeHeight or options.Height)
    _G[prefix .. 'Icon1']:SetShown(options.IconLeft)
    _G[prefix .. 'Icon2']:SetShown(options.IconRight == true)
    for i = 1, 4 do _G[prefix .. 'IJIcons' .. (i == 1 and '' or i)]:SetShown(i <= options.JournalIcons) end
    _G[prefix]:SetStatusBarTexture('dbm-gloss'); _G[prefix .. 'Spark']:SetAlpha(1)
    _G[prefix .. 'Name']:SetFont('native', 14)
    return 'native-style'
end
function prototype:SetText(v, inline, private)
    _G[self.frame.name .. 'BarName']:SetText(private and v or (inline or '') .. v)
    return 'native-text'
end
function prototype:SetIcon(v, eventID, custom)
    local prefix = self.frame.name .. 'Bar'
    _G[prefix .. 'Icon1']:SetTexture(v)
    if custom then
        -- Model DBT's custom-journal path: clear pooled slots and replace
        -- texture, native size and crop before the skin's post-hook runs.
        for i = 1,4 do _G[prefix .. 'IJIcons' .. (i == 1 and '' or i)]:SetTexture(nil) end
        local index = 0
        for path,h,w,tw,th,l,r,t,b in custom:gmatch('|T([^:|]+):(%d+):(%d+):[^|]-:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)|t') do
            index = index + 1
            local icon = _G[prefix .. 'IJIcons' .. (index == 1 and '' or index)]
            icon:SetTexture(path); icon:SetSize(tonumber(w),tonumber(h))
            icon:SetTexCoord(tonumber(l)/tonumber(tw),tonumber(r)/tonumber(tw),tonumber(t)/tonumber(th),tonumber(b)/tonumber(th))
        end
    end
    return 'native-icon'
end
function prototype:Update()
    self.duration = self.duration - 0.01
    if self.auditFlash then
        self.auditPhase = (self.auditPhase or 0) + 1
        _G[self.frame.name .. 'Bar']:SetStatusBarColor(0.4,0.5,0.6, self.auditPhase % 2 == 0 and 1 or 0)
    end
end
function prototype:SetVariance()
    local prefix = self.frame.name .. 'Bar'
    local t = _G[prefix .. 'Variance']
    t:SetTexture('native-gradient'); t:SetBlendMode('ADD'); t:SetVertexColor(1, 1, 1, 0.5)
    t:SetWidth(self.varianceWidth or 40); t:ClearAllPoints(); t:SetPoint('RIGHT', _G[prefix], 'RIGHT')
    t:SetShown(self.hasVariance == true)
    _G[prefix .. 'VarianceBorder']:SetShown(self.hasVariance == true)
    return 'native-variance'
end
local function bar(id)
    nextID = nextID + 1
    local f = CreateFrame('Frame', 'DBT_Bar_' .. nextID)
    local prefix = f.name .. 'Bar'
    local b = CreateFrame('StatusBar', prefix, f)
    b.fill = b:CreateTexture(); b.fill.path = 'dbm-gloss'; b.fill.color = {0.9, 0.4, 0.1, 0.75}
    b:CreateTexture(prefix .. 'Background')
    b:CreateTexture(prefix .. 'Spark')
    b:CreateTexture(prefix .. 'Variance'); b:CreateTexture(prefix .. 'VarianceBorder')
    for _, side in ipairs({'Top', 'Bottom', 'Left', 'Right'}) do b:CreateTexture(prefix .. 'Border' .. side) end
    for i = 1, 2 do local t = b:CreateTexture(prefix .. 'Icon' .. i); t.path = 136116; t.shown = i == 1 end
    for i = 1, 4 do
        local t = b:CreateTexture(prefix .. 'IJIcons' .. (i == 1 and '' or i)); t.path = 'role-' .. i
        t.shown = i <= 2
    end
    object('FontString', prefix .. 'Name', b); object('FontString', prefix .. 'Timer', b)
    local obj = setmetatable({frame = f, id = id, duration = 20}, {__index = prototype})
    obj:SetVariance()
    f.scripts.OnUpdate = function() obj:Update() end
    pool[id] = obj
    return obj
end
local first = bar('existing')
DBT = {Options = {Height = 20, HugeHeight = 28, IconLocked = true, IconLeft = true, JournalIcons = 2},
    GetBar = function(_, id) return pool[id] end,
    GetBarIterator = function() iteratorCalls = iteratorCalls + 1; local key; return function() key = next(pool, key); return key and pool[key] end end,
    CreateBar = function(_, _, id) return pool[id] or bar(id), 'native-create' end}
event('ADDON_LOADED')
local f, b = first.frame, _G[first.frame.name .. 'Bar']
local nativeAnchor = {}
f:SetPoint('TOP', nativeAnchor, 'TOP', 27, -60)
assert(b.fill.path == 'Interface\\Buttons\\WHITE8X8' and b.fill.color[1] == 0.9 and b.fill.color[4] == 0.75)
local label, timer = _G[f.name .. 'BarName'], _G[f.name .. 'BarTimer']
assert(label.font == 'eui' and label.size == 9 and label.justifyV == 'MIDDLE')
assert(_G[f.name .. 'BarSpark'].alpha == 0 and _G[f.name .. 'BarBorderTop'].alpha == 0)
assert(_G[f.name .. 'BarIcon1'].crop and _G[f.name .. 'BarIcon1'].path == 136116)
assert(f.children[#f.children - 1].regions[1].fillColor[1] == accent, 'spell icon edge should follow accent')
assert(_G[f.name .. 'BarBackground'].alpha == 0, 'native track background must not layer over the row background')
_G[f.name .. 'BarBackground']:SetAlpha(1)
assert(_G[f.name .. 'BarBackground'].alpha == 0, 'native redraw restored a second background')
assert(b.h == 5 and f.h == 20 and DBT.Options.Height == 20, 'thin strip must scale with height without changing native frame/settings')
local panel, spellIcon = f.regions[1], _G[f.name .. 'BarIcon1']
assert(spellIcon.w == 20 and spellIcon.h == 20 and spellIcon.points[1][1] == 'LEFT')
assert(panel.fillColor[4] == 0.65 and panel.points[1][4] == 0 and panel.points[2][4] == 0, 'panel should stay inside native row')
assert(#f.regions == 5, 'panel background and four accent edges missing')
for i = 2, 5 do assert(f.regions[i].fillColor[1] == accent and f.regions[i].fillColor[4] == 0.35, 'panel needs subdued full accent outline') end
assert(f.regions[2].h == 1 and f.regions[4].w == 1)
assert(spellIcon.points[1][4] == 0 and spellIcon.h == DBT.Options.Height, 'small spell icon must meet the row top and bottom')
assert(label.points[1][1] == 'LEFT' and label.points[1][5] > 0 and timer.points[1][5] == label.points[1][5], 'name and countdown must share the line above progress')
assert(label.points[1][5] - label.h / 2 >= b.points[1][5] + 1, 'name overlaps the progress strip')
assert(label.h == 10 and timer.h == 10 and label.wordWrap == false)
assert(label.shadow[4] == 0.9 and timer.shadow[4] == 0.9)
assert(label.points[2][4] < timer.points[1][4] - timer.w, 'name overlaps reserved countdown')
assert(b:GetWidth() == 169 and b.points[2][4] == -2 and timer.points[1][4] == -4, 'thin strip must reach the row end below countdown text')
assert(label.points[1][4] == b.points[1][4] and label.points[2][4] < b.points[2][4], 'only the name should reserve countdown width')
assert(_G[f.name .. 'BarIJIcons'].alpha == 0 and spellIcon.alpha == 1, 'small row should hide only mechanic symbols')
local stripWidth, labelRight, timerRight = b:GetWidth(), label.points[2][4], timer.points[1][4]
_G[f.name .. 'BarIJIcons2']:Hide(); first:SetIcon(136116)
assert(b:GetWidth() == stripWidth and label.points[2][4] == labelRight and timer.points[1][4] == timerRight, 'small row reserved hidden mechanics')
assert(f.points[1][2] == nativeAnchor and f.points[1][4] == 27 and f.points[1][5] == -60, 'skin moved native stack row')
_G[f.name .. 'BarIJIcons2']:SetShown(true)
local tint, endpoint, trackEnd
for _, t in ipairs(b.regions) do
    if t.sublevel == 2 then tint = t elseif t.sublevel == 3 then endpoint = t elseif t.sublevel == 4 then trackEnd = t end
    assert(not t.gradient and not t.gradientAlpha, 'matte bars must not create gradient overlays')
end
assert(tint and tint.layer == 'ARTWORK' and tint.all == b.fill and tint.fillColor[4] == 0.2)
assert(not endpoint and not trackEnd, 'full-width progress tracks must not create white end ticks')

local trackEdges = 0
for _, region in ipairs(b.regions) do
    if region.sublevel == -1 then
        trackEdges = trackEdges + 1
        assert(region.fillColor[1] == 0.2 and region.fillColor[4] == 0.4 and region.points[1][2] == b, 'track edge should be subtle')
    end
end
assert(trackEdges == 0, 'inner track outlines must not create extra grey boxes')
assert(not _G[f.name .. 'BarVariance'].shown, 'disabled variance indicator became visible')
first.hasVariance, first.varianceWidth, first.varianceDuration, first.totalTime = true, 73, 5, 20
assert(first:SetVariance() == 'native-variance')
local variance = _G[f.name .. 'BarVariance']
assert(variance.path == 'Interface\\Buttons\\WHITE8X8' and variance.blend == 'BLEND')
assert(variance.shown and variance.w == b:GetWidth() * 0.25 and variance.points[1][1] == 'RIGHT', 'variance time proportion/direction changed')
assert(variance.color[1] == 0.14 and variance.color[4] == 0.65)
assert(f.children[#f.children].shown == false, 'hidden right icon acquired a visible border')
local nativeUpdate = f.scripts.OnUpdate
local oldCreated, oldHooks, oldFonts, oldReads, oldTexts = created, hooks, fontWrites, childReads, textWrites
for _ = 1, 1000 do f.scripts.OnUpdate() end
assert(nativeUpdate == f.scripts.OnUpdate and created == oldCreated and hooks == oldHooks and fontWrites == oldFonts and childReads == oldReads and textWrites == oldTexts)
assert(first.duration < 20, 'native timer stopped')
assert(first:ApplyStyle() == 'native-style' and b.fill.path == 'Interface\\Buttons\\WHITE8X8')
assert(label.font == 'eui' and label.size == 9)
assert(first:SetIcon(999) == 'native-icon' and spellIcon.path == 999)
assert(b.h == 5, 'repeated paint cumulatively resized strip')
first.enlarged = true; first:ApplyStyle()
assert(b.h == 24 and spellIcon.h == 24 and timer.size == 11, 'huge row must follow native configured height')
assert(tint.fillColor[1] == 0.08 and tint.fillColor[4] == 0.4 and b.fill.color[1] == 0.9, 'huge fill tint must darken without changing native category colors')
assert(label.points[1][5] == 0 and timer.points[1][5] == 0 and label.h == b.h, 'huge text/countdown must share one centerline')
assert(label.points[1][4] >= b.points[1][4] and label.points[2][4] < b.points[2][4], 'huge name must reserve countdown width over the fill')
assert(b.points[2][4] == -2 and b.points[2][4] > timer.points[1][4], 'huge fill must extend behind its countdown to the row end')

local symbol = _G[f.name .. 'BarIJIcons']
assert(symbol.alpha == 1 and symbol.h == 21, 'default mechanic icon should use the former 125% size')
local twoWidth, twoTimer = b:GetWidth(), timer.points[1][4]
local hugeLeft, hugeRight, hugeLabelRight = b.points[1][4], b.points[2][4], label.points[2][4]
assert(symbol.points[1][3] == 'LEFT' and symbol.points[1][4] + symbol.w / 2 < 0, 'mechanic must sit before the left spell icon')
_G[f.name .. 'BarIJIcons2']:Hide(); first:SetIcon(999)
assert(b:GetWidth() == twoWidth and timer.points[1][4] == twoTimer, 'single mechanic changed track/countdown alignment')
local singleWidth = b:GetWidth()
symbol:Hide(); first:SetIcon(999)
assert(b:GetWidth() == singleWidth and timer.points[1][4] == -4, 'absent indicators changed track/countdown alignment')
symbol:SetShown(true); first:SetIcon(999)
assert(b:GetWidth() == singleWidth, 'reappearing symbol did not restore its space')
DBT.Options.HugeTextXOffset, DBT.Options.HugeTextYOffset = 2, 3
first:ApplyStyle()
assert(label.points[1][4] == 32 and label.points[1][5] == 3 and timer.points[1][5] == 3, 'native text offsets lost')
DBT.Options.HugeTextXOffset, DBT.Options.HugeTextYOffset = 0, 0
DBT.Options.JournalIcons = 4; first:ApplyStyle()
assert(symbol.h == 14 and _G[f.name .. 'BarIJIcons3'].points[1][5] < symbol.points[1][5], 'four-symbol grid must fit within row height')
assert(b.points[1][4] == hugeLeft and b.points[2][4] == hugeRight and label.points[2][4] == hugeLabelRight and timer.points[1][4] == twoTimer)
for i = 1, 4 do
    local icon = _G[f.name .. 'BarIJIcons' .. (i == 1 and '' or i)]
    assert(icon.points[1][4] + icon.w / 2 < 0, 'mechanic grid overlaps the row')
end
-- Sparse slots use a full-size centered symbol, not a four-slot size limit.
for i = 1, 4 do _G[f.name .. 'BarIJIcons' .. (i == 1 and '' or i)]:SetShown(i == 3) end
first:SetIcon(999)
assert(_G[f.name .. 'BarIJIcons3'].h == 21 and _G[f.name .. 'BarIJIcons3'].points[1][5] == 0)
-- Recognize the actual native texture/crop, independent of timer names or colors.
DBM_COMMON_L = {
    DAMAGE_ICON = '|TInterface\\Journal\\sheet.blp:20:20:0:0:256:64:32:64:0:32|t',
    INTERRUPT_ICON = '|TInterface\\Journal\\sheet.blp:20:20:0:0:256:64:96:128:0:32|t',
}
local mechanic = _G[f.name .. 'BarIJIcons3']
local nativeColor = {0.7,0.8,0.9,0.65}
mechanic:SetTexture('Interface\\Journal\\sheet.blp'); mechanic:SetTexCoord(32/256,64/256,0,32/64)
mechanic:SetVertexColor(table.unpack(nativeColor)); first:SetIcon(999)
local glyphAtlas = 'Interface\\AddOns\\EUIAddonSkins\\Media\\DBMMechanics.tga'
assert(mechanic.path == glyphAtlas and mechanic.crop[1] == 1/8 and mechanic.color[1] == accent, 'damage glyph not replaced with monochrome sword')
local glyphObjects, glyphHooks = created, hooks
for _ = 1, 10 do first:ApplyStyle() end
assert(mechanic.path == glyphAtlas and created == glyphObjects and hooks == glyphHooks, 'warm glyph styling must reuse native texture')
-- Modern texture identity can be a file ID; prefer the public file-path accessor.
mechanic:SetTexture(12345); mechanic.filePath = 'Interface/Journal/sheet.blp'
mechanic:SetTexCoord(96/256,128/256,0,32/64); first:SetIcon(999)
assert(mechanic.path == glyphAtlas and mechanic.crop[1] == 3/8, 'modern interrupt crop not recognized')
mechanic:SetTexture('custom-unknown'); mechanic:SetTexCoord(0,1,0,1); first:SetIcon(999)
assert(mechanic.path == 'custom-unknown' and mechanic.crop[2] == 1 and mechanic.color[1] == nativeColor[1], 'unknown symbol or native tint was overwritten')
-- Empty configured/shown slots must not reserve room or invent a symbol.
for i = 1, 4 do _G[f.name .. 'BarIJIcons' .. (i == 1 and '' or i)]:SetShown(i == 3) end
first:SetIcon(999)
local occupiedWidth = b:GetWidth()
mechanic:SetTexture(nil); first:SetIcon(999)
assert(b:GetWidth() == occupiedWidth and mechanic.path == nil, 'empty configured slots changed track length')
mechanic:SetTexture('Interface\\Journal\\sheet.blp'); mechanic:SetTexCoord(32/256,64/256,0,32/64)
mechanic.masked = true; first:SetIcon(999)
assert(mechanic.path ~= glyphAtlas, 'masked mechanic artwork changed')
mechanic.masked = nil
local privateCoord = {}
issecretvalue = function(v) return v == privateCoord end
mechanic.privateCoords = {privateCoord,0,0,0.5,0.25,0,0.25,0.5}
first:SetIcon(999); assert(mechanic.path ~= glyphAtlas, 'secret coordinates inspected')
mechanic.privateCoords, issecretvalue = nil, nil
-- Numeric-only paths without an accessor safely retain the original symbol.
local nativePathGetter = mechanic.GetTextureFilePath
mechanic.GetTextureFilePath = nil; mechanic:SetTexture(34567)
first:SetIcon(999); assert(mechanic.path == 34567)
mechanic.GetTextureFilePath = nativePathGetter
-- Every original atlas cell maps only from its matching native mechanic tag.
local fields = {'TANK_ICON','DAMAGE_ICON','HEALER_ICON','INTERRUPT_ICON','IMPORTANT_ICON','MAGIC_ICON','BLEED_ICON','DEADLY_ICON'}
DBM_COMMON_L = {}
for i, field in ipairs(fields) do
    DBM_COMMON_L[field] = string.format('|TInterface\\Journal\\all.blp:20:20:0:0:256:32:%d:%d:0:32|t',(i-1)*32,i*32)
end
for i = 1, 8 do
    mechanic:SetTexture('Interface\\Journal\\all.blp'); mechanic:SetTexCoord((i-1)/8,i/8,0,1)
    first:SetIcon(999)
    assert(mechanic.path == glyphAtlas and mechanic.crop[1] == (i-1)/8 and mechanic.crop[2] == i/8, 'wrong glyph for native mechanic '..i)
end
-- Installed EUI modules supply matching artwork without bundling/loading them.
-- Their absence and late arrival must retain the exact semantic fallback.
local previousAddOns, previousFileID = C_AddOns, GetFileIDFromPath
local loadedEUI = {}
C_AddOns = {IsAddOnLoaded = function(name) return loadedEUI[name] end}
local expectedEUI = {
    [1] = 'Interface\\AddOns\\EllesmereUIRaidFrames\\Media\\tank.png',
    [2] = 'Interface\\AddOns\\EllesmereUIRaidFrames\\Media\\dps.png',
    [3] = 'Interface\\AddOns\\EllesmereUIRaidFrames\\Media\\healer.png',
    [4] = 'Interface\\AddOns\\EllesmereUIDamageMeters\\Media\\dm_home_interrupt.png',
    [8] = 'Interface\\AddOns\\EllesmereUIDamageMeters\\Media\\dm_home_deaths.png',
}
loadedEUI.EllesmereUIRaidFrames, loadedEUI.EllesmereUIDamageMeters = true, true
local euiObjects, euiHooks = created, hooks
for i = 1, 8 do
    mechanic:SetTexture('Interface\\Journal\\all.blp'); mechanic:SetTexCoord((i-1)/8,i/8,0,1)
    first:SetIcon(999)
    assert(mechanic.path == (expectedEUI[i] or glyphAtlas), 'incorrect EUI semantic mapping '..i)
    if expectedEUI[i] then assert(mechanic.crop[1] == 0 and mechanic.crop[2] == 1) end
    first:ApplyStyle()
    assert(mechanic.path == (expectedEUI[i] or glyphAtlas), 'EUI glyph lost on warm styling')
end
assert(created == euiObjects and hooks == euiHooks, 'EUI glyph selection allocated UI objects/hooks')
loadedEUI.EllesmereUIDamageMeters = nil; first:ApplyStyle()
assert(mechanic.path == glyphAtlas and mechanic.crop[1] == 7/8, 'missing EUI module did not fall back')
loadedEUI.EllesmereUIDamageMeters = true; first:ApplyStyle()
assert(mechanic.path == expectedEUI[8], 'late EUI module did not upgrade the cached fallback')
-- Numeric Retail texture IDs match resolved native paths even without a
-- GetTextureFilePath accessor. Resolve the sheet once, never on countdowns.
local resolutions = 0
GetFileIDFromPath = function(path)
    resolutions = resolutions + 1
    if path == 'Interface\\Journal\\all.blp' then return 98765 end
end
local oldCommon = DBM_COMMON_L; DBM_COMMON_L = {}
for field, value in pairs(oldCommon) do DBM_COMMON_L[field] = value end
mechanic.GetTextureFilePath = nil; mechanic:SetTexture(98765); mechanic:SetTexCoord(2/8,3/8,0,1)
first:SetIcon(999)
assert(mechanic.path == expectedEUI[3], 'Retail file-ID healer symbol stayed native')
local resolvedOnce = resolutions
for _ = 1, 10 do first:ApplyStyle() end
assert(resolutions == resolvedOnce and mechanic.path == expectedEUI[3], 'warm styling repeated native file-ID lookups')
mechanic.GetTextureFilePath = nativePathGetter
C_AddOns, GetFileIDFromPath = previousAddOns, previousFileID
local nativeCoords = mechanic.GetTexCoord
mechanic.GetTexCoord = function() return 0,1/8,0,1 end
mechanic:SetTexture('Interface\\Journal\\all.blp'); first:SetIcon(999)
assert(mechanic.path == glyphAtlas and mechanic.crop[1] == 0, 'four-coordinate compatibility failed')
mechanic.GetTexCoord = nativeCoords
mechanic:SetTexture('role-3'); mechanic:SetTexCoord(0,1,0,1)
first:SetIcon(999)
-- Native enlargement width changes remain bounded by opposing fill anchors.
local beforeWidth = b:GetWidth()
f:SetSize(230, 28); b:SetWidth(230)
assert(b:GetWidth() == beforeWidth + 35 and b:GetWidth() < f:GetWidth())
f:SetSize(195, 20)
-- Huge single-row layout preserves fitted inline text and configured dimensions.
label:SetText('|Twarning:20:20|t Custom User Bar')
DBT.Options.HugeHeight = 40; first:ApplyStyle()
assert(b.h == 36 and label.h == 36 and spellIcon.h == 27, 'row/icon geometry must scale without overflowing narrow rows')
assert(label.text == '|Twarning:13:13|t Custom User Bar' and label.justifyV == 'MIDDLE')
f:SetSize(400, 40); first:ApplyStyle()
assert(spellIcon.h == 36 and _G[f.name .. 'BarIJIcons'].h == 20)
DBT.Options.JournalIcons = 1; first:ApplyStyle()
assert(symbol.h == 30, 'single mechanic must follow height rather than old concept width compartment')
PixelUtil = {GetPixelToUIUnitFactor = function() return 0.75 end}; f.scale = 1.5
first:ApplyStyle()
assert(f.regions[2].h == 0.5 and f.regions[4].w == 0.5 and f.children[#f.children - 1].regions[1].h == 0.5)
assert(b.points[1][4] * 2 == math.floor(b.points[1][4] * 2))
PixelUtil = nil; GetPhysicalScreenSize = function() return 1820, 1024 end
first:ApplyStyle(); assert(f.regions[2].h == 0.5)
GetPhysicalScreenSize = nil; f.scale = 1
DBT.Options.HugeHeight, DBT.Options.JournalIcons = 28, 2
f:SetSize(195, 20)
DBT.Options.IconRight = true; first:ApplyStyle()
local rightIcon = _G[f.name .. 'BarIcon2']
assert(rightIcon.shown and rightIcon.points[1][1] == 'RIGHT' and rightIcon.points[1][4] == -2)
assert(b.points[2][4] < -rightIcon.w and label.points[2][4] < timer.points[1][4] - timer.w, 'right spell icon overlaps content')
DBT.Options.IconRight = false; first.enlarged = false; first:ApplyStyle()
assert(symbol.alpha == 0 and b.h == 5 and panel.points[1][4] == 0)
assert(tint.fillColor[1] == 0.14 and tint.fillColor[4] == 0.2, 'small fill styling changed')
assert(label.size == 9 and label.h == 10 and label.points[1][5] == 3 and b:GetWidth() == 169, 'small layout changed after huge transition')
local smallHeight, smallWidth, smallY, smallFont = b.h, b:GetWidth(), label.points[1][5], label.size
for _ = 1, 10 do
    first.enlarged = true; first:ApplyStyle()
    assert(b.h == 24 and label.points[1][5] == 0 and label.h == 24)
    first.enlarged = false; first:ApplyStyle()
    assert(b.h == smallHeight and b:GetWidth() == smallWidth and label.points[1][5] == smallY and label.size == smallFont, 'pooled size transition lost small layout')
end

DBT.Options.IconLeft = false; first:ApplyStyle()
assert(b.points[1][4] == 4 and not spellIcon.shown, 'absent spell icon left blank space')
DBT.Options.IconLeft = true
DBT.Options.Height = 10; f:SetSize(100, 10); first:ApplyStyle()
assert(b:GetWidth() > 20 and b.h == 6 and label.size == 6 and label.points[2][4] < timer.points[1][4] - timer.w, 'smallest row must remain usable')
DBT.Options.Height = 20; f:SetSize(195, 20); first:ApplyStyle()
DBT.Options.IconLocked, DBT.Options.Height = false, 30
first:ApplyStyle()
assert(f.h == 20 and panel.points[1][5] == 15 and panel.points[2][5] == -15, 'unlocked hit frame/settings changed')
DBT.Options.IconLocked, DBT.Options.Height = true, 40; first:ApplyStyle()
assert(b.h == 10 and label.h == 25 and label.points[1][5] > 0, 'two-row layout did not follow configured height')
DBT.Options.Height = 60; first:ApplyStyle()
assert(b.h == 15)
DBT.Options.Height = 20; f:SetSize(195, 20); first:ApplyStyle()
-- Text updates normalize only oversized inline textures, retaining full source
-- geometry for a later font change and all native text/crop information.
local inline = '|Twarning:20:20:0:0:512:256:401:433:1:33|t '
assert(first:SetText('|cffffff00Custom User Bar|r', inline) == 'native-text')
assert(label.text == '|Twarning:10:10:0:0:512:256:401:433:1:33|t |cffffff00Custom User Bar|r')
for _ = 1, 10 do
    first:SetText('|cffffff00Custom User Bar|r', inline)
    assert(label.text == '|Twarning:10:10:0:0:512:256:401:433:1:33|t |cffffff00Custom User Bar|r', 'native text reset restored oversized icon')
end
local textCount = textWrites
for _ = 1, 10 do first:ApplyStyle() end
assert(textWrites == textCount, 'warm paint rewrote normalized text')
DBT.Options.FontSize = 30; DBT.Options.Height = 60; first:ApplyStyle()
assert(label.text == inline .. '|cffffff00Custom User Bar|r', 'larger fonts did not restore original inline icon size')
DBT.Options.FontSize, DBT.Options.Height = nil, 20; first:ApplyStyle()
first:SetText('Auto |Twarning:0:0|t and atlas |A:warning:20:20|a')
assert(label.text == 'Auto |Twarning:0:0|t and atlas |A:warning:20:20|a')
first:SetText('Aspect |Twarning:40:20|t')
assert(label.text == 'Aspect |Twarning:10:5|t')
local secretLabel = {}
issecretvalue = function(v) return v == secretLabel end
first:SetText(secretLabel, nil, true)
first:ApplyStyle()
assert(label.text == secretLabel, 'secret inline text inspected or changed')
issecretvalue = nil
first:SetText('Normal text')
-- Native color updates remain authoritative; the same tint tracks the fill.
b.fill:SetVertexColor(0.1, 0.3, 0.9, 0.75)
assert(b.fill.color[3] == 0.9 and tint.all == b.fill)
local new, result = DBT:CreateBar(20, 'new')
assert(result == 'native-create' and _G[new.frame.name .. 'Bar'].fill.path == 'Interface\\Buttons\\WHITE8X8')
gradientMode = 'legacy'
local legacy = DBT:CreateBar(20, 'legacy-gradient')
for _, t in ipairs(_G[legacy.frame.name .. 'Bar'].regions) do assert(not t.gradient and not t.gradientAlpha) end
gradientMode = 'none'
local fallback = DBT:CreateBar(20, 'fallback-gradient')
for _, t in ipairs(_G[fallback.frame.name .. 'Bar'].regions) do assert(not t.gradient and not t.gradientAlpha) end
gradientMode = 'modern'
-- Unlike the reference skins' CreateBar handlers, creating a timer must not
-- enumerate the entire active pool or repaint existing timer text.
local beforeIterator, beforeFonts = iteratorCalls, fontWrites
for i = 1, 25 do DBT:CreateBar(20, 'burst-' .. i) end
assert(iteratorCalls == beforeIterator, 'timer creation traversed existing bars')
assert(fontWrites - beforeFonts == 25 * 4, 'timer burst repainted existing timer fonts')
print('BENCH dbm_create burst=25 active_pool_walks=' .. (iteratorCalls - beforeIterator) .. ' font_writes=' .. (fontWrites - beforeFonts))
oldCreated, oldHooks = created, hooks
for _ = 1, 20 do DBT:CreateBar(20, 'new'); first:ApplyStyle() end
assert(created == oldCreated and hooks == oldHooks, 'pooled bar duplicated UI objects/hooks')
local private = bar('private'); private.isSecret = true
DBT:CreateBar(20, 'private'); assert(_G[private.frame.name .. 'Bar'].fill.path == 'dbm-gloss')
local protected = bar('protected'); protected.frame.protected = true
DBT:CreateBar(20, 'protected'); assert(_G[protected.frame.name .. 'Bar'].fill.path == 'dbm-gloss')
DebuffTypeColor = {Magic = {r=0.2,g=0.6,b=1}, Curse = {r=0.6,g=0,b=1}, Disease={r=0.6,g=0.4,b=0}, Poison={r=0,g=0.6,b=0}, Bleed={r=1,g=0,b=0}}
local preview = CreateFrame('Frame'); preview.Border = CreateFrame('Frame', nil, preview)
preview.Textures, preview.BorderTextures, preview.DurationTexts, preview.StackTexts = {}, {}, {}, {}
for i = 1, 5 do
    preview.Textures[i] = preview:CreateTexture(); preview.Textures[i].path = 237555
    preview.BorderTextures[i] = preview:CreateTexture()
    preview.DurationTexts[i] = object('FontString'); preview.StackTexts[i] = object('FontString')
end
DBM.Auras = {PlayerPreview = preview, PreviewToggle = function() return 'native-preview' end, OnSettingsChange = function() return 'native-settings' end}
event('ADDON_LOADED')
assert(DBM.Auras:PreviewToggle() == 'native-preview')
assert(preview.Textures[1].crop and preview.BorderTextures[1].alpha == 0 and preview.DurationTexts[1].font == 'eui')
assert(preview.Border.borderColor[1] == accent)
assert(preview.Border.backdrop.edgeSize == 1 and preview.Border.points[1][4] == -1, 'selection outline not tightened')
assert(preview.StackTexts[1].size < preview.DurationTexts[1].size)
assert(preview.StackTexts[1].points[1][4] == -3 and preview.StackTexts[1].shadow[4] == 0.9)
-- Five semantic preview edge colors; never recolor the cooldown or symbol.
for i = 1, 5 do
    local edgeLayer = preview.children[i + 1]
    assert(edgeLayer.regions[1].fillColor[1] == DebuffTypeColor[({'Magic','Curse','Disease','Poison','Bleed'})[i]].r)
end
local colors = DebuffTypeColor; DebuffTypeColor = nil
DBM.Auras:OnSettingsChange()
assert(preview.BorderTextures[1].alpha == 1 and not preview.children[2].shown, 'native border fallback not restored')
DebuffTypeColor = colors; DBM.Auras:OnSettingsChange()
-- Current Retail exposes colors and standalone glyphs through AuraUtil,
-- without the old global table. Native border art must still disappear.
DebuffTypeColor = nil
AuraUtil = {
    GetAuraBorderColor = function(kind) return colors[kind] end,
    SetAuraDispelTypeIcon = function(t, kind) t.atlas = 'native-' .. kind end,
}
preview.Symbols = {object('FontString')}; preview.Symbols[1].text = 'M'
DBM.Auras:OnSettingsChange()
local modernCreated, modernHooks = created, hooks
for i, kind in ipairs({'Magic','Curse','Disease','Poison','Bleed'}) do
    local layer = preview.children[i + 1]
    local symbol = layer.regions[5]
    assert(preview.BorderTextures[i].alpha == 0 and layer.shown)
    assert(layer.regions[1].fillColor[1] == colors[kind].r)
    assert(symbol.atlas == 'native-' .. kind and symbol.w <= 18 and symbol.points[1][1] == 'TOPRIGHT')
end
assert(preview.Symbols[1].text == 'M', 'native accessibility abbreviation changed')
for _ = 1, 20 do DBM.Auras:OnSettingsChange() end
assert(created == modernCreated and hooks == modernHooks, 'preview refresh duplicated objects/hooks')
preview.BorderTextures[1]:Hide(); DBM.Auras:OnSettingsChange()
assert(not preview.children[2].regions[5].shown, 'disabled dispel glyph remained visible')
preview.BorderTextures[1]:SetShown(true); DBM.Auras:OnSettingsChange()
-- Warning text is owned by DBM; retain content/colors/size/anchors and native
-- animation methods. Crop only DBM's plain inline spell-icon tags.
local warning = object('FontString', 'DBMWarning1')
local specialWarning = object('FontString', 'DBMSpecialWarning1')
warning.size, specialWarning.size = 22, 50
warning.color, specialWarning.color = {1, 0.4, 0, 1}, {1, 1, 0, 1}
warning:SetPoint('TOP', 0, 0)
warning:SetText('|cffff4400Danger|r |T136116:12:12|t |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t')
specialWarning:SetText('Move |T123:12:12|t |T456:20:20|t')
DBM.UpdateWarningOptions = function() warning:SetFont('native', 24); return 'native-options' end
DBM.UpdateSpecialWarningOptions = function() specialWarning:SetFont('native', 48); return 'native-special-options' end
event('ADDON_LOADED')
assert(warning.font == 'eui' and warning.size == 22 and specialWarning.font == 'eui' and specialWarning.size == 50)
assert(warning.text == '|cffff4400Danger|r |T136116:12:12:0:0:64:64:5:59:5:59|t |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t')
assert(specialWarning.text == 'Move |T123:12:12:0:0:64:64:5:59:5:59|t |T456:20:20|t')
assert(warning.color[2] == 0.4 and warning.points[1][1] == 'TOP')
assert(warning.shadow[4] == 0.9 and specialWarning.shadowOffset[1] == 1)
assert(DBM:UpdateWarningOptions() == 'native-options' and warning.font == 'eui' and warning.size == 24)
assert(DBM:UpdateSpecialWarningOptions() == 'native-special-options' and specialWarning.font == 'eui' and specialWarning.size == 48)
warning:SetFontObject('native'); assert(warning.font == 'eui')
local privateText = {}; issecretvalue = function(v) return v == privateText end
warning:SetText(privateText); assert(warning.text == privateText, 'secret warning text modified')
warning:SetText('New |T789:12:12|t'); assert(warning.text == 'New |T789:12:12:0:0:64:64:5:59:5:59|t')
local warningHooks = hooks
for _ = 1, 20 do event('ADDON_LOADED') end
assert(hooks == warningHooks, 'warning refresh duplicated hooks')
local liveButton = CreateFrame('Button')
local liveIcon = liveButton:CreateTexture(); liveIcon.path = 987
DBM.Auras.AuraTrackingState = {player = {buttonRegions = {[liveButton] = {icon = liveIcon}}}}
secret = true; DBM.Auras:OnSettingsChange(); assert(not liveIcon.crop, 'restricted live aura touched')
secret = false; DBM.Auras:OnSettingsChange(); assert(liveIcon.crop)
-- Blizzard Skins+ custom accent controls timer edges independently of global accent.
EllesmereUIDB = {blizzWinAccentBar = {useCustom = true, color = {r = 0.35, g = 0.45, b = 0.55}}}
local fillR, fillG, fillB = b.fill:GetVertexColor()
for _, fn in ipairs(looks) do fn() end; flush()
assert(f.regions[2].fillColor[1] == 0.35 and f.children[#f.children - 1].regions[1].fillColor[1] == 0.35)
first.enlarged = true; first:ApplyStyle()
assert(f.regions[2].fillColor[1] == 0.35 and f.children[#f.children - 1].regions[1].fillColor[1] == 0.35, 'huge timer ignored Blizzard Skins+ accent')
first.enlarged = false; first:ApplyStyle()
assert(b.fill.color[1] == fillR and b.fill.color[2] == fillG and b.fill.color[3] == fillB, 'custom border accent recolored semantic fill')
-- Accent visibility affects timer outlines, not backgrounds or fill.
EllesmereUIDB.blizzWinAccentBar.enabled = false
for _, fn in ipairs(looks) do fn() end; flush()
for i = 2, 5 do assert(not f.regions[i].shown, 'small timer accent outline remained visible') end
assert(not f.children[#f.children - 1].regions[1].shown and panel.shown and b.fill.shown)
assert(not trackEnd and not endpoint, 'accent changes resurrected end ticks')
first.enlarged = true; first:ApplyStyle()
for i = 2, 5 do assert(not f.regions[i].shown, 'huge timer accent outline remained visible') end
assert(not f.children[#f.children - 1].regions[1].shown)
EllesmereUIDB.blizzWinAccentBar.enabled = true
for _, fn in ipairs(looks) do fn() end; flush()
for i = 2, 5 do assert(f.regions[i].shown, 'accent toggle did not restore timer outline') end
assert(f.children[#f.children - 1].regions[1].shown)
first.enlarged = false; first:ApplyStyle()
EllesmereUIDB.blizzWinAccentBar.useCustom = false
accent = 0.8; for _, fn in ipairs(looks) do fn() end; flush()
assert(f.regions[2].fillColor[1] == accent and preview.Border.borderColor[1] == accent)
assert(f.regions[3].fillColor[1] == accent and f.children[#f.children - 1].regions[1].fillColor[1] == accent, 'full panel/spell icon accent did not refresh')
combat = true
warning:SetText('Combat |T789:12:12|t'); assert(warning.text == 'Combat |T789:12:12:0:0:64:64:5:59:5:59|t')
local duringCombat = DBT:CreateBar(20, 'combat')
assert(_G[duringCombat.frame.name .. 'Bar'].fill.path == 'Interface\\Buttons\\WHITE8X8', 'ordinary combat timer not styled')
accent = 0.9; for _, fn in ipairs(looks) do fn() end; flush()
assert(preview.Border.borderColor[1] ~= accent, 'aura refresh should defer during combat')
combat = false; event('PLAYER_REGEN_ENABLED')
assert(preview.Border.borderColor[1] == accent, 'deferred theme refresh lost')
-- Native DBM settings page is built only after the lazy GUI category exists.
assert(DBM_GUI == nil and EUIAddonSkinsDB.dbm.smallLayout == 'strip' and EUIAddonSkinsDB.dbm.hugeLayout == 'fill')
local pageCount, nativePage, nativeArea, dropdowns, nativePreview = 0, nil, nil, {}, nil
local prototypes = {}
local function group(frame) return setmetatable({frame = frame}, {__index = prototypes}) end
function prototypes:CreateNewPanel(title, kind)
    assert(title == 'EUI AddonSkins' and kind == 'option')
    pageCount = pageCount + 1; nativePage = group(CreateFrame('Frame')); return nativePage
end
function prototypes:CreateArea(title)
    assert(title == 'Timer layouts')
    nativeArea = group(CreateFrame('Frame', nil, self.frame))
    nativeArea.frame.mytype = 'area'
    nativeArea.frame:CreateFontString():SetText(title)
    return nativeArea
end
function prototypes:CreateDropdown(title, values, binding, key, selectValue, width)
    local control = CreateFrame('DropdownButton', nil, self.frame)
    control:SetWidth(width); control.mytype = 'dropdown2'; control.values = values
    control:CreateFontString():SetText(title)
    control:SetScript('OnShow', function() control.value = binding.Options[key] end)
    control.selectValue = function(value) control.value = value; selectValue(value) end
    control.SetSelectedValue = function(self, value) self.value = value; selectValue(value) end
    dropdowns[key] = control
    return control
end
function prototypes:CreateButton(title, width, height, onclick)
    local control = CreateFrame('Button', nil, self.frame)
    control:SetSize(width,height); control.label = control:CreateFontString(); control.label:SetText(title)
    control:SetScript('OnClick', onclick); nativePreview = control
    return control
end
function prototypes:CreateText(value, width)
    local text = self.frame:CreateFontString(); text:SetText(value); text:SetWidth(width); return text
end
S.Checkbox = function(frame) frame.checkboxStyled = true end
S.Panel = function(frame) frame.panelStyled = true end
S.Shell = function(frame) frame.shellStyled = true end
S.Dropdown = function(frame) frame.dropdownStyled = true end
S.Button = function(frame) frame.buttonStyled = true end
local nativeDemoCalls, collapseDuration = 0, nil
DBM.DemoMode = function(self, forceOld)
    assert(self == DBM and forceOld == true, 'preview must explicitly choose native DBM bars on Retail')
    nativeDemoCalls = nativeDemoCalls + 1
    local small = DBT:CreateBar(20, 'native-preview-small')
    local huge = DBT:CreateBar(5, 'native-preview-huge'); huge.enlarged = true; huge:ApplyStyle()
    assert(_G[small.frame.name .. 'Bar'].fill.path == 'Interface\\Buttons\\WHITE8X8')
    assert(_G[huge.frame.name .. 'Bar'].fill.path == 'Interface\\Buttons\\WHITE8X8')
    return 62
end
DBM_GUI = {}
event('ADDON_LOADED'); assert(pageCount == 0, 'incomplete GUI must not create a partial settings page')
local menuUpdates = 0
DBM_GUI_OptionsFrame = CreateFrame('Frame')
DBM_GUI_OptionsFrame.UpdateMenuFrame = function() menuUpdates = menuUpdates + 1 end
DBM_GUI_OptionsFrame.DisplayFrame = function(_, page) DBM_GUI.currentViewing = page end
DBM_GUI_OptionsFrame.ShowTab = function(self, tab)
    self.tab = tab; self:UpdateMenuFrame()
    if DBM_GUI.currentViewing then self:DisplayFrame(DBM_GUI.currentViewing) end
end
event('ADDON_LOADED')
local sidePreview = DBM_GUI_OptionsFrame.children[1]
assert(sidePreview and sidePreview.text == 'EUI Bar Styling' and sidePreview.buttonStyled and sidePreview.enabled)
assert(sidePreview:GetParent() == DBM_GUI_OptionsFrame and sidePreview.points[1][3] == 'TOPRIGHT', 'preview must attach outside the main window')
assert(pageCount == 0, 'side preview must not require the timer-category APIs')
local sideButton = sidePreview
sideButton.scripts.OnClick(); assert(nativeDemoCalls == 0, 'opening styling panel started demo bars')
local sidePanel
for _, child in ipairs(frames) do if child.w == 330 and child:GetParent() == UIParent then sidePanel = child end end
assert(sidePanel and sidePanel:IsShown(), 'side styling panel missing')
local function sideControl(text)
    for _, child in ipairs(sidePanel.children) do
        if child.text == text or child.Text and child.Text.text == text then return child end
    end
    error('Missing side control: ' .. text)
end
sidePreview = sideControl('Preview DBM bars')
sidePreview.scripts.OnClick(); assert(nativeDemoCalls == 1)
nativeDemoCalls = 0
DBM_GUI.Cat_Timers = group(CreateFrame('Frame'))
DBM_GUI.CollapseForPreview = function(_, duration) collapseDuration = duration end
local originalDemo = DBM.DemoMode
EUIAddonSkinsDB.extraSettings = {keep = true}
local dbtOptions = {}; for key,value in pairs(DBT.Options) do dbtOptions[key] = value end
local nativeDefaults = {saved = true}; DBT.DefaultOptions = nativeDefaults
event('ADDON_LOADED')
assert(pageCount == 1 and dropdowns.smallLayout and dropdowns.hugeLayout and nativePreview.enabled and menuUpdates == 1)
assert(dropdowns.smallLayout.dropdownStyled and dropdowns.hugeLayout.dropdownStyled and nativePreview.buttonStyled)
assert(DBM.DemoMode == originalDemo, 'default Blizzard/native test action was replaced')
dropdowns.smallLayout.scripts.OnShow(); dropdowns.hugeLayout.scripts.OnShow()
assert(dropdowns.smallLayout.value == 'strip' and dropdowns.hugeLayout.value == 'fill')
local uiCreated, uiHooks = created, hooks
for _ = 1, 10 do event('ADDON_LOADED'); nativePage.frame.scripts.OnShow() end
assert(pageCount == 1 and created == uiCreated and hooks == uiHooks and menuUpdates == 1, 'settings controls/hooks or category-list updates duplicated')
-- Navigating ordinary options must not repaint the active HUD timer pool,
-- warnings or aura previews. Full/manual refreshes still discover/repaint it.
if os.getenv('EUI_AUDIT_BASELINE') ~= '1' then
    local page = CreateFrame('Frame', nil, DBM_GUI_OptionsFrame); page.mytype = 'panel'
    local text = page:CreateFontString(); text:SetText('Ordinary options')
    DBM_GUI_OptionsFrame:DisplayFrame(page); flush()
    local navIterations, navFonts, navObjects, navHooks = iteratorCalls, fontWrites, created, hooks
    for i = 1, 100 do DBM_GUI_OptionsFrame:ShowTab(i % 2 + 1) end
    flush()
    assert(iteratorCalls == navIterations and fontWrites == navFonts, 'GUI navigation repainted HUD or unchanged fonts')
    assert(created == navObjects and hooks == navHooks, 'GUI navigation duplicated objects/hooks')
    print(('BENCH dbm_navigation_hud pool_walks=%d font_writes=%d callbacks=100'):format(iteratorCalls - navIterations, fontWrites - navFonts))
    modules.DBM.refresh(); flush(); assert(iteratorCalls > navIterations, 'manual refresh lost HUD discovery')
end
-- Changes repaint existing bars synchronously, without traversing GUI frames.
first.enlarged = false; first:ApplyStyle()
local beforeUIReads = childReads
dropdowns.smallLayout.selectValue('fill')
assert(EUIAddonSkinsDB.dbm.smallLayout == 'fill' and EUIAddonSkinsDB.dbm.hugeLayout == 'fill')
assert(b.h == 16 and label.points[1][5] == 0 and childReads == beforeUIReads)
local unchangedIterations = iteratorCalls
for _ = 1, 100 do dropdowns.smallLayout.selectValue('fill') end
assert(iteratorCalls == unchangedIterations, 'unchanged selection repainted active bars')
dropdowns.hugeLayout.selectValue('strip')
assert(EUIAddonSkinsDB.dbm.hugeLayout == 'strip' and b.h == 16, 'huge selector modified small layout')
first.enlarged = true; first:ApplyStyle()
assert(b.h == 7 and label.points[1][5] > 0, 'huge strip preference not applied')
dropdowns.smallLayout.selectValue('strip')
assert(b.h == 7 and EUIAddonSkinsDB.dbm.hugeLayout == 'strip')
dropdowns.hugeLayout.selectValue('fill'); assert(b.h == 24 and label.points[1][5] == 0)
first.enlarged = false; first:ApplyStyle(); assert(b.h == 5)
dropdowns.smallLayout.selectValue('unsupported'); assert(EUIAddonSkinsDB.dbm.smallLayout == 'strip' and b.h == 5)
-- The selected preferences survive ordinary theme/display refreshes and apply to new bars.
dropdowns.smallLayout.selectValue('fill'); for _, fn in ipairs(looks) do fn() end; flush()
dropdowns.smallLayout.scripts.OnShow(); assert(dropdowns.smallLayout.value == 'fill')
local futureLayout = DBT:CreateBar(20, 'settings-new-small')
assert(_G[futureLayout.frame.name .. 'Bar'].h == 16)
dropdowns.smallLayout.selectValue('strip')
assert(_G[futureLayout.frame.name .. 'Bar'].h == 5)
nativePreview.scripts.OnClick(); assert(nativeDemoCalls == 1 and collapseDuration == 62)
-- Missing preview APIs and combat are explicit, safe unavailable states.
DBM.DemoMode = nil; nativePage.frame.scripts.OnShow(); sidePreview.scripts.OnShow(); assert(not nativePreview.enabled and not sidePreview.enabled)
nativePreview.scripts.OnClick(); assert(nativeDemoCalls == 1)
sidePreview.scripts.OnClick(); assert(nativeDemoCalls == 1)
DBM.DemoMode = originalDemo
combat = true; event('PLAYER_REGEN_DISABLED'); assert(not nativePreview.enabled and not sidePreview.enabled)
local combatHeight = b.h
dropdowns.smallLayout.selectValue('fill')
assert(EUIAddonSkinsDB.dbm.smallLayout == 'fill' and b.h == combatHeight, 'layout changes must defer during combat')
nativePreview.scripts.OnClick(); assert(nativeDemoCalls == 1)
sidePreview.scripts.OnClick(); assert(nativeDemoCalls == 1)
combat = false; event('PLAYER_REGEN_ENABLED')
assert(nativePreview.enabled and sidePreview.enabled and b.h == 16 and label.points[1][5] == 0)
sidePreview.scripts.OnClick(); assert(nativeDemoCalls == 2 and collapseDuration == 62)
dropdowns.smallLayout.selectValue('strip'); assert(b.h == 5)
for key,value in pairs(DBT.Options) do assert(dbtOptions[key] == value, 'native DBM options changed: '..key) end
for key,value in pairs(dbtOptions) do assert(DBT.Options[key] == value) end
assert(DBT.DefaultOptions == nativeDefaults and nativeDefaults.saved and EUIAddonSkinsDB.extraSettings.keep)
-- End-user side controls: independent styling, native restoration and warm reuse.
do
    local smallTab, hugeTab = sideControl('Small Bars'), sideControl('Big Bars')
    local style = sideControl('Apply EUI styling')
    local border = sideControl('Accent border (follows EUI visibility)')
    local glyphs = sideControl('EUI mechanic icons (outside Big Bars)')
    local reset = sideControl('Reset EUI styling')
    local opacity
    for _, child in ipairs(sidePanel.children) do if child.kind == 'Slider' and child.minValue == 0 then opacity = child end end
    local function checked(control, value) control:SetChecked(value); control.scripts.OnClick(control) end
    smallTab.scripts.OnClick()
    assert(style.checkboxStyled and style.checked and not glyphs:IsShown())
    assert(opacity.mouse == true and opacity.minValue == 0 and opacity.maxValue == 100 and opacity.step == 1 and opacity.thumb.w == 10 and opacity.thumb.h == 14)
    local oldHugeOpacity = EUIAddonSkinsDB.dbm.hugeOpacity
    local walks = iteratorCalls
    for i = 1, 40 do opacity:SetValue(i) end
    assert(iteratorCalls == walks, 'opacity drag refreshed the timer pool synchronously for every callback')
    flush()
    assert(iteratorCalls == walks + 1 and panel.fillColor[4] == 0.4 and EUIAddonSkinsDB.dbm.hugeOpacity == oldHugeOpacity)
    walks = iteratorCalls; for _ = 1, 30 do opacity:SetValue(40) end; flush()
    assert(iteratorCalls == walks, 'unchanged opacity repainted timers')
    checked(border, false); assert(not f.regions[2]:IsShown(), 'per-type border override ignored')
    hugeTab.scripts.OnClick(); first.enlarged = true; first:ApplyStyle()
    assert(f.regions[2]:IsShown() and glyphs:IsShown(), 'small border override leaked into Huge Bars')
    first.enlarged = false; first:ApplyStyle(); smallTab.scripts.OnClick()
    checked(border, true)
    local progress = sideControl('Progress: DBM category colours')
    local nativeRGB = {b.fill:GetVertexColor()}
    progress.scripts.OnClick()
    assert(EUIAddonSkinsDB.dbm.smallColour == 'accent' and EUIAddonSkinsDB.dbm.hugeColour == 'category')
    assert(tint.fillColor[1] == accent and tint.fillColor[4] == 1 and tint.all == b.fill)
    b.fill:SetVertexColor(0.2, 0.3, 0.4, 0.8)
    assert(tint.fillColor[1] == accent, 'native urgency recolour replaced accent overlay')
    EllesmereUIDB.blizzWinAccentBar.useCustom = true
    EllesmereUIDB.blizzWinAccentBar.color = {r = 0.23, g = 0.34, b = 0.45}
    EllesmereUIDB.blizzWinAccentBar.enabled = false
    for _, fn in ipairs(looks) do fn() end; flush()
    assert(tint.fillColor[1] == 0.23 and not f.regions[2]:IsShown(), 'progress colour/theme or global border visibility ignored')
    EllesmereUIDB.blizzWinAccentBar.useCustom, EllesmereUIDB.blizzWinAccentBar.enabled = false, true
    for _, fn in ipairs(looks) do fn() end; flush()
    assert(tint.fillColor[1] == accent and f.regions[2]:IsShown())
    progress.scripts.OnClick()
    assert(b.fill.color[1] == 0.2 and tint.fillColor[4] == 0.2, 'category colours were written back into native data')
    b.fill:SetVertexColor(table.unpack(nativeRGB))
    -- Use a fresh native bar so every restored property has a known baseline.
    local restored = bar('restore-settings')
    local rf, rb = restored.frame, _G[restored.frame.name .. 'Bar']
    local ri, rn = _G[rf.name .. 'BarIcon1'], _G[rf.name .. 'BarName']
    rb:SetPoint('TOPLEFT', rf, 'TOPLEFT', 0, 0); rb:SetPoint('BOTTOMRIGHT', rf, 'BOTTOMRIGHT', 0, 0)
    ri:SetPoint('RIGHT', rf, 'LEFT', -2, 0); ri:SetSize(20,20); ri:SetTexCoord(0,1,0,1)
    rn:SetPoint('LEFT', rb, 'LEFT', 3, 0); rn:SetFont('native',14)
    rn:SetWordWrap(true); rn:SetShadowOffset(0,0); rn.fontObject = 'native-shadow'
    restored:ApplyStyle()
    DBT:CreateBar(20, 'restore-settings')
    assert(rb.fill.path == 'Interface\\Buttons\\WHITE8X8' and rn.font == 'eui')
    -- Border textures can be created lazily after the original native snapshot.
    local lateBorder = rb:CreateTexture(rf.name .. 'BarBorderRight'); lateBorder:SetAlpha(0.7)
    restored:ApplyStyle(); assert(lateBorder.alpha == 0)
    rn.fontObject = 'eui-shadow'
    restored:SetText('Restore |Tknown:40:40|t')
    local appliedObjects, appliedHooks = created, hooks
    checked(style, false)
    assert(rb.fill.path == 'dbm-gloss' and rb.h == DBT.Options.Height and rn.font == 'native' and rn.fontObject == 'native-shadow', 'native style did not return')
    assert(rb.points[1][2] == rf and rb.points[1][4] == 0 and ri.points[1][3] == 'LEFT' and ri.w == 20)
    local ulx, uly, _, _, urx = ri:GetTexCoord()
    assert(ulx == 0 and uly == 0 and urx == 1 and rn.wordWrap and rn.shadowOffset[1] == 0)
    assert(rn.text == 'Restore |Tknown:40:40|t', 'original inline text was not restored')
    assert(_G[rf.name .. 'BarBackground'].alpha == 1 and lateBorder.alpha == 0.7, 'native alpha remained locked')
    assert(not panel:IsShown() and not tint:IsShown() and not endpoint and not trackEnd)
    assert(not opacity.enabled and not border.enabled and not progress.enabled and style.enabled)
    _G[rf.name .. 'BarBackground']:SetAlpha(0.6); assert(_G[rf.name .. 'BarBackground'].alpha == 0.6)
    restored:SetVariance(); assert(_G[rf.name .. 'BarVariance'].path == 'native-gradient')
    local unstyled = DBT:CreateBar(12, 'disabled-small-type')
    assert(_G[unstyled.frame.name .. 'Bar'].fill.path == 'dbm-gloss', 'disabled type styled a new timer')
    restored.enlarged = true; restored:ApplyStyle()
    assert(rb.fill.path == 'Interface\\Buttons\\WHITE8X8', 'disabled Small setting blocked Huge Bars')
    restored.enlarged = false; restored:ApplyStyle(); assert(rb.fill.path == 'dbm-gloss')
    checked(style, true)
    assert(rb.fill.path == 'Interface\\Buttons\\WHITE8X8' and panel:IsShown() and tint:IsShown())
    checked(style, false)
    assert(_G[rf.name .. 'BarBackground'].alpha == 0.6, 'second session restored stale native alpha')
    checked(style, true)
    local warmObjects, warmHooks = created, hooks
    for _ = 1, 5 do checked(style, false); checked(style, true) end
    assert(created == warmObjects and hooks == warmHooks, 'type toggles duplicated textures or hooks')
    assert(appliedObjects <= created and appliedHooks <= hooks)
    hugeTab.scripts.OnClick(); restored.enlarged = true; restored:ApplyStyle()
    local rm = _G[rf.name .. 'BarIJIcons']
    DBM_COMMON_L = {TANK_ICON = '|TInterface\\Journal\\sheet.blp:20:20:0:0:256:64:0:32:0:32|t'}
    rm:SetShown(true); rm:SetTexture('Interface\\Journal\\sheet.blp'); rm:SetTexCoord(0,32/256,0,32/64)
    rm:SetVertexColor(0.7,0.8,0.9,0.6); restored:SetIcon(123)
    assert(rm.path ~= 'Interface\\Journal\\sheet.blp')
    checked(glyphs, false)
    assert(rm.path == 'Interface\\Journal\\sheet.blp' and rm.color[1] == 0.7 and rm.color[4] == 0.6, 'native mechanic artwork/tint not restored')
    local gx, gy, _, _, gr = rm:GetTexCoord(); assert(gx == 0 and gy == 0 and gr == 32/256)
    checked(glyphs, true); assert(rm.path ~= 'Interface\\Journal\\sheet.blp')
    checked(style, false); assert(rm.path == 'Interface\\Journal\\sheet.blp' and rb.fill.path == 'dbm-gloss')
    checked(style, true)
    -- Combat stores preferences and catches up once it is safe.
    combat = true; event('PLAYER_REGEN_DISABLED')
    local previous = rb.fill.path
    checked(style, false); assert(rb.fill.path == previous and not sidePreview.enabled)
    combat = false; event('PLAYER_REGEN_ENABLED'); assert(rb.fill.path == 'dbm-gloss' and sidePreview.enabled)
    EUIAddonSkinsDB.dbm.futureOption = 'keep'
    reset.scripts.OnClick()
    assert(EUIAddonSkinsDB.dbm.smallEnabled and EUIAddonSkinsDB.dbm.hugeEnabled and EUIAddonSkinsDB.dbm.hugeGlyphs)
    assert(EUIAddonSkinsDB.dbm.smallOpacity == 0.65 and EUIAddonSkinsDB.dbm.hugeOpacity == 0.65 and EUIAddonSkinsDB.dbm.futureOption == 'keep')
    assert(EUIAddonSkinsDB.dbm.smallLayout == 'strip' and EUIAddonSkinsDB.dbm.hugeLayout == 'fill')
    assert(dropdowns.smallLayout.value == 'strip' and dropdowns.hugeLayout.value == 'fill', 'reset left the native layout page stale')
    assert(rb.fill.path == 'Interface\\Buttons\\WHITE8X8' and b.h == 5)
    local panelObjects, panelHooks, panelWalks = created, hooks, iteratorCalls
    for _ = 1, 20 do sideButton.scripts.OnClick(); sideButton.scripts.OnClick(); smallTab.scripts.OnClick(); hugeTab.scripts.OnClick() end
    assert(created == panelObjects and hooks == panelHooks and iteratorCalls == panelWalks, 'opening/switching the panel rebuilt UI or scanned timers')
    for key,value in pairs(DBT.Options) do assert(dbtOptions[key] == value, 'styling changed DBT profile '..key) end
    print('PASS: DBM side options, independent types, native restore/re-enable, lazy border alpha, glyph restore, coalesced opacity, combat, profile preservation and panel reuse')
end
-- Regression coverage for the three alpha.25 audit findings.
do
    local small, huge = sideControl('Small Bars'), sideControl('Big Bars')
    local style = sideControl('Apply EUI styling')
    local reset = sideControl('Reset EUI styling')
    local function checked(control,value) control:SetChecked(value); control.scripts.OnClick(control) end
    reset.scripts.OnClick(); small.scripts.OnClick()
    first.enlarged = false; first:ApplyStyle()
    local progress = sideControl('Progress: DBM category colours')
    local original = {b.fill:GetVertexColor()}
    progress.scripts.OnClick()
    for _, alpha in ipairs({0, 0.25, 0.5, 1}) do
        b:SetStatusBarColor(0.4,0.5,0.6,alpha)
        assert(tint.alpha == alpha and tint.fillColor[1] == accent and b.fill.color[1] == 0.4, 'accent tint masked DBT flashing or overwrote native colour')
    end
    local alphaWrites = tint.alphaWrites
    local nObjects,nHooks,nFonts,nReads,nWalks = created,hooks,fontWrites,childReads,iteratorCalls
    for _ = 1,1000 do b:SetStatusBarColor(0.5,0.6,0.7,1) end
    assert(tint.alphaWrites == alphaWrites, 'unchanged native alpha rewrote overlay opacity')
    first.auditFlash = true
    for _ = 1,1000 do
        first:Update()
        assert(tint.alpha == b.fill.color[4], 'simulated native Update flashing did not reach accent tint')
    end
    first.auditFlash = nil
    assert(created == nObjects and hooks == nHooks and fontWrites == nFonts and childReads == nReads and iteratorCalls == nWalks, 'flashing added objects/hooks/fonts/scans')
    b.fill:SetVertexColor(0.6,0.5,0.4,0.35); assert(tint.alpha == 0.35, 'direct vertex-alpha changes ignored')
    b:SetStatusBarColor(0.3,0.4,0.5); assert(tint.alpha == 1, 'omitted alpha must retain native default of one')
    local previousSecret = issecretvalue
    local privateAlpha = {}
    issecretvalue = function(v) return v == privateAlpha or previousSecret and previousSecret(v) end
    alphaWrites = tint.alphaWrites
    b:SetStatusBarColor(0.3,0.4,0.5,privateAlpha)
    assert(tint.alphaWrites == alphaWrites, 'secret native alpha was read or applied')
    issecretvalue = previousSecret
    b:SetStatusBarColor(0.3,0.4,0.5,1)
    progress.scripts.OnClick()
    b:SetStatusBarColor(0.4,0.5,0.6,0)
    assert(tint.alpha == 0 and tint.fillColor[4] == 0.2, 'category tint still masks native flashing')
    b.fill:SetVertexColor(table.unpack(original))
    -- Deferred preferences must survive both native style/icon callbacks and
    -- new timer creation in combat, then apply after PLAYER_REGEN_ENABLED.
    combat = true; event('PLAYER_REGEN_DISABLED')
    checked(style,false)
    first:SetIcon(456); first:ApplyStyle(); first:SetText('Deferred |Tknown:40:40|t')
    assert(b.fill.path == 'Interface\\Buttons\\WHITE8X8' and panel:IsShown() and b.h == 5, 'native callback applied pending disable during combat')
    local future = DBT:CreateBar(20,'combat-pending-style')
    assert(_G[future.frame.name .. 'Bar'].fill.path == 'Interface\\Buttons\\WHITE8X8', 'new combat timer consumed uncommitted preferences')
    combat = false; event('PLAYER_REGEN_ENABLED')
    assert(b.fill.path == 'dbm-gloss' and not panel:IsShown() and _G[future.frame.name .. 'Bar'].fill.path == 'dbm-gloss')
    combat = true; event('PLAYER_REGEN_DISABLED'); checked(style,true)
    first:SetIcon(456); first:ApplyStyle(); assert(b.fill.path == 'dbm-gloss', 'pending enable applied during combat')
    combat = false; event('PLAYER_REGEN_ENABLED'); assert(b.fill.path == 'Interface\\Buttons\\WHITE8X8')
    combat = true; event('PLAYER_REGEN_DISABLED')
    progress.scripts.OnClick()
    dropdowns.smallLayout.selectValue('fill')
    local opacity
    for _, control in ipairs(sidePanel.children) do if control.kind == 'Slider' and control.minValue == 0 then opacity = control end end
    opacity:SetValue(25); flush()
    first:SetIcon(456); first:ApplyStyle()
    assert(b.h == 5 and panel.fillColor[4] == 0.65 and tint.fillColor[4] == 0.2, 'pending layout/opacity/colour leaked through callbacks')
    combat = false; event('PLAYER_REGEN_ENABLED')
    assert(b.h == 16 and panel.fillColor[4] == 0.25 and tint.fillColor[4] == 1)
    reset.scripts.OnClick()
    -- Reuse the same timer with different native custom-icon sizes/crops.
    huge.scripts.OnClick()
    local obj = bar('native-icon-reuse'); obj.enlarged = true
    local icon = _G[obj.frame.name .. 'BarIJIcons']
    local tag1 = '|Tcustom-first:40:40:0:0:64:64:0:64:0:64|t'
    local tag2 = '|Tcustom-second:20:24:0:0:64:64:8:56:4:60|t'
    obj:SetIcon(123,nil,tag1)
    DBT:CreateBar(10,'native-icon-reuse')
    local iconObjects,iconHooks = created,hooks
    assert(obj:SetIcon(321,nil,tag2) == 'native-icon')
    checked(style,false)
    local ulx,uly,_,_,urx,_,_,lry = icon:GetTexCoord()
    assert(icon.w == 24 and icon.h == 20 and ulx == 8/64 and uly == 4/64 and urx == 56/64 and lry == 60/64, 'restored stale custom-icon geometry')
    assert(icon.path == 'custom-second', 'restoration replaced the latest native artwork')
    checked(style,true)
    obj:SetIcon(321,nil,tag1); obj:SetIcon(321,nil,tag2); checked(style,false)
    assert(icon.w == 24 and icon.h == 20 and created == iconObjects and hooks == iconHooks, 'repeated pooled icon updates lost native sizes or duplicated objects/hooks')
    -- Known EUI glyph substitutions must also restore the latest native crop.
    checked(style,true)
    DBM_COMMON_L = {TANK_ICON = '|Tnative-known:20:24:0:0:64:64:8:56:4:60|t'}
    obj:SetIcon(321,nil,DBM_COMMON_L.TANK_ICON)
    assert(icon.path ~= 'native-known')
    checked(style,false)
    assert(icon.path == 'native-known' and icon.w == 24 and icon.h == 20)
    reset.scripts.OnClick(); small.scripts.OnClick(); checked(style,false)
    local disabledAlphaWrites = tint.alphaWrites
    b:SetStatusBarColor(0.1,0.2,0.3,0); b.fill:SetVertexColor(0.3,0.2,0.1,0.5)
    assert(tint.alphaWrites == disabledAlphaWrites, 'restored native type still updated hidden tint')
    checked(style,true); b.fill:SetVertexColor(table.unpack(original))
    for key,value in pairs(DBT.Options) do assert(dbtOptions[key] == value, 'audit fixes modified native profile '..key) end
    print('PASS: DBM native flash alpha, unchanged-alpha fast path, combat callback/new-timer deferral, pooled custom sizes/crops and native restoration')
end
-- Full-width tracks keep countdowns on the correct text line in both layouts.
do
    first.enlarged = false; first:ApplyStyle()
    assert(timer.points[1][5] == label.points[1][5] and timer.h == label.h and timer.points[1][5] - timer.h/2 >= b.points[1][5] + 1)
    assert(spellIcon.w == DBT.Options.Height and spellIcon.h == DBT.Options.Height and spellIcon.points[1][4] == 0)
    local rightEdge = b.points[2][4]
    dropdowns.smallLayout.selectValue('fill')
    assert(timer.points[1][5] == 0 and b.points[2][4] == rightEdge and timer.h == b.h, 'filled Small countdown must sit inside full-width fill')
    dropdowns.smallLayout.selectValue('strip')
    first.enlarged = true; first:ApplyStyle()
    dropdowns.hugeLayout.selectValue('strip')
    assert(timer.points[1][5] == label.points[1][5] and timer.h == label.h and b.points[2][4] == rightEdge, 'Huge strip countdown must sit above progress')
    dropdowns.hugeLayout.selectValue('fill')
    assert(timer.points[1][5] == 0 and timer.h == b.h and b.points[2][4] == rightEdge)
    first.enlarged = false; first:ApplyStyle()
end
-- DBM's explicit mechanic tags identify Retail numeric textures without any
-- GetTextureFilePath/GetFileIDFromPath API. The option affects external symbols
-- only, restores the originals immediately, and never changes spell artwork.
do
    local oldFileID, oldAddOns, oldCommon = GetFileIDFromPath, C_AddOns, DBM_COMMON_L
    GetFileIDFromPath = nil
    C_AddOns = {IsAddOnLoaded = function() return false end}
    local fields = {'TANK_ICON','DAMAGE_ICON','HEALER_ICON','INTERRUPT_ICON','IMPORTANT_ICON','MAGIC_ICON','BLEED_ICON','DEADLY_ICON'}
    DBM_COMMON_L = {}
    for i,field in ipairs(fields) do
        DBM_COMMON_L[field] = string.format('|TInterface\\EncounterJournal\\native-sheet.blp:20:20:0:0:256:32:%d:%d:0:32|t',(i-1)*32,i*32)
    end
    local obj = bar('retail-native-tags'); obj.enlarged = true
    local nativeSetIcon = prototype.SetIcon
    obj.SetIcon = function(self,v,eventID,custom)
        local result = nativeSetIcon(self,v,eventID,custom)
        local path = self.frame.name .. 'BarIJIcons'
        local icon = _G[path]
        if icon:GetTexture() ~= nil then icon:SetTexture(60001) end
        return result
    end
    for i = 1,4 do _G[obj.frame.name .. 'BarIJIcons' .. (i == 1 and '' or i)].GetTextureFilePath = nil end
    obj.inlineIcon = DBM_COMMON_L.TANK_ICON
    obj:SetIcon(777,nil,obj.inlineIcon)
    DBT:CreateBar(10,'retail-native-tags')
    local mechanic, spell = _G[obj.frame.name .. 'BarIJIcons'], _G[obj.frame.name .. 'BarIcon1']
    assert(mechanic.path == glyphAtlas and mechanic.crop[1] == 0, 'first bar discovery lost native semantic tag with numeric textures')
    sideControl('Big Bars').scripts.OnClick()
    local artwork = sideControl('EUI mechanic icons (outside Big Bars)')
    local function useEUI(value) artwork:SetChecked(value); artwork.scripts.OnClick(artwork) end
    local baseObjects,baseHooks = created,hooks
    for i,field in ipairs(fields) do
        assert(obj:SetIcon(777,nil,DBM_COMMON_L[field]) == 'native-icon')
        assert(mechanic.path == glyphAtlas and mechanic.crop[1] == (i-1)/8, 'numeric mechanic tag failed for '..field)
        assert(mechanic.points[1][4] < 0, 'semantic icon left its external gutter')
        useEUI(false)
        assert(mechanic.path == 60001, 'native mechanic artwork was not restored for '..field)
        useEUI(true)
        assert(mechanic.path == glyphAtlas and mechanic.crop[1] == (i-1)/8, 're-enabling did not swap external mechanic artwork')
        assert(spell.path == 777 and spell.crop[1] == 0.08 and spell.crop[2] == 0.92, 'mechanic toggle changed spell artwork')
    end
    obj:SetIcon(777,nil,'|Tinvalid-short-tag|t' .. DBM_COMMON_L.TANK_ICON)
    assert(mechanic.path == glyphAtlas and mechanic.crop[1] == 0, 'malformed tags shifted native semantic slots')
    obj:SetIcon(777,nil,'|Tcustom-unrecognized:20:20:0:0:64:64:0:64:0:64|t')
    assert(mechanic.path == 60001, 'stale semantic hint changed unknown custom artwork')
    assert(created == baseObjects and hooks == baseHooks, 'mechanic switches duplicated objects/hooks')
    GetFileIDFromPath, C_AddOns, DBM_COMMON_L = oldFileID, oldAddOns, oldCommon
    sideControl('Small Bars').scripts.OnClick()
    print('PASS: full-width track/countdown geometry, flush Small icons, no end ticks, external mechanic toggles and numeric-only Retail semantic tags')
end
-- Mechanic-size/colour controls, final background opacity, and top-right access.
do
    local smallTab,bigTab = sideControl('Small Bars'),sideControl('Big Bars')
    local scale,opacity
    for _,control in ipairs(sidePanel.children) do
        if control.kind == 'Slider' then if control.minValue == 50 then scale = control else opacity = control end end
    end
    local accentBox = sideControl('Use EUI accent colour')
    local customButton = sideControl('Custom mechanic colour')
    local glyphs = sideControl('EUI mechanic icons (outside Big Bars)')
    local reset = sideControl('Reset EUI styling')
    local function checked(c,v) c:SetChecked(v); c.scripts.OnClick(c) end
    assert(sideButton.points[1][3] == 'TOPRIGHT' and sideButton.points[1][4] == 8 and sideButton.points[1][5] == 0, 'styling button is not at DBM top-right')
    reset.scripts.OnClick(); smallTab.scripts.OnClick()
    local nativeAlpha = f.alpha
    f:SetAlpha(0.3)
    opacity:SetValue(100); flush()
    assert(panel.ignoreParentAlpha and panel.fillColor[4] * panel:GetEffectiveAlpha() == 1, '100% background still inherits DBT row transparency')
    assert(b.fill:GetEffectiveAlpha() == 0.3 and f.alpha == 0.3, 'background fix changed native row/fill opacity')
    opacity:SetValue(0); flush(); assert(panel.fillColor[4] == 0)
    f:SetAlpha(nativeAlpha)
    assert(not scale:IsShown() and not accentBox:IsShown() and sidePanel.h == 438)
    bigTab.scripts.OnClick()
    assert(scale:IsShown() and accentBox:IsShown() and sidePanel.h == 580 and scale.minValue == 50 and scale.maxValue == 250)
    local obj = bar('mechanic-options'); obj.enlarged = true
    local common = DBM_COMMON_L
    DBM_COMMON_L = {TANK_ICON = '|Tmechanic-options-sheet:20:20:0:0:64:64:0:32:0:32|t'}
    obj.inlineIcon = DBM_COMMON_L.TANK_ICON
    obj:SetIcon(777,nil,obj.inlineIcon); DBT:CreateBar(10,'mechanic-options')
    local icon,spell = _G[obj.frame.name .. 'BarIJIcons'],_G[obj.frame.name .. 'BarIcon1']
    local iconSize,spellSize = icon.w,spell.w
    local nativeBar = _G[obj.frame.name .. 'Bar']
    local trackEnd = nativeBar.points[2][4]
    assert(accentBox.checked and icon.color[1] == accent, 'mechanics do not default to EUI accent')
    local previousWalks = iteratorCalls
    for i = 105,200,5 do scale:SetValue(i) end
    assert(iteratorCalls == previousWalks, 'mechanic slider did not coalesce refreshes')
    flush(); assert(iteratorCalls == previousWalks + 1 and icon.w == iconSize * 2 and spell.w == spellSize and nativeBar.points[2][4] == trackEnd)
    local previousPicker = ColorPickerFrame
    local picker = {rgb = {0.2,0.4,0.6}}
    function picker:SetupColorPickerAndShow(info) self.info = info end
    function picker:GetColorRGB() return table.unpack(self.rgb) end
    ColorPickerFrame = picker
    checked(accentBox,false)
    assert(customButton.enabled)
    customButton.scripts.OnClick()
    picker.info.swatchFunc(); flush()
    assert(icon.color[1] == 0.2 and icon.color[2] == 0.4 and icon.color[3] == 0.6 and spell.path == 777)
    picker.info.cancelFunc(); flush(); assert(icon.color[1] == 1 and icon.color[2] == 1, 'colour cancel did not restore previous value')
    customButton.scripts.OnClick(); picker.info.swatchFunc(); flush()
    checked(accentBox,true)
    local previousAccent = accent
    accent = 0.42; for _,fn in ipairs(looks) do fn() end; flush()
    assert(icon.color[1] == 0.42, 'cached glyph ignored theme-accent changes')
    local previousEUI = EllesmereUIDB
    EllesmereUIDB = {blizzWinAccentBar = {useCustom = true, enabled = false, color = {r = 0.14,g = 0.28,b = 0.56}}}
    for _,fn in ipairs(looks) do fn() end; flush()
    assert(icon.color[1] == 0.14 and icon.color[2] == 0.28 and icon.color[3] == 0.56, 'mechanic accent ignored Blizzard Skins+ custom colour')
    assert(not obj.frame.regions[2]:IsShown(), 'mechanic colour bypassed accent border visibility')
    checked(accentBox,false); assert(icon.color[1] == 0.2)
    combat = true; event('PLAYER_REGEN_DISABLED')
    scale:SetValue(150); picker.rgb = {0.7,0.3,0.1}; picker.info.swatchFunc(); flush()
    obj:SetIcon(777,nil,obj.inlineIcon)
    assert(icon.w == iconSize * 2 and icon.color[1] == 0.2, 'combat callbacks leaked pending icon settings')
    combat = false; event('PLAYER_REGEN_ENABLED')
    assert(icon.w == 32, 'post-combat 150% mechanic size not applied at native 28-unit row height')
    assert(icon.color[1] == 0.7 and icon.color[2] == 0.3, 'post-combat custom colour not applied')
    checked(glyphs,false)
    assert(not accentBox.enabled and not customButton.enabled and scale.enabled, 'native artwork control states incorrect')
    assert(icon.path == 'mechanic-options-sheet' and icon.color[1] == 1, 'native mechanic colour was not restored')
    checked(glyphs,true)
    reset.scripts.OnClick()
    local savedR = EUIAddonSkinsDB.dbm.hugeIconR
    picker.info.swatchFunc(); flush()
    assert(EUIAddonSkinsDB.dbm.hugeIconR == savedR and EUIAddonSkinsDB.dbm.hugeIconScale == 1 and EUIAddonSkinsDB.dbm.hugeIconAccent, 'reset allowed stale colour callback or lost defaults')
    ColorPickerFrame = nil; checked(accentBox,false); assert(not customButton.enabled, 'missing picker API was not handled')
    ColorPickerFrame = previousPicker
    EllesmereUIDB,accent,DBM_COMMON_L = previousEUI,previousAccent,common
    reset.scripts.OnClick(); smallTab.scripts.OnClick()
    for key,value in pairs(DBT.Options) do assert(dbtOptions[key] == value, 'new controls changed DBM profile '..key) end
    print('PASS: mechanic scale, accent/custom/cancel colours, theme/combat/reset/missing-picker guards, independent opaque background and top-right Big Bars UI')
end
-- Rebased icon percentages, detachable position/reset, accent titles and footer.
do
    local small,big = sideControl('Small Bars'),sideControl('Big Bars')
    local title,notice,drag
    for _,text in ipairs(sidePanel.regions) do
        if text.text == 'Options' then title = text end
        if text.text and text.text:find('Changes apply immediately',1,true) then notice = text end
    end
    for _,child in ipairs(sidePanel.children) do if child.scripts.OnDragStart then drag = child end end
    local resetPosition
    for _,child in ipairs(DBM_GUI_OptionsFrame.children) do if child.text == 'Reset position' then resetPosition = child end end
    assert(title and notice and drag and resetPosition, 'detachable Options UI controls missing')
    assert(sidePanel:GetParent() == UIParent and sidePanel.movable and drag.dragButtons[1] == 'LeftButton')
    assert(notice.size == 14 and notice.spacing == 2 and notice.justifyV == 'TOP' and notice.points[2][1] == 'BOTTOMRIGHT', 'footer is not readable or does not fill its space')
    assert(title.color[1] == accent and sideButton:GetFontString().color[1] == accent)
    local originalEUI = EllesmereUIDB
    EllesmereUIDB = {blizzWinAccentBar = {useCustom = true, color = {r = 0.3,g = 0.5,b = 0.7}}}
    for _,fn in ipairs(looks) do fn() end; flush()
    assert(title.color[1] == 0.3 and sideButton:GetFontString().color[1] == 0.3, 'panel/opener titles did not follow accent changes')
    sideButton:GetFontString():SetTextColor(1,1,1,1); sideButton.scripts.OnEnter(sideButton)
    assert(sideButton:GetFontString().color[1] == 0.3, 'hover reset opener accent colour')
    local baseObjects,baseHooks,baseWalks = created,hooks,iteratorCalls
    sidePanel.left,sidePanel.top = 350,600
    drag.scripts.OnDragStart(); assert(sidePanel.moving)
    drag.scripts.OnDragStop()
    assert(not sidePanel.moving and EUIAddonSkinsDB.dbm.optionsPosition.x == 350 and EUIAddonSkinsDB.dbm.optionsPosition.y == -168)
    assert(sidePanel.points[1][1] == 'TOPLEFT' and sidePanel.points[1][2] == UIParent)
    local pointX,pointY = sidePanel.points[1][4],sidePanel.points[1][5]
    big.scripts.OnClick(); small.scripts.OnClick(); sideButton.scripts.OnClick(); sideButton.scripts.OnClick()
    assert(sidePanel.points[1][4] == pointX and sidePanel.points[1][5] == pointY, 'resize/reopen lost detached top-left position')
    assert(created == baseObjects and hooks == baseHooks and iteratorCalls == baseWalks, 'drag/reopen rebuilt controls or scanned HUD')
    resetPosition.scripts.OnClick()
    assert(not EUIAddonSkinsDB.dbm.optionsPosition and sidePanel.points[1][2] == sideButton and sidePanel:IsShown(), 'position reset did not recover the Options panel')
    -- Scaling conversion uses a versioned saved setting; old 125% becomes 100%
    -- once, while an explicit old 100% retains its previous rendered size at 80%.
    local originalDB = EUIAddonSkinsDB.dbm
    local function legacy(scale)
        local db = {}; for key,value in pairs(originalDB) do db[key] = value end
        db.hugeIconScale,db.iconScaleVersion = scale,nil
        EUIAddonSkinsDB.dbm = db; modules.DBM.refresh(); flush()
        return db
    end
    local converted = legacy(1.25)
    assert(converted.hugeIconScale == 1 and converted.iconScaleVersion == 2)
    modules.DBM.refresh(); flush(); assert(converted.hugeIconScale == 1, 'icon scaling migrated twice')
    converted = legacy(1); assert(converted.hugeIconScale == 0.8)
    EUIAddonSkinsDB.dbm = originalDB; EllesmereUIDB = originalEUI
    modules.DBM.refresh(); flush()
    assert(title.color[1] == accent and sideButton:GetFontString().color[1] == accent)
    print('PASS: former 125% rebased to 100%, one-time migration, draggable detached Options panel, saved position/reset, accent labels and larger anchored footer')
end
-- Disabled skins can save preferences without repainting anything.
enabled = false
sidePreview.scripts.OnShow(); assert(not sidePreview.enabled)
sidePreview.scripts.OnClick(); assert(nativeDemoCalls == 2, 'disabled skin must not start its preview')
local disabledIterations, disabledHeight = iteratorCalls, b.h
dropdowns.smallLayout.selectValue('fill')
assert(iteratorCalls == disabledIterations and b.h == disabledHeight and EUIAddonSkinsDB.dbm.smallLayout == 'fill')
enabled = true; modules.DBM.refresh(); flush(); assert(b.h == 16)
dropdowns.smallLayout.selectValue('strip'); assert(b.h == 5)
enabled = false
warning:SetFont('native', 30); warning:SetText('Disabled |T789:12:12|t')
assert(warning.font == 'native' and warning.text == 'Disabled |T789:12:12|t')
local disabledTintWrites = tint.alphaWrites
b:SetStatusBarColor(0.3,0.4,0.5,0)
assert(tint.alphaWrites == disabledTintWrites, 'disabled integration still handled native fill colour')
first:SetVariance(); assert(variance.path == 'native-gradient')
first:ApplyStyle(); assert(b.fill.path == 'dbm-gloss')
local skipped = DBT:CreateBar(20, 'disabled'); assert(_G[skipped.frame.name .. 'Bar'].fill.path == 'dbm-gloss')
assert(#errors == 0, table.concat(errors, '\n'))
DBM, DBT, C_Secrets, DebuffTypeColor, AuraUtil = nil, nil, nil, nil, nil
DBMWarning1, DBMSpecialWarning1, issecretvalue = nil, nil, nil
UIParent = previousUIParent
CreateColor, DBM_COMMON_L, DBM_GUI, DBM_GUI_OptionsFrame = nil, nil, nil, nil
print('PASS: DBM HUD late/core-only load, timer lifecycle/native colors/actions, reuse, no countdown work, aura previews, restricted guards, theme/combat/toggles')
