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
    function t:SetDesaturated(v) self.desaturated = v end
    function t:SetBlendMode(v) self.blendMode = v end
    function t:SetRotation(v) self.rotation = v end
    function t:SetGradientAlpha(...) self.gradient = {...} end
    function t:GetNumMaskTextures() return self.masked and 1 or 0 end
    function t:SetText(s) assert(self.font, "FontString:SetText(): Font not set"); self.text = s end
    function t:GetFont() return self.font, self.font and (self.fontSize or 12), '' end
    function t:SetFont(v, size) self.font, self.fontSize = v, size; self.fontWrites = (self.fontWrites or 0) + 1 end
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
function S.Font(t, r, g, b) local _, size = t:GetFont(); t:SetFont('eui', size or 12); if r then t:SetTextColor(r, g, b) end end
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
function S.EditBox(f, options) f.input = true; f.inputOptions = options end
function S.Dropdown(f) f.dropdown = true end
function S.FadeNineSlice() end
SetPortraitTexture = function(t) t:SetTexture('player-face') end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
local auditScans = setmetatable({}, {__mode = 'k'})
local auditHelper = ns.CreateSkinHelper
ns.CreateSkinHelper = function(...)
    local H = auditHelper(...); local scan = H.Scan
    H.Scan = function(root, ...) auditScans[root] = (auditScans[root] or 0) + 1; return scan(root, ...) end
    return H
end
local auditBaseline = os.getenv('EUI_AUDIT_BASELINE') == '1'

local H = ns.CreateSkinHelper(S, {})
-- Scoped soft borders preserve EUI fill, hover, icons, scrollbars and other skins.
local softAPI = setmetatable({}, {__index = S})
local createdBorders = 0
local function primitive(f)
    if f.softFixture then return end
    f.softFixture = true
    f.fill = f:CreateTexture(); f.fill:SetColorTexture(0.08, 0.08, 0.08, 0.92)
    f.hover = f:CreateTexture(); f.hover:SetColorTexture(1, 1, 1, 0.1)
    local border = frame('Frame', nil, f); f.pixelBorder = border; createdBorders = createdBorders + 1
    for i = 1, 4 do
        local edge = border:CreateTexture(); edge:SetColorTexture(0.2, 0.2, 0.2, 1)
        edge.GetDrawLayer = function() return 'BORDER' end
        edge.GetWidth = function() return i <= 2 and 100 or 1 end
        edge.GetHeight = function() return i <= 2 and 1 or 24 end
    end
end
softAPI.Button, softAPI.Dropdown, softAPI.Checkbox = primitive, primitive, primitive
softAPI.Panel = function(f, options) f.options = options end
softAPI.PageButton = function(f, glyph) primitive(f); f.glyph = glyph end
softAPI.EditBox = softAPI.Panel
softAPI.Shell = softAPI.Panel
local soft = ns.CreateSoftSkin(softAPI, {})
local ordinary = frame('Button'); ordinary.Icon = ordinary:CreateTexture(); ordinary.Icon.path = 'semantic-icon'
local unrelated = frame('Frame', nil, ordinary); local line = unrelated:CreateTexture(); line:SetColorTexture(0.2, 0.2, 0.2, 1)
soft.Button(ordinary)
assert(ordinary.pixelBorder.regions[1].color[1] == 0.055 and line.color[1] == 0.2)
assert(ordinary.fill.color[1] == 0.08 and ordinary.hover.color[4] == 0.1 and ordinary.Icon.path == 'semantic-icon')
local hook = ordinary.pixelBorder.regions[1].SetColorTexture
ordinary.pixelBorder.regions[1]:SetColorTexture(0.25, 0.25, 0.25, 1)
assert(ordinary.pixelBorder.regions[1].color[1] == 0.055)
for _ = 1, 5 do soft.Button(ordinary); soft.RefreshSoftBorders() end
assert(createdBorders == 1 and ordinary.pixelBorder.regions[1].SetColorTexture == hook)
local stock = frame('Button'); softAPI.Button(stock); assert(stock.pixelBorder.regions[1].color[1] == 0.2)
local panel, input = frame(), frame('EditBox')
local opts = {padInput = true}; soft.Panel(panel); soft.EditBox(input, opts)
assert(panel.options.noBorder and panel.options.inset and input.options.noBorder and input.options.padInput and not opts.noBorder)
assert(soft.ScrollBar == S.ScrollBar and soft.PageButton == softAPI.PageButton and soft.SquareIcon == S.SquareIcon)
local page, stepper = frame('Button'), frame('Button')
soft.SoftPageButton(page, '>'); soft.PageButton(stepper, '^')
assert(page.glyph == '>' and page.pixelBorder.regions[1].color[1] == 0.055)
assert(stepper.glyph == '^' and stepper.pixelBorder.regions[1].color[1] == 0.2, 'scroll steppers must keep their chrome')
combat = true; ordinary.pixelBorder.regions[1]:SetColorTexture(0.2, 0.2, 0.2, 1)
assert(ordinary.pixelBorder.regions[1].color[1] == 0.2)
combat = false; soft.RefreshSoftBorders(); assert(ordinary.pixelBorder.regions[1].color[1] == 0.055)
enabled = false; ordinary.pixelBorder.regions[1]:SetColorTexture(0.2, 0.2, 0.2, 1); assert(ordinary.pixelBorder.regions[1].color[1] == 0.2)
enabled = true
-- Asset identifiers must never reach SquareIcon; mixed rows retain the real Texture.
for _, asset in ipairs({134400, "Interface/Icons/Test", true}) do
    local row = frame('Button'); row.icon = asset; row.Icon = texture()
    H.Scan(row, function() end)
    assert(row.Icon.crop and H.Icon(row) == row.Icon)
    local primitive = frame('Button'); primitive.icon = asset
    H.Scan(primitive, function() end)
    assert(not H.Icon(primitive))
