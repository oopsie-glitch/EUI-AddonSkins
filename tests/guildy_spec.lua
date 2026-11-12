-- Guildy fixtures: lazy window inside Blizzard's guild window, borrowed Blizzard
-- editor, selection borders, data buttons, segmented options, tabs and combat.
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
    function t:SetSize(w, h) self.width, self.height = w, h end
    function t:SetHeight(h) self.height = h end
    function t:SetWidth(w) self.width = w end
    function t:SetTexCoord(...) self.crop = {...} end
    function t:GetNumMaskTextures() return 0 end
    function t:SetText(s) self.text = s end
    function t:GetText() return self.text end
    function t:GetFont() return self.font, 12, '' end
    function t:SetFont(v) self.font = v; self.fontWrites = (self.fontWrites or 0) + 1 end
    function t:SetTextColor(...) self.textColor = {...} end
    function t:GetTextColor() return table.unpack(self.textColor or {1, 1, 1, 1}) end
    function t:GetParent() return self.parent end
    return t
end
local function frame(kind, name, parent)
    local f = {kind = kind or 'Frame', name = name, parent = parent, regions = {}, children = {}, hooks = {}}
    function f:GetObjectType() return self.kind end
    function f:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function f:GetPoint() return 'CENTER', nil, 'CENTER', 0, 0 end
    function f:ClearAllPoints() self.points = {} end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:GetWidth() return self.width or 24 end
    function f:GetHeight() return self.height or 24 end
    function f:SetID(v) self.id = v end
    function f:GetID() return self.id end
    function f:IsShown() return not self.hidden end
    function f:Show() self.hidden = false; if self.hooks.OnShow then self.hooks.OnShow(self) end end
    function f:Hide() self.hidden = true end
    function f:IsEnabled() return not self.disabled end
    function f:SetEnabled(v) self.disabled = not v; local h = self.hooks[v and 'OnEnable' or 'OnDisable']; if h then h(self) end end
    function f:GetName() return self.name end
    function f:GetParent() return self.parent end
    function f:IsForbidden() return false end
    function f:IsProtected() return self.protected end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:HasScript() return true end
    function f:HookScript(event, fn) local old = self.hooks[event]; self.hooks[event] = function(...) if old then old(...) end; fn(...) end end
    function f:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
    function f:SetScript(e, fn) self.hooks[e] = fn end
    function f:GetBackdrop() return self.backdrop end
    -- BackdropTemplateMixin:SetBackdrop reapplies a white border through SetBackdropBorderColor.
    function f:SetBackdrop(b) assert(not combat, 'styled during combat'); self.backdrop = b; if b then self:SetBackdropBorderColor(1, 1, 1, 1) end end
    function f:GetBackdropColor() return table.unpack(self.color or {0, 0, 0, 1}) end
    function f:GetBackdropBorderColor() return table.unpack(self.border or {0, 0, 0, 1}) end
    function f:SetBackdropColor(...) self.color = {...} end
    function f:SetBackdropBorderColor(...) self.border = {...} end
    function f:CreateTexture() local t = texture(nil, self); self.regions[#self.regions + 1] = t; return t end
    function f:CreateFontString() local t = texture('FontString', self); t.font = 'native'; self.regions[#self.regions + 1] = t; return t end
    function f:GetFontString() return self.label end
    function f:GetNormalTexture() return self.normal end
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
function S.SquareIcon(t) t:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
function S.PageButton(f, label) f.glyph = label end
function S.ScrollBar(f) f.scroll = true end
function S.Panel(f) f.panel = true end
function S.Shell(f, options) f.shell = true; f.shellOptions = options end
function S.Tab(f) f.tab = true end
function S.SetTabSelection(f, selected) f.selected = selected end
function S.CloseButton(f) f.close = true end
function S.Checkbox(f) f.checkbox = true end
function S.EditBox(f) f.input = true end
function S.Dropdown(f) f.dropdown = true end
function S.FadeNineSlice(f) f.faded = true end
function S.GetPanelColor() return 0.03, 0.03, 0.04, 0.95 end
local looks = {}
S.OnLooksChanged = function(fn) looks[#looks + 1] = fn end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
local modules = {}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Skins/Guildy.lua'))('EUIAddonSkins', ns)
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 12, 'Guildy refresh loop')
    end
end
local function label(parent, text)
    local t = parent:CreateFontString(); t:SetText(text); t:SetTextColor(1, 0.82, 0, 1); return t
end
local function Button(parent, text, name)
    local b = frame('Button', name, parent)
    b.label = label(b, text); b.art = b:CreateTexture()
    return b
end
local GOLD = {0.79, 0.64, 0.29}
local function Box(parent, border)
    local box = frame('Frame', nil, parent)
    box:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8x8', edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border', edgeSize = 12})
    box:SetBackdropColor(0.08, 0.068, 0.048, 0.95)
    box:SetBackdropBorderColor(GOLD[1] * border, GOLD[2] * border, GOLD[3] * border)
    return box
end

