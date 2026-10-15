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
assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Skins/PallyPower.lua'))('EUIAddonSkins', ns)
PallyPower = nil; assert(not modules.PallyPower.available(), 'PallyPower should remain optional')
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 12, 'PallyPower refresh loop')
    end
end
local function icon(parent, name)
    local t = parent:CreateTexture(); t.name = name; t.GetName = function(self) return self.name end
    t.path = 'spell-art'; return t
end
local function label(parent, text)
    local t = parent:CreateFontString(nil, nil, 'native'); t:SetText(text); t:SetTextColor(1, 0.2, 0.1, 0.8); return t
end
local function Buff(name)
    local f = frame('Button', name)
    f:SetBackdrop({bgFile = 'native-fill', edgeFile = 'native-border', edgeSize = 8})
    f:SetBackdropColor(0.8, 0.1, 0.2, 0.65)
    f.protected = true
    f.alpha, f.width, f.height, f.spell, f.unit = 0, 100, 34, 123, 'raid1'
    f.hooks.OnClick = function() f.casts = (f.casts or 0) + 1 end
    f.hooks.OnEnter = function() f.expanded = true end
    f.HookScript = function() error('skin hooked a protected buff script') end
    f.SetAttribute = function() error('skin changed secure attributes') end
    f.Execute = function() error('skin executed a secure snippet') end
    f.SetPoint = function() error('skin changed secure anchors') end
    f.SetSize = function() error('skin changed secure dimensions') end
    f.Show = function() error('skin changed secure visibility') end
    f.Hide = f.Show
    local setBackdrop = f.SetBackdrop
    f.SetBackdrop = function(self, value) assert(not combat, 'protected styling during combat'); setBackdrop(self, value) end
    f.icon, f.timer, f.range = icon(f, name .. 'Icon'), label(f, '12:34'), icon(f, name .. 'Range')
    f.range:SetVertexColor(1, 0, 0, 1)
    return f
end
PallyPowerAnchor = frame('CheckButton', 'PallyPowerAnchor')
PallyPowerAnchor.protected = true
PallyPowerAnchor.normal, PallyPowerAnchor.checkedArt = PallyPowerAnchor:CreateTexture(), PallyPowerAnchor:CreateTexture()
function PallyPowerAnchor:GetCheckedTexture() return self.checkedArt end
PallyPowerAnchor.hooks.OnClick = function(_, button) PallyPowerAnchor.action = button end
PallyPowerAnchor.HookScript = function() error('skin hooked protected anchor') end
PallyPowerBlessingsFrame = frame('Frame', 'PallyPowerBlessingsFrame')
local dividerGroup = frame('Frame', 'PallyPowerBlessingsFrameClassGroup1', PallyPowerBlessingsFrame)
local divider = dividerGroup:CreateTexture(); divider.name = 'PallyPowerBlessingsFrameClassGroup1Line'
local numberedDivider = PallyPowerBlessingsFrame:CreateTexture(); numberedDivider.name = 'PallyPowerBlessingsFrameLine11'
_G[divider.name] = divider
local secondColumn = frame('Frame', 'PallyPowerBlessingsFrameClassGroup2', PallyPowerBlessingsFrame)
local secondLine = secondColumn:CreateTexture(); secondLine.name = 'PallyPowerBlessingsFrameClassGroup2Line'; _G[secondLine.name] = secondLine
local columnHeader = frame('Button', 'PallyPowerBlessingsFrameClassGroup1ClassButton', dividerGroup)
columnHeader.Icon = icon(columnHeader, 'PallyPowerBlessingsFrameClassGroup1ClassButtonIcon')
local grid = frame('Button', 'PallyPowerBlessingsFramePlayer1Class1', PallyPowerBlessingsFrame)
grid.Icon = icon(grid, 'PallyPowerBlessingsFramePlayer1Class1Icon'); grid.Text = label(grid, 'Paladin')
grid.hooks.OnClick = function() grid.assignment = 'native-assignment' end
local close = frame('Button', 'PallyPowerBlessingsFrameCloseButton', PallyPowerBlessingsFrame)
local title = frame('Button', 'PallyPowerBlessingsFrameTitle', PallyPowerBlessingsFrame)
title.text = label(title, 'Pally Power'); title.hooks.OnUpdate = function() return 'grid-update-native' end
local buff = Buff('PallyPowerC1'); local player = Buff('PallyPowerC1P1')
local options, dialog = frame('Frame', 'PallyPowerOptions'), {OpenFrames = {}}
function dialog:Open(app)
    self.OpenFrames[app] = self.OpenFrames[app] or {frame = frame('Frame')}
    local f = self.OpenFrames[app].frame
    if not f.edit then
        f.edit = frame('EditBox', nil, f); f.check = frame('CheckButton', nil, f)
        f.obj = {frame = f, type = 'Frame', titletext = label(f, 'Options')}
        f.titleArt = f:CreateTexture(); f.titleArt:SetTexture(131080)
        f.status = frame('Button', nil, f); f.status.obj = f.obj
        f.obj.statustext = label(f.status, 'Status')
        f.status:SetBackdrop({bgFile = 'native-status', edgeFile = 'native-border'})
        f.heading = frame('Frame', nil, f); f.heading.obj = {frame = f.heading, type = 'Heading'}
        f.heading.line = f.heading:CreateTexture(); f.heading.line:SetTexture(137057)
        f.heading.text = label(f.heading, 'Settings')
        f.tabs = frame('Frame', nil, f); f.tabs.obj = {frame = f.tabs, type = 'TabGroup', tabs = {}}
        function f.tabs.obj:SetTabs()
            for i = 1, 2 do
                local tab = frame('Button', nil, self.frame); tab.selected = i == 1; self.tabs[i] = tab
                tab.nativeArt = tab:CreateTexture()
            end
        end
        function f.tabs.obj:SelectTab(index)
            for i, tab in ipairs(self.tabs) do tab.selected = i == index; tab.nativeArt:SetAlpha(1) end
        end
        f.tabs.obj:SetTabs()
    end
    return 'dialog-native'
