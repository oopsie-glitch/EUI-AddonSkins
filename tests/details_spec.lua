-- Native-control fixtures: actions, geometry, status colours, redraws and reuse.
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
    function f:SetPoint(...)
        local point = {...}
        local function Depends(region, target, visited)
            if region == target then return true end
            if type(region) ~= 'table' or visited[region] then return false end
            visited[region] = true
            for _, anchor in ipairs(region.points or {}) do
                if Depends(anchor[2], target, visited) then return true end
            end
            return false
        end
        assert(not Depends(point[2], self, {}), 'Cannot anchor to a region dependent on it')
        self.points = self.points or {}; self.points[#self.points + 1] = point
    end
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
    function f:GetScript(e) return self.hooks[e] end
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
local settingsRegistered, openedCategory = 0
Settings = {
    RegisterCanvasLayoutCategory = function(panel) settingsRegistered = settingsRegistered + 1; return {GetID = function() return 123 end} end,
    RegisterAddOnCategory = function() end,
    OpenToCategory = function(id) openedCategory = id end,
}
S.GetFont = function() return 'eui', '' end
S.GetPanelColor = function() return 0.03, 0.03, 0.03, 0.95 end
S.OnLooksChanged = function(fn) S.looks = fn end
local modules = {}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins', ns)
Details = nil
EUIAddonSkinsDB = nil; EllesmereUIDB = nil
assert(loadfile('EUIAddonSkins/MeterStyle.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/DetailsLayout.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/DetailsSettings.lua'))('EUIAddonSkins', ns)
assert(ns.DetailsSettings().meter == false and ns.DetailsSettings().menus == true, 'meter matching must be opt-in')
assert(loadfile('EUIAddonSkins/Skins/Details.lua'))('EUIAddonSkins', ns)
assert(not modules.Details.available(), 'Details must remain optional')
local function flush()
    local rounds = 0
    while #timers > 0 do local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end; rounds = rounds + 1; assert(rounds < 12, 'refresh loop') end
end
C_AddOns = {IsAddOnLoaded = function(name) return name == 'EllesmereUIDamageMeters' end}
local nextInstanceId = 0
local function instance()
    nextInstanceId = nextInstanceId + 1
    local obj = {meu_id = nextInstanceId, baseframe = frame(), row_info = {height = 24, space = {between = 0}, texture = 'native', textR_show_data = {true, true, true}, textR_bracket = '[', textR_separator = ',', textR_enable_custom_text = true}, barras = {}, position = {x = 100, y = 200}, segment = 3}
    obj.baseframe.titleBar = frame('Frame', nil, obj.baseframe); obj.baseframe.titleBar.texture = obj.baseframe.titleBar:CreateTexture()
    obj.baseframe.cabecalho = {ball = obj.baseframe:CreateTexture(), fechar = frame('Button', nil, obj.baseframe)}
    obj.baseframe:SetSize(340, 160)
    obj.use_multi_fontstrings = true
    obj.baseframe.titleBar:Hide()
    obj.nativeTitle = font(obj.baseframe); obj.nativeTitle:SetText('00:06 Damage Done')
    obj.baseframe.lock_button = frame('Button', nil, obj.baseframe); obj.baseframe.lock_button.label = font(obj.baseframe.lock_button)
    obj.baseframe.resize_direita = frame('Button', nil, obj.baseframe); obj.baseframe.resize_direita.texture = obj.baseframe.resize_direita:CreateTexture()
    for _, key in ipairs({'modo_selecao', 'segmento', 'atributo', 'report', 'reset', 'fechar'}) do
        local b = key == 'fechar' and obj.baseframe.cabecalho.fechar or frame('Button', nil, obj.baseframe)
        obj.baseframe.cabecalho[key] = key == 'fechar' and b or {widget = b}
        b.normal = b:CreateTexture(); b:SetPoint('BOTTOMRIGHT', obj.baseframe, 'TOPRIGHT', 5, -6)
        -- Details can fade the button itself while its mouse scripts remain live.
        b.alpha = key == 'reset' and 1 or 0
        b.hooks.OnClick = function() return key .. '-native' end
    end
    obj.baseframe.cabecalho.fechar.action = function() return 'close-native' end
    obj.bgdisplay = frame(); obj.attribute_text = font(obj.baseframe)
    return setmetatable(obj, {__index = Details})
end
local callbacks, setterCalls = {}, 0
Details = {
    GetTitleBarFontString = function(self) return {widget = self.nativeTitle} end,
    GetInstanceAttributeText = function() return 'Damage Done' end,
    GetShowingCombat = function(self) return {GetCombatTime = function() return self.elapsed or 6 end} end,
    SetTitleBarText = function() return 'title-native' end,
    RefreshMainWindow = function() return 'refresh-native' end,
    SetMenuOwner = function(_, owner) GameCooltip:SetHost(owner); return 'owner-native' end,
    SetBarRightTextSettings = function(self, total, ps, percent, bracket, sep)
        self.row_info.textR_show_data = {total, ps, percent}; self.row_info.textR_bracket = bracket; self.row_info.textR_separator = sep
    end,
    CreateEventListener = function() return {RegisterEvent = function(_, event, fn) assert(not callbacks[event]); callbacks[event] = fn end} end,
    GetAllInstances = function() return Details.instances end,
    InstanceRefreshRows = function() return 'rows-native' end,
    SetBarSettings = function(self, height, textureName, _, _, _, _, _, _, _, _, spacing)
        setterCalls = setterCalls + 1; self.row_info.height = height; self.row_info.space.between = spacing; self.row_info.texture = textureName
        self:InstanceRefreshRows()
    end,
    OpenOptionsWindow = function() DetailsOptionsWindow = frame('Frame', 'DetailsOptionsWindow'); return 'options-native' end,
    ChangeSkin = function() return 'skin-native' end,
    ApplyProfile = function() return 'profile-native' end,
}
-- Source-shaped native raid-plugin menu: Cooltip injects Host as self.
Details.RaidTables = {IsAvailable = function(_, id, host) return id == 'compare' or id == 'vanguard' end}
function Details.RaidTables:switch(fixed, id, host)
    local fromMenu = not self
    self = self or Details.RaidTables
    assert(self:IsAvailable(id, host))
    host.selectedPlugin = id
    if fromMenu then GameCooltip:ExecFunc(host.baseframe.cabecalho.atributo.widget) end
    return 'switch-native', fixed, nil, 'tail-native'
end
local unrelatedAction = function() return 'unrelated-native' end
function Details:MontaRaidOption(host)
    GameCooltip.FunctionsTableMain = {unrelatedAction, self.RaidTables.switch, self.RaidTables.switch}
    GameCooltip.ParametersTableMain = {{}, {'compare', host}, {'vanguard', host}}
    return 'raid-menu-native'
end
Details.instances = {instance()}
local meter = Details.instances[1]
local function row()
    local r = frame('Button'); r.statusbar = frame('StatusBar', nil, r); r.textura = r.statusbar:CreateTexture()
    r.statusbar.SetStatusBarTexture = function(self, path) self.fill = path end
    r.statusbar.value, r.statusbar.classColour = 937, {0.3, 0.7, 1}
    r.lineText1, r.lineText4 = font(r), font(r)
    r.lineText1:SetTextColor(0.3, 0.7, 1, 0.8)
    r.icone_classe = r:CreateTexture(); r.icone_classe.crop = {0.25, 0.5, 0.5, 0.75}
    r.action = function() return 'breakdown-native' end
    return r
end
meter.barras[1] = row()
local media = {Register = function(self, kind, name, path) self[kind] = {name, path} end}
LibStub = function(name) if name == 'LibSharedMedia-3.0' then return media end end
_EDM_DB = {profile = {dm = {barHeight = 18, barSpacing = 2, barTexture = 'test', leftFontSize = 11, rightFontSize = 10, bgAlpha = 0.7}}}
_EDM_BarTextures = {test = 'eui-bar'}
EllesmereUI = {GetFontPath = function() return 'eui-meter-font' end, GetFontOutlineFlag = function() return 'OUTLINE' end}
local tip1, tip2 = frame(), frame()
for _, f in ipairs({tip1, tip2}) do
    f:SetBackdrop({bgFile = 'native-tooltip'}); f:SetBackdropColor(0.2, 0.2, 0.2, 1); f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    local line = frame(); f.Lines = {line}; local bar = frame('StatusBar', nil, line); line.leftText = font(bar); line.rightText = font(bar)
    f.HaveRoundedCorners = true
    function f:EnableRoundedCorners() self.disabled = false end
    function f:DisableRoundedCorners() self.disabled = true end
    f.frameBackgroundTexture, f.gradientTexture = f:CreateTexture(), f:CreateTexture()
    line.background, line.divbar, line.leftIcon = bar:CreateTexture(), line:CreateTexture(), bar:CreateTexture()
    line.divbar:SetAlpha(0.1); line.divbar:SetTexCoord(0.2, 0.8, 0, 0.1)
    line.leftIcon:SetVertexColor(1, 0, 0, 1)
    line.action = function() return 'delete-native' end
end
GameCooltip = {ExecFunc = function(_, host)
    assert(host.CoolTip, 'legacy ExecFunc requires missing CoolTip metadata')
end, entries = {}, Reset = function(self) self.entries = {} end,
    AddLine = function(self, text, right, level) self.entries[#self.entries + 1] = {text = text, right = right, level = level or 1} end,
    AddMenu = function(self, level, action) self.entries[#self.entries].action = action end,
    Hide = function(self) self.hidden = true end, frame1 = tip1, frame2 = tip2, GetOwner = function(self) return self.owner end,
    SetHost = function(self, owner) self.owner = owner end,
    ShowCooltip = function() return 'menu-native' end, BuildCooltip = function() end,
    BuildTooltip = function() end, BuildTooltipSecondFrame = function() end,
    ShowRoundedCorner = function(self)
        for _, f in ipairs({self.frame1, self.frame2}) do f:EnableRoundedCorners(); f:SetBackdrop(nil) end
    end}
modules.Details.install(S, modules.Details); flush()
assert(setterCalls == 0 and meter.baseframe.cabecalho.ball.alpha == 1, 'default menu-only mode changed the meter')
GameCooltip:SetHost(meter.baseframe.cabecalho.fechar); GameCooltip:ShowCooltip()
assert(tip1.border[1] == 0.055, 'menu-only mode missed a meter popup')
GameCooltip:SetHost(frame())
local settingsPanel = ns.CreateDetailsSettingsPanel()
settingsPanel.meter:SetChecked(true); settingsPanel.meter.hooks.OnClick(settingsPanel.meter); flush()
SlashCmdList.EUIDETAILS(); assert(settingsRegistered == 1 and openedCategory == 123, 'settings panel must register once and be reachable')
assert(setterCalls == 1 and meter.row_info.height == 18 and meter.row_info.space.between == 2)
assert(meter.position.x == 100 and meter.position.y == 200 and meter.segment == 3)
assert(meter.baseframe.cabecalho.ball.alpha == 0 and meter.baseframe.titleBar.height == 22)
assert(meter.baseframe.cabecalho.fechar.action() == 'close-native')
assert(meter.nativeTitle.alpha == 0 and meter.baseframe.lock_button.label.alpha == 0 and meter.baseframe.resize_direita.texture.alpha == 0)
assert(meter.use_multi_fontstrings == false and meter.row_info.textR_show_data[3] == false and meter.row_info.textR_bracket == '(')
local ownHeader
for _, f in ipairs(meter.baseframe.children) do if f.regions[2] and f.regions[2].text == 'Damage Done' then ownHeader = f end end
assert(ownHeader and not ownHeader.hidden and ownHeader.regions[3].text == ' (0:06)', 'independent header/timer missing')
local icons = {}
for _, key in ipairs({'modo_selecao', 'segmento', 'atributo', 'report', 'reset', 'fechar'}) do
    local value = meter.baseframe.cabecalho[key]
    local button = value.widget or value
    for _, region in ipairs(ownHeader.regions) do
        if region.kind == 'Texture' and region.points[1] and region.points[1][2] == button then icons[key] = region end
    end
    assert(icons[key] and icons[key].alpha == 1, 'toolbar icon must render independently of native button alpha: ' .. key)
    assert(icons[key].width == 22 and icons[key].height == 22, 'header icon size depends on native startup geometry: ' .. key)
    button:SetWidth(12); button:SetHeight(12)
    assert(button:GetWidth() == 22 and button:GetHeight() == 22, 'late startup dimensions shrank toolbar hit area: ' .. key)
end
local closeButton = meter.baseframe.cabecalho.fechar
closeButton:Hide(); closeButton.hooks.OnHide()
assert(icons.fechar.alpha == 0, 'hidden native button left a floating icon')
closeButton:Show(); closeButton.hooks.OnShow(); flush()
assert(icons.fechar.alpha == 1, 'shown native button did not recover its icon')
assert(meter.baseframe.titleBar.hidden, 'native title-bar visibility should remain unchanged')
assert(meter.baseframe.cabecalho.fechar.normal.alpha == 0 and meter.baseframe.cabecalho.fechar.points[1][1] == 'RIGHT')
assert(meter.baseframe.cabecalho.reset.widget.hooks.OnClick() == 'reset-native', 'toolbar action changed')
meter.elapsed = 65; assert(Details:RefreshMainWindow(meter) == 'refresh-native'); assert(ownHeader.regions[3].text == ' (1:05)')
local secret = {}; issecretvalue = function(v) return v == secret end
meter.elapsed = secret; Details:RefreshMainWindow(meter); assert(ownHeader.regions[3].text == '', 'secret timer must not be formatted')
meter.elapsed = 6; issecretvalue = nil
Details:RefreshMainWindow(meter)
meter.baseframe.cabecalho.fechar:SetPoint('BOTTOMRIGHT', meter.baseframe, 'TOPRIGHT', 99, 99)
assert(meter.baseframe.cabecalho.fechar.points[1][1] == 'RIGHT', 'native toolbar redraw escaped the header')
local r = meter.barras[1]
assert(r.textura.path == 'eui-bar' and r.lineText1.font == 'eui-meter-font' and r.lineText1.size == 11 and r.lineText4.size == 10)
assert(r.statusbar.value == 937 and r.statusbar.classColour[2] == 0.7 and r.lineText1.textColor[4] == 0.8 and r.icone_classe.crop[1] == 0.25 and r.action() == 'breakdown-native')
local writes = r.lineText1.writes
for _ = 1, 20 do assert(meter:InstanceRefreshRows() == 'rows-native'); modules.Details.refresh(); flush() end
assert(setterCalls == 1 and r.lineText1.writes == writes, 'warm refresh repeated geometry/font writes')
assert(Details:OpenOptionsWindow() == 'options-native' and DetailsOptionsWindow.shellOptions.noBorder)
-- Source-shaped category reset: a page OnShow scan runs before Details applies
-- the final selected template. Styling must be settled when the click returns.
DetailsOptionsWindow.sectionFramesContainer = {}
for id = 1, 3 do
    local page = frame('Frame', nil, DetailsOptionsWindow); page:Hide()
    local button = frame('Button', nil, DetailsOptionsWindow); button.label = font(button)
    local widget = {widget = button, type = 'button', icon = button:CreateTexture()}
    button.MyObject, page.sectionButton = widget, widget
    function widget:SetTemplate()
        button:SetBackdrop({bgFile = 'native-category'}); button.selected = nil
        button.label:SetAlpha(1)
    end
    function widget:SetIcon() self.icon:SetAlpha(1) end
    button.hooks.OnClick = function() return Details222.OptionsPanel.SelectOptionsSection(id) end
    DetailsOptionsWindow.sectionFramesContainer[id] = page
end
Details222 = {OptionsPanel = {SelectOptionsSection = function(id)
    local pages = DetailsOptionsWindow.sectionFramesContainer
    for _, page in ipairs(pages) do page:Hide(); page.sectionButton:SetTemplate(); page.sectionButton:SetIcon() end
    local page = pages[id]; page:Show()
    if page.hooks.OnShow then page.hooks.OnShow(page) end
    page.sectionButton:SetTemplate(); page.sectionButton:SetIcon()
    return 'section-native'
end}}
modules.Details.refresh(); flush()
for _, id in ipairs({1, 2, 3, 1, 3}) do
    local page = DetailsOptionsWindow.sectionFramesContainer[id]
    assert(Details222.OptionsPanel.SelectOptionsSection(id) == 'section-native', 'category method return changed')
    page.sectionButton.widget.hooks.OnClick()
    for i, section in ipairs(DetailsOptionsWindow.sectionFramesContainer) do
        local button = section.sectionButton.widget
        assert(button.backdrop == nil and button.tab and button.selected == (i == id), 'category styles/selection flashed after native reset')
        assert(section.sectionButton.icon.alpha == 0, 'native category marker returned')
        assert(button.label.alpha == 0, 'native template label overlapped the EUI tab label')
    end
    flush()
    assert(page.sectionButton.widget.selected, 'queued scan lost the selected category')
end
local input = frame('EditBox', nil, DetailsOptionsWindow)
local description = font(DetailsOptionsWindow)
local dfInput = frame('EditBox', nil, DetailsOptionsWindow)
dfInput.MyObject = {type = 'textentry'}
dfInput:SetPoint('LEFT', description, 'RIGHT', 2, 0); dfInput:SetSize(120, 18)
dfInput.value = 'saved-value'; dfInput.commit = function() return 'commit-native' end
local dropdown = frame('Button', nil, DetailsOptionsWindow); dropdown.MyObject = {type = 'dropdown', SetTemplate = function() end}
dropdown.dropdownframe = frame('ScrollFrame', nil, dropdown); dropdown.statusbar = dropdown:CreateTexture()
local check = frame('Button', nil, DetailsOptionsWindow); check.MyObject = {type = 'switch', checked_texture = check:CreateTexture(), SetTemplate = function() end}
check.action = function() return 'checkbox-native' end
local infoBar = frame('StatusBar', nil, DetailsOptionsWindow); infoBar.value = 65; infoBar.SetStatusBarTexture = function(self, p) self.fill = p end
modules.Details.refresh(); flush()
assert(input.inputOptions.noBorder and dropdown.dropdown and check.button and check.action() == 'checkbox-native')
assert(dfInput.inputOptions.padInput == false and not dfInput.padded and dfInput.points[1][4] == 2 and dfInput:GetWidth() == 120, 'DF field expanded across its description')
assert(dfInput.value == 'saved-value' and dfInput.commit() == 'commit-native', 'DF input contents/commit changed')
assert(infoBar.fill == 'eui-bar' and infoBar.value == 65)
-- The designer is created after the options window and repopulates controls
-- after object clicks. Native refreshes must finish with styled pooled rows.
local editor = frame('Frame', 'DetailsOptionsDesignerEditor', DetailsOptionsWindow)
local selector = frame('ScrollFrame', nil, editor)
selector.lines = {}
for i = 1, 2 do
    local line = frame('Button', nil, selector); line.Label = font(line); line.Icon = line:CreateTexture()
    selector.lines[i] = line
end
function selector:GetLines() return self.lines end
function selector:Refresh()
    for i, line in ipairs(self.lines) do line.Label:SetText('Object ' .. i); line.Label:SetFont('native', 12) end
    return 'selector-native'
end
function selector:RefreshMe() self.initialRefreshes = (self.initialRefreshes or 0) + 1; self:Refresh() end
function editor:GetObjectSelector() return selector end
function editor:EditObject()
    self.lazyControl = frame('Button', nil, self)
    self.lazyControl.MyObject = {type = 'switch', checked_texture = self.lazyControl:CreateTexture()}
    selector:Refresh()
    return 'edit-native'
end
modules.Details.refresh(); flush()
assert(selector.initialRefreshes == 1 and selector.lines[1].Label.text == 'Object 1', 'designer list was not populated once')
assert(editor:EditObject() == 'edit-native' and editor.lazyControl.button, 'lazy designer controls waited for queued styling')
assert(selector:Refresh() == 'selector-native' and selector.lines[1].Label.font == 'eui', 'selector row waited for queued font styling')
for _ = 1, 3 do modules.Details.refresh(); flush() end
assert(selector.initialRefreshes == 1 and not selector.lines[1].button, 'designer refresh was repeated or pooled row became an action button')
-- Shared menu/submenu ownership must not leak to another addon.
GameCooltip:SetHost(meter.baseframe.cabecalho.fechar); assert(GameCooltip:ShowCooltip() == 'menu-native')
assert(tip1.backdrop.bgFile ~= 'native-tooltip' and tip2.border[1] == 0.055 and tip1.Lines[1].leftText.font == 'eui')
GameCooltip:ShowRoundedCorner()
assert(tip1.disabled and tip2.disabled and tip1.backdrop.bgFile == 'Interface\\Buttons\\WHITE8X8', 'rounded menu art overwrote EUI shell')
assert(tip1.frameBackgroundTexture.alpha == 0 and tip2.gradientTexture.alpha == 0, 'native menu background overlays were left visible')
assert(tip1.Lines[1].background.path == 'Interface\\Buttons\\WHITE8X8' and tip1.Lines[1].background.color[4] == 0.14)
assert(tip1.Lines[1].leftIcon.color[1] == 1 and tip1.Lines[1].leftIcon.color[2] == 0 and tip1.Lines[1].action() == 'delete-native', 'semantic icon/action was changed')
local pooled = frame(); tip2.Lines[2] = pooled; pooled.leftText = font(pooled); pooled.background = pooled:CreateTexture()
GameCooltip:BuildTooltipSecondFrame()
assert(pooled.leftText.font == 'eui' and pooled.background.color[4] == 0.14, 'new submenu row was not styled synchronously')
accent = 0.8; modules.Details.refresh(); flush()
assert(tip1.Lines[1].background.color[1] == 0.8, 'open popup ignored the accent refresh')
ns.SetDetailsSetting('menus', false); flush()
assert(not tip1.disabled and tip1.frameBackgroundTexture.alpha == 1 and pooled.background.path == 'native', 'menu toggle did not restore the shared popup')
ns.SetDetailsSetting('menus', true); flush()
assert(tip1.disabled and tip1.frameBackgroundTexture.alpha == 0, 'menu toggle did not restyle the open popup')
accent = 0.4
local stranger = frame(); GameCooltip:SetHost(stranger)
assert(tip1.backdrop.bgFile == 'native-tooltip' and tip2.border[1] == 0.4 and tip1.Lines[1].leftText.font == 'native')
assert(not tip1.disabled and not tip2.disabled and tip1.frameBackgroundTexture.alpha == 1 and tip2.gradientTexture.alpha == 1, 'shared menu native layers were not restored')
assert(tip1.Lines[1].background.path == 'native' and tip1.Lines[1].divbar.crop[1] == 0.2 and tip1.Lines[1].divbar.alpha == 0.1 and pooled.leftText.font == 'native', 'pooled menu art or fonts leaked to another addon')
GameCooltip:SetHost(meter.baseframe); tip1.hooks.OnHide()
assert(tip1.backdrop.bgFile == 'native-tooltip', 'hidden menu was not restored')
GameCooltip:SetHost(stranger)
local second = instance(); Details.instances[2] = second
callbacks.DETAILS_INSTANCE_OPEN('DETAILS_INSTANCE_OPEN', second); flush()
assert(second.baseframe.cabecalho.ball.alpha == 0 and setterCalls == 2, 'late meter was not styled')
local late = row(); meter.barras[2] = late
callbacks.DETAILS_INSTANCE_NEWROW('DETAILS_INSTANCE_NEWROW', meter, late)
assert(late.lineText1.font == 'eui-meter-font' and late.textura.path == 'eui-bar')
combat = true
local deferred = row(); meter.barras[3] = deferred
callbacks.DETAILS_INSTANCE_NEWROW('DETAILS_INSTANCE_NEWROW', meter, deferred); flush()
assert(deferred.lineText1.font == 'native')
combat = false
for _, f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.hooks.OnEvent(f, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(deferred.lineText1.font == 'eui-meter-font')
_EDM_DB.profile.dm.barHeight = 20; _EDM_DB.profile.dm.barSpacing = 0
S.looks(); flush(); assert(meter.row_info.height == 20 and meter.row_info.space.between == 0 and setterCalls == 4)
assert(_EDM_DB.profile.dm.bgAlpha == 0.7, 'EUI profile was modified')
_EDM_DB, _EDM_BarTextures = nil, nil
S.looks(); flush(); assert(meter.row_info.height == 18 and r.textura.path == 'Interface\\Buttons\\WHITE8X8', 'missing EUI meter must use safe defaults')
assert(meter.baseframe.cabecalho.fechar.hooks.OnClick() == 'fechar-native', 'native close action was changed')
-- Independent controls: disabling meter matching restores its owned settings.
ns.SetDetailsSetting('meter', false); flush()
assert(meter.row_info.height == 24 and meter.row_info.space.between == 0 and meter.row_info.texture == 'native', 'meter settings not restored')
for _, icon in pairs(icons) do assert(icon.alpha == 0, 'header icon survived disabling meter matching') end
assert(meter.baseframe.cabecalho.modo_selecao.widget.alpha == 0, 'native button fade preference was changed')
assert(meter.baseframe.cabecalho.ball.alpha == 1 and r.lineText1.font == 'native', 'meter artwork/fonts not restored')
assert(ownHeader.hidden and meter.nativeTitle.alpha == 1 and meter.baseframe.cabecalho.fechar.normal.alpha == 1)
assert(meter.baseframe.cabecalho.fechar.points[1][1] == 'BOTTOMRIGHT' and meter.use_multi_fontstrings and meter.row_info.textR_show_data[3] and meter.row_info.textR_bracket == '[' and meter.row_info.textR_enable_custom_text, 'format/control placement not restored')
assert(meter.position.x == 100 and meter.segment == 3)
local menuOnlyRow = row(); meter.barras[5] = menuOnlyRow
callbacks.DETAILS_INSTANCE_NEWROW('DETAILS_INSTANCE_NEWROW', meter, menuOnlyRow)
assert(menuOnlyRow.textura.path == 'native' and DetailsOptionsWindow.shellOptions.noBorder, 'menu-only mode changed the meter')
ns.SetDetailsSetting('menus', false); flush()
GameCooltip:SetHost(meter.baseframe); GameCooltip:ShowCooltip(); assert(tip1.backdrop.bgFile == 'native-tooltip')
local untouchedOptions = frame('Frame', 'DetailsReportWindow')
modules.Details.refresh(); flush(); assert(not untouchedOptions.shell, 'disabled menu skin changed a new window')
ns.SetDetailsSetting('meter', true); flush()
assert(meter.row_info.height == 18 and menuOnlyRow.lineText1.font == 'eui-meter-font' and not untouchedOptions.shell, 'meter-only mode must not enable menus')
ns.SetDetailsSetting('meter', false); flush()
assert(meter.row_info.height == 24 and menuOnlyRow.lineText1.font == 'native', 'second toggle lost original appearance')
ns.SetDetailsSetting('meter', true); flush()
enabled = false; local disabledRow = row(); meter.barras[4] = disabledRow
callbacks.DETAILS_INSTANCE_NEWROW('DETAILS_INSTANCE_NEWROW', meter, disabledRow); modules.Details.refresh(); flush()
assert(disabledRow.textura.path == 'native' and disabledRow.lineText1.font == 'native')
assert(not meter.baseframe.hooks.OnUpdate, 'skinning must not add polling')
-- Recovery still runs if EUI never dispatches a disabled skin after reloading.
local savedProfile = next(ns.DetailsSettings().backups)
ns.DetailsSettings().meter = false
ns.DetailsSettings().backups[savedProfile][meter.meu_id] = {height = 28, spacing = 3, texture = 'pre-reload'}
meter.row_info.height = 18
for _, f in ipairs(events) do
    if f.events and f.events.PLAYER_LOGIN and f.events.ADDON_LOADED and not f.events.PLAYER_REGEN_ENABLED then
        f.hooks.OnEvent(f, 'PLAYER_LOGIN')
    end
end
assert(meter.row_info.height == 28 and meter.row_info.space.between == 3 and meter.row_info.texture == 'pre-reload', 'disabled-skin reload recovery failed')
ns.DetailsSettings().backups[savedProfile][meter.meu_id] = {height = 29, spacing = 2, texture = 'pre-profile'}
assert(Details:ApplyProfile() == 'profile-native')
assert(meter.row_info.height == 29 and meter.row_info.texture == 'pre-profile', 'disabled-skin profile recovery failed')
-- Separate Details profiles must not inherit another profile's baseline.
enabled = true
local profileName = 'Profile A'
Details.GetCurrentProfileName = function() return profileName end
ns.SetDetailsSetting('meter', true); flush()
profileName = 'Profile B'
meter.row_info.height, meter.row_info.space.between, meter.row_info.texture = 35, 4, 'profile-b'
callbacks.DETAILS_PROFILE_APPLYED('DETAILS_PROFILE_APPLYED'); flush()
ns.SetDetailsSetting('meter', false); flush()
assert(meter.row_info.height == 35 and meter.row_info.space.between == 4 and meter.row_info.texture == 'profile-b', 'restoration crossed profile boundaries')
-- Quick controls append to the settings pop-out without replacing native entries.
assert(ns.DetailsSettings().tiny == false, 'Tiny Threat must be opt-in for new installations')
GameCooltip:Reset(); GameCooltip:AddLine('Native entry')
Details:SetMenuOwner(meter.baseframe.cabecalho.fechar, meter)
assert(#GameCooltip.entries == 1, 'submenu added to an unrelated pop-out')
local gear = meter.baseframe.cabecalho.modo_selecao.widget
assert(Details:SetMenuOwner(gear, meter) == 'owner-native')
assert(#GameCooltip.entries == 6 and GameCooltip.entries[1].text == 'Native entry')
assert(GameCooltip.entries[2].text == 'EUI AddonSkins' and GameCooltip.entries[3].level == 2)
Details:SetMenuOwner(gear, meter); assert(#GameCooltip.entries == 6, 'submenu duplicated during reuse')
GameCooltip.entries[6].action(); assert(openedCategory == 123)
GameCooltip.entries[4].action(); flush()
assert(ns.DetailsSettings().tiny and GameCooltip.hidden, 'Tiny Threat menu toggle did not apply')
GameCooltip.entries[4].action(); flush(); assert(not ns.DetailsSettings().tiny)
assert(GameCooltip.entries[5].text:find('reload'), 'menu setting must explain reload')
GameCooltip:Reset(); Details:SetMenuOwner(gear, meter)
assert(#GameCooltip.entries == 5, 'reset did not rebuild the submenu exactly once')
-- Tiny Threat is a plugin hosted by one Details instance; DF rows are wrappers.
local tinyHost = instance(); tinyHost.modo = 4; tinyHost.current_raid_plugin = 'DETAILS_PLUGIN_TINY_THREAT'
Details.instances[3] = tinyHost
local bar = frame('StatusBar'); bar.fill = bar:CreateTexture()
bar.lefttext, bar.righttext = font(bar), font(bar)
bar.lefttext:SetText('Tank'); bar.righttext:SetText('100%'); bar.lefttext:SetTextColor(1, 0, 0, 1)
bar.GetStatusBarTexture = function(self) return self.fill end
local tinyRow = {widget = bar}
local tiny = {Rows = {tinyRow}, GetPluginInstance = function() return tinyHost end,
    RefreshRow = function(_, r)
        r.widget.fill:SetTexture('tiny-native'); r.widget.lefttext:SetFont('tiny-font'); r.widget.righttext:SetFont('tiny-font')
        return 'tiny-native-return'
    end}
tiny.RefreshRows = function(self) for _, r in ipairs(self.Rows) do self:RefreshRow(r) end end
Details.GetPlugin = function(_, id) if id == 'DETAILS_PLUGIN_TINY_THREAT' then return tiny end end
tiny:RefreshRows(); ns.SetDetailsSetting('meter', true); flush()
assert(meter.row_info.height == 18 and tinyHost.row_info.height == 24 and bar.lefttext.font == 'tiny-font', 'Details toggle leaked into Tiny Threat')
ns.SetDetailsSetting('tiny', true); flush()
assert(tinyHost.row_info.height == 18 and bar.lefttext.font == 'eui-meter-font' and bar.fill.path == 'Interface\\Buttons\\WHITE8X8')
assert(tinyHost.use_multi_fontstrings and tinyHost.row_info.textR_show_data[3], 'Tiny Threat inherited damage-number formatting')
for _ = 1, 3 do modules.Details.refresh(); flush() end
local writes = bar.lefttext.writes
assert(tiny:RefreshRow(tinyRow) == 'tiny-native-return' and bar.lefttext.font == 'eui-meter-font', 'native Tiny redraw lost styling or return value')
assert(bar.lefttext.writes - writes == 2, 'Tiny Threat refresh hook was duplicated')
assert(bar.lefttext.text == 'Tank' and bar.righttext.text == '100%' and bar.lefttext.textColor[2] == 0, 'Tiny Threat data/colours changed')
ns.SetDetailsSetting('meter', false); flush()
assert(meter.row_info.height == 35 and tinyHost.row_info.height == 18 and bar.lefttext.font == 'eui-meter-font', 'independent Tiny-only mode failed')
ns.SetDetailsSetting('tiny', false); flush()
assert(tinyHost.row_info.height == 24 and bar.lefttext.font == 'tiny-font' and bar.fill.path == 'tiny-native', 'Tiny Threat toggle did not restore native style')
ns.SetDetailsSetting('tiny', true); flush()
tinyHost.modo = 2; modules.Details.refresh(); flush()
assert(tinyHost.row_info.height == 24, 'leaving Tiny Threat retained its host styling')
tinyHost.modo = 4; modules.Details.refresh(); flush()
assert(tinyHost.row_info.height == 18 and bar.lefttext.font == 'eui-meter-font', 'returning to Tiny Threat did not restyle')
combat = true; ns.SetDetailsSetting('tiny', false); flush()
assert(tinyHost.row_info.height == 18, 'combat toggle changed UI immediately')
combat = false
for _, f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.hooks.OnEvent(f, 'PLAYER_REGEN_ENABLED') end end
flush()
assert(tinyHost.row_info.height == 24 and bar.lefttext.font == 'tiny-font', 'combat-deferred independent restoration failed')
ns.SetDetailsSetting('meter', true); flush()
tinyHost.baseframe.cabecalho.ball:SetAlpha(0.7)
assert(tinyHost.baseframe.cabecalho.ball.alpha == 0.7, 'disabled Tiny window retained a fade guard from Details')
-- A retained instance can have saved appearance settings but no live window.
local retained = instance()
retained.baseframe = nil
retained.ChangeSkin = function(self)
    assert(self.baseframe, 'ChangeSkin called without a live window')
    self.skinResets = (self.skinResets or 0) + 1
end
Details.instances[4] = retained
local backups = ns.DetailsSettings().backups
local profile = '::' .. profileName
assert(backups[profile], 'fixture profile is missing')
backups[profile][retained.meu_id] = {height = 27, spacing = 3, texture = 'retained-native'}
retained.row_info.height = 18
ns.SetDetailsSetting('meter', false); flush()
assert(retained.row_info.height == 27 and retained.row_info.space.between == 3 and retained.row_info.texture == 'retained-native', 'unbuilt instance settings were not restored')
assert(not retained.skinResets and not backups[profile][retained.meu_id], 'unbuilt instance reset or backup was retained')
-- A previously styled window may also disappear before the toggle is clicked.
ns.SetDetailsSetting('meter', true); flush()
local existingFrame = meter.baseframe
meter.baseframe = nil
meter.ChangeSkin = retained.ChangeSkin
ns.SetDetailsSetting('meter', false); flush()
assert(not meter.skinResets and meter.row_info.height == 35, 'closed instance restoration called its renderer or lost settings')
meter.baseframe = existingFrame
ns.SetDetailsSetting('meter', true); flush()
assert(meter.row_info.height == 18, 'restored window could not be styled again')
-- Native header redraws must never introduce sibling anchor cycles.
local isolated = instance()
local activeLayout = true
local helper = ns.CreateSkinHelper(S, modules.Details)
local layout = ns.CreateDetailsLayout(helper, function() return activeLayout end, function() end, function() end)
local controls = {}
for _, key in ipairs({'modo_selecao', 'segmento', 'atributo', 'report', 'reset', 'fechar'}) do
    local obj = isolated.baseframe.cabecalho[key]
    controls[#controls + 1] = obj.widget or obj
end
local nativePrevious = isolated.baseframe
for _, b in ipairs(controls) do b:ClearAllPoints(); b:SetPoint('RIGHT', nativePrevious, 'LEFT', -4, 0); nativePrevious = b end
layout.Window(isolated, ns.GetMeterStyle(S))
-- Native order reverses our old sibling chain: this failed before the fix.
controls[2]:ClearAllPoints(); controls[2]:SetPoint('RIGHT', controls[1], 'LEFT', -4, 0)
assert(controls[1].points[1][2] == controls[2].points[1][2], 'custom buttons should anchor independently to the header')
local clearing, firstRestorePoint = {}, true
activeLayout = false
for _, b in ipairs(controls) do
    local clear, set = b.ClearAllPoints, b.SetPoint
    b.ClearAllPoints = function(self) clearing[self] = true; clear(self) end
    b.SetPoint = function(self, ...)
        if firstRestorePoint then
            for _, other in ipairs(controls) do assert(clearing[other], 'restoring anchors before all custom links were cleared') end
            firstRestorePoint = false
        end
        return set(self, ...)
    end
end
layout.Restore()
for i, b in ipairs(controls) do assert(b.points[1][2] == (i == 1 and isolated.baseframe or controls[i-1]), 'native anchor graph was not restored') end
-- Release EUI anchors before native ChangeSkin starts rebuilding its graph.
local nativeResetChecked = false
meter.ChangeSkin = function(self)
    local button = self.baseframe.cabecalho.modo_selecao.widget
    assert(button.points[1][2] == self.baseframe, 'native renderer ran before releasing the custom layout')
    nativeResetChecked = true
    return 'skin-native'
end
ns.SetDetailsSetting('meter', false); flush()
assert(nativeResetChecked, 'restoration did not rebuild the live native skin')
-- Source-shaped modern menu refresh: button has OnEnter, no injected CoolTip.
local attribute = meter.baseframe.cabecalho.atributo.widget
assert(not attribute.CoolTip)
attribute:SetScript('OnEnter', function(self, motion, forced, fromClick)
    assert(self == attribute and forced and fromClick, 'native menu refresh arguments changed')
    meter.menuRefreshed = (meter.menuRefreshed or 0) + 1
    Details:MontaRaidOption(meter)
end)
-- Adapt only the exact native raid callbacks; retain arguments and other actions.
for _ = 1, 3 do
    assert(Details:MontaRaidOption(meter) == 'raid-menu-native')
    assert(GameCooltip.FunctionsTableMain[1] == unrelatedAction)
    for index, id in ipairs({'compare', 'vanguard'}) do
        local callback = GameCooltip.FunctionsTableMain[index + 1]
        GameCooltip:SetHost(attribute)
        local before = meter.menuRefreshed or 0
        local result, fixed, empty, tail = callback(attribute, 'fixed-native', id, meter)
        assert(result == 'switch-native' and fixed == 'fixed-native' and empty == nil and tail == 'tail-native' and meter.selectedPlugin == id and meter.menuRefreshed == before + 1, 'raid callback lost its native receiver/arguments/returns/menu refresh')
    end
end
-- Do not reopen a menu if the plugin changes its owner during activation.
local bound = GameCooltip.FunctionsTableMain[2]
GameCooltip:SetHost(stranger)
local before = meter.menuRefreshed
bound(attribute, 'fixed-native', 'compare', meter)
assert(meter.menuRefreshed == before and GameCooltip:GetOwner() == stranger, 'plugin callback hijacked a different popup')
-- A missing modern handler safely closes the old selection menu.
attribute:SetScript('OnEnter', nil); GameCooltip:SetHost(attribute); GameCooltip.hidden = false
bound(attribute, 'fixed-native', 'vanguard', meter)
assert(GameCooltip.hidden and meter.selectedPlugin == 'vanguard', 'missing menu handler did not close safely')
local currentSettings = EUIAddonSkinsDB.details
EUIAddonSkinsDB.details = {meter = true, menus = false}
assert(ns.DetailsSettings().tiny == true, 'existing meter users lost Tiny Threat appearance during migration')
EUIAddonSkinsDB.details.tiny = false
assert(ns.DetailsSettings().tiny == false, 'migration overwrote an explicit Tiny Threat choice')
EUIAddonSkinsDB.details = currentSettings
print('PASS: Details quick submenu, independent Tiny Threat modes, native plugin redraws/restoration, meter styles, actions/data, dynamic controls, themes and combat guards')
