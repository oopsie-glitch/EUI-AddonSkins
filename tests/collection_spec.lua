-- Integration regressions for optional, lazy targets and session-only RXP themes.
local timers, errors, modules, looks = {}, {}, {}, {}
local enabled = true
local popupOptions
local ns = {IsEnabled = function() return enabled end,
    BindPopupOwner = function(_, _, _, options) popupOptions = options end, RefreshPopupMenus = function() end}
function ns.RegisterModule(id, label, available, install)
    modules[id] = {available = available, install = install}
end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
C_Timer.After = function(_, fn) timers[#timers + 1] = fn end
hooksecurefunc = function(object, key, fn)
    local original = object[key]
    object[key] = function(...)
        local result = table.pack(original(...)); fn(...); return table.unpack(result, 1, result.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 15, 'refresh loop')
    end
end
local function region(path, layer)
    return {alpha = 0.8, GetObjectType = function() return 'Texture' end,
        GetTexture = function() return path end, GetDrawLayer = function() return layer end,
        GetAlpha = function(self) return self.alpha end, SetAlpha = function(self, a) self.alpha = a end}
end
local function frame(kind)
    local f = {kind = kind or 'Frame', children = {}, regions = {}, hooks = {}}
    function f:CreateTexture(_, layer, _, sublevel)
        self.created = self.created or {}
        local t = {SetPoint = function(self, ...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end, ClearAllPoints = function(self) self.points = {} end, SetHeight = function(self, h) self.height = h end, SetSize = function(self, w, h) self.width, self.height = w, h end, SetWidth = function(self, w) self.width = w end,
            SetColorTexture = function(self, ...) self.color = {...} end,
            SetAllPoints = function(self, target) self.allPoints = target end,
            AddMaskTexture = function(self, mask) self.masks = self.masks or {}; table.insert(self.masks, mask) end,
            RemoveMaskTexture = function(self, mask)
                assert(self.masks[1] == mask); table.remove(self.masks, 1)
            end,
            SetAlpha = function(self, a) self.alpha = a end,
            GetAlpha = function(self) return self.alpha or 1 end,
            SetGradient = function(self, _, lo, hi)
                self.gradient = {{lo.r, lo.g, lo.b, lo.a}, {hi.r, hi.g, hi.b, hi.a}}
                self.alpha = lo.a
            end,
            SetBlendMode = function(self, mode) self.blend = mode end,
            SetTexCoord = function(self, ...) self.coords = {...} end,
            GetTexCoord = function(self) return table.unpack(self.coords) end,
            GetHeight = function(self) return self.height end,
            GetTexture = function(self) return self.path end,
            SetTexture = function(self, path) self.path = path end, SetVertexColor = function(self, r, g, b, a) self.tint = {r, g, b, a}; self.alpha = a end,
            GetVertexColor = function(self) return table.unpack(self.tint or {1, 1, 1, 1}) end,
            SetHorizTile = function() end, SetVertTile = function() end,
            SetShown = function(self, shown) self.shown = shown end}
        t.layer, t.sublevel = layer, sublevel
        self.created[#self.created + 1] = t
        return t
    end
    function f:CreateMaskTexture()
        return {
            SetTexture = function(self, path, x, y) self.path, self.wrapX, self.wrapY = path, x, y end,
            SetTextureSliceMargins = function(self, ...) self.margins = {...} end,
            SetTextureSliceMode = function(self, mode) self.mode = mode end,
            SetAllPoints = function(self, edge) self.edge = edge end,
        }
    end
    function f:SetFrameLevel(level) self.level = level end
    function f:SetAlpha(alpha) self.alpha = alpha end
    function f:GetAlpha() return self.alpha or 1 end
    function f:GetFrameLevel() return self.level or 4 end
    function f:GetFrameStrata() return self.strata or "BACKGROUND" end
    function f:GetHeight() return self.height or 24 end
    function f:SetHeight(h) self.height = h end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:GetPoint(i) return table.unpack((self.points or {})[i or 1] or {}) end
    function f:GetNumPoints() return #(self.points or {}) end
    function f:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function f:ClearAllPoints() self.points = {} end
    function f:IsShown() return self.shown ~= false end
    function f:SetShown(shown)
        if self:IsShown() == shown then return end
        self.shown = shown
        local callback = self.hooks[shown and "OnShow" or "OnHide"]
        if callback then callback(self) end
    end
    function f:SetAllPoints(target) self.allPoints = target end
    function f:EnableMouse(value) self.mouseEnabled = value end
    function f:GetObjectType() return self.kind end
    function f:IsProtected() return self.protected end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:HookScript(key, fn) self.hooks[key] = fn end
    function f:SetBackdrop(v) self.backdropValue = v; self.borderColor = {1, 1, 1, 1} end
    function f:GetBackdrop() return self.backdropValue end
    function f:SetBackdropColor() end
    function f:SetBackdropBorderColor(...) self.borderColor = {...} end
    function f:GetBackdropBorderColor() return table.unpack(self.borderColor or {1, 1, 1, 1}) end
    return f
end
local savedCreateColor = CreateColor
CreateColor = function(r, g, b, a)
    return {r = r, g = g, b = b, a = a, SetRGBA = function(self, nr, ng, nb, na)
        self.r, self.g, self.b, self.a = nr, ng, nb, na
    end}
end
local parents = {}
local combat, combatEvents = false
InCombatLockdown = function() return combat end
CreateFrame = function(_, _, parent)
    local f = frame()
    parents[f] = parent
    function f:RegisterEvent(event) self.event = event; combatEvents = self end
    function f:SetScript(event, fn) self.hooks[event] = fn end
    return f
end
local S = {GetAccentColor = function() return 0.1, 0.8, 0.6 end,
    GetPanelColor = function() return 0.03, 0.03, 0.04, 0.95 end,
    GetFont = function() return 'EUI-font', 'OUTLINE' end,
    OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
local shells, edits = 0, 0
function S.Shell(f, options) f.shellOptions = options; shells = shells + 1; for _, r in ipairs(f.regions) do r:SetAlpha(0) end end
local registeredPanels = {}
function S.Panel(f) registeredPanels[f] = true; for _, r in ipairs(f.regions) do r:SetAlpha(0) end end
function S.EditBox(f) edits = edits + 1; assert(not f.protected) end
for _, key in ipairs({'Font', 'Button', 'StateButtonLabel', 'Checkbox', 'Dropdown', 'ScrollBar', 'CloseButton', 'FadeNineSlice', 'PageButton'}) do S[key] = function(f) if key == 'CloseButton' then f.euiClose = true end end end
for _, file in ipairs({'EUIAddonSkins/Accent.lua', 'EUIAddonSkins/Widgets.lua', 'EUIAddonSkins/Skins/ForeverDungeonJournal.lua', 'EUIAddonSkins/Skins/RXPGuides.lua'}) do
    assert(loadfile(file))('EUIAddonSkins', ns)
end
RXP = nil; ForeverDungeonJournal_NS = nil
assert(not modules.RXPGuides.available() and not modules.ForeverDungeonJournal.available(), 'targets must be optional')
local source = {font = 'original-font', background = {1, 1, 1, 1}, textColor = {1, 0, 0}, mapPins = {1, 0, 0}, tooltip = {1, 1, 0}}
local source2 = {font = 'original-v2', backgroundColors = {common = {1, 1, 1}}, borderColors = {common = {1, 1, 1}}, textColor = {title = {1, 1, 0}}, edge = {}, mapPins = {0, 1, 1}, navigationArrow = 'arrow'}
local guide = frame()
guide.backdrop = {
    edge = {edgeSize = 8, insets = {left = 4, right = 2, top = 2, bottom = 4}},
    guideName = {edgeSize = 8, insets = {left = 4, right = 2, top = 2, bottom = 4}},
    bottom = {insets = {left = 4, right = 2, top = 2, bottom = 4}},
}
guide.GuideName = frame(); guide.GuideName.bg = region('banner', 'BACKGROUND'); guide.GuideName.icon = region('logo', 'ARTWORK')
guide.GuideName:SetHeight(35)
guide.BottomFrame = frame(); guide.BottomFrame:SetBackdrop({edgeFile = 'old'})
local step = frame(); step.number = frame(); step:SetBackdrop({edgeFile = 'old'}); step.number:SetBackdrop({edgeFile = 'old'})
guide.CurrentStepFrame = frame(); guide.CurrentStepFrame.framePool = {step}
guide.Footer = frame(); guide.Footer.bg = region('footer', 'BACKGROUND')
local secret, input = frame('EditBox'), frame('EditBox'); secret.protected = true
guide.children = {secret, input}
local guideCreates, originalCalls, renders = 0, 0, 0
local lazyTarget
local shownMenu
local savedOptionsText = GAMEOPTIONS_MENU
GAMEOPTIONS_MENU = "Options"
RXP = {targeting = {CreateTargetFrame = function(self) self.activeTargetFrame = lazyTarget end}, RXPFrame = guide, settings = {profile = {activeTheme = 'Custom', guideFontSize = 12}},
    ShowMenu = function(_, menu, owner) shownMenu = menu; return owner, nil, 9 end,
    LoadActiveTheme = function() originalCalls = originalCalls + 1; return source, nil, 'tail' end,
    RenderFrame = function() renders = renders + 1; return nil, 'render-tail' end,
    LoadGuide = function(_, key) return key end,
    v2 = {state = {}, DisableLegacyGuideWindow = function()
            for _, panel in ipairs({guide.BottomFrame, guide.GuideName, guide.Footer, guide.CurrentStepFrame}) do
                panel:SetShown(false)
            end
        end,
        UpdatePlayerActiveStepItem = function() return "native update" end, GetTheme = function() return source2 end,
        GetGuideWindow = function(self)
            guideCreates = guideCreates + 1
            local window = {frame = frame(), banner = region('v2-banner', 'ARTWORK'), UpdateTheme = function() end}
            self.state.guideWindow = window; return window
        end}}
assert(modules.RXPGuides.available())
modules.RXPGuides.install(S, modules.RXPGuides); flush()
assert(guide.BottomFrame.borderColor[1] == 0.055 and step.borderColor[1] == 0.055 and step.number.borderColor[1] == 0.055, 'legacy border tint missing')
guide.protected = true
step:SetBackdrop({edgeFile = 'old'}); assert(step.borderColor[1] == 0.055, 'white border visible before queued refresh'); flush()
assert(step.borderColor[1] == 0.055, 'reused step backdrop became white on a protected guide root')
step:SetBackdropBorderColor(0.1, 0.8, 0.6, 1); assert(step.borderColor[2] == 0.8, 'semantic status border changed')
step:SetBackdropBorderColor(0.2, 0.2, 0.22, 1); assert(step.borderColor[1] == 0.055, 'neutral border must stay subdued')
guide.protected = false
assert(guideCreates == 0, 'skin must not create lazy guide windows')
assert(edits == 1, 'protected controls must remain unstyled')
assert(guide.GuideName.bg.alpha == 0, 'legacy banner remains visible')
local theme, empty, tail = RXP:LoadActiveTheme()
assert(theme ~= source and empty == nil and tail == 'tail', 'theme wrapper lost returns')
assert(theme.font == 'EUI-font' and source.font == 'original-font' and source.background[1] == 1)
assert(theme.mapPins == source.mapPins and theme.tooltip == source.tooltip, 'semantic colors changed')
assert(RXP.settings.profile.activeTheme == 'Custom' and RXP.settings.profile.guideFontSize == 12)
assert(RXP.colors == theme and RXP.RXPFrame.backdrop.edge.edgeSize == 1)
-- The native renderer applies these shared backdrops to guide panels, pooled
-- active steps, step-number badges and the Active Targets title/body.
for _, key in ipairs({'edge', 'guideName', 'bottom'}) do
    local backdrop = guide.backdrop[key]
    local expected = key == 'bottom' and 0 or backdrop.edgeSize
    for _, side in ipairs({'left', 'right', 'top', 'bottom'}) do
        assert(backdrop.insets[side] == expected, 'fill detached from border: ' .. key .. '/' .. side)
    end
end
step:SetBackdrop(guide.backdrop.edge); step.number:SetBackdrop(guide.backdrop.edge); flush()
assert(step:GetBackdrop().insets.left == 1 and step.number:GetBackdrop().insets.bottom == 1)

local v2 = RXP.v2:GetTheme()
assert(v2 ~= source2 and v2.backgroundColors ~= source2.backgroundColors)
assert(source2.backgroundColors.common[1] == 1 and v2.mapPins == source2.mapPins and v2.navigationArrow == 'arrow')
local window = RXP.v2:GetGuideWindow(); flush()
assert(window.banner.alpha == 0 and guideCreates == 1)
window.banner:SetAlpha(1); assert(window.banner.alpha == 0, 'banner alpha lock missing')
-- The whole-UI look, rather than the game client or the eui/modern palette,
-- selects the variant. Exercise the existing theme and layout refresh route.
local activeLook = "eui"
local rimCalls, lastRim = 0
local rings = {}
local row = frame()
function row:IsShown() return true end
function row:SetBackdropColor(...) self.fill = {...} end
function row:GetBackdropColor() return table.unpack(self.fill or {}) end
guide.ScrollChild = {framePool = {row}}
local button = frame("Button")
local guidePanel = frame()
guidePanel.GetFrameLevel = function() return 4 end
guidePanel.rxpBackground = region("fill", "BACKGROUND")
guidePanel.rxpBackground.textures = {{GetVertexColor = function() return 1, 1, 1, 0.95 end}}
guidePanel.rxpBorder = region("edge", "BORDER")
window.guideStepsFrame = guidePanel
local band = frame()
band.GetFrameLevel = guidePanel.GetFrameLevel
band.rxpBackground = region("fill", "BACKGROUND")
band.rxpBorder = region("edge", "BORDER")
window.guideNameFrame = band
window.footer = frame()
window.footerBackground = region("footer", "BACKGROUND")
local bandBorderAlpha = band.rxpBorder:GetAlpha()
local oldBorderAlpha = guidePanel.rxpBorder:GetAlpha()
window.settingsButton = button
window.guideSteps = {items = {}, SetRows = function(self, items) self.items = items end}
local scrollButton = frame("Button")
scrollButton.Normal = region("native", "ARTWORK")
function scrollButton:IsEnabled() return not self.disabled end
local scrollAction = function() return "native scroll" end
scrollButton.click = scrollAction
window.guideSteps.scroll = {scrollbar = {ScrollUpButton = scrollButton}}
local checkbox = frame("CheckButton")
local checked, disabledChecked = checkbox:CreateTexture(), checkbox:CreateTexture()
checked:SetTexture("Interface\\AddOns\\RXPGuides\\Textures\\DarkMode\\rxp-checked-32.blp")
disabledChecked:SetTexture("Interface/AddOns/RXPGuides/Textures/rxp-checked-32")
checkbox.theme = {}
checked.GetObjectType = function() return "Texture" end
disabledChecked.GetObjectType = checked.GetObjectType
checkbox.GetCheckedTexture = function() return checked end
checkbox.GetDisabledCheckedTexture = function() return disabledChecked end
local element = {button = checkbox}
function checkbox:GetParent() return element end
function element:GetLeft() return 100 end
function element:GetRight() return self.right or 350 end
function element:GetEffectiveScale() return 0.8 end
local click = function(self)
    if self.mouseEnabled then
        self.checked = not self.checked
        element.skip = self.checked -- RestedXP PostClick copies GetChecked() to element.skip.
    end
    return "native check"
end
checkbox.click = click
checkbox:EnableMouse(true)
step.elements = {element}
guide.children[#guide.children + 1] = checkbox
local statusCheckbox = frame("CheckButton")
local statusCheck = statusCheckbox:CreateTexture()
statusCheck.GetObjectType = checked.GetObjectType
statusCheck:SetTexture("Interface/AddOns/RXPGuides/Textures/rxp-checked-32")
statusCheck:SetVertexColor(0.85, 0.17, 0.15, 1)
statusCheckbox.theme = {}
function statusCheckbox:GetCheckedTexture() return statusCheck end
guide.children[#guide.children + 1] = statusCheckbox
local up, down = frame("Button"), frame("Button")
local position = 5
for _, arrow in ipairs({up, down}) do
    arrow:SetSize(20, 20)
    arrow.regions = {region("original-arrow", "ARTWORK")}
    arrow.IsEnabled = scrollButton.IsEnabled
    function arrow:Click()
        if self:IsEnabled() then position = position + (self == up and -1 or 1) end
    end
end
local legacyBar = frame("Slider")
legacyBar.ScrollUpButton, legacyBar.ScrollDownButton = up, down
guide.ScrollFrame = {ScrollBar = legacyBar}
local v2Row = frame()
v2Row.rxpBackground = frame()
v2Row.rxpBackground.textures = {{GetVertexColor = function() return 1, 1, 1, 0.95 end}}
function v2Row:IsShown() return true end
EllesmereUI = {
    IS_FOREVER = true,
    ForeverBorder = function(host, _, _, _, kind)
        assert(kind == "textured")
        rimCalls = rimCalls + 1
        local edge = host:CreateTexture()
        edge:SetTexture("live-forever-rim")
        edge:SetTexCoord(0.1, 0.2, 0.3, 0.4)
        edge:SetHeight(6)
        lastRim = {on = true, host = host, texture = edge, [5] = edge}
        if parents[host] then rings[parents[host]] = lastRim end
        return lastRim
    end,
    ForeverBorderSeat = function(ring, host, _, ...)
        assert(ring.host == host or parents[ring.host] == host)
        ring.insets = {...}
    end,
    ForeverBorderShown = function(ring, shown) ring.on = shown end,
    ForeverBorderDivider = function(host, layer, sub)
        local texture = host:CreateTexture(nil, layer, nil, sub)
        texture:SetTexture("forever-rule")
        texture:SetHeight(6)
        return texture
    end,
    GetActiveProfileData = function() return {windowSkinLook = activeLook} end,
    ProfileWindowSkinLook = function(profile)
        return EllesmereUI.IS_FOREVER and profile.windowSkinLook or "blizzard"
    end,
}
assert(RXP.v2:GetTheme().borderColors.common[1] == 0.055)
local savedTextureAPI = C_Texture
local firstAtlas = true
C_Texture = {GetAtlasInfo = function()
    -- Only the V1 header takes the atlas for this fixture. V2 still tests
    -- the fallback branch below.
    if not firstAtlas then return end
    firstAtlas = false
    return {file = 12345, leftTexCoord = 0, rightTexCoord = 1, topTexCoord = 0, bottomTexCoord = 1}
end}
guide.GuideName:SetBackdrop({bgFile = "white"})
local savedEnum = Enum
Enum = {UITextureSliceMode = {Stretched = 0}}
activeLook = "forever"
modules.RXPGuides.refresh(); flush()
assert(rimCalls == 5 and lastRim.on and parents[lastRim.host] == button)
assert(checkbox.click == click and checkbox:click() == "native check" and element.skip)
checkbox:click(); assert(element.skip == false and checkbox.mouseEnabled)
assert(checked.path:find("UI-CheckBox-Check", 1, true) and checked.width == 8 and checkbox.created[3].shown)
assert(checked.tint[1] == 0.91 and checked.tint[2] == 0.71 and disabledChecked.tint[1] == 0.53)
assert(statusCheck.path:find("rxp-checked-32", 1, true) and statusCheck.tint[2] == 0.17)
local skipBorder = checkbox.created[4]
assert(#checkbox.created == 7 and skipBorder.shown and skipBorder.height == 1 and skipBorder.points[1][2] == checkbox)
local oldTooltip, oldUIParent = GameTooltip, UIParent
GameTooltip = frame()
function GameTooltip:GetOwner() return self.owner end
function GameTooltip:GetWidth() return 90 end
function GameTooltip:GetEffectiveScale() return 1 end
UIParent = {GetRight = function() return 750 end, GetEffectiveScale = function() return 1 end}
GameTooltip.owner = checkbox
checkbox.hooks.OnEnter(checkbox)
assert(GameTooltip.points[1][1] == "LEFT" and GameTooltip.points[1][2] == element and GameTooltip.owner == checkbox)
element.right = 890
checkbox.hooks.OnEnter(checkbox)
assert(GameTooltip.points[1][1] == "RIGHT" and GameTooltip.points[1][3] == "LEFT")
GameTooltip, UIParent = oldTooltip, oldUIParent
local upHost, downHost = rings[up].host, rings[down].host
for _, arrow in ipairs({up, down}) do
    local host = rings[arrow].host
    local glyph, fill = host.created[1], host.created[3]
    assert(host.allPoints == arrow and not host.mouseEnabled and not registeredPanels[host])
    assert(table.concat(rings[arrow].insets, ",") == "3,-3,-3,3" and arrow.width == 20)
    assert(glyph.path:find(arrow == up and "eui-arrow-up3" or "eui-arrow-down3", 1, true))
    assert(arrow.regions[1]:GetAlpha() == 0 and fill.color[1] == 0.06)
    arrow.hooks.OnEnter()
    assert(fill.color[1] == 0.12)
    arrow.hooks.OnMouseDown()
    assert(fill.color[1] == 0.035)
    arrow.hooks.OnMouseUp()
    assert(fill.color[1] == 0.12)
    arrow:Click()
    arrow.disabled = true; arrow.hooks.OnDisable()
    assert(host:GetAlpha() == 0.65 and glyph:GetAlpha() == 0.45)
    local prior = position
    arrow:Click()
    assert(position == prior)
    arrow.hooks.OnLeave()
    arrow.disabled = false; arrow.hooks.OnEnable()
    assert(host:GetAlpha() == 1 and glyph:GetAlpha() == 1)
end
assert(position == 5)
assert(scrollButton.click == scrollAction and scrollButton.Normal:GetAlpha() == 0)
local scrollIcon = scrollButton.created[1]
assert(scrollIcon.path:find("eui-arrow-up3", 1, true) and scrollIcon.points[1][2] == scrollButton)
scrollButton.disabled = true
scrollButton.hooks.OnDisable()
assert(scrollIcon:GetAlpha() == 0.45)
assert(guidePanel.rxpBorder:GetAlpha() == 0 and band.rxpBorder:GetAlpha() == 0)
assert(guide.BottomFrame.borderColor[4] == 0 and step.borderColor[4] == 0)
local legacyArt, guideArt = rings[guide].host, rings[window.frame].host
assert(legacyArt.points[1][2] == guide.CurrentStepFrame and legacyArt.points[2][2] == guide.Footer)
assert(guideArt.points[1][2] == band and guideArt.points[2][2] == window.footer)
guide.CurrentStepFrame:SetShown(false)
assert(legacyArt.points[1][2] == guide.GuideName)
guide.CurrentStepFrame:SetShown(true)
assert(legacyArt.points[1][2] == guide.CurrentStepFrame)
-- Simulate EUI's Restrip: only registered frames' direct textures are faded.
assert(not registeredPanels[guideArt] and not registeredPanels[legacyArt])
assert(guideArt.mouseEnabled == false and legacyArt.mouseEnabled == false)
registeredPanels[button] = true
for host in pairs(registeredPanels) do
    for _, texture in ipairs(host.created or {}) do texture:SetAlpha(0) end
end
for _, art in ipairs({legacyArt, guideArt}) do
    local alpha = art:GetAlpha()
    local plate, grain = art.created[1].alpha * alpha, art.created[2].alpha * alpha
    assert(art.created[1].color[1] == 0.165)
    assert(math.abs(1 - (1 - plate) * (1 - grain) - 0.66 * 0.95 / 0.92) < 0.0001)
    for i = 1, 2 do
        local fill = art.created[i]
        assert(fill.allPoints == art and #fill.masks == 1)
        local mask = fill.masks[1]
        assert(mask.edge == art and mask.mode == 0 and table.concat(mask.margins, ",") == "8,8,8,8")
        assert(mask.wrapX == "CLAMPTOBLACKADDITIVE" and mask.wrapY == "CLAMPTOBLACKADDITIVE")
    end
    assert(art.created[1].layer == "BACKGROUND" and art.created[1].sublevel == 1)
    assert(art.created[2].layer == "BACKGROUND" and art.created[2].sublevel == 2)
end
local bandArt, legacyHeaderArt
for host, parent in pairs(parents) do
    if parent == band and host.created and #host.created == 3 then bandArt = host end
    if parent == guide.GuideName and host.created and #host.created == 4 then legacyHeaderArt = host end
end
local topRule = assert(legacyHeaderArt and legacyHeaderArt.created[3])
local bottomRule = legacyHeaderArt.created[4]
assert(legacyHeaderArt.created[1].coords[4] == 33 / 40 and topRule.path == rings[guide][5].path)
assert(table.concat(topRule.coords, ",") == table.concat(rings[guide][5].coords, ","))
assert(topRule.height == 6 and topRule.points[1][1] == "TOPLEFT" and topRule.points[2][1] == "TOPRIGHT")
assert(topRule.points[1][2] == legacyHeaderArt and topRule.points[2][2] == legacyHeaderArt)
for _, point in ipairs(topRule.points) do assert(point[4] == 0 and point[5] == 2) end
guide.CurrentStepFrame:SetShown(false)
assert(not topRule.shown, "the upper separator must yield to the outer rim")
guide.CurrentStepFrame:SetShown(true)
assert(topRule.shown)
assert(legacyHeaderArt.mouseEnabled == false and not registeredPanels[legacyHeaderArt])
assert(topRule:GetAlpha() == bottomRule:GetAlpha() and topRule:GetAlpha() > 0)
assert(topRule.masks[1] == legacyHeaderArt.created[1].masks[1] and bottomRule.masks[1] == topRule.masks[1])
assert(topRule.sublevel > legacyHeaderArt.created[1].sublevel and bottomRule.sublevel == topRule.sublevel)
assert(bandArt and bandArt.mouseEnabled == false and bandArt.created[1].color[1] == 0.185 and bandArt.created[2].alpha > 0)
assert(bandArt.created[1].masks[1].edge == guideArt)
assert(lastRim.texture.alpha ~= 0 and rings[window.frame].texture.alpha ~= 0)
local base = 0.66 * 0.95 / 0.92
local bandAlpha = 1 - (1 - base) * (1 - bandArt.created[1].alpha) * (1 - bandArt.created[2].alpha)
assert(math.abs(bandAlpha - 0.80 * 0.95 / 0.92) < 0.0001)
local stepFill = legacyArt.created[3]
assert(stepFill.shown and stepFill.allPoints == guide.CurrentStepFrame and stepFill.masks[1] == legacyArt.created[1].masks[1])
local stepAlpha = 1 - (1 - base) * (1 - stepFill.alpha * legacyArt:GetAlpha())
assert(math.abs(stepAlpha - 0.75 * 0.95 / 0.92) < 0.0001)
guide.CurrentStepFrame:SetShown(false)
assert(not stepFill.shown)
guide.CurrentStepFrame:SetShown(true)
assert(stepFill.shown)

assert(#row.created == 1 and row.created[1].shown)
window.guideSteps:SetRows({{frame = v2Row}})
assert(#v2Row.created == 1 and v2Row.created[1].shown)
local v2Fill = 0.95 * v2Row.rxpBackground:GetAlpha()
assert(math.abs(1 - (1 - base) * (1 - v2Fill) - 0.70 * 0.95 / 0.92) < 0.0001)
assert(v2Row:GetAlpha() == 1 and window.footerBackground:GetAlpha() == 0)
modules.RXPGuides.refresh(); flush()
assert(rimCalls == 5 and #row.created == 1 and #v2Row.created == 1)
local bronze = RXP.v2:GetTheme()
assert(bronze.borderColors.common[1] == 0.49)
assert(bronze.backgroundColors.guideName[1] > bronze.backgroundColors.common[1])
assert(step.borderColor[1] == 0.49 and RXP.colors.background[1] == 0.062)
assert(math.abs(1 - (1 - base) * (1 - RXP.colors.bottomFrameBG[4]) - 0.70 * 0.95 / 0.92) < 0.0001)
assert(RXP.colors.bottomFrameHighlight[2] == 0.8 and RXP.colors.bottomFrameHighlight[4] == 1)
assert(bronze.backgroundColors.common[4] == 0.95) -- V2 native row fill is unchanged.
step:SetBackdropBorderColor(0.1, 0.8, 0.6, 1)
assert(step.borderColor[2] == 0.8)
step:SetBackdrop(guide.backdrop.edge)
assert(step.borderColor[1] == 0.49)
activeLook = "eui"
modules.RXPGuides.refresh(); flush()
assert(step.borderColor[1] == 0.055 and RXP.colors.background[1] == 0.03)
assert(not lastRim.on and not row.created[1].shown and not v2Row.created[1].shown)
assert(not legacyArt:IsShown() and not guideArt:IsShown() and not legacyHeaderArt:IsShown())
assert(not skipBorder.shown and not upHost:IsShown() and not downHost:IsShown())
assert(up.regions[1]:GetAlpha() == 0.8 and down.regions[1]:GetAlpha() == 0.8)
assert(not checkbox.created[3].shown and not scrollIcon.shown and scrollButton.Normal:GetAlpha() == 0.8)
assert(v2Row.rxpBackground:GetAlpha() == 1 and window.footerBackground:GetAlpha() == 0.8)
assert(RXP.colors.bottomFrameBG[4] == 0.95 and RXP.colors.bottomFrameHighlight[4] == 1)
assert(step.borderColor[4] == 1 and guide.BottomFrame.borderColor[4] == 1)
assert(guidePanel.rxpBorder:GetAlpha() == oldBorderAlpha and band.rxpBorder:GetAlpha() == bandBorderAlpha)
activeLook = "forever"
modules.RXPGuides.refresh(); flush()
assert(rimCalls == 5 and legacyArt:IsShown() and guideArt:IsShown())
assert(skipBorder.shown and upHost:IsShown() and downHost:IsShown())
guide.CurrentStepFrame.height = 0
modules.RXPGuides.refresh(); flush()
assert(legacyArt.points[1][2] == guide.GuideName)
step.strata = "MEDIUM"
modules.RXPGuides.refresh(); flush()
local tipRing = lastRim
assert(rimCalls == 6 and tipRing.host:IsShown() and tipRing.host.mouseEnabled == false)
step.strata = nil
modules.RXPGuides.refresh(); flush()
assert(rimCalls == 6 and not tipRing.host:IsShown() and step.borderColor[4] == 0)
C_Texture = {GetAtlasInfo = function(atlas)
    assert(atlas == "ui-questtracker-primary-objective-header")
    return {file = 12345, leftTexCoord = 0, rightTexCoord = 1, topTexCoord = 0, bottomTexCoord = 1}
end}
local auxTarget, auxItem = frame(), frame()
local function label()
    local text = frame("FontString")
    text.font = {"RXP-font", 12, ""}
    function text:GetFont() return table.unpack(self.font) end
    function text:SetFont(...) self.font = {...} end
    function text:GetTextColor() return 0.8, 0.7, 0.4, 1 end
    function text:SetTextColor(...) self.tint = {...} end
    function text:SetText(value) self.value = value end
    function text:GetText() return self.value end
    function text:SetJustifyH(value) self.justify = value end
    return text
end
local resizeButton = frame("Button")
resizeButton:SetSize(16, 16)
resizeButton:SetPoint("BOTTOMRIGHT", guide.Footer, "BOTTOMRIGHT", -1, 3)
resizeButton:EnableMouse(true)
resizeButton.regions = {region("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Up", "ARTWORK")}
function resizeButton:CreateFontString()
    local text = label()
    self.regions[#self.regions + 1] = text
    return text
end
local dragging, width = false, 200
local startSizing = function() dragging = true end
local stopSizing = function() dragging = false end
resizeButton.hooks.OnMouseDown, resizeButton.hooks.OnMouseUp = startSizing, stopSizing
guide.Footer.icon = resizeButton
local nativeAccept = "|TInterface/GossipFrame/AvailableQuestIcon:0|t"
local nativeTurnin = "|TInterface/GossipFrame/ActiveQuestIcon:0|t"
local nativeTalk = "|Tinterface/worldmap/chatbubble_64grey.blp:20|t"
local nativeFlag = "|TInterface/WORLDSTATEFRAME/ColumnIcon-FlagCapture2:0|t"
local statusIcons = "|TInterface/GossipFrame/DailyQuestIcon:0|t|T135421:0|t|A:questlegendary:12:12|a"
local originalMarkers = nativeAccept .. nativeTurnin .. nativeTalk .. nativeFlag .. statusIcons .. "|cff00ff00NPC|r"
row.text = label()
row.text:SetText(originalMarkers)
local activeIcon = label()
activeIcon:SetText(nativeAccept)
element.icon = activeIcon
local v2Icon = label()
v2Icon:SetText(nativeTalk)
local v2Text = label()
v2Text:SetText(nativeFlag)
local activeItem = {elementRows = {{icon = v2Icon, text = v2Text}}}
local v2ListText = label()
v2ListText:SetText(nativeTurnin)
window.guideSteps:SetRows({{frame = v2Row, text = v2ListText}})
RXP.v2.state.player = {Player = {activeStepFrame = {children = {activeItem}}}}
assert(RXP.v2:UpdatePlayerActiveStepItem(activeItem) == "native update")
local function CheckBronzeMarkers()
    local text = row.text:GetText()
    assert(text:find("RestedXPQuestAccept:0|t", 1, true))
    assert(text:find("RestedXPQuestTurnIn:0|t", 1, true))
    assert(text:find("RestedXPTalk:20|t", 1, true))
    assert(text:find("RestedXPRouteFlag:0|t", 1, true))
    assert(text:find(statusIcons .. "|cff00ff00NPC|r", 1, true))
    assert(activeIcon:GetText():find("RestedXPQuestAccept:0|t", 1, true))
    assert(v2ListText:GetText():find("RestedXPQuestTurnIn:0|t", 1, true))
    assert(v2Icon:GetText():find("RestedXPTalk:20|t", 1, true))
    assert(v2Text:GetText():find("RestedXPRouteFlag:0|t", 1, true))
end
local oldFont = S.Font
S.Font = function(text)
    if text.SetFont then text:SetFont("EUI-font", select(2, text:GetFont()), "OUTLINE") end
end
local labels = {}
guide.GuideName.text = label()
guide.GuideName.text:SetText("The Barrens\nDungeon Guide")
function guide.GuideName:CreateFontString()
    local text = label()
    labels[#labels + 1] = text
    return text
end
for _, f in ipairs({auxTarget, auxItem}) do
    f.title = frame()
    f.title.text = label()
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 5, 8)
    f.title:SetHeight(19)
    f:SetBackdrop({edgeFile = 'old', bgFile = 'fill'})
    f.title:SetBackdrop({edgeFile = 'old', bgFile = 'fill'})
end
RXP.targeting.activeTargetFrame, RXP.activeItemFrame = auxTarget, auxItem
modules.RXPGuides.refresh(); flush()
local titleArt = {}
for host, parent in pairs(parents) do
    if (parent == auxTarget.title or parent == auxItem.title) and host.created then
        titleArt[#titleArt + 1] = host
        local fill = host.created[1]
        assert(host.mouseEnabled == false and fill.path == 12345 and fill.coords[1] == 64 / 300)
        assert(fill.coords[4] == 33 / 40 and #host.created == 2, "the atlas rail/shadow must not occupy the title seam")
        assert(fill.points[1][4] == 0 and fill.points[1][5] == 0 and fill.points[2][4] == 0 and fill.points[2][5] == 0)
        assert(fill.points[3][2] == host and fill.points[3][5] == 0)
        local auxBody = fill.points[1][2]
        assert(fill.masks[1] == rings[auxBody].host.created[1].masks[1])
        local titleFrame = parents[host]
        local iconInset = auxBody == auxTarget and 15 or (43 - 25 - 2)
        assert(-titleFrame.points[1][5] + titleFrame:GetHeight() < iconInset)
        assert(fill:GetAlpha() > 0 and fill:GetAlpha() < 1 and host.created[2]:GetAlpha() == 0)
    end
end
assert(#titleArt == 2)
local resizeArt
for _, texture in ipairs(guide.Footer.created or {}) do
    if texture.path and texture.path:find("resize_element.png", 1, true) then resizeArt = texture end
end
local resizePlus = resizeButton.regions[2]
assert(resizeArt and resizeArt.shown and resizeArt.width == 10 and resizeArt.height == 10
    and resizeArt.points[1][2] == resizeButton and not resizePlus:IsShown())
assert(resizeButton.width == 16 and resizeButton.height == 16 and resizeButton.mouseEnabled)
assert(resizeButton.hooks.OnMouseDown == startSizing and resizeButton.hooks.OnMouseUp == stopSizing)
resizeButton.hooks.OnMouseDown()
if dragging then width = width + 25; guide:SetSize(width, 400) end
resizeButton.hooks.OnMouseUp()
assert(guide.width == 225 and not dragging)
CheckBronzeMarkers()
row.text:SetText(statusIcons)
assert(row.text:GetText() == statusIcons)
local media = "|TInterface/AddOns/EUIAddonSkins/Media/"
local sizedFlag = "|T137205:0:1.25:-2:1|t"
local explicitTalk = "|T308474:16:16::1|t"
local untouched = "||T137205:0|t|T137205:0:0:0:0:32:32:0:32:0:32|t"
local wrapped = sizedFlag .. "Run to Durnholde Keep\n" .. explicitTalk .. "Talk to Ott" .. untouched
local expected = media .. "RestedXPRouteFlag:0:1.25:-2:1|tRun to Durnholde Keep\n"
    .. media .. "RestedXPTalk:16:16::1|tTalk to Ott" .. untouched
row.text:SetText(wrapped)
assert(row.text:GetText() == expected)
row.text:SetText(wrapped)
assert(row.text:GetText() == expected)
v2Icon:SetText("|T132053:0|t")
assert(v2Icon:GetText() == media .. "RestedXPTalk:0|t")
v2Icon:SetText(nativeTalk)

row.text:SetText(originalMarkers)
CheckBronzeMarkers()
assert(#labels == 2 and guide.GuideName.text:GetAlpha() == 0)
assert(labels[1]:GetText() == "The Barrens" and labels[2]:GetText() == "Dungeon Guide")
assert(labels[1].justify == "LEFT" and labels[1].points[1][4] == 7)
assert(select(2, labels[2]:GetFont()) == select(2, labels[1]:GetFont()) - 2)
guide.GuideName.text:SetText("A single-line title")
assert(guide.GuideName.text:GetAlpha() == 1 and not labels[1]:IsShown() and not labels[2]:IsShown())
guide.GuideName.text:SetText("Shadowfang Keep\nDungeon Guide")
assert(guide.GuideName.text:GetAlpha() == 0 and labels[1]:GetText() == "Shadowfang Keep")
for _, f in ipairs({auxTarget, auxItem}) do
    local _, _, _, _, y = f.title:GetPoint()
    local path, size, flags = f.title.text:GetFont()
    assert(y == -1 and f.title:GetHeight() == 11 and path == "EUI-font" and size == 10 and flags == "OUTLINE")
end
for _, f in ipairs({auxTarget, auxItem}) do
    assert(rings[f].host.created[1].allPoints == rings[f].host and #rings[f].host.created[1].masks == 1)
end
local oldDB, oldStub = EUIAddonSkinsDB, LibStub
EUIAddonSkinsDB = {}
local registry, dialog, opened = {}, {}
function registry:RegisterOptionsTable(key, options) self[key] = options end
function dialog:SetDefaultSize() end
local opacityRoot = {type = "Frame", frame = frame()}
local slider = frame("Slider")
local thumb = region("native-thumb", "ARTWORK")
function slider:GetThumbTexture() return thumb end
function slider:GetOrientation() return "HORIZONTAL" end
local nativeSetValue = function(self, value) self.value = value end
slider.SetValue = nativeSetValue
slider:EnableMouse(true)
opacityRoot.children = {{type = "Slider", frame = frame(), slider = slider, parent = opacityRoot}}
local close, status = frame("Button"), frame("Button")
local closeClick = function() return "native dialog close" end
close.obj, status.obj = opacityRoot, opacityRoot
function close:GetScript(event) if event == "OnClick" then return closeClick end end
function close:GetFontString() return label() end
status:SetBackdrop({bgFile = "native"})
opacityRoot.statustext = {GetParent = function() return status end}
opacityRoot.frame.children = {close, status}
function dialog:FeedGroup() end
function dialog:Open(key)
    opened = registry[key]
    self.OpenFrames = {[key] = opacityRoot}
    opacityRoot.userdata = {appName = key}
    self:FeedGroup(key, opened, opacityRoot, opacityRoot)
end
LibStub = function(name, silent)
    if name == "AceConfigRegistry-3.0" then return registry end
    if name == "AceConfigDialog-3.0" then return dialog end
    if oldStub then return oldStub(name, silent) end
end
local nativeAction = function() return "native" end
local nativeMenu = {
    {text = "Guide", hasArrow = true, menuList = {{text = "Nested", hasArrow = true, padding = 3}}},
    {text = "Options...", func = nativeAction},
}
local owner = {}
local a, b, c = RXP:ShowMenu(nativeMenu, owner)
assert(a == owner and b == nil and c == 9)
assert(shownMenu[1].padding == 28 and shownMenu[1].menuList[1].padding == 31 and nativeMenu[1].padding == nil)
assert(shownMenu[2].text == "EUI AddonSkins" and shownMenu[3] == nativeMenu[2] and shownMenu[3].func() == "native")
local choices = shownMenu[2].menuList
assert(choices[2].checked())
choices[3].func(); flush()
assert(EUIAddonSkinsDB.restedXP.style == "standard" and not legacyArt:IsShown())
assert(not resizeArt.shown and resizePlus:IsShown() and checked.color[1] == 0.1 and checked.color[2] == 0.8)
assert(row.text:GetText() == originalMarkers and activeIcon:GetText() == nativeAccept)
assert(v2ListText:GetText() == nativeTurnin and v2Icon:GetText() == nativeTalk and v2Text:GetText() == nativeFlag)
assert(guide.GuideName.text:GetAlpha() == 1 and guide.GuideName.text.justify == "CENTER" and not labels[1]:IsShown())
assert(select(5, auxTarget.title:GetPoint()) == 8 and auxTarget.title:GetHeight() == 19)
assert(select(2, auxTarget.title.text:GetFont()) == 12)
activeLook = "eui"
choices[4].func(); flush()
assert(EUIAddonSkinsDB.restedXP.style == "forever" and legacyArt:IsShown())
assert(resizeArt.shown and not resizePlus:IsShown() and checked.tint[1] == 0.91)
assert(statusCheck.path:find("rxp-checked-32", 1, true) and statusCheck.tint[2] == 0.17)
CheckBronzeMarkers()
choices[5].func()
assert(opened.args.opacity.get() == 72)
assert(status:GetBackdrop() == nil and close:GetScript("OnClick") == closeClick)
local dialogArt
for host, parent in pairs(parents) do
    if parent == opacityRoot.frame and host.rxpRim then dialogArt = host end
end
assert(dialogArt and dialogArt.mouseEnabled == false and dialogArt.rxpRim.host.mouseEnabled == false)
local track
for host, parent in pairs(parents) do
    if parent == slider and host.rxpBronze then track = host end
end
assert(track and track:GetHeight() == 2 and track.rxpBronze.created[1].color[1] == 0.49)
assert(track.mouseEnabled == false and track.rxpBronze.mouseEnabled == false and slider.mouseEnabled)
assert(slider.SetValue == nativeSetValue)
slider:SetValue(50)
assert(slider.value == 50)
local look = popupOptions.legacyLook()
local menuLevels = {frame(), frame(), frame()}
for _, level in ipairs(menuLevels) do
    look.legacyShell(level)
    local plate, grain = level.created[1], level.created[2]
    assert(plate.gradient and plate.alpha == 1 and grain.alpha == 0.28 and plate.masks[1] == grain.masks[1])
end
assert(look.chevrons and look.chevronColor[1] == 0.88)
local calls = originalCalls
for i = 0, 20 do opened.args.opacity.set(nil, i) end
flush()
assert(EUIAddonSkinsDB.restedXP.opacity == 0.20 and opened.args.opacity.get() == 20)
assert(originalCalls == calls, "opacity dragging reloaded the guide theme")
assert(rings[guide].on and legacyArt:GetAlpha() == 1)
local function composite(...)
    local remaining = 1
    for _, alpha in ipairs({...}) do remaining = remaining * (1 - alpha) end
    return 1 - remaining
end
assert(math.abs(composite(legacyArt.created[1].alpha, legacyArt.created[2].alpha, stepFill.alpha) - 0.2) < 0.0001)
local bodyRGB = {table.unpack(legacyArt.created[1].gradient[2])}
local function bodyPixel(art, world, channel)
    local plate, grain = art.created[1], art.created[2]
    local function Over(value, color, alpha) return color * alpha + value * (1 - alpha) end
    local body = Over(world, plate.color[channel] * plate.gradient[2][channel], plate.gradient[2][4])
    return Over(body, grain.tint[channel], grain.tint[4])
end
opened.args.opacity.set(nil, 100); flush()
local opaque = {}
for channel = 1, 3 do opaque[channel] = bodyPixel(legacyArt, 0, channel) end
local function CheckLegacyHeaderSeam()
    local header, body = guide.GuideName, guide.BottomFrame
    assert(legacyHeaderArt.allPoints == header and bottomRule.height == 1)
    for _, fill in ipairs({legacyHeaderArt.created[1], legacyHeaderArt.created[2]}) do
        assert(fill.allPoints == legacyHeaderArt)
    end
    for _, texture in ipairs({legacyArt.created[1], legacyArt.created[2]}) do
        local point = texture.points[1]
        assert(point[1] == "TOPLEFT" and point[2] == header and point[3] == "BOTTOMLEFT" and point[5] == 0)
    end
    for i, side in ipairs({"LEFT", "RIGHT"}) do
        local point, rail = header.points[i], bottomRule.points[i]
        assert(point[1] == "BOTTOM" .. side and point[2] == body and point[3] == "TOP" .. side and point[5] == 0)
        assert(rail[1] == point[1] and rail[2] == legacyHeaderArt and rail[3] == point[1] and rail[5] == 0)
        assert(rail[4] == (i == 1 and 2 or -2))
    end
    local title = labels[1]
    local upperEdge = topRule.points[1][5] - topRule.height
    local titleTop = title.points[1][5]
    local textBottom = titleTop - select(2, title:GetFont()) + labels[2].points[1][5] - select(2, labels[2]:GetFont())
    local xInset = legacyArt.points[1][4]
    for _, scale in ipairs({0.65, 0.85, 1}) do
        local function Pixel(value) return math.floor(value * scale + 0.5) end
        assert(Pixel(upperEdge) > Pixel(titleTop) and Pixel(textBottom) >= Pixel(-header:GetHeight() + bottomRule.height))
        -- The composition starts two units outside the header. The new rail
        -- ends exactly where each two-unit side rim turns inward.
        assert(Pixel(xInset + 2) == Pixel(topRule.points[1][4]))
        assert(Pixel(-xInset - 2) == Pixel(topRule.points[2][4]))
    end
end
CheckLegacyHeaderSeam()
guide.BottomFrame:SetSize(350, 600)
guide.GuideName.text:SetFont("EUI-font", 18, "OUTLINE")
assert(RXP:LoadGuide("resized-legacy-guide") == "resized-legacy-guide"); flush()
assert(select(2, labels[1]:GetFont()) == 14)
CheckLegacyHeaderSeam()
for _, percent in ipairs({0, 25, 50, 75, 95, 100}) do
    if percent == 0 then row:SetBackdropColor(0.15, 0.1, 0.08, 1) end -- stale idle fill
    if percent == 50 then row:SetBackdropColor(table.unpack(RXP.colors.bottomFrameHighlight)) end
    if percent == 75 then row:SetBackdropColor(table.unpack(RXP.colors.bottomFrameBG)) end
    opened.args.opacity.set(nil, percent); flush()
    assert(row.fill[4] == (percent == 50 and 1 or 0), "idle/hover backgrounds were conflated")
    local alpha = percent / 100
    assert(math.abs(topRule:GetAlpha() - alpha) < 0.0001 and bottomRule:GetAlpha() == topRule:GetAlpha())
    assert(legacyHeaderArt.created[3] == topRule and legacyHeaderArt.created[4] == bottomRule and #legacyHeaderArt.created == 4)
    assert(math.abs(composite(legacyArt.created[1].alpha, legacyArt.created[2].alpha) - alpha) < 0.0001)
    assert(legacyArt:GetAlpha() == 1 and guideArt:GetAlpha() == 1 and rings[guide].on)
    assert(guideArt.created[1].masks[1].edge == guideArt and bandArt.created[1].masks[1].edge == guideArt)
    assert(RXP.colors.bottomFrameBG[4] == 0 and v2Row.rxpBackground:GetAlpha() == 0)
    local plate, grain = legacyArt.created[1], legacyArt.created[2]
    assert(plate.blend == "BLEND" and plate.shown == (alpha > 0) and grain.shown == (alpha > 0))
    assert(plate.gradient[1][4] == plate.gradient[2][4])
    for channel = 1, 3 do
        assert(plate.gradient[2][channel] == bodyRGB[channel])
        for _, world in ipairs({0.1, 0.8}) do
            local expected = world * (1 - alpha) + opaque[channel] * alpha
            assert(math.abs(bodyPixel(legacyArt, world, channel) - expected) < 0.0001)
            assert(math.abs(bodyPixel(guideArt, world, channel) - expected) < 0.0001)
        end
    end
    local header = bandArt.created
    assert(math.abs(composite(header[1].alpha, header[2].alpha) - alpha) < 0.0001)
    assert(titleArt[1].created[1]:GetAlpha() == alpha and window.footerBackground:GetAlpha() == 0)
    for _, level in ipairs(menuLevels) do
        assert(level.created[1].alpha == 1 and level.created[2].alpha == 0.28)
    end
    for _, art in ipairs(titleArt) do
        local atlas = art.created[1]
        assert(atlas.tint[1] == 0.62 and atlas.tint[4] == alpha)
        local auxBody = atlas.points[1][2]
        local body, bodyFill = rings[auxBody].host, rings[auxBody].host.created[1]
        if alpha > 0 then
            local point = bodyFill.points[1]
            assert(point[1] == "TOPLEFT" and point[2] == parents[art] and point[3] == "BOTTOMLEFT")
            assert(point[4] + parents[art].points[1][4] == 0 and point[5] == 0)
        end
        assert(bodyFill.masks[1] == atlas.masks[1])
        assert(math.abs(composite(bodyFill:GetAlpha(), body.created[2]:GetAlpha()) - alpha) < 0.0001)
    end
    assert(bandArt.created[1].allPoints == bandArt, "the title band must stay inset from the outer rim")
    if alpha > 0 then
        assert(plate.points[1][2] == guide.GuideName and plate.points[1][3] == "BOTTOMLEFT")
        assert(plate.points[2][2] == guide.Footer and plate.points[2][3] == "TOPRIGHT")
        assert(math.abs(composite(legacyArt.upperPlate.alpha, legacyArt.upperGrain.alpha) - alpha) < 0.0001)
        assert(legacyArt.upperPlate.masks[1] == plate.masks[1])
    end
    assert(checkbox.click == click and scrollButton.click == scrollAction)
end
choices[6].func(); flush()
assert(not EUIAddonSkinsDB.restedXP and not legacyArt:IsShown())
opacityRoot.frame:SetShown(false)
opacityRoot.children[1].frame:SetShown(false) -- simulate inherited OnHide
assert(status:GetBackdrop().bgFile == "native" and dialogArt:GetAlpha() == 0)
assert(track:GetAlpha() == 0 and thumb:GetAlpha() == 0.8)
activeLook = "forever"
-- V2 keeps the V1 root and root-owned cog alive while hiding the native
-- panels. Reproduce the two pieces of chrome shown in the live screenshot.
local v2Mode = false
function RXP.v2:IsGuideWindowEnabled() return v2Mode end
local cog = frame("Button")
guide.Footer.cog = cog
parents[cog] = guide
modules.RXPGuides.refresh(); flush()
assert(legacyArt:IsShown() and rings[cog].on and not guideArt:IsShown())
local function Visible(f)
    return f:IsShown() and (not parents[f] or Visible(parents[f]))
end
assert(Visible(legacyArt) and Visible(rings[cog].host))
v2Mode = true
RXP.v2:DisableLegacyGuideWindow()
assert(guide:IsShown() and cog:IsShown() and not guide.Footer:IsShown())
assert(not Visible(legacyArt) and not rings[cog].on, "legacy root-owned art survived V2 takeover")
flush()
assert(Visible(guideArt) and rings[button].on)
assert(not Visible(legacyArt) and not rings[cog].on, "refresh resurrected legacy chrome")

-- Geometry is solved from the live V2 header/footer anchors, without a
-- reposition callback. Simulate translation plus a resize of that owner.
parents[band], parents[window.footer], parents[button] = window.frame, window.frame, window.frame
local function GuideArtBounds()
    local _, top, _, dx, dy = guideArt:GetPoint(1)
    local _, bottom, _, dx2, dy2 = guideArt:GetPoint(2)
    assert(parents[guideArt] == window.frame and parents[top] == window.frame and parents[bottom] == window.frame)
    local owner = parents[guideArt]
    return owner.x + dx, owner.y + owner.height + dy, owner.x + owner.width + dx2, owner.y + dy2
end
window.frame.x, window.frame.y = 20, 30
window.frame:SetSize(200, 350)
local left, top, right, bottom = GuideArtBounds()
assert(left == 18 and top == 382 and right == 222 and bottom == 28)
window.frame.x, window.frame.y = 50, 60
window.frame:SetSize(240, 420)
left, top, right, bottom = GuideArtBounds()
assert(left == 48 and top == 482 and right == 292 and bottom == 58)
window.frame:SetShown(false)
assert(not Visible(guideArt) and not Visible(rings[button].host))
assert(RXP:LoadGuide("closed-guide") == "closed-guide"); flush()
assert(not Visible(guideArt) and not legacyArt:IsShown())
window.frame:SetShown(true)
assert(Visible(guideArt) and not Visible(legacyArt))
activeLook = "eui"
modules.RXPGuides.refresh(); flush()
assert(not guideArt:IsShown() and not legacyArt:IsShown())
activeLook = "forever"
modules.RXPGuides.refresh(); flush()
assert(Visible(guideArt) and not legacyArt:IsShown() and not rings[cog].on)

-- A fresh legacy root with V2 already selected models the /reload setup.
local coldLegacy = frame()
coldLegacy.Footer, coldLegacy.GuideName = frame(), frame()
coldLegacy.Footer.cog = frame("Button")
RXP.RXPFrame = coldLegacy
modules.RXPGuides.refresh(); flush()
assert(not rings[coldLegacy] and not rings[coldLegacy.Footer.cog])
RXP.RXPFrame = guide

-- V2 releases its widget by hiding the owning frame. A newly acquired
-- guide gets its own shell; refresh retires the previous composition.
window.frame:SetShown(false)
RXP.v2.state.guideWindow = {frame = frame(), guideNameFrame = frame(), footer = frame()}
local replacement = RXP.v2.state.guideWindow
assert(RXP:LoadGuide("replacement-guide") == "replacement-guide"); flush()
assert(not guideArt:IsShown() and not bandArt:IsShown() and Visible(rings[replacement.frame].host))
v2Mode = false
for _, panel in ipairs({guide.BottomFrame, guide.GuideName, guide.Footer, guide.CurrentStepFrame}) do
    panel:SetShown(true)
end
modules.RXPGuides.refresh(); flush()
assert(Visible(legacyArt) and rings[cog].on and not rings[replacement.frame].host:IsShown())
RXP.v2.state.guideWindow = window
EUIAddonSkinsDB, LibStub, GAMEOPTIONS_MENU = oldDB, oldStub, savedOptionsText
EllesmereUI.IS_FOREVER = false
modules.RXPGuides.refresh(); flush()
for _, host in ipairs(titleArt) do assert(not host:IsShown()) end
RXP.targeting.activeTargetFrame, RXP.activeItemFrame = nil, nil
S.Font = oldFont
assert(not legacyArt:IsShown() and not guideArt:IsShown())
assert(RXP.v2:GetTheme().borderColors.common[1] == 0.055)
EllesmereUI = nil
Enum = savedEnum
C_Texture = savedTextureAPI
CreateColor = savedCreateColor

local target = frame(); target.protected = true; target.title = frame()
target.title.text = {GetObjectType = function() return 'FontString' end}
local action = frame('Button'); action.protected = true
function action:SetAttribute() error('secure target attributes changed') end
target.children = {action}
local targetUpdates = 0
function target:UpdateVisuals()
    assert(not combat, 'target visuals changed in combat')
    targetUpdates = targetUpdates + 1
    self:SetBackdrop({edgeFile = 'old'})
    self.title:SetBackdrop({edgeFile = 'old'})
end
lazyTarget = target
combat = true
RXP.targeting:CreateTargetFrame(); flush()
assert(targetUpdates == 0, 'target updates must wait until combat ends')
combat = false
combatEvents.hooks.OnEvent(); flush()
assert(targetUpdates > 0 and target.borderColor[1] == 0.055 and target.title.borderColor[1] == 0.055)
target:UpdateVisuals(); assert(target.borderColor[1] == 0.055, 'target border flashed before deferred refresh'); flush(); assert(target.borderColor[1] == 0.055, 'target tint lost after native redraw')
RXP.settings.profile.hideActiveTargetsBackground = true
function target:UpdateVisuals() targetUpdates = targetUpdates + 1; self:SetBackdrop(nil) end
modules.RXPGuides.refresh(); flush()
assert(target:GetBackdrop() == nil, 'skin restored a hidden target background')
-- Routine combat endings must not rerender native themes; dirty changes do.
local callsBeforeIdle = originalCalls
combatEvents.hooks.OnEvent(); flush()
assert(originalCalls == callsBeforeIdle, 'idle combat end refreshed RXP theme')
combat = true
modules.RXPGuides.refresh(); flush()
assert(originalCalls == callsBeforeIdle, 'theme updated during combat')
combat = false
combatEvents.hooks.OnEvent(); flush()
assert(originalCalls == callsBeforeIdle + 1, 'combat-deferred theme lost')
local originalTheme = {frame = {1, 0, 0}}
ForeverDungeonJournal_NS = {THEMES = {dungeon = originalTheme}, ToggleJournal = function()
    local root = frame(); root.rightPanel = frame()
    local portrait = region(12345, 'ARTWORK'); root.rightPanel.regions = {portrait}
    root.portrait = portrait
    local close = frame('Button')
    function close:GetParent() return root end
    function close:GetPoint() return 'TOPRIGHT', root, 'TOPRIGHT', -3, -3 end
    function close:GetNormalTexture() return region(123456, 'ARTWORK') end
    local closeClicks = 0
    close.onClick = function() closeClicks = closeClicks + 1 end
    root.close, root.closeClicks = close, function() return closeClicks end
    root.children = {root.rightPanel, close}
    root.dungeonMapArtHolder = frame(); root.dungeonMapArtHolder.children = {frame('EditBox')}
    root.children[#root.children + 1] = root.dungeonMapArtHolder
    ForeverDungeonJournalFrame = root
    return nil, 'journal-tail'
end}
modules.ForeverDungeonJournal.install(S, modules.ForeverDungeonJournal); flush()
assert(shells == 0, 'journal skin created a window eagerly')
local missing, result = ForeverDungeonJournal_NS.ToggleJournal(); flush()
assert(missing == nil and result == 'journal-tail')
assert(ForeverDungeonJournalFrame.shellOptions.noTopBar, 'journal header must keep a continuous background')
assert(ForeverDungeonJournalFrame.portrait.alpha == 0.8, 'boss portrait faded')
assert(ForeverDungeonJournalFrame.close.euiClose, 'numeric-texture close button missed')
ForeverDungeonJournalFrame.close.onClick(); assert(ForeverDungeonJournalFrame.closeClicks() == 1, 'close action lost')
assert(edits == 1, 'map contents must not be scanned')
local icon = region('Interface\\Icons\\INV_Misc_Book_09', 'ARTWORK')
ForeverDungeonJournalSettings = frame(); ForeverDungeonJournalSettings.regions = {icon}
modules.ForeverDungeonJournal.refresh(); flush()
assert(icon.alpha == 0.8, 'settings icon faded')
local previous = shells
modules.ForeverDungeonJournal.refresh(); flush(); assert(shells == previous, 'shell faded twice')
for _, fn in ipairs(looks) do fn() end; flush()
assert(RXP.settings.profile.activeTheme == 'Custom' and source2.font == 'original-v2')
enabled = false
local passthrough = RXP:LoadActiveTheme(); assert(passthrough == source, 'disabled theme wrapper still active')
assert(renders == 0, 'skin refresh must not reload guide content')
local r1, r2 = RXP.RenderFrame(); assert(r1 == nil and r2 == 'render-tail')
assert(originalCalls >= 2 and renders == 1)
-- Legacy chrome must also work when the guide root is implicitly protected.
local header = frame(); guide.GuideName = header
local function icon()
    local t = region('native-logo', 'ARTWORK')
    function t:ClearAllPoints() self.points = {} end
    function t:SetPoint(...) self.points = {...} end
    function t:SetSize(w, h) self.width, self.height = w, h end
    return t
end
header.icon, header.classIcon = icon(), icon()
S.SquareIcon = function(t) t.square = true end
local scrollbar = frame('Slider'); local thumb = icon()
function thumb:SetColorTexture(...) self.color = {...} end
scrollbar.GetThumbTexture = function() return thumb end
scrollbar.GetOrientation = function() return 'VERTICAL' end
guide.ScrollFrame = {ScrollBar = scrollbar}
guide.UpdateScrollBar = function() thumb.color = {1, 1, 1}; return 'scroll-native' end
guide.protected = true
enabled = true; modules.RXPGuides.refresh(); flush()
assert(header.icon.alpha == 0 and header.classIcon.alpha == 0, 'guide branding remains visible')
assert(thumb.color[1] == 0.1, 'logo removal changed scrollbar styling')
local scrollbarReturn = guide.UpdateScrollBar()
assert(scrollbarReturn == 'scroll-native' and thumb.color[1] == 0.1,
    'RXP scrollbar must skin before the callback returns: ' .. tostring(scrollbarReturn) .. '/' .. tostring(thumb.color[1]) .. '/' .. table.concat(errors, '\n'))
local thin = scrollbar.created[2]
assert(thin.width == 4 and thin.points[1][2] == thumb and thin.color[1] == 0.1)
thin.GetTexture = function() return "white" end
scrollbar.regions = {thin}
local created = #scrollbar.created
for _ = 1, 5 do guide.UpdateScrollBar() end
assert(#scrollbar.created == created and thin.color[1] == 0.1 and thin.alpha ~= 0, 'warm slider styling must retain the slim visual')
assert(thumb.alpha == 0 and not thumb.width, 'native thumb hit geometry must be preserved')
assert(#errors == 0, table.concat(errors, '\n'))
print('PASS: optional/lazy targets, legacy border/fill alignment and tint after redraw, Active Targets/combat/hidden backgrounds, numeric close texture and clicks, source/profile immutability, portraits/icons/maps, disable')
