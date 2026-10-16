-- HUD lifecycle regression: actual shared helper/scoped adapter, no GUI loaded.
local timers, modules, frames, looks, errors = {}, {}, {}, {}, {}
local enabled, combat, accent, secret = true, false, 0.2, false
local created, hooks, fontWrites, childReads = 0, 0, 0, 0
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
    function o:IsForbidden() return self.forbidden end
    function o:IsProtected() return self.protected end
    function o:SetPoint(...) self.points[#self.points + 1] = {...} end
    function o:SetAllPoints(v) self.all = v end
    function o:SetHeight(v) self.h = v end
    function o:SetSize(w, h) self.w, self.h = w, h end
    function o:ClearAllPoints() self.points = {} end
    function o:Hide() self.shown = false end
    function o:SetBackdrop(v) self.backdrop = v end
    function o:SetShadowColor(...) self.shadow = {...} end
    function o:SetShadowOffset(...) self.shadowOffset = {...} end
    function o:SetWidth(v) self.w = v end
    function o:GetWidth()
        local a, b = self.points[1], self.points[2]
        if self.kind == 'StatusBar' and a and b and a[1] == 'BOTTOMLEFT' and b[1] == 'BOTTOMRIGHT' and a[2] == b[2] then
            return a[2]:GetWidth() + b[4] - a[4]
        end
        return self.w
    end
    function o:GetHeight() return self.h end
    function o:GetTexture() return self.path end
    function o:SetTexture(v) self.path = v end
    function o:SetBlendMode(v) self.blend = v end
    function o:SetColorTexture(...) self.fillColor = {...} end
    function o:GetVertexColor() return table.unpack(self.color) end
    function o:SetVertexColor(...) self.color = {...} end
    function o:SetAlpha(v) self.alpha = v end
    function o:GetAlpha() return self.alpha end
    function o:GetNumMaskTextures() return self.masked and 1 or 0 end
    function o:SetTexCoord(...) self.crop = {...} end
    function o:SetShown(v) self.shown = v end
    function o:IsShown() return self.shown end
    function o:IsVisible() return self.shown end
    function o:GetFont() return self.font, self.size, '' end
    function o:GetText() return self.text end
    function o:SetText(v) self.text = v end
    function o:SetFontObject(v) self.font = v end
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
    function o:CreateTexture(name, layer, _, sublevel)
        local t = object('Texture', name, self); t.layer, t.sublevel = layer, sublevel; self.regions[#self.regions + 1] = t; return t
    end
    function o:GetStatusBarTexture() return self.fill end
    function o:SetStatusBarTexture(v) self.fill.path = v end
    if name then _G[name] = o end
    if parent and kind ~= 'Texture' and kind ~= 'FontString' then parent.children[#parent.children + 1] = o end
    return o
end
CreateFrame = function(kind, name, parent)
    local f = object(kind, name, parent); frames[#frames + 1] = f; return f
end
local ns = {IsEnabled = function() return enabled end}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
local S = {GetAccentColor = function() return accent, 0.6, 0.7 end,
    GetFont = function() return 'eui', '' end, OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
function S.Font(f) local _, size = f:GetFont(); f:SetFont('eui', size) end
function S.SquareIcon(t) t:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
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
local pool, nextID = {}, 0
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
function prototype:SetIcon(v) _G[self.frame.name .. 'BarIcon1']:SetTexture(v); return 'native-icon' end
function prototype:Update() self.duration = self.duration - 0.01 end
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
    GetBarIterator = function() local key; return function() key = next(pool, key); return key and pool[key] end end,
    CreateBar = function(_, _, id) return pool[id] or bar(id), 'native-create' end}
event('ADDON_LOADED')
local f, b = first.frame, _G[first.frame.name .. 'Bar']
local nativeAnchor = {}
f:SetPoint('TOP', nativeAnchor, 'TOP', 27, -60)
assert(b.fill.path == 'Interface\\Buttons\\WHITE8X8' and b.fill.color[1] == 0.9 and b.fill.color[4] == 0.75)
assert(_G[f.name .. 'BarName'].font == 'eui' and math.abs(_G[f.name .. 'BarName'].size - 10.08) < 0.001)
assert(_G[f.name .. 'BarSpark'].alpha == 0 and _G[f.name .. 'BarBorderTop'].alpha == 0)
assert(_G[f.name .. 'BarIcon1'].crop and _G[f.name .. 'BarIcon1'].path == 136116)
assert(f.children[#f.children - 1].regions[1].fillColor[1] == 0.16, 'timer icon edge should be neutral')
assert(_G[f.name .. 'BarBackground'].fillColor[4] == 0.95)
assert(math.abs(b.h - 3.96) < 0.001 and f.h == 20 and DBT.Options.Height == 20, 'thin strip changed native frame/settings')
assert(_G[f.name .. 'BarIcon1'].w == 16 and _G[f.name .. 'BarIcon1'].h == 16)
assert(math.abs(_G[f.name .. 'BarIJIcons'].w - 11.16) < 0.001 and _G[f.name .. 'BarIJIcons'].path == 'role-1')
assert(_G[f.name .. 'BarIJIcons2'].points[1][1] == 'RIGHT' and _G[f.name .. 'BarIJIcons2'].points[1][2] == f)
assert(_G[f.name .. 'BarName'].points[1][1] == 'TOPLEFT' and _G[f.name .. 'BarName'].points[1][4] == 6)
assert(_G[f.name .. 'BarTimer'].points[1][2] == f and _G[f.name .. 'BarTimer'].size > _G[f.name .. 'BarName'].size)
assert(b:GetWidth() < f:GetWidth() and b:GetWidth() > 30, 'strip did not reserve space for timer/mechanics')
local panel = f.regions[1]
assert(panel.layer == 'BACKGROUND' and panel.fillColor[4] == 0.94 and panel.points[1][4] == -24, 'panel does not contain spell icon')
assert(#f.regions == 5, 'panel background and four accent edges missing')
assert(f.regions[2].fillColor[1] == accent and f.regions[2].fillColor[4] == 0.2, 'top accent should be restrained')
for i = 3, 5 do assert(f.regions[i].fillColor[1] == 0.07, 'side/bottom edge should be neutral') end
local stripWidth, labelRight, timerRight = b:GetWidth(), _G[f.name .. 'BarName'].points[2][4], _G[f.name .. 'BarTimer'].points[1][4]
_G[f.name .. 'BarIJIcons2']:Hide(); first:SetIcon(136116)
assert(b:GetWidth() == stripWidth and _G[f.name .. 'BarName'].points[2][4] == labelRight and _G[f.name .. 'BarTimer'].points[1][4] == timerRight, 'missing mechanic icon shifted the strip/text')
_G[f.name .. 'BarIJIcons']:Hide(); first:SetIcon(136116)
assert(b:GetWidth() == stripWidth, 'empty mechanic group changed reserved width')
assert(f.points[1][2] == nativeAnchor and f.points[1][4] == 27 and f.points[1][5] == -60, 'skin moved native stack row')
_G[f.name .. 'BarIJIcons']:SetShown(true); _G[f.name .. 'BarIJIcons2']:SetShown(true)
local tint
for _, t in ipairs(b.regions) do if t.sublevel == 2 then tint = t end end
assert(tint and tint.layer == 'ARTWORK' and tint.all == b.fill and tint.fillColor[4] == 0.28, 'fill tint missing or above text')
assert(not _G[f.name .. 'BarVariance'].shown, 'disabled variance indicator became visible')
first.hasVariance, first.varianceWidth, first.varianceDuration, first.totalTime = true, 73, 5, 20
assert(first:SetVariance() == 'native-variance')
local variance = _G[f.name .. 'BarVariance']
assert(variance.path == 'Interface\\Buttons\\WHITE8X8' and variance.blend == 'BLEND')
assert(variance.shown and variance.w == b:GetWidth() * 0.25 and variance.points[1][1] == 'RIGHT', 'variance time proportion/direction changed')
assert(variance.color[1] == 0.14 and variance.color[4] == 0.65)
assert(f.children[#f.children].shown == false, 'hidden right icon acquired a visible border')
local nativeUpdate = f.scripts.OnUpdate
local oldCreated, oldHooks, oldFonts, oldReads = created, hooks, fontWrites, childReads
for _ = 1, 1000 do f.scripts.OnUpdate() end
assert(nativeUpdate == f.scripts.OnUpdate and created == oldCreated and hooks == oldHooks and fontWrites == oldFonts and childReads == oldReads)
assert(first.duration < 20, 'native timer stopped')
assert(first:ApplyStyle() == 'native-style' and b.fill.path == 'Interface\\Buttons\\WHITE8X8')
assert(_G[f.name .. 'BarName'].font == 'eui' and math.abs(_G[f.name .. 'BarName'].size - 10.08) < 0.001)
assert(first:SetIcon(999) == 'native-icon' and _G[f.name .. 'BarIcon1'].path == 999)
assert(math.abs(b.h - 3.96) < 0.001, 'repeated paint cumulatively shrank strip')
first.enlarged = true; first:ApplyStyle()
assert(math.abs(b.h - 5.72) < 0.001 and _G[f.name .. 'BarIcon1'].h == 24, 'large panel did not follow native size')
DBT.Options.HugeTextXOffset, DBT.Options.HugeTextYOffset = 2, 3
first:ApplyStyle()
assert(_G[f.name .. 'BarName'].points[1][4] == 8 and _G[f.name .. 'BarTimer'].points[1][5] == 3)
DBT.Options.JournalIcons = 4
local stacked = _G[f.name .. 'BarIJIcons']; stacked:ClearAllPoints(); stacked:SetPoint('BOTTOMRIGHT', _G[f.name .. 'BarIcon1'], 'BOTTOMLEFT', 0, 0)
first:ApplyStyle(); assert(stacked.points[1][1] == 'TOPRIGHT' and stacked.w == 9.36, 'four-symbol group not compact')
assert(_G[f.name .. 'BarIJIcons3'].points[1][5] < stacked.points[1][5], 'four symbols should use two rows')
-- AnimateEnlarge updates the native frame and calls SetWidth on the strip.
-- Opposing anchors keep the strip inside its allocated body region.
local beforeWidth = b:GetWidth()
f:SetSize(230, 28); b:SetWidth(230)
assert(b:GetWidth() == beforeWidth + 35 and b:GetWidth() < f:GetWidth())
f:SetSize(195, 20)
DBT.Options.JournalIcons = 2; first.enlarged = false; first:ApplyStyle()
DBT.Options.IconLeft, DBT.Options.IconRight = false, true
first:ApplyStyle()
assert(not _G[f.name .. 'BarIcon1'].shown and _G[f.name .. 'BarIcon2'].shown)
assert(panel.points[1][4] == 0 and panel.points[2][4] == 24, 'panel did not follow native icon visibility')
DBT.Options.IconLeft, DBT.Options.IconRight = true, false
DBT.Options.Height = 10; f:SetSize(100, 10); first:ApplyStyle()
assert(b:GetWidth() > 20 and _G[f.name .. 'BarName'].points[1][1] == 'LEFT', 'smallest native row needs compact fallback')
DBT.Options.Height = 20; f:SetSize(195, 20); first:ApplyStyle()
assert(_G[f.name .. 'BarName'].points[1][1] == 'TOPLEFT' and panel.points[1][4] == -24)
DBT.Options.IconLocked, DBT.Options.Height = false, 30
first:ApplyStyle()
assert(f.h == 20 and panel.points[1][5] == 14 and panel.points[2][5] == -14, 'unlocked native hit frame changed or panel height lost')
DBT.Options.IconLocked, DBT.Options.Height = true, 20; first:ApplyStyle()
-- Native color updates remain authoritative; the same tint tracks the fill.
b.fill:SetVertexColor(0.1, 0.3, 0.9, 0.75)
assert(b.fill.color[3] == 0.9 and tint.all == b.fill)
local new, result = DBT:CreateBar(20, 'new')
assert(result == 'native-create' and _G[new.frame.name .. 'Bar'].fill.path == 'Interface\\Buttons\\WHITE8X8')
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
accent = 0.8; for _, fn in ipairs(looks) do fn() end; flush()
assert(f.regions[2].fillColor[1] == accent and preview.Border.borderColor[1] == accent)
assert(f.regions[3].fillColor[1] == 0.07, 'theme refresh recolored neutral panel edges')
combat = true
warning:SetText('Combat |T789:12:12|t'); assert(warning.text == 'Combat |T789:12:12:0:0:64:64:5:59:5:59|t')
local duringCombat = DBT:CreateBar(20, 'combat')
assert(_G[duringCombat.frame.name .. 'Bar'].fill.path == 'Interface\\Buttons\\WHITE8X8', 'ordinary combat timer not styled')
accent = 0.9; for _, fn in ipairs(looks) do fn() end; flush()
assert(preview.Border.borderColor[1] ~= accent, 'aura refresh should defer during combat')
combat = false; event('PLAYER_REGEN_ENABLED')
assert(preview.Border.borderColor[1] == accent, 'deferred theme refresh lost')
enabled = false
warning:SetFont('native', 30); warning:SetText('Disabled |T789:12:12|t')
assert(warning.font == 'native' and warning.text == 'Disabled |T789:12:12|t')
first:SetVariance(); assert(variance.path == 'native-gradient')
first:ApplyStyle(); assert(b.fill.path == 'dbm-gloss')
local skipped = DBT:CreateBar(20, 'disabled'); assert(_G[skipped.frame.name .. 'Bar'].fill.path == 'dbm-gloss')
assert(#errors == 0, table.concat(errors, '\n'))
DBM, DBT, C_Secrets, DebuffTypeColor, AuraUtil = nil, nil, nil, nil, nil
DBMWarning1, DBMSpecialWarning1, issecretvalue = nil, nil, nil
print('PASS: DBM HUD late/core-only load, timer lifecycle/native colors/actions, reuse, no countdown work, aura previews, restricted guards, theme/combat/toggles')