-- Optional target: no Guildy, no activation.
SlashCmdList = nil
assert(not modules.Guildy.available(), 'Guildy should remain optional')
SlashCmdList = {GUILDY = function() end}
assert(modules.Guildy.available())

-- Blizzard globals Guildy relies on.
local toggles = 0
function ToggleGuildFrame() toggles = toggles + 1; return 'native-toggle' end
function PanelTemplates_SelectTab(tab) tab.nativeSelected = true end
function PanelTemplates_DeselectTab(tab) tab.nativeSelected = false end
CommunitiesGuildTextEditFrame = frame('Frame', 'CommunitiesGuildTextEditFrame')
local container = frame('Frame', nil, CommunitiesGuildTextEditFrame)
CommunitiesGuildTextEditFrame.Container = container
local blizzardEdit = frame('EditBox', nil, container)
local blizzardAccept = Button(container, 'Accept')

-- Installed before Guildy built its window (it builds on the first guild-window open).
modules.Guildy.install(S, modules.Guildy); flush()
local nativeToggle = ToggleGuildFrame

-- Guildy builds GuildyFrame as ButtonFrameTemplate inside Blizzard's window.
local main = frame('Frame', 'GuildyFrame')
main.PortraitContainer = frame('Frame', nil, main)
local ring = main.PortraitContainer:CreateTexture()
main.PortraitContainer.portrait = main.PortraitContainer:CreateTexture()
main.CloseButton = Button(main, '', 'GuildyFrameCloseButton')
main.Emblem = frame('Frame', nil, main)
local emblemArt = main.Emblem:CreateTexture(); local emblemText = main.Emblem:CreateFontString()
main.OptionsButton = Button(main, '')
main.OptionsButton.Icon = main.OptionsButton:CreateTexture()
main.OptionsButton:SetScript('OnClick', function() main.optionsClicked = true end)
local side = frame('Frame', nil, main); side.sideTab = true; local sideArt = side:CreateTexture()
local tab1, tab2 = Button(main, 'Chat', 'GuildyFrameTab1'), Button(main, 'Members', 'GuildyFrameTab2')
tab1:SetID(1); tab2:SetID(2); main.selectedTab = 1
local grip = frame('Button', nil, main); grip.normal = grip:CreateTexture()
grip.normal.path = 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up'
local content = frame('Frame', nil, main)
local panel = frame('Frame', nil, content)
local box = Box(panel, 0.7)
local search = frame('EditBox', nil, panel)
local check = frame('CheckButton', nil, panel)
local reset = Button(panel, 'Reset')
-- data buttons: a heat-map cell and a sort header keep their own art
local cell = frame('Button', nil, panel); cell.Text = label(cell, '12')
local heat = cell:CreateTexture(); heat:SetColorTexture(0.2, 0.8, 0.1, 0.6)
local header = frame('Button', nil, panel); header.Text = label(header, 'Name')
header:SetScript('OnClick', function() header.sorted = true end)
-- the chat timeline rail: 2px gold track and a gold thumb button
local rail = frame('Button', nil, panel)
local railTrack = rail:CreateTexture(); railTrack.layer = 'BACKGROUND'; railTrack:SetWidth(2); railTrack:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.35)
local thumb = frame('Button', nil, rail)
local thumbEdge = thumb:CreateTexture(); thumbEdge.layer = 'BACKGROUND'; thumbEdge:SetColorTexture(0, 0, 0, 1)
local thumbFill = thumb:CreateTexture(); thumbFill:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
local thumbHi = thumb:CreateTexture(); thumbHi.layer = 'HIGHLIGHT'; thumbHi:SetColorTexture(1, 0.82, 0, 0.35)
rail:SetScript('OnClick', function() rail.jumped = true end)
-- the Blizzard editor is lent into this panel
container.parent = panel; panel.children[#panel.children + 1] = container

assert(ToggleGuildFrame() == 'native-toggle' and toggles == 1); flush()
assert(main.shell and main.shellOptions.noAccent, 'Guildy window not shelled on first open')
assert(ring.alpha == 0 and main.PortraitContainer.portrait.alpha == 1, 'portrait ring not removed or portrait hidden')
assert(main.CloseButton.close)
assert(emblemArt.alpha == 1 and emblemText.font == 'native', 'guild emblem was styled')
assert(main.OptionsButton.button and main.OptionsButton.Icon.alpha == 1, 'options cog lost its icon')
assert(not side.button and sideArt.alpha == 1, 'side tab art changed')
assert(tab1.tab and tab1.selected == true and tab2.tab and tab2.selected == false, 'bottom tabs not styled with selection')
assert(grip.normal.alpha == 0, 'resize grip art remained')
assert(search.input and check.checkbox and reset.button and reset.label.font == 'eui')
assert(reset.label.textColor[2] == 0.82, 'button label colour not preserved')
assert(not cell.button and heat.alpha == 1 and heat.color[2] == 0.8, 'data cell lost its colour art')
assert(cell.Text.font == 'eui' and not header.button, 'custom data buttons were boxed')
header.hooks.OnClick(header); assert(header.sorted, 'sort header action lost')
assert(not blizzardEdit.input and not blizzardAccept.button and blizzardAccept.label.font == 'native',
    'borrowed Blizzard editor was styled')

-- Boxes keep a backdrop so Guildy's own border colours still mean something.
assert(box.backdrop.edgeFile == 'Interface\\Buttons\\WHITE8X8' and box.backdrop.edgeSize == 1, 'box not flattened')
assert(box.border[1] == 0.055 and box.color[1] > 0.03 and box.color[4] == 0.9, 'resting box lit by the backdrop reset or wrong colours')
assert(railTrack.color[1] == accent and railTrack.color[4] == 0.35 and thumbFill.color[1] == accent, 'timeline rail kept gold')
assert(thumbEdge.color[1] == 0 and thumbEdge.alpha == 1 and not rail.button and not thumb.button, 'timeline rail art replaced')
rail.hooks.OnClick(rail); assert(rail.jumped, 'timeline rail action lost')
box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3])
assert(box.border[1] == accent and box.border[4] == 1, 'selected card border did not use the accent')
box:SetBackdropBorderColor(GOLD[1] * 0.5, GOLD[2] * 0.5, GOLD[3] * 0.5)
assert(box.border[1] == 0.055, 'deselected card border stayed lit')
box:SetBackdropBorderColor(1, 0.82, 0)
assert(box.border[1] == accent, 'hover border did not use the accent')