end
local forbidden = texture(); forbidden.IsForbidden = function() return true end
assert(not H.Texture(forbidden) and not H.Texture(texture('FontString')))
local node = frame('Button', 'Attune_Node_Test')
node:SetBackdrop({bgFile = 'native-fill', edgeFile = 'native-bevel', edgeSize = 16})
node:SetBackdropColor(0.37, 0.72, 0.27, 0.3); node:SetBackdropBorderColor(0.37, 0.72, 0.27, 1)
node.action = function() return 'quest-original' end
H.ThinBackdrop(node)
assert(node.backdrop.edgeSize == 1 and node.color[1] == 0.37 and node.border[2] == 0.72 and node.action() == 'quest-original')
node:SetBackdrop({bgFile = 'native-fill', edgeFile = 'native-bevel', edgeSize = 16})
assert(node.backdrop.edgeSize == 1, 'native redraw restored bevel')
local button = frame('Button'); button.normal = texture(); button.regions = {button.normal}
button.action = function() return 'original-toggle' end
H.Toggle(button, false); H.Toggle(button, true)
assert(button.regions[2].text == '-' and #button.regions == 2 and button.normal.alpha == 0 and button.action() == 'original-toggle')
local slider = frame('Slider'); local thumb = texture(); slider.regions = {texture(), thumb}
slider.GetThumbTexture = function() return thumb end; slider.GetOrientation = function() return 'HORIZONTAL' end
slider.value, slider.min, slider.max, slider.step = 0.75, 0.5, 1, 0.01
slider.hooks.OnValueChanged = function() return 'zoom-original' end
H.LegacySlider(slider); local count = #slider.regions
accent = 0.8; H.LegacySlider(slider)
assert(slider.regions[#slider.regions].alpha == 1 and thumb.color[1] == 0.8 and #slider.regions == count and slider.value == 0.75 and slider.hooks.OnValueChanged() == 'zoom-original')
local chrome = frame(); chrome.PortraitContainer = frame()
local portrait = texture(); portrait.path = 'quest-scroll'; portrait.masked = true
chrome.PortraitContainer.portrait = portrait; chrome.PortraitContainer.regions = {portrait}
H.Portrait(chrome)
local square = chrome.regions[1]
assert(square.path == 'quest-scroll' and square.width == 28 and square.points[1][4] == 8 and portrait.alpha == 0 and square.borderParent == chrome)
H.Portrait(chrome); assert(#chrome.regions == 1 and chrome.accent)
H.Portrait(chrome, true); assert(square.path == 'player-face' and square.crop[1] == 0.2)
-- Exercise the adapters, not just utility primitives.
local modules = {}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Skins/Attune.lua'))('EUIAddonSkins', ns)
Attune_MainFrame = frame('Frame', 'Attune_MainFrame'); Attune_GraphRoot = frame('Frame', 'Attune_GraphRoot', Attune_MainFrame)
local card = frame('Button', 'Attune_Node_42', Attune_GraphRoot)
card:SetBackdrop({edgeFile = 'native', bgFile = 'fill'}); card:SetBackdropColor(0.8, 0.6, 0, 0.3)
local text = card:CreateFontString(); text:SetTextColor(1, 0.8, 0)
local icon = frame('Button', 'Attune_Icon_42', card); icon.normal = texture(); icon.normal.path = 'quest-icon'
local graphLine = Attune_GraphRoot:CreateTexture(); graphLine.color = {0.8, 0.6, 0, 1}
modules.Attune.install(S, modules.Attune)
local function flush()
    while #timers > 0 do local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end end
end
flush()
assert(Attune_MainFrame.shellOptions.noBorder, 'Attune soft window border missing')
assert(card.backdrop.edgeSize == 1 and card.color[1] == 0.8 and text.font == 'eui' and text.textColor[1] == 1)
assert(not card.button and icon.normal.path == 'quest-icon' and icon.normal.crop and graphLine.color[1] == 0.8)
local tree = frame('Button', nil, Attune_MainFrame)
tree.treeline, tree.selected, tree.text, tree.icon = {}, true, tree:CreateFontString(), tree:CreateTexture()
tree.icon.path = 'dungeon-status-art'; tree.toggle = frame('Button', nil, tree)
tree.toggle.normal = texture(); tree.toggle.normal.path = 130821
modules.Attune.refresh(); flush()
assert(tree.icon.path == 'dungeon-status-art' and tree.icon.alpha == 1 and tree.euiSelection.color[4] == 0.2)
assert(tree.toggle.regions[1].text == '-')
assert(loadfile('EUIAddonSkins/Skins/Altoholic.lua'))('EUIAddonSkins', ns)
AltoholicFrame = frame('Frame', 'AltoholicFrame'); AltoholicFrame.Tabs = {}
local mixedRow = frame('Button', nil, AltoholicFrame); mixedRow.icon = 134400; mixedRow.Icon = texture()
local assetRow = frame('Button', nil, AltoholicFrame); assetRow.icon = 134400
local owner = frame('Frame', nil, AltoholicFrame)
owner.AddButtonInfo = function() end
owner.Initialize = function(self) self.initialize = function() end; return 'init-original' end
owner.Toggle = function() return 'toggle-original' end
local pool = frame('Button')
local mvc = {BindViewToController = function(_, proxy) proxy.GetListFromPool = function(_, level) if level == 1 then return pool end end end}
LibStub = function(name) if name == 'LibMVC-1.0' then return mvc end end
local bindings = 0
ns.BindPopupOwner = function() end
ns.BindPopupList = function(_, _, boundOwner, list) assert(boundOwner == owner and list == pool); bindings = bindings + 1 end
modules.Altoholic.install(S, modules.Altoholic); flush()
assert(mixedRow.Icon.crop and mixedRow.button)
assert(AltoholicFrame.shellOptions.noBorder, 'Altoholic soft chrome must stay scoped to its window')
assert(owner:Initialize() == 'init-original' and owner:Toggle() == 'toggle-original' and bindings >= 3)
do
-- AddonFactory scroll borders live on the scrollframe, not the slider.
local altoScroll = frame('ScrollFrame', nil, AltoholicFrame)
for _, key in ipairs({'scrollBorderTop', 'scrollBorderMiddle', 'scrollBorderBottom', 'scrollFrameScrollBarBackground'}) do
    altoScroll[key] = altoScroll:CreateTexture()
end
local altoBar = frame('Slider', nil, altoScroll); altoScroll.ScrollBar = altoBar
local altoThumb = altoBar:CreateTexture(); altoThumb:SetSize(18, 24); altoThumb:SetTexCoord(0.2, 0.8, 0.125, 0.875)
altoBar.GetThumbTexture = function() return altoThumb end
altoBar.GetOrientation = function() return 'VERTICAL' end
altoBar.ScrollUpButton, altoBar.ScrollDownButton = frame('Button', nil, altoBar), frame('Button', nil, altoBar)
altoBar.value, altoBar.minimum, altoBar.maximum = 12, 0, 300
altoBar:SetPoint('TOPRIGHT', altoScroll, 'TOPRIGHT', -20, -18)
altoBar.ScrollUpButton.hooks.OnClick = function() altoBar.value = altoBar.value - 12; return 'scroll-up-native' end
altoBar.ScrollDownButton.hooks.OnClick = function() altoBar.value = altoBar.value + 12; return 'scroll-down-native' end
-- Realm rows leave their final two pooled cells visible; character rows need them.
local realmRow = frame('Button', nil, AltoholicFrame); realmRow.Collapse = frame('Button', nil, realmRow)
for i = 1, 12 do realmRow['Item' .. i] = frame('Button', nil, realmRow) end
realmRow.DrawRealmLine = function(self)
    self.character = nil; self.Collapse:Show()
    for i = 2, 10 do self['Item' .. i]:Hide() end
    return 'realm-native'
end
realmRow.DrawCharacterLine = function(self)
    self.character = 'character'; self.Collapse:Hide()
    for i = 1, 12 do self['Item' .. i]:Show() end
    return 'character-native'
end
modules.Altoholic.refresh(); flush()
for _, key in ipairs({'scrollBorderTop', 'scrollBorderMiddle', 'scrollBorderBottom', 'scrollFrameScrollBarBackground'}) do assert(altoScroll[key].alpha == 0, 'Altoholic retained native scroll border') end
assert(altoThumb.width == 8 and altoThumb.height == 18 and altoThumb.crop[1] == 0 and altoThumb.crop[2] == 1 and altoThumb.path == 'solid')
assert(altoBar.ScrollUpButton.glyph == '^' and altoBar.ScrollDownButton.glyph == 'v')
altoBar.ScrollUpButton.hooks.OnClick(); assert(altoBar.value == 0, 'native scroll-up action changed')
altoBar.ScrollDownButton.hooks.OnClick(); assert(altoBar.value == 12 and altoBar.maximum == 300 and altoBar.points[1][4] == -20, 'native scrolling range or anchors changed')
assert(not realmRow.Item11:IsShown() and not realmRow.Item12:IsShown() and realmRow.Item1:IsShown())
local realmHook, objectCount = realmRow.DrawRealmLine, #altoBar.regions
for _ = 1, 3 do modules.Altoholic.refresh(); flush() end
assert(realmRow.DrawRealmLine == realmHook and #altoBar.regions == objectCount, 'Altoholic hooks/textures duplicated')
assert(realmRow:DrawCharacterLine() == 'character-native'); modules.Altoholic.refresh(); flush()
assert(realmRow.Item11:IsShown() and realmRow.Item12:IsShown(), 'valid character cells were hidden')
assert(realmRow:DrawRealmLine() == 'realm-native' and not realmRow.Item11:IsShown() and not realmRow.Item12:IsShown(), 'reused realm row exposed empty cells')
combat = true; altoThumb:SetSize(18, 24); modules.Altoholic.refresh(); flush(); assert(altoThumb.width == 18)
combat = false
for _, f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.hooks.OnEvent(f, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(altoThumb.width == 8)
enabled = false; realmRow.Item11:Show(); realmRow.Item12:Show(); realmRow:DrawRealmLine()
assert(realmRow.Item11:IsShown() and realmRow.Item12:IsShown(), 'disabled Altoholic skin processed realm rows')
enabled = true
-- Native category rebuilds reset atlas textures and font objects every click.
do
    local categories = frame('Frame', nil, AltoholicFrame); categories.Buttons = {}
    local function Category()
        local b = frame('Button', nil, categories)
        b.Text = b:CreateFontString(nil, nil, 'native-font')
        for _, key in ipairs({'NormalTexture', 'SelectedTexture', 'HighlightTexture'}) do
            b[key] = b:CreateTexture()
            b[key].SetAtlas = function(self, atlas) self.path = atlas end
        end
        b.SetData = function(self, data) self.data = data end
        b.SetSelected = function(self, data) self.SelectedTexture:SetShown(data.isSelected == true); return 'selected-native' end
        b.SetCategory = function(self, text)
            self.Text:SetText(text); self.Text:SetPoint('LEFT', self, 'LEFT', 8, 0)
            self.Text:SetFont('native-font'); self.NormalTexture:SetAtlas('auctionhouse-nav-button'); self.NormalTexture:SetAlpha(1)
            return 'category-native'
        end
        b.SetSubCategory = function(self, text)
            self.Text:SetText(text); self.Text:SetPoint('LEFT', self, 'LEFT', 18, 0)
            self.Text:SetFont('native-font'); self.NormalTexture:SetAtlas('auctionhouse-nav-button-secondary'); self.NormalTexture:SetAlpha(1)
            return 'subcategory-native'
        end
        b.SetSubSubCategory = function(self, text)
            self.Text:SetText(text); self.Text:SetPoint('LEFT', self, 'LEFT', 26, 0)
            self.Text:SetFont('native-font'); self.NormalTexture:SetAlpha(0)
            return 'nested-native'
        end
        return b
    end
    categories.Buttons = {Category(), Category()}
    categories.UpdateCategories = function(self)
        for i, b in ipairs(self.Buttons) do
            b:SetCategory('Category ' .. i); b:SetData({isSelected = i == self.selected}); b:SetSelected(b.data)
        end
        return 'rebuild-native'
    end
    categories.selected = 1
    modules.Altoholic.refresh(); flush()
    assert(categories:UpdateCategories() == 'rebuild-native')
    for i, b in ipairs(categories.Buttons) do
        assert(b.NormalTexture.alpha == 0 and b.SelectedTexture.alpha == 0 and b.HighlightTexture.alpha == 0 and b.Text.font == 'eui', 'native category redraw escaped EUI styling')
        assert(b.euiSelection.color[4] == (i == 1 and 0.2 or 0), 'category selection was lost')
    end
    local category = categories.Buttons[2]
    assert(category:SetSubCategory('Experience') == 'subcategory-native' and category.NormalTexture.alpha == 0 and category.Text.font == 'eui')
    assert(category.Text.points[#category.Text.points][4] == 18, 'subcategory indentation changed')
    assert(category:SetSubSubCategory('Nested') == 'nested-native' and category.Text.points[#category.Text.points][4] == 26)
    categories.selected = 2; categories:UpdateCategories()
    assert(categories.Buttons[1].euiSelection.color[4] == 0 and category.euiSelection.color[4] == 0.2, 'selection did not move synchronously')
    local hooks, regions = category.SetCategory, #category.regions
    for _ = 1, 10 do categories:UpdateCategories(); modules.Altoholic.refresh(); flush() end
    assert(category.SetCategory == hooks and #category.regions == regions, 'category hooks or selection textures duplicated')
    categories.Buttons[3] = Category(); categories:UpdateCategories()
    assert(categories.Buttons[3].Text.font == 'eui' and categories.Buttons[3].NormalTexture.alpha == 0, 'late category button was not skinned synchronously')
    accent = 0.9; modules.Altoholic.refresh(); flush(); assert(category.euiSelection.color[1] == 0.9)
    enabled = false; category:SetCategory('Disabled'); assert(category.NormalTexture.alpha == 1 and category.Text.font == 'native-font', 'disabled skin processed a category redraw')
    enabled = true
end
end

-- ItemRack options: native scripts and equipment semantics survive restyling.
do
    assert(loadfile('EUIAddonSkins/Skins/ItemRack.lua'))('EUIAddonSkins', ns)
    local checkbox, inset, getFFD = S.Checkbox, S.Inset, S.GetFFD
    S.Checkbox = function(f, opts) f.checkOptions = opts; checkbox(f) end
    S.Inset = function(f) f.inset = true end
    ItemRackOptFrame = frame('Frame', 'ItemRackOptFrame')
    local root = ItemRackOptFrame
    local sets = frame('Frame', 'ItemRackOptSubFrame2', root)
    sets.gradient = sets:CreateTexture(); sets.gradient.layer = 'BACKGROUND'; sets:SetBackdrop({edgeFile = 'bevel'})
    local artwork = sets:CreateTexture(); artwork.layer = 'ARTWORK'; artwork.path = 'semantic-art'
    for _, side in ipairs({'Left', 'Middle', 'Right'}) do _G['ItemRackOptSetsDropTexture' .. side] = sets:CreateTexture() end
    local choose = frame('Button', 'ItemRackOptSetsDropDownButton', sets)
    choose.action = function() return 'choose-set' end
    local move = frame('Button', 'ItemRackOptSortMoveUp', root)
    move.action = function() return 'move-native' end
    local slot = frame('CheckButton', 'ItemRackOptInv7', root)
    ItemRackOptInv7Icon = slot:CreateTexture(); slot.normal = slot:CreateTexture()
    slot.checked = true; slot.action = function() return 'select-equipment' end
    local check = frame('CheckButton', 'ItemRackOptQueueEnable', root); check.checked = true
    local tristate = frame('CheckButton', 'ItemRackOptShowHelm', sets)
    local triCheck = tristate:CreateTexture(); triCheck.color = {0.5, 0.5, 0.5, 1}
    tristate.GetCheckedTexture = function() return triCheck end
    local horizontal = frame('Slider', 'ItemRackOptSlider1', root)
    local hthumb = horizontal:CreateTexture(); horizontal.GetThumbTexture = function() return hthumb end
    horizontal.GetOrientation = function() return 'HORIZONTAL' end
    horizontal.value, horizontal.range = 1, {0.5, 2}
    horizontal.hooks.OnValueChanged = function() return 'scale-native' end
    local vertical = frame('Slider', 'ItemRackOptSetsIconScrollFrameScrollBar', sets)
    local vthumb = vertical:CreateTexture(); vertical.GetThumbTexture = function() return vthumb end
    vertical.GetOrientation = function() return 'VERTICAL' end
    local row = frame('Button', 'ItemRackOptSortList1', root)
    ItemRackOptSortList1Icon = row:CreateTexture()
    ItemRackOptSortList1Highlight = row:CreateTexture(); ItemRackOptSortList1Highlight:SetShown(true)
    local label = row:CreateFontString(nil, nil, 'native'); label.textColor = {0, 0.44, 0.87}
    row.action = function() return 'queue-selection' end
    ItemRackMenuFrame = frame('Frame', 'ItemRackMenuFrame')
    local menu = ItemRackMenuFrame
    local function MenuItem(index)
        local f = frame('CheckButton', 'ItemRackMenu' .. index, menu)
        _G[f.name .. 'Icon'] = f:CreateTexture(); f.normal = f:CreateTexture()
        f.action = function() return 'equip-native' end
        return f
    end
    local item = MenuItem(1)
    local secure = MenuItem(2); secure.protected = true; secure.attributes = {macro = 'equip'}
    local config = frame('Frame', 'ItemRackOptSubFrame1', root)
    local gradient = config:CreateTexture(); gradient.layer = 'BACKGROUND'
    local configRows = {}
    for index = 1, 5 do
        local row = frame('Button', 'ItemRackOptList' .. index, config)
        row.GetWidth = function() return 156 end
        configRows[index] = row
        for _, suffix in ipairs({'Label', 'CheckText', 'NumberLabel'}) do
            _G[row.name .. suffix] = row:CreateFontString(nil, nil, 'native')
        end
        _G[row.name .. 'Underline'] = row:CreateTexture()
        frame('CheckButton', row.name .. 'CheckButton', row)
    end
    local tick = ItemRackOptList3CheckButton:CreateTexture(); tick.path = 'gold-check'
    ItemRackOptList3CheckButton.GetCheckedTexture = function() return tick end
    ItemRackOptList3CheckButton.checked = true
    local setPicker = frame('Frame', 'ItemRackOptSubFrame5', root)
    local anonymous = frame('Frame', nil, setPicker)
    anonymous:SetBackdrop({edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border'})
    local anonymousGradient = anonymous:CreateTexture(); anonymousGradient.layer = 'BACKGROUND'
    local setRow = frame('Button', 'ItemRackOptSetList1', anonymous)
    ItemRackOptSetList1Icon = setRow:CreateTexture(); ItemRackOptSetList1Icon.path = 'set-art'
    ItemRackOptSetList1Highlight = setRow:CreateTexture(); ItemRackOptSetList1Highlight.shown = false
    local setLabel = setRow:CreateFontString(nil, nil, 'native'); setLabel.textColor = {0.7, 0.7, 0.7, 1}
    setRow.action = function() return 'select-set-native' end
    local pickerClose = frame('Button', 'ItemRackOptSetListClose', anonymous)
    pickerClose.action = function() return 'close-native' end
    local unrelated = frame('Frame', nil, root)
    local unrelatedArt = unrelated:CreateTexture(); unrelatedArt.layer = 'BACKGROUND'
    local grid = frame('Frame', 'ItemRackOptSetsIconFrame', sets)
    local gridGradient = grid:CreateTexture(); gridGradient.layer = 'BACKGROUND'
    grid:SetBackdrop({edgeFile = 'native-border'})
    local function SetIcon(index)
        local button = frame('Button', 'ItemRackOptSetsIcon' .. index, grid)
        _G[button.name .. 'Icon'] = button:CreateTexture()
        button.highlight = button:CreateTexture(); button.highlight.path = 'gold-highlight'
        button.GetHighlightTexture = function(self) return self.highlight end
        button.action = function() return 'set-icon-native' end
        return button
    end
    local gridIcon = SetIcon(1); gridIcon.highlight.shown = true
    local preview = frame('CheckButton', 'ItemRackOptSetsCurrentSet', sets)
    ItemRackOptSetsCurrentSetIcon = preview:CreateTexture(); ItemRackOptSetsCurrentSetIcon.path = 'preview-art'
    local setName = frame('EditBox', 'ItemRackOptSetsName', sets)
    local number = frame('EditBox', 'ItemRackOptMenuScale', config)
    number.GetFont, number.SetFont = ItemRackOptList1Label.GetFont, ItemRackOptList1Label.SetFont
    number.GetTextColor, number.SetTextColor = ItemRackOptList1Label.GetTextColor, ItemRackOptList1Label.SetTextColor
    number.SetJustifyH = function(self, v) self.justify = v end
    number.SetJustifyV = function(self, v) self.justifyV = v end
    number.SetTextInsets = function(self, ...) self.textInsets = {...} end
    setName.GetFont, setName.SetFont = number.GetFont, number.SetFont
    setName.GetTextColor, setName.SetTextColor = number.GetTextColor, number.SetTextColor
    setName.SetTextInsets = number.SetTextInsets
    setName.text, setName.font = 'Saved set', 'native-input'
    setName.hooks.OnTextChanged = function() return 'validate-native' end
    number.font, number.text = 'native-input', '0.85'
    local inputFill = number:CreateTexture()
    local setNameFill = setName:CreateTexture()
    number.hooks.OnEnterPressed = function() return 'number-native' end
    local scale = frame('Slider', 'ItemRackOptMenuScaleSlider', config)
    local scaleThumb = scale:CreateTexture(); scale.GetThumbTexture = function() return scaleThumb end
    scale.GetOrientation = function() return 'HORIZONTAL' end
    ItemRackOptMenuScaleSliderMin = scale:CreateFontString(nil, nil, 'native')
    ItemRackOptMenuScaleSliderMax = scale:CreateFontString(nil, nil, 'native')
    scale.value, scale.range = 0.85, {0.5, 2}
    local drop = frame('Button', 'ItemRackOptQuickAccessMenuSide', config)
    ItemRackOptQuickAccessMenuSideText = drop:CreateFontString(nil, nil, 'native')
    local arrow = frame('Button', 'ItemRackOptQuickAccessMenuSideButton', drop)
    arrow.nativeArt = arrow:CreateTexture(); arrow.action = function() return 'arrow-native' end
    local euiArrow = drop:CreateTexture(); euiArrow.path = 'Azerite-PointingArrow'
    S.GetFFD = function(f)
        if f == number then return {bg = inputFill}
        elseif f == setName then return {bg = setNameFill}
        elseif f == drop then return {arrow = euiArrow} end
    end
    ItemRack = {BuildMenu = function() MenuItem(3); return 'menu-native', nil, 7 end, ToggleOptions = function() return 'options' end}
    ItemRackOpt = {TabOnClick = function() return 'tab-native' end,
        OptInfo = {{type = 'label'}, {type = 'number', button = number}, {type = 'check'},
            {type = 'button', button = drop}, {type = 'slider', button = scale}},
        ListScrollFrameUpdate = function()
            ItemRackOptList1Label:SetFont('native-heading', 12); ItemRackOptList1Label:SetTextColor(1, 0.82, 0)
            ItemRackOptList1Underline:SetAlpha(1)
            ItemRackOptList1Underline:SetTexture('native-gradient')
            ItemRackOptList3CheckText:SetTextColor(0.5, 0.5, 0.5)
            number:ClearAllPoints(); number:SetPoint('LEFT', ItemRackOptList2NumberLabel, 'RIGHT', 16, -1)
            return 'config-native', nil, 4
        end,
        SetsIconScrollFrameUpdate = function()
            if not ItemRackOptSetsIcon2 then SetIcon(2) end
            gridIcon.highlight.shown = false; ItemRackOptSetsIcon2.highlight.shown = true
            return 'icons-native', nil, 2
        end,
        PickSetOnShow = function() return 'show-sets-native' end,
        SetListScrollFrameUpdate = function() return 'sets-native' end,
        ToggleQuickAccessMenuSidePick = function()
            if not ItemRackOptQuickAccessMenuSidePick then
                local picker = frame('Frame', 'ItemRackOptQuickAccessMenuSidePick', drop)
                picker:SetBackdrop({edgeFile = 'native-border'})
                local choice = frame('Button', 'ItemRackOptQuickAccessMenuSidePick1', picker)
                choice.label = choice:CreateFontString(nil, nil, 'native'); choice.action = function() return 'pick-native' end
            end
            return 'picker-native'
        end,
        SortListScrollFrameUpdate = function() ItemRackOptSortList1Highlight:SetColorTexture(0.8, 0.7, 0.5, 1); return 'rows-native' end}
    modules.ItemRack.install(S, modules.ItemRack); flush()
    assert(sets.panel and sets.gradient.alpha == 0 and sets.gradient.path == nil and sets.backdrop == nil and artwork.alpha == 1)
    assert(ItemRackOptSetsDropTextureLeft.alpha == 0 and choose.glyph == 'v' and choose.action() == 'choose-set')
    assert(slot.normal.alpha == 0 and ItemRackOptInv7Icon.crop and not slot.checkbox and slot.checked and slot.action() == 'select-equipment')
    assert(check.checkbox and check.checkOptions.borderInset == 4 and check.checked and tristate.checkOptions.stockCheck)
    assert(horizontal.backdrop == nil and hthumb.width == 8 and hthumb.height == 12
        and horizontal.value == 1 and horizontal.range[2] == 2 and horizontal.hooks.OnValueChanged() == 'scale-native')
    assert(move.glyph == '^' and move.action() == 'move-native')
    assert(gradient.alpha == 0 and drop.dropdown and arrow.nativeArt.alpha == 0 and arrow.action() == 'arrow-native')
    assert(gradient.path == nil and ItemRackOptList1Underline.path == nil)
    assert(euiArrow.path:find('eui%-arrow%-left') and euiArrow.width == 9 and euiArrow.color[1] == 0.75
        and euiArrow.rotation == math.pi / 2 and ItemRackOptQuickAccessMenuSideText.points[2][4] == -22,
        'dropdown retained its gold arrow or failed to reserve label clearance')
    assert(tick.desaturated and tick.color[1] == accent and ItemRackOptList3CheckButton.checked
        and tick.points[1][4] == 4 and tick.points[2][4] == -4
        and not triCheck.desaturated and triCheck.color[1] == 0.5, 'checkbox treatment changed native tristate semantics')
    assert(anonymous.panel and anonymous.backdrop == nil and anonymousGradient.alpha == 0 and anonymousGradient.path == nil,
        'unnamed saved-set container retained its native gradient/border')
    assert(unrelatedArt.path == 'native' and unrelatedArt.alpha == 1, 'cleanup reached an unrelated unnamed frame')
    assert(ItemRackOptSetList1Icon.path == 'set-art' and setLabel.textColor[1] == 0.7
        and ItemRackOptSetList1Highlight.color[4] == 0.13 and not ItemRackOptSetList1Highlight.shown
        and setRow.action() == 'select-set-native' and pickerClose.close and pickerClose.action() == 'close-native')
    assert(grid.panel and grid.backdrop == nil and gridGradient.path == nil and gridIcon.highlight.color[4] == 0.13
        and gridIcon.highlight.blendMode == 'BLEND' and gridIcon.highlight.shown and gridIcon.action() == 'set-icon-native'
        and gridIcon.highlight.gradient[2] == 1 and gridIcon.highlight.gradient[9] == 1)
    assert(preview.width == 30 and preview.height == 30 and ItemRackOptSetsCurrentSetIcon.path == 'preview-art')
    assert(setName.input and setName.font == 'eui' and setName.fontSize == 11 and setName.text == 'Saved set'
        and setNameFill.color[1] == 0.055 and setName.textInsets[1] == 4 and setName.hooks.OnTextChanged() == 'validate-native')
    local a, b, c = ItemRackOpt.SetsIconScrollFrameUpdate(); assert(a == 'icons-native' and b == nil and c == 2)
    assert(not gridIcon.highlight.shown and ItemRackOptSetsIcon2.highlight.color[4] == 0.13
        and ItemRackOptSetsIcon2.highlight.shown, 'dynamic icon selection lost its styling/native visibility')
    assert(ItemRackOpt.PickSetOnShow() == 'show-sets-native')
    local iconRegions, chooserRegions = #gridIcon.regions, #anonymous.regions
    auditScans[root] = 0
    for _ = 1, 50 do ItemRackOpt.SetsIconScrollFrameUpdate(); assert(ItemRackOpt.SetListScrollFrameUpdate() == 'sets-native') end
    assert(auditScans[root] == 0 and #gridIcon.regions == iconRegions and #anonymous.regions == chooserRegions,
        'set icon/list updates allocated controls or scanned the full options window')
    gridGradient:SetTexture('native-gradient'); anonymousGradient:SetTexture('native-gradient')
    anonymous:SetBackdrop({edgeFile = 'restored-native-border'})
    modules.ItemRack.refresh(); flush()
    assert(gridGradient.path == nil and anonymousGradient.path == nil and anonymous.backdrop == nil,
        'native repaint restored a gradient or the saved-set border')
    local oldCreateColor, colorCalls = CreateColor, 0
    CreateColor = function(...) colorCalls = colorCalls + 1; return {...} end
    gridIcon.highlight.SetGradientAlpha = false
    gridIcon.highlight.SetGradient = function(self, direction, first, last) self.modernGradient = {direction, first, last} end
    for _ = 1, 10 do ItemRackOpt.SetsIconScrollFrameUpdate() end
    assert(colorCalls == 1 and gridIcon.highlight.modernGradient[2] == gridIcon.highlight.modernGradient[3],
        'modern gradient reset allocated colours repeatedly or used different endpoints')
    CreateColor = oldCreateColor
    combat = true; gridIcon.highlight:SetTexture('combat-native-highlight'); ItemRackOpt.SetsIconScrollFrameUpdate()
    assert(gridIcon.highlight.path == 'combat-native-highlight')
    combat = false
    for _, event in ipairs(events) do if event.events and event.events.PLAYER_REGEN_ENABLED then event.hooks.OnEvent(event, 'PLAYER_REGEN_ENABLED') end end
    flush(); assert(gridIcon.highlight.path == 'solid')
    enabled = false; gridIcon.highlight:SetTexture('disabled-native-highlight'); ItemRackOpt.SetsIconScrollFrameUpdate()
    assert(gridIcon.highlight.path == 'disabled-native-highlight')
    enabled = true; modules.ItemRack.refresh(); flush()
    assert(ItemRackOptList1Label.font == 'eui' and ItemRackOptList1Label.fontSize == 11
        and ItemRackOptList1Label.textColor[1] == 0.78 and ItemRackOptList1Underline.alpha == 0)
    assert(ItemRackOptList3CheckText.width == 132 and ItemRackOptList3CheckButton.width == 20)
    assert(number.input and number.font == 'eui' and number.fontSize == 10 and number.justify == 'CENTER'
        and number.text == '0.85' and number.hooks.OnEnterPressed() == 'number-native')
    assert(inputFill.color[1] == 0.055 and inputFill.color[4] == 0.9)
    assert(not number.inputOptions.padInput and number.justifyV == 'MIDDLE'
        and number.textInsets[1] == 2 and number.textInsets[2] == 2, 'numeric field inherited asymmetric popup padding')
    assert(number.points[1][1] == 'RIGHT' and number.points[1][2] == configRows[2])
    assert(scaleThumb.width == 8 and scaleThumb.height == 12 and scale.range[2] == 2 and scale.value == 0.85)
    assert(ItemRackOptMenuScaleSliderMin.fontSize == 9 and ItemRackOptMenuScaleSliderMax.fontSize == 9)
    auditScans[root] = 0
    local settingsHook, regions = ItemRackOpt.ListScrollFrameUpdate, #scale.regions
    for _ = 1, 50 do
        local a, b, c = ItemRackOpt.ListScrollFrameUpdate(); assert(a == 'config-native' and b == nil and c == 4)
    end
    assert(auditScans[root] == 0 and #scale.regions == regions and ItemRackOpt.ListScrollFrameUpdate == settingsHook,
        'Config row refresh scanned the full window or duplicated objects/hooks')
    assert(ItemRackOptList1Label.font == 'eui' and ItemRackOptList1Label.textColor[1] == 0.78
        and ItemRackOptList3CheckText.textColor[1] == 0.5 and ItemRackOptList1Underline.alpha == 0,
        'Config redraw lost heading styling or native disabled-label colour')
    local oldOffset, oldScroll = FauxScrollFrame_GetOffset, ItemRackOptListScrollFrame
    ItemRackOptListScrollFrame = frame('ScrollFrame')
    FauxScrollFrame_GetOffset = function() return 1 end
    ItemRackOpt.ListScrollFrameUpdate()
    assert(number.points[1][2] == configRows[1], 'recycled number field stayed anchored to its previous row')
    FauxScrollFrame_GetOffset, ItemRackOptListScrollFrame = oldOffset, oldScroll
    ItemRackOpt.ListScrollFrameUpdate(); assert(number.points[1][2] == configRows[2])
    assert(ItemRackOpt.ToggleQuickAccessMenuSidePick() == 'picker-native')
    assert(ItemRackOptQuickAccessMenuSidePick.panel and ItemRackOptQuickAccessMenuSidePick.backdrop == nil
        and ItemRackOptQuickAccessMenuSidePick1.button and ItemRackOptQuickAccessMenuSidePick1.action() == 'pick-native')
    combat = true; ItemRackOpt.ListScrollFrameUpdate(); assert(ItemRackOptList1Label.font == 'native-heading')
    combat = false
    for _, event in ipairs(events) do if event.events and event.events.PLAYER_REGEN_ENABLED then event.hooks.OnEvent(event, 'PLAYER_REGEN_ENABLED') end end
    flush(); assert(ItemRackOptList1Label.font == 'eui')
    enabled = false; ItemRackOpt.ListScrollFrameUpdate(); assert(ItemRackOptList1Label.font == 'native-heading')
    enabled = true; modules.ItemRack.refresh(); flush()
    assert(menu.panel and not item.checkbox and item.normal.alpha == 0 and item.action() == 'equip-native')
    assert(not secure.normal.alpha or secure.normal.alpha == 1); assert(secure.attributes.macro == 'equip')
    local a, b, c = ItemRack.BuildMenu(); assert(a == 'menu-native' and b == nil and c == 7)
    assert(ItemRackMenu3.normal.alpha == 0, 'new hover item missed completed-menu styling')
    auditScans[root] = 0
    for _ = 1, 100 do assert(ItemRackOpt.SortListScrollFrameUpdate() == 'rows-native') end
    assert((auditScans[root] or 0) == 0 and label.textColor[3] == 0.87 and row.action() == 'queue-selection')
    assert(ItemRackOptSortList1Highlight.color[4] == 0.13 and ItemRackOptSortList1Highlight.shown)
    local objects, hook = #vertical.regions, ItemRackOpt.SortListScrollFrameUpdate
    for _ = 1, 10 do modules.ItemRack.refresh(); flush() end
    assert(#vertical.regions == objects and ItemRackOpt.SortListScrollFrameUpdate == hook)
    local strip = vertical.regions[#vertical.regions]
    assert(strip.width == 4 and strip.alpha == 1 and vthumb.alpha == 0, 'scroll strip disappeared on refresh')
    combat = true; ItemRackOpt.SortListScrollFrameUpdate(); assert(ItemRackOptSortList1Highlight.color[4] == 1)
    combat = false
    for _, event in ipairs(events) do if event.events and event.events.PLAYER_REGEN_ENABLED then event.hooks.OnEvent(event, 'PLAYER_REGEN_ENABLED') end end
    flush(); assert(ItemRackOptSortList1Highlight.color[4] == 0.13)
    enabled = false; ItemRackOpt.SortListScrollFrameUpdate(); assert(ItemRackOptSortList1Highlight.color[4] == 1)
    enabled = true
    -- Detached secure equipment buttons get cosmetics only, outside combat.
    local oldQuality, oldInventoryQuality = GetItemQualityColor, GetInventoryItemQuality
    GetItemQualityColor = function(q) if q == 3 then return 0, 0.44, 0.87 else return 0.12, 1, 0 end end
    local equippedQuality = 3
    GetInventoryItemQuality = function(_, id) if id == 7 then return equippedQuality end end
    ItemRackUser = {Locked = 'ON', Sets = {}}
    ItemRack.Menu = {101, 0}
    ItemRack.GetInfoByID = function(id) return 'item', 'item-art', 'INVTYPE_LEGS', id == 101 and 3 or 2 end
    ItemRackOpt.Inv = {[7] = {id = 101, selected = 1}}
    local detached = frame('CheckButton', 'ItemRackButton7'); detached.protected = true
    ItemRackButton7Icon = detached:CreateTexture(); detached.normal = detached:CreateTexture()
    detached.attributes = {type = 'item', slot = 7}; detached.checked = true
    detached.hooks.PostClick = function() return 'secure-action' end
    detached.SetAttribute = function() error('skin changed secure attributes') end
    local empty = frame('CheckButton', 'ItemRackButton8'); empty.protected = true
    ItemRackButton8Icon = empty:CreateTexture(); ItemRackButton8Icon.path = 'empty-slot-art'; empty.normal = empty:CreateTexture()
    for _, key in ipairs({'Lock', 'Queue', 'Options', 'Close'}) do
        local control = frame('Button', 'ItemRackButtonMenu' .. key, menu)
        control.action = function() return 'control-native' end
    end
    ItemRack.UpdateButtons = function() return 'buttons-native' end
    ItemRack.ReflectLock = function() return 'lock-native' end
    modules.ItemRack.refresh(); flush()
    local function Edges(button)
        local edges = {}
        for _, r in ipairs(button.regions) do if r.width == 1 or r.height == 1 then edges[#edges + 1] = r end end
        return edges
    end
    local edges = Edges(detached)
    assert(#edges == 4 and edges[1].color[3] == 0.87 and detached.normal.alpha == 0)
    assert(ItemRackButton7Icon.crop and detached.attributes.type == 'item' and detached.attributes.slot == 7
        and detached.checked and detached.hooks.PostClick() == 'secure-action', 'detached skin changed an equipment action/state')
    assert(Edges(empty)[1].color[1] == 0.35 and ItemRackButton8Icon.path == 'empty-slot-art', 'empty slot lost its native artwork/neutral border')
    assert(Edges(slot)[1].color[3] == 0.87 and Edges(item)[1].color[3] == 0.87, 'rarity styling differs between options and menus')
    local marker
    for _, r in ipairs(slot.regions) do if r.width == 4 and r.height == 4 then marker = r end end
    assert(not marker, 'redundant set-selection square was recreated')
    ItemRackOpt.Inv[7].selected = false; ItemRackOptInv7Icon:SetVertexColor(0.25, 0.25, 0.25)
    modules.ItemRack.refresh(); flush()
    assert(ItemRackOptInv7Icon.color[1] == 0.25 and Edges(slot)[1].color[3] == 0.87,
        'removing selection markers changed native fading or the rarity border')
    local lockIcon = ItemRackButtonMenuLock.regions[#ItemRackButtonMenuLock.regions]
    assert(lockIcon.path:find('eui%-lock%-locked') and ItemRackButtonMenuClose.glyph == 'X'
        and ItemRackButtonMenuQueue.action() == 'control-native')
    ItemRackUser.Locked = 'OFF'; assert(ItemRack.ReflectLock() == 'lock-native' and lockIcon.path:find('eui%-lock%-unlocked'))
    menu.protected = true; modules.ItemRack.refresh(); flush()
    assert(Edges(secure)[1].color[1] == 0.35 and secure.attributes.macro == 'equip', 'secure-parent hover menu lost cosmetics or its action')
    local total = #detached.regions; local lockedHook = ItemRack.ReflectLock
    auditScans[root] = 0
    for _ = 1, 20 do ItemRack.UpdateButtons() end
    assert(#detached.regions == total and ItemRack.ReflectLock == lockedHook and auditScans[root] == 0,
        'detached styling duplicated regions/hooks or scanned options')
    combat = true; equippedQuality = 2; detached.normal:SetAlpha(1)
    assert(ItemRack.UpdateButtons() == 'buttons-native' and detached.normal.alpha == 1 and edges[1].color[3] == 0.87,
        'protected cosmetics changed during combat')
    combat = false
    for _, event in ipairs(events) do if event.events and event.events.PLAYER_REGEN_ENABLED then event.hooks.OnEvent(event, 'PLAYER_REGEN_ENABLED') end end
    flush(); assert(detached.normal.alpha == 0 and edges[1].color[2] == 1)
    enabled = false; detached.normal:SetAlpha(1); ItemRack.UpdateButtons(); assert(detached.normal.alpha == 1)
    enabled = true
    -- Universal uses ItemRackIcon names and modern item-colour APIs.
    local oldCItem, oldColors = C_Item, ITEM_QUALITY_COLORS
    local universal = frame('CheckButton', 'ItemRackButton9'); universal.protected = true
    ItemRackButton9ItemRackIcon = universal:CreateTexture()
    universal.icon = ItemRackButton9ItemRackIcon; universal.Icon = universal.icon
    universal.normal = universal:CreateTexture()
    universal.attributes = {type = 'item', slot = 9}
    universal.SetAttribute = function() error('Universal secure attributes changed') end
    GetInventoryItemQuality = function(_, id) if id == 9 then return 3 elseif id == 7 then return equippedQuality end end
    GetItemQualityColor = nil
    C_Item = {GetItemQualityColor = function(q) if q == 3 then return 0, 0.44, 0.87 end return 0.12, 1, 0 end}
    ItemRack.RefreshCustomItemIcons = function() return 'custom-native' end
    modules.ItemRack.refresh(); flush()
    assert(universal.icon.crop and universal.normal.alpha == 0 and #Edges(universal) == 4,
        'Universal detached icon retained vanilla styling')
    assert(Edges(universal)[1].color[3] == 0.87 and Edges(slot)[1].color[3] == 0.87,
        'modern-only colour API produced grey rarity borders')
    assert(Edges(empty)[1].color[1] == 0.35 and universal.attributes.slot == 9)
    local universalTotal = #universal.regions
    ItemRackButton9ItemRackIcon = nil -- Also support the addon-owned icon field.
    auditScans[root] = 0
    for _ = 1, 20 do assert(ItemRack.RefreshCustomItemIcons() == 'custom-native') end
    assert(#universal.regions == universalTotal and auditScans[root] == 0)
    C_Item = nil; ITEM_QUALITY_COLORS = {[3] = {r = 0, g = 0.44, b = 0.87}, [0] = {r = 0.62, g = 0.62, b = 0.62}}
    ItemRack.UpdateButtons()
    assert(Edges(universal)[1].color[3] == 0.87, 'quality colour table fallback failed')
    GetInventoryItemQuality = nil
    local oldGetID = ItemRack.GetID
    ItemRack.GetID = function(id) return id == 9 and 101 or 0 end
    ItemRack.UpdateButtons(); assert(Edges(universal)[1].color[3] == 0.87, 'inventory ID quality fallback failed')
    GetInventoryItemQuality = function() return 0 end
    ItemRack.UpdateButtons(); assert(Edges(universal)[1].color[1] == 0.62, 'poor quality was treated as an empty slot')
    combat = true; universal.normal:SetAlpha(1); ItemRack.RefreshCustomItemIcons()
    assert(universal.normal.alpha == 1, 'custom-icon hook changed protected cosmetics in combat')
    combat = false
    for _, event in ipairs(events) do if event.events and event.events.PLAYER_REGEN_ENABLED then event.hooks.OnEvent(event, 'PLAYER_REGEN_ENABLED') end end
    flush(); assert(universal.normal.alpha == 0)
    enabled = false; universal.normal:SetAlpha(1); ItemRack.RefreshCustomItemIcons(); assert(universal.normal.alpha == 1)
    enabled = true
    C_Item, ITEM_QUALITY_COLORS, ItemRack.GetID = oldCItem, oldColors, oldGetID
    GetItemQualityColor, GetInventoryItemQuality = oldQuality, oldInventoryQuality
    S.Checkbox, S.Inset, S.GetFFD = checkbox, inset, getFFD
end

assert(loadfile('EUIAddonSkins/Skins/ForeverDungeonJournal.lua'))('EUIAddonSkins', ns)
ForeverDungeonJournal_NS = {THEMES = {}, ToggleJournal = function() end}
ForeverDungeonJournalFrame = frame('Frame')
local journal = ForeverDungeonJournalFrame
journal.homePanel = frame('Frame', nil, journal)
journal.homeTitle = journal.homePanel:CreateFontString()
local cover = frame('Button', nil, journal.homePanel)
cover.dungeonName = 'Dalaran'; cover.art = cover:CreateTexture(); cover.art.path = 'dungeon-art'
cover.title = cover:CreateFontString(); cover.counts = cover:CreateFontString(); cover.counts.textColor = {1, 0.9, 0.5}
cover:SetBackdrop({bgFile = 'native', edgeFile = 'bevel'}); cover.action = function() return 'open-dungeon' end
journal.bugReportButton = frame('Button', nil, journal)
local bug = journal.bugReportButton:CreateTexture(); bug.path = 'bug-icon'
local bugLabel = journal.bugReportButton:CreateFontString()
journal.languageSelectorButton = frame('Button', nil, journal)
journal.languageSelectorText = journal.languageSelectorButton:CreateFontString()
local caret = journal.languageSelectorButton:CreateTexture(); caret.path = 'native-caret'
modules.ForeverDungeonJournal.install(S, modules.ForeverDungeonJournal); flush()
assert(journal.shellOptions.noBorder, 'journal soft shell missing')
assert(cover.border[1] == 0.055, 'journal card outline too bright')
cover:SetBackdropBorderColor(1, 1, 1, 1); assert(cover.border[1] == 0.055, 'neutral card redraw restored a bright border')
cover:SetBackdropBorderColor(0.2, 0.8, 0.2, 1); assert(cover.border[2] == 0.8, 'semantic card border lost')
assert(cover.backdrop.edgeSize == 1 and cover.art.path == 'dungeon-art' and cover.art.alpha == 1 and cover.counts.textColor[1] == 1 and cover.action() == 'open-dungeon')
assert(journal.homeTitle.textColor[1] == accent and journal.bugReportButton.button and bug.alpha == 1)
assert(caret.alpha == 0 and journal.languageSelectorButton.euiCaret.text == 'v')
-- All FDJ mode states keep their icon but never revive UIPanelButton art.
for _, key in ipairs({'mapTab', 'bossesTab', 'questsTab'}) do
    local tab = frame('Button', nil, journal); journal[key] = tab
    tab.normal = texture(); tab.regions = {tab.normal}; tab.fdjIcon = tab:CreateTexture()
    tab.text = tab:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    tab.SetNormalTexture = function(self, value) self.normal:SetTexture(value); self.normal:SetAlpha(1) end
end
journal.questsTab:Disable(); modules.ForeverDungeonJournal.refresh(); flush()
for _, key in ipairs({'mapTab', 'bossesTab', 'questsTab'}) do
    local tab = journal[key]
    assert(tab.tab and tab.normal.alpha == 0 and tab.Icon == tab.fdjIcon and tab.fdjIcon.alpha == 1)
    tab:SetNormalTexture('restored-red'); tab:Enable(); assert(tab.normal.alpha == 0 and not tab.selected)
    tab:Disable(); assert(tab.selected and tab.normal.alpha == 0)
end
-- Auctionator legacy templates: wrappers, controls and pooled inventory rows.
assert(loadfile('EUIAddonSkins/Skins/Auctionator.lua'))('EUIAddonSkins', ns)
AuctionFrame = frame(); AuctionFrame.selectedTab = 1
AuctionFrameTab1 = frame('Button'); AuctionFrameTab2 = frame('Button'); AuctionFrameTab3 = frame('Button')
Auctionator = {Tabs = {State = {knownTabs = {{name = 'Shopping', tabFrameName = 'AuctionatorShoppingFrame'}}}}}
AuctionatorShoppingFrame = frame(); local shopping = AuctionatorShoppingFrame
AuctionatorTabs_Shopping = frame('Button'); local tab = AuctionatorTabs_Shopping
local wrapper = frame(); tab.wrapperFrame = wrapper
wrapper.Title = wrapper:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
tab.Selected = function() wrapper.hidden = false end; tab.DeselectTab = function() wrapper.hidden = true end
shopping.SearchOptions = frame('Frame', nil, shopping); local options = shopping.SearchOptions
options.SearchLabel = options:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
options.SearchString = frame('EditBox', nil, options); options.SearchButton = frame('Button', nil, options)
shopping.ListsContainer = frame('Frame', nil, shopping); shopping.RecentsContainer = frame('Frame', nil, shopping)
shopping.ContainerTabs = frame('Frame', nil, shopping); local mini = shopping.ContainerTabs
mini.ListsTab = frame('Button', nil, mini); mini.ListsTab.id = 1
mini.RecentsTab = frame('Button', nil, mini); mini.RecentsTab.id = 2
mini.selectedTab = 2; mini.SetView = function(self, id) self.selectedTab = id end
shopping.Refresh = function() return 'native-refresh-result' end
local results = frame('Frame', nil, shopping); results.ScrollBar = frame('Frame', nil, results)
local cap = results.ScrollBar:CreateTexture()
results.ScrollArea = frame('Frame', nil, results); local spinner = results.ScrollArea:CreateTexture(); spinner.layer = 'OVERLAY'
local radio = frame('Frame', nil, shopping); radio.isAuctionatorRadio = true
radio.RadioButton = frame('CheckButton', nil, radio); radio.RadioButton.checked = true
radio.RadioButton.action = function() return 'native-duration' end
local item = frame('Button', nil, shopping); item.Icon = item:CreateTexture(); item.Icon.path = 'item-art'
item.IconBorder = item:CreateTexture(); item.IconBorder:SetVertexColor(0.3, 0.6, 1, 1)
item.Text = item:CreateFontString(nil, 'OVERLAY', 'GameFontNormal'); item.Text:SetText('34')
item.IconSelectedHighlight = item:CreateTexture(); item.action = function() return 'native-item-drag' end
local prices = frame('Frame', nil, shopping); prices.CurrentPrices = frame('Frame', nil, prices)
prices.HistoryPrices = frame('Frame', nil, prices); prices.HistoryPrices.hidden = true
prices.HistoryButton = frame('Button', nil, prices)
modules.Auctionator.install(S, modules.Auctionator); flush()
assert(shopping.shellOptions.noBorder and shopping.ListsContainer.panelOptions.noBorder and shopping.ListsContainer.panelOptions.inset)
assert(options.SearchString.inputOptions.noBorder and options.SearchString.inputOptions.padInput)
assert(shopping.Refresh() == 'native-refresh-result')
assert(tab.selected and AuctionFrameTab1.selected == false and AuctionFrame.selectedTab == 1)
assert(options.SearchButton.points[1][1] == 'LEFT' and shopping.ListsContainer.points[1][5] == -84)
assert(mini.RecentsTab.selected and not mini.ListsTab.selected and cap.alpha == 0 and results.ScrollBar.scroll)
assert(radio.RadioButton.checkbox and radio.RadioButton.regions[1].shown and radio.RadioButton.action() == 'native-duration')
assert(item.Icon.path == 'item-art' and item.Icon.crop and item.IconBorder.alpha == 0 and item.Text.text == '34')
assert(item.euiQualityTop.color[3] == 1 and item.IconSelectedHighlight.alpha == 1 and item.action() == 'native-item-drag')
item.IconBorder:SetVertexColor(1, 0.5, 0, 1); assert(item.euiQualityTop.color[1] == 1 and item.euiQualityTop.color[2] == 0.5)
radio.RadioButton:SetChecked(false); assert(not radio.RadioButton.regions[1].shown)
mini:SetView(1); tab:DeselectTab(); flush()
assert(not tab.selected and AuctionFrameTab1.selected == nil and mini.ListsTab.selected and not mini.RecentsTab.selected)
assert(not prices.HistoryButton.selected)
prices.HistoryPrices.hidden = false; modules.Auctionator.refresh(); flush(); assert(prices.HistoryButton.selected)
local count = #item.regions + #radio.RadioButton.regions
accent = 0.2; spinner:SetAlpha(0); modules.Auctionator.refresh(); flush()
assert(spinner.alpha == 1 and radio.RadioButton.regions[1].color[1] == accent)
assert(count == #item.regions + #radio.RadioButton.regions, 'warm refresh created more UI objects')
S.GetFont = function() return 'eui', '' end
-- Questie: actual adapter with AceGUI wrapper roots and independent tracker updates.
Questie, QuestieLoader = nil, nil
assert(loadfile('EUIAddonSkins/Skins/Questie.lua'))('EUIAddonSkins', ns)
assert(not modules.Questie.available())
Questie = {db = {profile = {trackerBackground = {r = 0.2, g = 0.3, b = 0.4, a = 0.25}}}}
local journey = {BuildMainFrame = function() return 'journey-native' end, ToggleJourneyWindow = function() end, private = {}}
local tracker = {Update = function() return 'tracker-native' end}
local init = function() coroutine.yield('initializing'); return 'initialized' end
tracker.Initialize = init
local nextLine
local linePool = {Initialize = init, GetNextLine = function() return nextLine, nil, 'native-tail' end}
QuestieLoader = {_modules = {QuestieJourney = journey, QuestieTracker = tracker, QuestieOptions = {ToggleConfigWindow = function() end}}}
QuestieLoader._modules.TrackerLinePool = linePool
QuestieJourneyFrame = {frame = frame()}; local journeyRoot = QuestieJourneyFrame.frame
QuestieConfigFrame = {frame = frame()}; local input = frame('EditBox', nil, QuestieConfigFrame.frame)
local groupFrame = frame('Frame', nil, journeyRoot)
local first, second = frame('Button', nil, groupFrame), frame('Button', nil, groupFrame)
first.selected, second.selected = true, false
local group = {type = 'TabGroup', frame = groupFrame, tabs = {first, second}, SelectTab = function(_, value) first.selected = value == 1; second.selected = value == 2 end}
groupFrame.obj = group
local detail = journeyRoot:CreateFontString(nil, 'OVERLAY', 'GameFontNormal'); detail:SetTextColor(0.2, 0.7, 0.3, 0.8)
Questie_BaseFrame = frame(); local base = Questie_BaseFrame
base:SetBackdrop({bgFile = 'white', edgeFile = 'native', edgeSize = 16}); base:SetBackdropColor(0.2, 0.3, 0.4, 0.25)
local line = frame('Frame', nil, base); local progress = line:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
progress:SetTextColor(0.8, 0.2, 0.1, 0.7)
local questToggle = frame('Button', nil, line); line.expandQuest = questToggle
questToggle.texture = questToggle:CreateTexture()
questToggle.SetMode = function(self, mode) self.mode = mode; self.texture:SetTexture(mode == 1 and 'UI-MinusButton-Up' or 'UI-PlusButton-Up') end
questToggle:SetMode(1)
local protectedItem = frame('Button', nil, base); protectedItem.protected = true; protectedItem.attributes = {type = 'item', item = 'quest item'}
protectedItem.Icon = protectedItem:CreateTexture()
local map = frame(); map.pin = map:CreateTexture(); local pinPath = map.pin.path
Questie_HeaderFrame = frame('Button', nil, base)
Questie_HeaderFrame.trackedQuests = {label = Questie_HeaderFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')}
Questie_HeaderFrame.questieIcon = frame('Button', nil, Questie_HeaderFrame)
Questie_HeaderFrame.questieIcon.texture = Questie_HeaderFrame.questieIcon:CreateTexture()
local journeyRow = frame('Button', nil, journeyRoot); journeyRow.treeline = {}
journeyRow.toggle = frame('Button', nil, journeyRow)
journeyRow.toggle.normal = texture()
journeyRow.toggle.SetNormalTexture = function(self, path) self.normal:SetTexture(path) end
journeyRow.toggle:SetNormalTexture(130821)
local dropdownWrapper = frame('Frame', nil, journeyRoot)
local dropdownWidget = {type = 'Dropdown', frame = dropdownWrapper, dropdown = frame('Frame', nil, dropdownWrapper), button = frame('Button', nil, dropdownWrapper), text = dropdownWrapper:CreateFontString(nil, nil, 'GameFontNormal'), SetLabel = function() end}
dropdownWrapper.obj = dropdownWidget
QuestieTrackerMenuFrame = frame()
local bound = false; ns.BindPopupOwner = function(_, module, owner) if owner == QuestieTrackerMenuFrame then assert(module == modules.Questie); bound = true end end
local dialog = {OpenFrames = {}, FeedGroup = function() return 'feed-native' end}
LibStub = function(name) if name == 'AceConfigDialog-3.0' then return dialog end end
modules.Questie.install(S, modules.Questie); flush()
assert(not Questie_HeaderFrame.questieIcon.texture.borderParent)
assert(questToggle.texture.alpha == 0 and questToggle.regions[2].text == '-')
questToggle:SetMode(0); assert(questToggle.regions[2].text == '+', 'tracker toggles must update synchronously')
assert(journeyRow.toggle.regions[1].text == '-')
journeyRow.toggle:SetNormalTexture(130838); assert(journeyRow.toggle.regions[1].text == '+')
assert(dropdownWidget.dropdown.points[1][4] == 0 and dropdownWidget.dropdown.points[2][4] == 0)
dropdownWidget:SetLabel('Continent'); assert(dropdownWidget.dropdown.points[1][4] == 0)
assert(tracker.Initialize == init and linePool.Initialize == init, 'yielding Questie initializers must remain unhooked')
local initializer = coroutine.create(init)
local ok, value = coroutine.resume(initializer); assert(ok and value == 'initializing')
ok, value = coroutine.resume(initializer); assert(ok and value == 'initialized')
assert(journeyRoot.shellOptions.noBorder and input.inputOptions.noBorder, 'Questie soft shell/input missing')
assert(journeyRoot.shellOptions.noTopBar, 'Journey header must not be split by a 25px strip')
assert(journeyRoot.shell and QuestieConfigFrame.frame.shell and input.input and first.selected and not second.selected)
assert(detail.font == 'eui' and detail.textColor[1] == 0.2 and detail.textColor[4] == 0.8)
assert(base.backdrop.edgeSize == 1 and base.color[4] == 0.25 and base.accent and not base.shell)
assert(progress.font == 'eui' and progress.textColor[1] == 0.8 and progress.textColor[4] == 0.7)
assert(not protectedItem.button and not protectedItem.Icon.crop and protectedItem.attributes.item == 'quest item')
assert(map.pin.path == pinPath and not map.pin.crop and bound and QuestieLoader._modules.Nonexistent == nil)
group:SelectTab(2); flush(); assert(not first.selected and second.selected)
local lateLine = frame('Frame', nil, base); local lateText = lateLine:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
lateText:SetTextColor(0.1, 0.5, 0.9, 1)
assert(tracker:Update() == 'tracker-native'); flush(); assert(lateText.font == 'eui' and lateText.textColor[3] == 0.9)
local pooled = frame('Button', nil, base); pooled.label = pooled:CreateFontString(nil, nil, 'GameFontNormal'); nextLine = pooled
local returned, hole, tail = linePool.GetNextLine(); assert(returned == pooled and hole == nil and tail == 'native-tail')
pooled.label:SetFont('questie-native'); assert(pooled.label.font == 'eui', 'font must be final before Questie measures a pooled row')
local fontHook = pooled.label.SetFont
for _ = 1, 5 do linePool.GetNextLine(); pooled.label:SetFont('questie-native'); end
assert(pooled.label.SetFont == fontHook)
local acquiring = coroutine.create(function()
    local row = linePool.GetNextLine(); coroutine.yield('acquired')
    row.label:SetFont('questie-native'); assert(row.label.font == 'eui'); return 'ready'
end)
local yielded, state = coroutine.resume(acquiring); assert(yielded and state == 'acquired')
yielded, state = coroutine.resume(acquiring); assert(yielded and state == 'ready')
combat = true; pooled.label:SetFont('combat-native'); assert(pooled.label.font == 'combat-native'); flush()
combat = false
for _, eventFrame in ipairs(events) do if eventFrame.events and eventFrame.events.PLAYER_REGEN_ENABLED then eventFrame.hooks.OnEvent(eventFrame, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(pooled.label.font == 'eui')
enabled = false; linePool.GetNextLine(); pooled.label:SetFont('disabled-native'); assert(pooled.label.font == 'disabled-native')
enabled = true; modules.Questie.refresh(); flush(); assert(pooled.label.font == 'eui')
local fontWrites = pooled.label.fontWrites
local hook = tracker.Update; local count = #base.regions
for _ = 1, 10 do modules.Questie.refresh(); flush() end
assert(pooled.label.fontWrites == fontWrites, 'warm tracker refresh must not reload its font')
assert(tracker.Update == hook and #base.regions == count, 'Questie refresh duplicated hooks/objects')
combat = true; local combatLine = frame('Frame', nil, base); local combatText = combatLine:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
tracker:Update(); flush(); assert(combatText.font == 'GameFontNormal')
combat = false
for _, eventFrame in ipairs(events) do if eventFrame.events and eventFrame.events.PLAYER_REGEN_ENABLED then eventFrame.hooks.OnEvent(eventFrame, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(combatText.font == 'eui')
enabled = false; local disabledLine = frame('Frame', nil, base); local disabledText = disabledLine:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
tracker:Update(); flush(); assert(disabledText.font == 'GameFontNormal')
enabled = true
print('PASS: Questie owned windows/tabs, tracker colours/opacity, secure items, dynamic rows, combat/toggles and hook idempotence')
-- DBM-GUI loads on demand; its colour selectors and previews are not ordinary buttons.
DBM_GUI, DBM_GUI_OptionsFrame = nil, nil
assert(loadfile('EUIAddonSkins/Skins/DBM.lua'))('EUIAddonSkins', ns)
assert(not modules.DBM.available(), 'DBM skin forced missing GUI initialization')
DBM_GUI = {CreateNewPanel = function() return 'panel-native' end}
local dbm = frame('Frame', 'DBM_GUI_OptionsFrame')
dbm.tab, dbm.tabs = 1, {{}, {}}
dbm.ShowTab = function(self, index) self.tab = index end
dbm.DisplayFrame = function(_, page) DBM_GUI.currentViewing = page; dbm.tabs[dbm.tab].selection = page end
dbm.UpdateMenuFrame = function() end
local dbmTab1 = frame('Button', 'DBM_GUI_OptionsFrameTab1', dbm)
local dbmTab2 = frame('Button', 'DBM_GUI_OptionsFrameTab2', dbm)
local tabArt = frame('Frame', nil, dbmTab2); local stockTab = tabArt:CreateTexture()
dbmTab2.kind = 'CheckButton'
local rootStockTab = dbmTab2:CreateTexture()
local wrapper = frame('Frame', nil, dbm)
frame('ScrollFrame', 'DBM_GUI_OptionsFrameList', wrapper)
local close = frame('Button', 'DBM_GUI_OptionsFrameClosePanelButton', dbm)
local page = frame('Frame', nil, dbm); page.mytype = 'panel'; page.showSub = true
dbm.tabs[1].selection = page
local row = frame('Button', nil, dbm); row.element = page
row.toggle = frame('Button', nil, row); row.toggle.normal = texture(); row.toggle.normal.path = 130821
local swatch = frame('Button', nil, page); swatch.SetColorRGB = function() return 'colour-native' end
local colour = swatch:CreateTexture(); colour:SetVertexColor(0.3, 0.8, 0.1, 1)
local preview = frame('ScrollingMessageFrame', nil, page)
local previewText = preview:CreateFontString(nil, 'OVERLAY', 'DBMPreviewFont')
local previewButton = frame('Button', nil, preview); previewButton.label = previewButton:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
local dropdown = frame('DropdownButton', nil, page); dropdown.mytype = 'dropdown2'
local check = frame('CheckButton', nil, page); check.checked = true
local slider = frame('Slider', nil, page); slider.GetThumbTexture = function() return thumb end
slider.GetOrientation = function() return 'HORIZONTAL' end; slider.value = 0.7
S.GetFont = function() return 'eui', 'OUTLINE' end
local html = frame('SimpleHTML', nil, page)
html.GetFont = function(self, tag) assert(tag == 'p'); return self.font or 'native', 13 end
html.SetFont = function(self, tag, path, size, flags) assert(tag == 'p'); self.font, self.fontSize, self.flags = path, size, flags end
html.SetFontObject = function(self, tag, path) assert(tag == 'p'); self.font = path end
local dbmLabel = page:CreateFontString(nil, nil, 'GameFontNormal'); dbmLabel:SetTextColor(0.2, 0.7, 0.3, 0.8)
local warning = frame(); local alert = warning:CreateFontString(nil, 'OVERLAY', 'DBMAlertFont')
local area = frame('Frame', nil, page); area.mytype = 'area'; area:SetBackdrop({bgFile = 'native'})
assert(modules.DBM.available())
S.Dropdown = function(f) f.dropdown = true end
modules.DBM.install(S, modules.DBM); flush()
assert(html.font == 'eui' and html.fontSize == 13 and html.flags == 'OUTLINE')
html:SetFontObject('p', 'native'); assert(html.font == 'eui', 'HTML styles must survive font object changes immediately')
html:SetFont('p', 'native', 13); assert(html.font == 'eui')
dbmLabel:SetFontObject('native'); assert(dbmLabel.font == 'eui' and dbmLabel.textColor[4] == 0.8)
rootStockTab:SetAlpha(1); assert(rootStockTab.alpha == 0, 'native tab artwork must remain hidden')
assert(dbm.shellOptions.noBorder and wrapper.panelOptions.inset and area.panelOptions.inset)
assert(dbm.shell and dbm.accent and dbmTab1.selected and not dbmTab2.selected and close.close)
assert(stockTab.alpha == 0 and wrapper.panelOptions.noBorder and wrapper.points[1][5] == -72)
assert(row.euiSelection.color[4] == 0.2 and row.toggle.regions[1].text == '-')
assert(colour.alpha == 1 and colour.color[2] == 0.8 and swatch:SetColorRGB() == 'colour-native')
assert(previewText.font == 'DBMPreviewFont' and not previewButton.button and alert.font == 'DBMAlertFont')
assert(dropdown.dropdown and check.checkbox and check.checked and slider.value == 0.7 and area.panel)
dbm:ShowTab(2); assert(not dbmTab1.selected and dbmTab2.selected, 'DBM tabs must style before the callback returns'); flush()
local dynamic = frame('CheckButton', nil, page)
assert(DBM_GUI:CreateNewPanel() == 'panel-native'); flush(); assert(dynamic.checkbox)
auditScans[dbm] = 0
for _ = 1,100 do assert(DBM_GUI:CreateNewPanel() == 'panel-native') end
flush()
print(('BENCH dbm_construct full=%d callbacks=100'):format(auditScans[dbm] or 0))
if not auditBaseline then assert(auditScans[dbm] == 1, 'DBM construction burst repeated full scans') end

local dbmHook, objects = dbm.ShowTab, #row.regions + #row.toggle.regions + #slider.regions
for _ = 1, 5 do modules.DBM.refresh(); flush() end
assert(dbm.ShowTab == dbmHook and objects == #row.regions + #row.toggle.regions + #slider.regions)
accent = 0.9; dbm:DisplayFrame(page); flush(); assert(row.euiSelection.color[1] == accent and thumb.color[1] == accent)
combat = true; dbmLabel:SetFontObject('combat-native'); assert(dbmLabel.font == 'combat-native')
local deferred = frame('CheckButton', nil, page)
DBM_GUI:CreateNewPanel(); flush(); assert(not deferred.checkbox)
combat = false
for _, eventFrame in ipairs(events) do if eventFrame.events and eventFrame.events.PLAYER_REGEN_ENABLED then eventFrame.hooks.OnEvent(eventFrame, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(deferred.checkbox and dbmLabel.font == 'eui')
enabled = false; dbmLabel:SetFontObject('disabled-native'); assert(dbmLabel.font == 'disabled-native')
local skipped = frame('CheckButton', nil, page)
DBM_GUI:CreateNewPanel(); flush(); assert(not skipped.checkbox)
enabled = true
print('PASS: DBM lazy GUI, dynamic controls, selection, swatches/previews, theme refresh, combat/toggles and idempotence')
-- AtlasLoot Continued: owned custom widgets and foreground/status art.
AtlasLoot = nil
assert(loadfile('EUIAddonSkins/Skins/AtlasLootContinued.lua'))('EUIAddonSkins', ns)
assert(not modules.AtlasLootContinued.available())
local atlasRoot = frame('Frame', 'AtlasLoot_GUI-Frame')
atlasRoot:SetBackdrop({bgFile = 'native-fill', edgeFile = 'native-bevel', edgeSize = 16})
local logo = atlasRoot:CreateTexture(); logo.path = 538639; atlasRoot.gameVersionLogo = logo
atlasRoot.CloseButton = frame('Button', nil, atlasRoot)
local atlasGUI = {frame = atlasRoot, Toggle = function() return 'atlas-native' end,
    ItemFrame = {Refresh = function() return 'items-native' end}}
AtlasLoot = {GUI = atlasGUI, Favourites = {GUI = {frame = frame()}}}
local favourites = AtlasLoot.Favourites
AtlasLoot.Favourites = nil
AtlasLoot.Addons = {GetAddon = function(_, name) if name == 'Favourites' then return favourites end end}
local map = atlasRoot:CreateTexture(); map.path = 'dungeon-map'
local model = frame('PlayerModel', nil, atlasRoot); local modelArt = model:CreateTexture()
local item = frame('Button', 'AtlasLoot_Button_1', atlasRoot)
item.icon, item.overlay, item.phaseIndicator = item:CreateTexture(), item:CreateTexture(), item:CreateTexture()
item.icon.path = 'loot-icon'; item.overlay:SetVertexColor(0.6, 0.2, 0.9, 1)
item.label = item:CreateFontString(nil, 'ARTWORK', 'GameFontNormal'); item.label:SetTextColor(0.6, 0.2, 0.9, 1)
local selectFrame = frame('ScrollFrame', 'AtlasLoot-Select-1', atlasRoot)
local selector = {frame = selectFrame, SetSelected = function() end, Update = function() end}; selectFrame.obj = selector
local selection = frame('CheckButton', nil, selectFrame); selection.obj, selection.info = selector, {id = 'boss'}
selection.label, selection.coin = selection:CreateFontString(nil, 'OVERLAY', 'GameFontNormal'), selection:CreateTexture()
selection.checked = true
local dropdown = frame('Button', 'AtlasLoot-DropDown-1', atlasRoot)
dropdown.label = dropdown:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
dropdown.button = frame('Button', 'AtlasLoot-DropDown-1-button', dropdown)
local popup, popupRow
dropdown.par = {Toggle = function()
    popup = frame('Frame', 'AtlasLoot-DropDown-CatFrame1', dropdown); popup:SetBackdrop({bgFile = 'native-fill'})
    popupRow = frame('Button', 'AtlasLoot-DropDown-Button1', popup)
    popupRow.icon, popupRow.check = popupRow:CreateTexture(), popupRow:CreateTexture()
    popupRow.label = popupRow:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    popupRow.label:SetTextColor(0.3, 0.8, 0.1, 1)
    return 'popup-native'
end, SetData = function() end, SetSelected = function() end}
S.GetPanelColor = function() return 0.02, 0.02, 0.02, 0.9 end
modules.AtlasLootContinued.install(S, modules.AtlasLootContinued); flush()
assert(atlasRoot.accent and not atlasRoot.shell and atlasRoot.backdrop.edgeSize == 1 and atlasRoot.color[4] == 0.9)
assert(atlasRoot.CloseButton.close and favourites.GUI.frame.shell and logo.alpha == 1 and map.path == 'dungeon-map')
atlasRoot:SetBackdropBorderColor(1, 1, 1, 1)
assert(atlasRoot.border[1] == 0.055, 'AtlasLoot native redraw must not restore a white outer border')
assert(item.icon.crop and item.overlay.alpha == 1 and item.phaseIndicator.alpha == 1 and item.overlay.color[3] == 0.9)
assert(item.label.textColor[3] == 0.9 and not item.button and not modelArt.crop)
assert(selection.euiAtlasSelection.color[4] == 0.2 and selection.coin.alpha == 1 and not selection.checkbox)
assert(dropdown.dropdown and dropdown.button.glyph == 'v')
assert(selectFrame.panelOptions.noBorder and selectFrame.panelOptions.inset and favourites.GUI.frame.shellOptions.noBorder)
local pageButton = frame('Button', 'AtlasLoot-nextPageButton', atlasRoot)
modules.AtlasLootContinued.refresh(); flush(); assert(pageButton.glyph == '>')
assert(dropdown.par:Toggle() == 'popup-native')
assert(popup.panelOptions.noBorder and popup.panelOptions.inset)
assert(popup.panel and popupRow.button and popupRow.check.alpha == 1 and popupRow.label.textColor[2] == 0.8,
    'AtlasLoot popup must be styled synchronously, without waiting for a timer')
flush(); selection:SetChecked(false); flush(); assert(selection.euiAtlasSelection.color[4] == 0)
local hook, objects = atlasGUI.Toggle, #selection.regions
for _ = 1, 5 do modules.AtlasLootContinued.refresh(); flush() end
assert(atlasGUI.Toggle == hook and #selection.regions == objects)
local late = frame('CheckButton', nil, atlasRoot)
assert(atlasGUI.ItemFrame:Refresh() == 'items-native'); flush(); assert(late.checkbox)
enabled = false; local untouched = frame('CheckButton', nil, atlasRoot)
atlasGUI:Toggle(); flush(); assert(not untouched.checkbox)
enabled = true
print('PASS: AtlasLoot windows, synchronous pooled menus, selectors, colours/overlays/maps/models, dynamic controls and idempotence')
-- GTFO: skin only its settings canvases; sound/gameplay methods stay untouched.
GTFO = nil
assert(loadfile('EUIAddonSkins/Skins/GTFO.lua'))('EUIAddonSkins', ns)
assert(not modules.GTFO.available())
GTFO = {Settings = {Volume = 3, Enabled = true}, PlaySound = function() return 'alert-native' end}
GTFO_MainFrame, GTFO_IgnoreOptionsFrame = nil, nil
GTFO_RenderOptions = function()
    GTFO_MainFrame = frame('Frame', 'GTFO_MainFrame')
    GTFO_IgnoreOptionsFrame = frame('Frame', 'GTFO_IgnoreOptionsFrame')
    return 'settings-native'
end
GTFO_RefreshOptions = function() return 'refresh-native' end
modules.GTFO.install(S, modules.GTFO); flush()
assert(GTFO_RenderOptions() == 'settings-native')
local gtfoCheck = frame('CheckButton', nil, GTFO_MainFrame); gtfoCheck.checked = true
local testButton = frame('Button', nil, GTFO_MainFrame)
testButton.label = testButton:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
testButton.action = function() return GTFO.PlaySound() end
local volume = frame('Slider', nil, GTFO_MainFrame); volume.GetThumbTexture = function() return thumb end
volume.GetOrientation = function() return 'HORIZONTAL' end; volume.value = 3
thumb:SetSize(32, 32)
volume.NineSlice = frame('Frame', nil, volume)
local nativeSliderEdge = volume.NineSlice:CreateTexture()
volume.SetScript = function(self, event, fn) self.hooks[event] = fn end
local sliderChanges = 0
volume:SetScript('OnValueChanged', function() sliderChanges = sliderChanges + 1 end)
local valueHandler = volume.hooks.OnValueChanged
local ignore = frame('CheckButton', nil, GTFO_IgnoreOptionsFrame)
local gtfoInput = frame('EditBox', nil, GTFO_MainFrame)
flush()
assert(gtfoInput.inputOptions.noBorder, 'GTFO soft input missing')
assert(GTFO_MainFrame.accent and not GTFO_MainFrame.shell and not GTFO_IgnoreOptionsFrame.shell)
assert(gtfoCheck.checkbox and gtfoCheck.checked and ignore.checkbox and testButton.button and testButton.action() == 'alert-native')
assert(thumb.width == 8 and thumb.height == 14 and nativeSliderEdge.alpha == 0, 'GTFO slider geometry/chrome incorrect')
nativeSliderEdge:SetAlpha(1); assert(nativeSliderEdge.alpha == 0, 'GTFO slider native border returned')
assert(volume.hooks.OnValueChanged == valueHandler and sliderChanges == 0, 'GTFO slider action changed')
assert(volume.value == 3 and GTFO.Settings.Volume == 3 and GTFO.Settings.Enabled)
local gtfoHook, objects = GTFO_RefreshOptions, #volume.regions
accent = 0.35; assert(GTFO_RefreshOptions() == 'refresh-native'); flush(); assert(thumb.color[1] == accent)
for _ = 1, 5 do modules.GTFO.refresh(); flush() end
assert(GTFO_RefreshOptions == gtfoHook and #volume.regions == objects)
combat = true; local deferred = frame('CheckButton', nil, GTFO_IgnoreOptionsFrame)
GTFO_RefreshOptions(); flush(); assert(not deferred.checkbox)
combat = false
for _, eventFrame in ipairs(events) do if eventFrame.events and eventFrame.events.PLAYER_REGEN_ENABLED then eventFrame.hooks.OnEvent(eventFrame, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(deferred.checkbox)
enabled = false; local skipped = frame('CheckButton', nil, GTFO_MainFrame)
GTFO_RefreshOptions(); flush(); assert(not skipped.checkbox)
enabled = true
print('PASS: GTFO late options, settings-only roots, preserved sound/actions/values, themes, combat/toggles and idempotence')
local fills = 0; S.ApplyBarFill = function() fills = fills + 1 end
-- Gargul's SetFont(rem, flags) overload must never receive a font path.
Gargul = nil
assert(loadfile('EUIAddonSkins/Skins/Gargul.lua'))('EUIAddonSkins', ns)
assert(not modules.Gargul.available())
UIParent = frame()
S.GetFont = function() return 'eui', 'OUTLINE' end
local gargulRoot = frame('Frame', 'GargulTestWindow', UIParent)
local overloaded = gargulRoot:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
overloaded._SetFont = overloaded.SetFont
overloaded.SetFont = function(self, rem) assert(type(rem) == 'number', 'Gargul SetFont called with a path'); self:_SetFont('gargul-' .. rem) end
overloaded:SetTextColor(0.2, 0.8, 0.3, 0.6)
local input = frame('EditBox', nil, gargulRoot); input._SetFont = function(self, path) self.font = path end
input.GetFont = function() return 'native', 12 end
input.SetFont = function(_, rem) assert(type(rem) == 'number') end
local countdown = frame('StatusBar', nil, gargulRoot); countdown.value = 17
local gear = frame('Button', nil, gargulRoot); gear.Texture = gear:CreateTexture()
local protected = frame('Button', nil, gargulRoot); protected.protected = true; protected.action = 'award-native'
local dropdown = frame('Frame', nil, gargulRoot); dropdown.initialize = function() end
local binding = false
ns.BindPopupOwner = function(_, module, f) if module == modules.Gargul and f == dropdown then binding = true end end
local scope = {InterfaceItems = {Frame = {Window = {frame = gargulRoot, type = 'Frame'}}}}
local iface = {Award = scope, set = function(_, s, id, item) s.InterfaceItems = {Frame = {[id] = item}}; return 'set-native' end,
    createWindow = function(_, details) return frame('Frame', details.name, UIParent) end}
Gargul = {Interface = iface, UI = {components = {}}}
local navigation = frame('Frame', nil, gargulRoot)
local navRow = frame('Button', nil, navigation)
local navLabel = navRow:CreateFontString(nil, 'ARTWORK', 'GameFontNormal'); navLabel:SetTextColor(0.1, 0.1, 0.1, 1)
local sections = {frame = navigation, Refresh = function() return 'refresh-native' end, SetData = function() return 'data-native' end}
local overview = {InterfaceItems = {Frame = {Window = {frame = gargulRoot, type = 'Frame'}}, Table = {Sections = sections}}}
local drawn
overview.showSection = function() drawn = frame('CheckButton', nil, gargulRoot); return 'section-native' end
iface.Settings = {Overview = overview}
modules.Gargul.install(S, modules.Gargul); flush()
assert(gargulRoot.shellOptions.noBorder and input.inputOptions.noBorder, 'Gargul soft shell/input missing')
assert(gargulRoot.shell and gargulRoot.accent and binding and input.input and input.font == 'eui')
assert(overloaded.font == 'eui' and overloaded.textColor[2] == 0.8 and overloaded.textColor[4] == 0.6)
assert(gear.Texture.crop and countdown.value == 17 and fills == 0 and not protected.button and protected.action == 'award-native')
assert(navLabel.textColor[1] == 0.9 and not navRow.button, 'Gargul sidebar must be readable without boxed rows')
navLabel:SetTextColor(0.1, 0.1, 0.1, 1); assert(navLabel.textColor[1] == 0.9)
assert(overview:showSection() == 'section-native' and drawn.checkbox, 'Gargul section must be styled before returning')
do
local newNav = frame('Button', nil, navigation)
local newNavLabel = newNav:CreateFontString(nil, 'ARTWORK', 'GameFontNormal'); newNavLabel:SetTextColor(0.1, 0.1, 0.1, 1)
flush(); auditScans[gargulRoot], auditScans[navigation] = 0, 0
for _ = 1,100 do assert(sections:Refresh() == 'refresh-native') end
flush()
assert(newNavLabel.font == 'eui' and newNavLabel.textColor[1] == 0.9 and not newNav.button)
print(('BENCH gargul_navigation full=%d local=%d callbacks=100'):format(auditScans[gargulRoot] or 0, auditScans[navigation] or 0))
if not auditBaseline then assert(auditScans[gargulRoot] == 0 and auditScans[navigation] == 100, 'navigation updates scanned unrelated Gargul windows') end
end

overloaded:SetFont(2); flush(); assert(overloaded.font == 'eui', 'Gargul relative-size updates must retain the EUI font')
local dynamicRoot = iface:createWindow({name = 'GargulDynamic'}); local late = frame('CheckButton', nil, dynamicRoot)
flush(); assert(dynamicRoot.shell and late.checkbox)
local dialogRoot = frame('Frame', nil, UIParent)
assert(iface:set(scope, 'Window', {frame = dialogRoot, type = 'GLAwardDialog'}) == 'set-native'); flush(); assert(dialogRoot.shell)
local hook, regions, fontHook = iface.createWindow, #gear.regions, overloaded.SetFont
for _ = 1, 5 do modules.Gargul.refresh(); flush() end
assert(iface.createWindow == hook and #gear.regions == regions and overloaded.SetFont == fontHook)
combat = true; local combatRoot = iface:createWindow({name = 'GargulCombat'}); flush(); assert(not combatRoot.shell)
combat = false
for _, eventFrame in ipairs(events) do if eventFrame.events and eventFrame.events.PLAYER_REGEN_ENABLED then eventFrame.hooks.OnEvent(eventFrame, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(combatRoot.shell)
enabled = false; local disabledRoot = iface:createWindow({name = 'GargulDisabled'}); flush(); assert(not disabledRoot.shell)
enabled = true
print('PASS: Gargul owned registry/factory/dialogs, overloaded fonts/inputs, menu ownership, icons, countdowns, secure actions and idempotence')
combat = true
local late = frame('Button', 'Attune_Node_43', Attune_GraphRoot); late.SetBackdrop = nil
modules.Attune.refresh(); flush(); assert(not late.button)
combat = false; enabled = false; modules.Attune.refresh(); flush()
print('PASS: thin semantic nodes, graph/icon preservation, toggle actions, legacy slider geometry, square contained portraits, live colours and idempotence')