end
LibStub = function(name) if name == 'AceConfigDialog-3.0' then return dialog end end
PallyPower = {classButtons = {buff}, playerButtons = {{player}}, optionsFrame = options,
    menuFrame = frame(), opt = {skin = 'native-profile', cBuffNeedAll = {r = 1, g = 0}},
    titleBar = frame('Button', 'PallyPowerTitleBar')}
PallyPower.titleBar.text = label(PallyPower.titleBar, 'Pally Buffs (5)')
PallyPower.titleBar.hooks.OnClick = function() return 'lock-pin-native' end
function PallyPower:CreateLayout() return 'layout-native' end
function PallyPower:UpdateLayout() return 'update-native' end
function PallyPower:ApplySkin()
    buff:SetBackdrop({bgFile = 'new-native', edgeFile = 'new-border', edgeSize = 8})
    buff:SetBackdropColor(0.2, 0.9, 0.1, 0.6); return 'skin-native'
end
function PallyPower:OpenConfigWindow()
    dialog:Open('PallyPower'); PallyPowerConfigFrame = dialog.OpenFrames.PallyPower.frame
    return 'options-native'
end
local controls = frame('Frame', nil, options)
local checkbox = frame('Button', nil, controls)
checkbox.obj = {frame = checkbox, type = 'CheckBox', checkbg = checkbox:CreateTexture(), check = checkbox:CreateTexture(), highlight = checkbox:CreateTexture(), text = label(checkbox, 'Toggle')}
function checkbox.obj:SetType() self.checkbg:SetTexture(130755); self.check:SetTexture(130751) end
function checkbox.obj:SetDisabled(v) self.disabled = v end
function checkbox.obj:SetValue(v) self.checked = v; if v then self.check:Show() else self.check:Hide() end end
checkbox.obj:SetValue(false)
local slider = frame('Slider', nil, controls); slider.thumb = slider:CreateTexture()
function slider:GetThumbTexture() return self.thumb end
function slider:GetOrientation() return 'HORIZONTAL' end
slider.hooks.OnValueChanged = function(_, v) slider.value = v end
local media = frame('Frame', nil, controls)
media.obj = {frame = media, type = 'LSM30_Background'}
for _, key in ipairs({'DLeft', 'DRight', 'DMiddle'}) do media[key] = media:CreateTexture() end
media.text, media.label = label(media, 'Background'), label(media, 'Texture')
media.dropButton = frame('Button', nil, media); media.dropButton.obj = media.obj
media.displayButton = frame('Button', nil, media); media.displayButton:SetBackdrop({bgFile = 'chosen-preview', edgeFile = 'native-border'})
function media.obj:ToggleDrop()
    self.dropdown = self.dropdown or frame('Frame', nil)
    local popup = self.dropdown
    popup.bgTex = popup.bgTex or popup:CreateTexture(); popup.bgTex:SetTexture('hover-preview')
    if not popup.row then
        popup.row = frame('Button', nil, popup); popup.row.obj = self
        popup.row.text, popup.row.check = label(popup.row, 'Chosen background'), popup.row:CreateTexture()
        popup.row.hooks.OnClick = function() self.value = 'chosen'; self.dropdown = nil end
    end
    popup:Show()
    return 'native-toggle'