-- Tab selection follows PanelTemplates; foreign tabs are untouched.
local foreign = Button(nil, 'Other', 'OtherFrameTab1')
PanelTemplates_SelectTab(tab2); PanelTemplates_DeselectTab(tab1); PanelTemplates_SelectTab(foreign)
assert(tab2.selected == true and tab1.selected == false and tab2.nativeSelected, 'tab selection not followed')
assert(not foreign.tab, 'foreign tab styled')

-- A tab panel built later is styled when it shows.
local lazy = frame('Frame', nil, content); lazy:Hide()
modules.Guildy.refresh(); flush()
local later = Button(lazy, 'Invite'); local laterBox = Box(lazy, 0.7)
lazy:Show(); flush()
assert(later.button and laterBox.backdrop.edgeSize == 1, 'lazy tab content not styled on show')

-- Segmented options: the chosen option is the disabled button.
local options = frame('Frame', 'GuildyOptions')
options.PortraitContainer = frame('Frame', nil, options)
local group = frame('Frame', nil, options); group.buttons = {}
for i, value in ipairs({'a', 'b'}) do
    local b = Button(group, value); b.value = value; group.buttons[i] = b
end
function group:SetValue(value)
    for _, b in ipairs(self.buttons) do b:SetEnabled(b.value ~= value) end
end
group:SetValue('a')
main.OptionsButton.hooks.OnClick(main.OptionsButton); flush()
assert(main.optionsClicked and options.shell, 'options window not styled after the cog click')
local a, b = group.buttons[1], group.buttons[2]
assert(a.euiSelection.color[4] == 0.2 and b.euiSelection.color[4] == 0, 'segmented selection not shown')
assert(a.label.textColor[1] == 1 and a.label.textColor[3] == 1, 'chosen segment label not white')
group:SetValue('b')
assert(b.euiSelection.color[4] == 0.2 and a.euiSelection.color[4] == 0, 'segmented selection did not follow SetValue')

-- Owned popups.
local confirm = Box(nil, 0.9); confirm.name = 'GuildyConfirm'; GuildyConfirm = confirm
local ok = Button(confirm, 'Yes')
modules.Guildy.refresh(); flush()
assert(confirm.shell and ok.button, 'confirmation popup not styled')

-- Repeated refreshes add no hooks or objects.
local hooked, regions = ToggleGuildFrame, #box.regions
for _ = 1, 10 do modules.Guildy.refresh(); flush() end
assert(ToggleGuildFrame == hooked and #box.regions == regions, 'duplicate hooks or objects')
assert(nativeToggle == ToggleGuildFrame)

-- Combat defers styling; leaving combat applies it.
local waiting = Button(panel, 'Promote')
combat = true
modules.Guildy.refresh(); flush()
assert(not waiting.button, 'styled during combat')
combat = false
for _, f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.hooks.OnEvent(f, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(waiting.button, 'combat recovery missed')

-- Accent changes repaint lit borders.
box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3])
accent = 0.9; for _, look in ipairs(looks) do look() end; flush()
assert(box.border[1] == 0.9, 'accent change not applied to a lit border')
assert(railTrack.color[1] == 0.9 and thumbFill.color[1] == 0.9, 'accent change not applied to the timeline rail')

-- Disabled skin stops processing.
enabled = false
box:SetBackdropBorderColor(GOLD[1] * 0.5, GOLD[2] * 0.5, GOLD[3] * 0.5)
assert(box.border[1] == GOLD[1] * 0.5, 'disabled skin still repainted borders')
local after = Button(panel, 'Late'); modules.Guildy.refresh(); flush()
assert(not after.button, 'disabled skin styled new controls')
print('PASS: Guildy lazy window, backdrop border reset, timeline rail, borrowed Blizzard editor, selection borders, data buttons, segmented options, tabs, popups, combat and disable')
