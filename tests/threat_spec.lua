-- ThreatClassic2 source-shaped frames, native redraws and owned Ace options.
local enabled, combat, accent, timers, events = true, false, 0.4, {}, {}
local ns = {IsEnabled = function() return enabled end, AttachAccent = function(_, f) f.accent = true end}
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) error(debug.traceback(e, 2)) end end
hooksecurefunc = function(object, name, callback)
    local original = object[name]
    object[name] = function(...)
        local values = table.pack(original(...)); callback(...); return table.unpack(values, 1, values.n)
    end
end
local function texture(kind, parent)
    local t = {kind = kind or 'Texture', alpha = 1, path = 'native', parent = parent, points = {}}
    function t:GetObjectType() return self.kind end
    function t:GetTexture() return self.path end
    function t:SetTexture(v) self.path = v end
    function t:GetAlpha() return self.alpha end
    function t:SetAlpha(v) self.alpha = v end
    function t:GetDrawLayer() return self.layer or 'ARTWORK' end
    function t:SetColorTexture(...) self.color = {...}; self.path = 'solid' end
    function t:SetVertexColor(...) self.color = {...} end
    function t:SetPoint(...) self.points[#self.points + 1] = {...} end
    function t:SetAllPoints(anchor) self.anchor = anchor end
    function t:ClearAllPoints() self.points = {} end
    function t:SetShown(v) self.shown = v end
    function t:GetVertexColor() return table.unpack(self.color or {1, 1, 1, 1}) end
    function t:SetSize(w, h) self.width, self.height = w, h end
    function t:SetHeight(h) self.height = h end
    function t:SetWidth(w) self.width = w end
    function t:GetStringWidth() return #(self.text or "") * 5 end
    function t:SetTexCoord(...) self.crop = {...} end
    function t:GetTexCoord() return table.unpack(self.crop or {0, 1, 0, 1}) end
    function t:GetNumMaskTextures() return self.masked and 1 or 0 end
    function t:SetText(s) assert(self.font, "FontString:SetText(): Font not set"); self.text = s end
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
    function f:SetSize(w, h)
        local changed = self.width ~= w or self.height ~= h; self.width, self.height = w, h
        if changed and self.hooks.OnSizeChanged then self.hooks.OnSizeChanged(self, w, h) end
    end
    function f:SetWidth(w)
        local changed = self.width ~= w; self.width = w
        if changed and self.hooks.OnSizeChanged then self.hooks.OnSizeChanged(self, w, self.height or 24) end
    end
    function f:GetID() return self.id end
    function f:IsShown() return not self.hidden end
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
    function f:GetBackdropColor() return table.unpack(self.color or {1, 1, 1, 1}) end
    function f:GetBackdropBorderColor() return table.unpack(self.border or {1, 1, 1, 1}) end
    function f:SetBackdropColor(...) self.color = {...} end
    function f:SetBackdropBorderColor(...) self.border = {...} end
    function f:CreateTexture() local t = texture(nil, self); self.regions[#self.regions + 1] = t; return t end
    function f:CreateFontString(_, _, template) local t = texture('FontString', self); t.font = template; self.regions[#self.regions + 1] = t; return t end
    function f:GetNormalTexture() return self.normal end
    function f:GetWidth() return self.width or 24 end
    function f:GetHeight() return self.height or 24 end
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
function S.EditBox(f, options)
    f.input = true; f.inputOptions = options
    if options.padInput and not f.padded then
        f.padded = true
        if f.points and f.points[1] then f.points[1][4] = (f.points[1][4] or 0) - 6 end
    end
end
function S.Dropdown(f) f.dropdown = true end
function S.FadeNineSlice() end
SetPortraitTexture = function(t) t:SetTexture('player-face') end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
local originalFrame = frame
frame = function(...)
    local f = originalFrame(...)
    function f:Show() self.hidden = false end
    function f:Hide() self.hidden = true end
    function f:GetNumPoints() return #(self.points or {}) end
    function f:GetPoint(i) return table.unpack(self.points[i]) end
    function f:GetFrameLevel() return self.level or 5 end
    function f:SetFrameLevel(level) self.level = level end
    function f:SetAllPoints() end
    function f:EnableMouse(value) self.mouse = value end
    function f:SetHeight(h)
        local changed = self.height ~= h; self.height = h
        if changed and self.hooks.OnSizeChanged then self.hooks.OnSizeChanged(self, self.width or 24, h) end
    end
    return f
end
local function font(parent)
    local t = parent:CreateFontString(nil, 'OVERLAY', 'native')
    t.font, t.size, t.flags = 'native', 12, ''
    function t:GetFont() return self.font, self.size, self.flags end
    function t:SetFont(path, size, flags) self.font, self.size, self.flags = path, size or self.size, flags or ''; self.writes = (self.writes or 0) + 1 end
    return t
end
UIParent = frame()
S.GetFont = function() return 'eui', '' end
S.GetPanelColor = function() return 0.03, 0.03, 0.03, 0.95 end
S.OnLooksChanged = function(fn) S.looks = fn end
local modules = {}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/MeterStyle.lua'))('EUIAddonSkins', ns)
local popupOwner, popupList
ns.BindPopupOwner = function(_, _, owner) popupOwner = owner end
ns.BindPopupList = function(_, _, owner, list) popupOwner, popupList = owner, list end
local function flush()
    local rounds = 0
    while #timers > 0 do local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end; rounds = rounds + 1; assert(rounds < 12, 'refresh loop') end
end
local oldFrame = frame
frame = function(...)
    local f = oldFrame(...)
    function f:GetScript(event) return self.hooks[event] end
    function f:SetStatusBarTexture(path)
        self.fill = path
        if not self.fillTexture then self.fillTexture = self:CreateTexture() end
        self.fillTexture:SetTexture(path)
    end
    function f:GetStatusBarTexture() return self.fillTexture end
    function f:SetStatusBarColor(...) self.statusColor = {...} end
    return f
end
CreateFrame = function(...) local f = frame(...); events[#events + 1] = f; return f end
ThreatClassic2BarFrame = nil
LibStub = function() end
assert(loadfile('EUIAddonSkins/Skins/ThreatClassic2.lua'))('EUIAddonSkins', ns)
assert(not modules.ThreatClassic2.available(), 'missing TC2 must remain optional')
local f = frame('Frame', 'ThreatClassic2BarFrame', UIParent)
f:SetSize(217, 161); f:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 50, -200)
f.bg = f:CreateTexture(); f.resize = frame('Frame', nil, f); f.resizeTexture = f.resize:CreateTexture()
f.header = frame('StatusBar', nil, f); f.header:SetSize(217, 18); f.header:SetPoint('BOTTOMLEFT', f, 'TOPLEFT', 0, 0)
f.header.text = font(f.header); f.header.text:SetText('Threat: target')
f.header.edgeBackdrop = frame('Frame', nil, f.header)
local nativeMenu = 0
f.header:SetScript('OnMouseUp', function(_, button) if button == 'RightButton' then nativeMenu = nativeMenu + 1 end end)
local list = frame(); list.GetOwnerRegion = function() return f.header end
Menu = {GetManager = function() return {GetOpenMenu = function() return list end} end}
local function bar()
    local b = frame('StatusBar', nil, f); b:SetSize(217, 18); b:SetPoint('TOP', f, 'TOP', 0, 0)
    b.edgeBackdrop = frame('Frame', nil, b); b:SetStatusBarTexture('native')
    b.name, b.val, b.perc, b.tps = font(b), font(b), font(b), font(b)
    b.name:SetText('native-name'); b.val:SetText('420'); b.perc:SetText('83%'); b.tps:SetText('12')
    b.value, b.threat, b.ignite = 83, {unit = 'secret-compatible', total = 420}, b:CreateTexture()
    b:SetStatusBarColor(1, 0.15, 0.1, 1)
    b.action = function() return 'row-native' end
    return b
end
local b = bar()
local open, embedded = frame(), frame()
local dialog = {OpenFrames = {ThreatClassic2 = {frame = open}}, BlizOptions = {ThreatClassic2 = {general = {frame = embedded}}},
    Open = function() return 'open-native' end, FeedGroup = function() return 'feed-native' end}
LibStub = function(name) if name == 'AceConfigDialog-3.0' then return dialog end end
_EDM_DB = {profile = {dm = {barTexture = 'test', hdrHeight = 22, hdrIconSize = 22}}}
_EDM_BarTextures = {test = 'eui-bar'}
EllesmereUI = {GetFontPath = function() return 'eui-meter-font' end}
C_AddOns = {IsAddOnLoaded = function(name) return name == 'EllesmereUIDamageMeters' end}
assert(modules.ThreatClassic2.available())
modules.ThreatClassic2.install(S, modules.ThreatClassic2); flush()
assert(f.bg.color[4] == 0.75 and f.header:GetHeight() == 22 and f.resizeTexture.alpha == 0)
assert(f.header.text.font == 'eui-meter-font' and f.header.text.text == 'Threat: target' and f.header.text.textColor[1] == accent)
assert(b.fill == 'eui-bar' and b.name.font == 'eui-meter-font' and b.name.size == 11)
assert(b.value == 83 and b.threat.total == 420 and b.val.text == '420' and b.perc.text == '83%' and b.tps.text == '12')
assert(b.statusColor[1] == 1 and b.statusColor[2] == 0.15 and b.action() == 'row-native')
assert(f.points[1][4] == 50 and f:GetWidth() == 217 and b:GetHeight() == 18 and b.points[1][1] == 'TOP', 'native meter geometry changed')
assert(open.shellOptions.noBorder and not embedded.shell, 'Ace embedded panel was given an extra shell')
local gear
for _, child in ipairs(f.header.children) do if child.kind == 'Button' then gear = child end end
assert(gear and gear:GetWidth() == 22 and gear.icon.path:find('dm_settings.png', 1, true))
gear.hooks.OnClick(); assert(nativeMenu == 1 and popupOwner == f.header and popupList == list, 'native context menu action lost')
assert(dialog:Open('ThreatClassic2') == 'open-native')
assert(dialog:FeedGroup('ThreatClassic2') == 'feed-native'); flush()
local children = #f.header.children
for _ = 1, 10 do modules.ThreatClassic2.refresh(); flush() end
assert(#f.header.children == children, 'warm refresh created duplicate controls')
local scans, getChildren = 0, f.GetChildren
f.GetChildren = function(self) scans = scans + 1; return getChildren(self) end
for _ = 1, 100 do b:SetStatusBarColor(1, 0.15, 0.1, 1); b.val:SetText('420') end
assert(scans == 0 and #timers == 0, 'ordinary threat redraws triggered skin scans')
b:SetStatusBarTexture('profile-native'); b:SetBackdrop({bgFile = 'native'}); b.edgeBackdrop:SetBackdrop({edgeFile = 'native'})
b.name:SetFont('profile-font', 16)
f.header:SetSize(240, 18); f.header.text:SetTextColor(1, 1, 0, 1)
assert(b.fill == 'eui-bar' and b.backdrop == nil and b.edgeBackdrop.backdrop == nil and b.name.font == 'eui-meter-font')
assert(f.header:GetHeight() == 22 and f.header.text.textColor[1] == accent, 'native header redraw overwrote the skin')
accent = 0.7; S.looks(); flush(); assert(f.header.text.textColor[1] == 0.7)
local late = bar(); modules.ThreatClassic2.refresh(); flush(); assert(late.fill == 'eui-bar')
combat = true; b:SetStatusBarTexture('combat-native'); flush(); assert(b.fill == 'combat-native', 'combat mutation was not deferred')
combat = false
for _, event in ipairs(events) do if event.events and event.events.PLAYER_REGEN_ENABLED then event.hooks.OnEvent(event, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(b.fill == 'eui-bar', 'deferred meter update was lost')
enabled = false; b:SetStatusBarTexture('disabled-native'); b.name:SetFont('disabled-font', 16)
modules.ThreatClassic2.refresh(); flush(); assert(b.fill == 'disabled-native' and b.name.font == 'disabled-font')
assert(not f.hooks.OnUpdate and not b.hooks.OnUpdate, 'skin added threat polling')
print('PASS: ThreatClassic2 optional loading, shared EUI meter look, native threat/colours/columns/geometry/menu actions, lazy Ace options, redraws, combat/toggle guards and warm reuse')