end
media.dropButton.hooks.OnClick = function() return media.obj:ToggleDrop() end
modules.PallyPower.install(S, modules.PallyPower); flush()
assert(PallyPowerBlessingsFrame.shellOptions.noTopBar and PallyPowerBlessingsFrame.shellOptions.noAccent and not PallyPowerBlessingsFrame.accent)
assert(divider.alpha == 0 and numberedDivider.alpha == 0, 'native white assignment divider remained visible')
assert(not grid.Icon.borderParent, 'assignment icon received a black border')
for _, edge in ipairs(grid.pixelBorder.regions) do assert(edge.color[4] == 0, 'assignment button outline remained visible') end
assert(checkbox.obj.checkbg.path == 'solid' and checkbox.obj.checkbg.width == 14 and checkbox.obj.check.hidden)
checkbox.obj:SetValue(true); assert(not checkbox.obj.check.hidden and checkbox.obj.checked)
checkbox.obj:SetType(); assert(checkbox.obj.check.path == 'solid')
checkbox.obj:SetDisabled(true); assert(checkbox.obj.check.color[1] == 0.5)
local assignmentReads = 0
local assignmentRegions = PallyPowerBlessingsFrame.GetRegions
PallyPowerBlessingsFrame.GetRegions = function(self) assignmentReads = assignmentReads + 1; return assignmentRegions(self) end
for i = 1, 50 do checkbox.obj:SetDisabled(i % 2 == 0); checkbox.obj:SetType() end
assert(assignmentReads == 0, 'checkbox setup repeatedly rescanned the complete integration')
PallyPowerBlessingsFrame.GetRegions = assignmentRegions

assert(slider.thumb.width == 10 and slider.thumb.height == 16)
slider.hooks.OnValueChanged(slider, 1.5); assert(slider.value == 1.5)
assert(media.panel and media.DLeft.alpha == 0 and media.dropButton.dropdown)
assert(media.displayButton.backdrop.bgFile == 'chosen-preview' and not media.displayButton.backdrop.edgeFile)
assert(media.obj:ToggleDrop() == 'native-toggle')
assert(media.obj.dropdown.panel and media.obj.dropdown.bgTex.path == 'hover-preview' and media.obj.dropdown.bgTex.alpha == 1)
local mediaPopup = media.obj.dropdown; mediaPopup.row.hooks.OnClick(); assert(media.obj.value == 'chosen')
assert(columnHeader.euiPallyHeader and columnHeader.euiPallyHeader.alpha == 1)
local fills = {}; for _, t in ipairs(dividerGroup.regions) do if t ~= divider then fills[#fills + 1] = t end end
assert(#fills == 1 and fills[1].color[4] == 0.65)
local secondFill; for _, t in ipairs(secondColumn.regions) do if t ~= secondLine then secondFill = t end end
assert(secondFill.color[1] > fills[1].color[1], 'alternating columns lack contrast')
assert(PallyPowerAnchor.normal.path == 'native' and PallyPowerAnchor.checkedArt.path == 'native', 'skin changed the original lock button artwork')
PallyPowerAnchor.hooks.OnClick(PallyPowerAnchor, 'RightButton'); assert(PallyPowerAnchor.action == 'RightButton')
assert(options.check == nil and not options.shell, 'embedded options received a nested shell')
assert(grid.Icon.alpha == 1 and grid.Icon.path == 'spell-art' and grid.Icon.crop[1] == 0.08)
grid.hooks.OnClick(); assert(grid.assignment == 'native-assignment')
assert(close.close and title.hooks.OnUpdate() == 'grid-update-native')
assert(buff.backdrop.edgeSize == 1 and buff.backdrop.bgFile == 'Interface\\Buttons\\WHITE8X8' and buff.color[1] == 0.8)
assert(buff.timer.font == 'eui' and buff.timer.text == '12:34' and buff.timer.textColor[1] == 1 and buff.timer.textColor[4] == 0.8)
assert(buff.icon.crop[1] == 0.08 and not buff.range.crop and buff.range.color[1] == 1)
assert(buff.alpha == 0 and buff.width == 100 and buff.height == 34 and buff.spell == 123 and buff.unit == 'raid1')
buff.hooks.OnClick(); buff.hooks.OnEnter(); assert(buff.casts == 1 and buff.expanded)
assert(menus[PallyPower.menuFrame] and PallyPower.titleBar.panel and PallyPower.titleBar.accent)
local optionButton = frame('Button', 'PallyPowerOptionsAction', options); optionButton.Text = label(optionButton, 'Option')
modules.PallyPower.refresh(); flush()
for _, edge in ipairs(optionButton.pixelBorder.regions) do assert(edge.color[4] == 1, 'assignment border removal leaked into other options') end
assert(PallyPower:ApplySkin() == 'skin-native' and buff.backdrop.edgeSize == 1 and buff.color[2] == 0.9)
assert(PallyPower:OpenConfigWindow() == 'options-native' and PallyPowerConfigFrame.shellOptions.noTopBar and PallyPowerConfigFrame.edit.input and PallyPowerConfigFrame.check.checkbox)
assert(not PallyPowerConfigFrame.accent and PallyPowerConfigFrame.shellOptions.noAccent)
assert(PallyPowerConfigFrame.titleArt.alpha == 0 and PallyPowerConfigFrame.heading.line.alpha == 0)
assert(PallyPowerConfigFrame.heading.text.font == 'eui' and PallyPowerConfigFrame.status.panel)
local tabWidget = PallyPowerConfigFrame.tabs.obj
assert(tabWidget.tabs[1].tab and tabWidget.tabs[1].selected and not tabWidget.tabs[1].button and tabWidget.tabs[1].nativeArt.alpha == 0)
tabWidget:SelectTab(2); assert(tabWidget.tabs[2].tab and tabWidget.tabs[2].selected and not tabWidget.tabs[1].selected)
tabWidget:SetTabs(); flush(); assert(tabWidget.tabs[1].tab, 'new option tabs were not styled after their construction burst')
PallyPowerConfigFrame.heading.line:SetAlpha(1); numberedDivider:SetAlpha(1)
assert(PallyPowerConfigFrame.heading.line.alpha == 0 and numberedDivider.alpha == 0, 'native redraw restored separator textures')
dialog:Open('Other'); assert(not dialog.OpenFrames.Other.frame.shell and not dialog.OpenFrames.Other.frame.edit.input, 'PallyPower styling leaked to another Ace dialog')
local later = Buff('PallyPowerC2'); PallyPower.classButtons[2] = later
assert(PallyPower:CreateLayout() == 'layout-native' and later.backdrop.edgeSize == 1, 'late buff controls were not styled')
local hook, objects = PallyPower.UpdateLayout, #grid.regions
for _ = 1, 10 do PallyPower:UpdateLayout(); modules.PallyPower.refresh(); flush() end
assert(PallyPower.UpdateLayout == hook and #grid.regions == objects and not buff.hooks.OnUpdate, 'skin added duplicate hooks, objects or polling')
local waiting = Buff('PallyPowerC3')
combat = true

PallyPower.classButtons[3] = waiting
PallyPower:UpdateLayout(); modules.PallyPower.refresh(); flush()
assert(waiting.backdrop.edgeSize == 8 and waiting.timer.font == 'native', 'combat refresh styled a protected control')
combat = false
for _, f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.hooks.OnEvent(f, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(waiting.backdrop.edgeSize == 1 and waiting.timer.font == 'eui')
accent = 0.9; for _, look in ipairs(looks) do look() end; flush()
assert(PallyPower.titleBar.text.textColor[1] == 0.9)
assert(not PallyPowerBlessingsFrame.accent and divider.alpha == 0)
for _, edge in ipairs(grid.pixelBorder.regions) do
    edge:SetColorTexture(1, 1, 1, 1)
    assert(edge.color[4] == 0, 'theme redraw restored an assignment border')
end
LibStub = nil; modules.PallyPower.refresh(); flush(); assert(menus[PallyPower.menuFrame], 'missing Ace library caused initialization failure')
enabled = false; buff:SetBackdrop({bgFile = 'disabled-native', edgeSize = 8}); PallyPower:UpdateLayout(); flush()
assert(buff.backdrop.edgeSize == 8 and PallyPower.opt.skin == 'native-profile', 'disabled skin changed the native profile or processed redraws')
print('PASS: PallyPower beta assignment/options menus, icons and fonts; native secure casts, attributes, flyouts, status colours, geometry, optional/lazy loading, combat deferral and hook reuse')
