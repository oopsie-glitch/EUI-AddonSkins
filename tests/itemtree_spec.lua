-- ItemTree v1.2.7 (Forever): EUI colour tokens before the window is built,
-- the gold metal frame faded as Assets.Apply draws it, red plate buttons given
-- EUI's button a frame later (their glyph kept), and the window chrome.
do
local globals = {"GetPhysicalScreenSize", "ItemTree", "CreateFrame", "hooksecurefunc", "InCombatLockdown", "geterrorhandler", "C_Timer"}
local saved = {}
for _, key in ipairs(globals) do saved[key] = _G[key] end

local calls, frames, textures, hooks = 0, 0, 0, 0
local locked, enabled = false, true
local events, looks, timers = {}, {}, {}
local function region(kind, parent)
    local f = {kind = kind, alpha = 1, scripts = {}, regions = {}, children = {}, parent = parent}
    function f:GetObjectType() return self.kind end
    function f:GetParent() return self.parent end
    function f:SetAlpha(value) self.alpha = value end
    function f:GetAlpha() return self.alpha end
    function f:SetAllPoints(target) self.allPoints = target end
    function f:EnableMouse(value) self.mouse = value end
    function f:SetColorTexture(...) self.fill = {...} end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetChildren() return table.unpack(self.children) end
    function f:SetHeight(h) self.height = h end
    function f:SetPoint(...) self.point = {...} end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:SetShown(on) self.shown = on end
    function f:IsShown() return self.shown end
    function f:SetTextColor(r, g, b) self.color = {r, g, b} end
    function f:SetVertexColor(r, g, b) self.tint = {r, g, b} end
    function f:GetTextColor() if self.color then return self.color[1], self.color[2], self.color[3] end end
    function f:GetFontString() return self.label end
    function f:GetText() return self.text end
    function f:IsEnabled() return self.enabled ~= false end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:SetWidth(w) self.width = w end
    function f:ClearAllPoints() self.point = nil end
    function f:GetEffectiveScale() return (self.parent and self.parent:GetEffectiveScale() or 1) * (self.scale or 1) end
    function f:SetTexture(path) self.path = path end
    function f:SetTexCoord(...) self.coords = {...} end
    function f:IsMultiLine() return self.multi end
    function f:CreateTexture(_, layer, _, sublevel)
        textures = textures + 1
        local t = region("Texture", self)
        t.layer, t.sublevel = layer, sublevel
        self.regions[#self.regions + 1] = t
        return t
    end
    function f:HookScript(name, fn) hooks = hooks + 1; self.scripts[name] = fn end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:RegisterEvent(event) events[event] = self end
    return f
end
CreateFrame = function(_, _, parent)
    frames = frames + 1
    local f = region("Frame", parent)
    if parent then parent.children[#parent.children + 1] = f end
    return f
end
hooksecurefunc = function(owner, key, fn)
    hooks = hooks + 1
    local native = owner[key]
    owner[key] = function(...)
        local result = table.pack(native(...))
        fn(...)
        return table.unpack(result, 1, result.n)
    end
end
InCombatLockdown = function() return locked end
geterrorhandler = function() return function(message) error(message) end end
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
GetPhysicalScreenSize = function() return 1920, 1080 end
local function RunTimers()
    local due = timers; timers = {}
    for _, fn in ipairs(due) do fn() end
end

-- ItemTree as UI/Theme.lua, UI/Assets.lua and UI/Frame.lua expose it.
local GOLD = {r = 0.79, g = 0.65, b = 0.36, a = 1, hex = "C9A65C"}
local colors = {
    ITEMTREE_COLOR_SURFACE_FRAME = {r = 0.04, g = 0.04, b = 0.03, a = 1, hex = "0B0A08"},
    ITEMTREE_COLOR_SURFACE_INSET = {r = 0.09, g = 0.07, b = 0.07, a = 1, hex = "161311"},
    ITEMTREE_COLOR_BORDER_GOLD = GOLD,
    ITEMTREE_COLOR_TEXT_TITLE = {r = 1, g = 0.82, b = 0, a = 1, hex = "FFD100"},
    ITEMTREE_COLOR_TEXT_SELECTED = {r = 1, g = 0.82, b = 0, a = 1, hex = "FFD100"},
    ITEMTREE_LIST_STATE_SELECTED = {r = 0.79, g = 0.65, b = 0.36, a = 0.18},
    ITEMTREE_COLOR_QUALITY_EPIC = {r = 0.64, g = 0.21, b = 0.93, a = 1, hex = "A335EE"},
    ITEMTREE_COLOR_SEMANTIC_NEW = {r = 0.47, g = 0.72, b = 0.96, a = 1},
    ITEMTREE_COLOR_MONEY_GOLD = {r = 1, g = 0.84, b = 0, a = 1, hex = "FFD700"},
    ITEMTREE_COLOR_PROFESSION_CARD_FILL = {r = 0.25, g = 0.18, b = 0.12, a = 1, hex = "3F2D1E"},
    ITEMTREE_COLOR_PROFESSION_CARD_GOLD = {r = 1, g = 0.83, b = 0.42, a = 1, hex = "FFD36B"},
    ITEMTREE_COLOR_PROFESSION_CARD_EDGE = {r = 0.43, g = 0.32, b = 0.21, a = 1, hex = "6E5236"},
    ITEMTREE_FADE_BUTTON = {{r = 0.23, g = 0.14, b = 0.11, a = 1, hex = "3A231D"}, {r = 0.12, g = 0.07, b = 0.06, a = 1, hex = "1E120F"}},
}
local epic, new, money = colors.ITEMTREE_COLOR_QUALITY_EPIC, colors.ITEMTREE_COLOR_SEMANTIC_NEW, colors.ITEMTREE_COLOR_MONEY_GOLD
local cardFill, cardGold = colors.ITEMTREE_COLOR_PROFESSION_CARD_FILL, colors.ITEMTREE_COLOR_PROFESSION_CARD_GOLD
local OWN = {ITEMTREE_FONT_TITLE = "Fonts/FRIZQT__.TTF", ITEMTREE_FONT_BODY = "Fonts/ARIALN.TTF"}
local Theme = {colors = colors, OWN_FONTS = OWN,
    -- body as ItemTree's ChooseFonts leaves it on a Latin client; title as a Korean client's game face
    fonts = {ITEMTREE_FONT_TITLE = "Fonts/2002.TTF", ITEMTREE_FONT_BODY = OWN.ITEMTREE_FONT_BODY}}
function Theme.ColorTable(key) return Theme.colors[key] end
function Theme.Hex(key)
    local c = Theme.colors[key]
    if c.hex then return c.hex:lower() end
    return string.format("%02x%02x%02x", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))
end
local Assets = {applied = 0}
function Assets.Apply(texture, key) Assets.applied = Assets.applied + 1; texture.asset = key; return true end
local Frame = {builds = 0, current = "Tree"}
function Frame.Tab() return Frame.current end
function Frame.SelectTab(name) Frame.current = name end
local function fontString() local fs = region("FontString"); fs.color = {1, 1, 1}; return fs end
function Frame.ItemId(key) return type(key) == "string" and tonumber(key:match("^item:(%d+)$")) or nil end
function Frame.Open(key) Frame.rootKey = key end
function Assets.ItemIcon(id) return "icon-" .. id end
function Frame.IsCreatureRoot(key) return type(key) == "string" and key:find("^npc:") ~= nil end
function Frame.DrawCreaturePortrait(texture, key)
    if key == "npc:0" then return false end
    texture:SetTexture("portrait-" .. key); return true
end
-- The info column (UI/InfoPanel.lua), built when the first page needs it, with its Dialog NineSlice.
local InfoPanel = {}
function InfoPanel.Attach(region)
    if InfoPanel.frame then return true end
    local column = CreateFrame("Frame", nil, region)
    column.art = region and CreateFrame("Frame", nil, column) or nil
    column.art.TopLeftCorner = column.art:CreateTexture()
    column.icon = column:CreateTexture(nil, "ARTWORK")
    InfoPanel.frame = column
    return true
end
function InfoPanel.NewSurface(region)
    local column = CreateFrame("Frame", nil, region)
    column.art = CreateFrame("Frame", nil, column)
    column.art.TopLeftCorner = column.art:CreateTexture()
    column.icon = column:CreateTexture(nil, "ARTWORK")
    return {frame = column}
end
local drawnTitle
function Frame.Build()
    Frame.builds = Frame.builds + 1
    if Frame.frame then return Frame.frame end
    local frame = region("Frame")
    frame.NineSlice = region("Frame", frame)
    frame.Bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.CloseButton = region("Button", frame)
    frame.CloseButton.scripts.OnClick = function() return "native-close" end
    Frame.frame, Frame.closeButton = frame, frame.CloseButton
    Frame.title = frame:CreateTexture(nil, "OVERLAY"); Frame.title.kind = "FontString"
    -- The body surface and title colour, read from the tokens as the window is built.
    local surface = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    local c = Theme.ColorTable("ITEMTREE_COLOR_SURFACE_FRAME")
    surface:SetColorTexture(c.r, c.g, c.b, c.a)
    Frame.surface = surface
    drawnTitle = Theme.Hex("ITEMTREE_COLOR_TEXT_TITLE")
    -- The info column's metal frame and a red plate button with its glyph.
    Frame.corner = frame:CreateTexture(nil, "BORDER")
    Assets.Apply(Frame.corner, "INFO_FRAME_CORNER_TL")
    local button = region("Button", frame)
    button.scripts.OnClick = function() return "native-dice" end
    button.plate = {normal = button:CreateTexture(nil, "BACKGROUND"), pushed = button:CreateTexture(nil, "BACKGROUND")}
    Assets.Apply(button.plate.normal, "BUTTON_UP")
    Assets.Apply(button.plate.pushed, "BUTTON_DOWN")
    button.glyph = button:CreateTexture(nil, "ARTWORK") -- after the plate, as the plate builders do
    Assets.Apply(button.glyph, "ICON_DICE")
    Frame.dice = button
    -- Two top tabs from the client's tab template, with ItemTree's glyph.
    Frame.builtTabs = {}
    for index, name in ipairs({"Tree", "BossLoot"}) do
        local tab = region("Button", frame)
        tab.tabName = name
        tab.Left, tab.Middle, tab.Right = tab:CreateTexture(), tab:CreateTexture(), tab:CreateTexture()
        tab.icon = tab:CreateTexture(nil, "ARTWORK")
        tab.Text = fontString(); tab.tabText = tab.Text
        Frame.builtTabs[index] = tab
    end
    -- A flat view tab (buildTab) and the Recent button (UIPanelButtonTemplate).
    local view = region("Button", frame)
    view.background = view:CreateTexture(nil, "BACKGROUND")
    view.edges = {view:CreateTexture(nil, "BORDER"), view:CreateTexture(nil, "BORDER")}
    view.label = fontString(); view.label:SetTextColor(0.6, 0.6, 0.62)
    Frame.viewTabs = {view}
    local strip = region("Frame", frame)
    local recent = region("Button", strip)
    frame.children[#frame.children + 1] = strip
    strip.children[#strip.children + 1] = recent
    for _, tab in ipairs(Frame.builtTabs) do frame.children[#frame.children + 1] = tab end
    recent.Left, recent.Middle, recent.Right = recent:CreateTexture(), recent:CreateTexture(), recent:CreateTexture()
    recent.icon = recent:CreateTexture(nil, "ARTWORK")
    recent.label = fontString(); recent.label.text = "Recent"; recent.label:SetTextColor(1, 0.82, 0)
    recent.scripts.OnClick = function() return "native-recent" end
    Frame.recent = recent
    -- The portrait (template, round-masked by SetPortraitToTexture) and its ring.
    frame.PortraitContainer = region("Frame", frame)
    Frame.ring = frame.PortraitContainer:CreateTexture(nil, "OVERLAY")
    Frame.portrait = frame.PortraitContainer:CreateTexture(nil, "OVERLAY")
    -- A tick box (buildCheckBox), the search box (own magnifier) and a multi-line note box.
    local tick = region("Button", frame)
    tick.square = tick:CreateTexture(nil, "ARTWORK"); Assets.Apply(tick.square, "CHECKBOX_UP")
    tick.check = tick:CreateTexture(nil, "OVERLAY"); Assets.Apply(tick.check, "CHECKBOX_CHECK")
    tick.check:Hide()
    Frame.tick = tick
    local search = region("EditBox", frame)
    search.magnifier = search:CreateTexture(nil, "OVERLAY")
    search.border = search:CreateTexture(nil, "BORDER"); Assets.Apply(search.border, "INPUT_BORDER_MIDDLE")
    Frame.searchBox = search
    local note = region("EditBox", frame); note.multi = true; Frame.note = note
    for _, f in ipairs({frame.PortraitContainer, tick, search, note}) do frame.children[#frame.children + 1] = f end
    search.Left, search.Middle, search.Right = search:CreateTexture(), search:CreateTexture(), search:CreateTexture()
    return frame
end
-- The tree pane (UI/Tree.lua), built on the first page too, with its SearchBoxTemplate box.
local Tree = {}
function Tree.Attach(region)
    if Tree.search then return true end
    local box = CreateFrame("EditBox", nil, region)
    box.kind = "EditBox"
    box.Left, box.Middle, box.Right = box:CreateTexture(), box:CreateTexture(), box:CreateTexture()
    box.searchIcon = box:CreateTexture(nil, "OVERLAY")
    Tree.search = box
    return true
end
-- ItemTree_Professions' card border (UI/Skin.lua Skin.Border): eight bevel pieces and a face.
local Skin = {BORDER_ORDER = {"TL", "TOP", "TR", "LEFT", "RIGHT", "BL", "BOTTOM", "BR"}}
function Skin.Colour(key) return Theme.ColorTable(key) end
function Skin.Border(frame, w, h, style)
    local pieces = rawget(frame, "borderPieces")
    if not pieces then
        pieces = {}
        for _, name in ipairs(Skin.BORDER_ORDER) do pieces[name] = frame:CreateTexture(nil, "BACKGROUND", nil, -3) end
        pieces.FACE = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
        frame.borderPieces = pieces
    end
    for _, name in ipairs(Skin.BORDER_ORDER) do pieces[name]:Show() end
    pieces.FACE:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3); pieces.FACE:Show()
    return true
end
function Skin.Flipbook(texture, key, fraction)
    texture.coords = {0, 0, 0, 0.5, 0.5 * fraction, 0, 0.5 * fraction, 0.5}
    return true
end
function Skin.ThreeSlice(frame, key, x, y, w, h, store)
    local pieces = rawget(frame, store)
    if not pieces then
        pieces = {LEFT = frame:CreateTexture(), MIDDLE = frame:CreateTexture(), RIGHT = frame:CreateTexture()}
        frame[store] = pieces
    end
    for _, piece in pairs(pieces) do piece:Show() end
    return true
end
ItemTree = {Theme = Theme, Assets = Assets, UI = {Frame = Frame, InfoPanel = InfoPanel, Tree = Tree}}

local S = {}
for _, name in ipairs({"Panel", "CloseButton", "Button", "Font", "FadeNineSlice", "SquareIcon", "EditBox", "ScrollBar"}) do
    S[name] = function(f, options)
        assert(not locked, "cosmetic write in combat: " .. name)
        calls = calls + 1
        f.skin, f.opts = name, options
        if name == "FadeNineSlice" then f:SetAlpha(0) end
        if name == "EditBox" then for _, r in ipairs(f.regions) do r:SetAlpha(0) end end
        if name == "SquareIcon" then f.border = options end
        if name == "Button" then
            local keep = {}
            for _, key in ipairs(options or {}) do keep[f[key]] = true end
            for _, r in ipairs(f.regions) do if not keep[r] then r:SetAlpha(0) end end
        end
    end
end
local panel, accent = {0.1, 0.1, 0.12}, {0.2, 0.7, 0.6}
S.GetFont = function() return "EUI.ttf", "" end
S.GetPanelColor = function() return panel[1], panel[2], panel[3], 1 end
S.GetAccentColor = function() return accent[1], accent[2], accent[3] end
S.OnLooksChanged = function(fn) looks[#looks + 1] = fn end

local ns = {IsEnabled = function() return enabled end}
local module = {}
ns.RegisterModule = function(id, label, available, install)
    assert(id == "ItemTree" and label == "ItemTree" and available())
    install(S, module)
end
assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins", ns)
ns.RegisterSkinDefinition = function(id, fn) assert(id == "ItemTree"); fn() end
assert(loadfile("EUIAddonSkins/Skins/ItemTree.lua"))("EUIAddonSkins", ns)

-- Activated at login, before ItemTree builds its window: tokens swapped, nothing styled yet.
assert(calls == 0 and Frame.builds == 0)
local frameToken = colors.ITEMTREE_COLOR_SURFACE_FRAME
assert(frameToken.r == panel[1] and frameToken.hex == nil)
assert(colors.ITEMTREE_COLOR_BORDER_GOLD ~= GOLD and GOLD.r == 0.79, "original token table changed in place")
assert(colors.ITEMTREE_COLOR_TEXT_SELECTED.g == accent[2] and colors.ITEMTREE_LIST_STATE_SELECTED.a == 0.18)
assert(Theme.Hex("ITEMTREE_COLOR_TEXT_TITLE") == "ffffff")
assert(Theme.fonts.ITEMTREE_FONT_BODY == "EUI.ttf" and Theme.fonts.ITEMTREE_FONT_TITLE == "Fonts/2002.TTF")
-- Professions: the cards keep ItemTree's colours (state: recommended, locked); fades are two-stop pairs.
assert(colors.ITEMTREE_COLOR_PROFESSION_CARD_FILL == cardFill and colors.ITEMTREE_COLOR_PROFESSION_CARD_GOLD == cardGold)
local fade = colors.ITEMTREE_FADE_BUTTON
assert(#fade == 2 and fade[1].r == 0.18 and fade[2].r == 0.1 and fade[1].hex == nil)
assert(colors.ITEMTREE_COLOR_QUALITY_EPIC == epic and colors.ITEMTREE_COLOR_SEMANTIC_NEW == new and colors.ITEMTREE_COLOR_MONEY_GOLD == money)

-- The build (a tick after PLAYER_ENTERING_WORLD) reads the EUI tokens and gets the chrome.
local frame = Frame.Build()
assert(Frame.surface.fill[1] == panel[1] and drawnTitle == "ffffff")
assert(frame.NineSlice.skin == "FadeNineSlice" and frame.Bg.alpha == 0)
assert(frame.CloseButton.skin == "CloseButton" and frame.CloseButton.scripts.OnClick() == "native-close")
assert(Frame.title.skin == "Font")
local backing = frame.regions[#frame.regions]
for _, r in ipairs(frame.regions) do if r.sublevel == -8 then backing = r end end
assert(backing.sublevel == -8 and backing.fill[1] == panel[1] and backing.allPoints == frame)
assert(Frame.corner.alpha == 0 and Frame.corner.asset == "INFO_FRAME_CORNER_TL")
Frame.corner:SetAlpha(1); assert(Frame.corner.alpha == 0, "metal frame came back")
-- The plate button waits a frame, then keeps its glyph and loses the plate.
local dice = Frame.dice
assert(not dice.skin and #timers == 1)
RunTimers()
assert(dice.skin == "Button" and dice.glyph.alpha == 1 and dice.plate.normal.alpha == 0)
assert(dice.scripts.OnClick() == "native-dice")

-- Top tabs: template art faded, glyph kept, underline on the open tab only.
local tree, boss = Frame.builtTabs[1], Frame.builtTabs[2]
assert(tree.Left.alpha == 0 and tree.Right.alpha == 0 and tree.icon.alpha == 1 and not tree.skin)
assert(tree.Text.skin == "Font")
local treeLine, bossLine = tree.regions[#tree.regions], boss.regions[#boss.regions]
assert(treeLine.shown and not bossLine.shown and treeLine.fill[2] == accent[2])
-- Labels: the open tab white, the others (and their glyphs) in the accent colour.
assert(tree.Text.color[1] == 1 and tree.Text.color[2] == 1 and boss.Text.color[2] == accent[2] and boss.icon.tint[2] == accent[2])
Frame.SelectTab("BossLoot")
assert(bossLine.shown and not treeLine.shown)
assert(boss.Text.color[2] == 1 and boss.icon.tint[2] == 1 and tree.Text.color[2] == accent[2])
-- The flat view tab: outline faded, underline follows its label's title colour.
local view = Frame.viewTabs[1]
local viewLine = view.regions[#view.regions]
assert(view.edges[1].alpha == 0 and view.background.alpha == 1 and not viewLine.shown)
view.label:SetTextColor(1, 1, 1); assert(viewLine.shown)
view.label:SetTextColor(0.6, 0.6, 0.62); assert(not viewLine.shown)
-- Recent (UIPanelButtonTemplate, inside a strip): EUI button, glyph kept, template art not kept.
local recent = Frame.recent
assert(recent.skin == "Button" and recent.icon.alpha == 1 and recent.Left.alpha == 0 and recent.label.skin == "Font")
assert(recent.scripts.OnClick() == "native-recent")
-- Its gold label and glyph take the accent; grey while disabled, accent again when enabled.
assert(recent.label.color[2] == accent[2] and recent.icon.tint[2] == accent[2])
recent.enabled = false; recent.scripts.OnDisable(recent); assert(recent.label.color[1] == 0.5)
recent.enabled = nil; recent.scripts.OnEnable(recent); assert(recent.label.color[2] == accent[2])
-- Hovers: tabs have an accent hover over their plate.
local function hoverOf(f) for _, r in ipairs(f.regions) do if r.layer == "HIGHLIGHT" then return r end end end
assert(hoverOf(tree) and hoverOf(tree).fill[2] == accent[2] and hoverOf(tree).fill[4] == 0.15)
assert(hoverOf(Frame.viewTabs[1]) and hoverOf(Frame.viewTabs[1]).fill[2] == accent[2])

-- Tick box: a frame later, EUI box with an accent fill that follows the tick.
RunTimers()
local tick = Frame.tick
assert(tick.square.alpha == 0 and tick.check.alpha == 0)
local fill
for _, r in ipairs(tick.regions) do if r.layer == "OVERLAY" and r ~= tick.check then fill = r end end
assert(fill and not fill.shown and fill.fill[2] == accent[2])
tick.check:Show(); assert(fill.shown)
tick.check:Hide(); assert(not fill.shown)
-- Its edges are one physical pixel at the window's scale (1080p: 768/1080 units at scale 1),
-- and follow a scale change on the next show.
local edge
for _, r in ipairs(tick.regions) do if r.layer == "ARTWORK" and r.sublevel == 1 and r.height then edge = r end end
assert(edge and math.abs(edge.height - 768 / 1080) < 1e-6)
frame.scale = 0.5
frame.scripts.OnShow(frame)
assert(math.abs(edge.height - 768 / 1080 / 0.5) < 1e-6)
frame.scale = nil
-- Search box: EUI's box, its magnifier kept, its input border faded; the multi-line box left alone.
local search = Frame.searchBox
assert(search.skin == "EditBox" and search.opts.padInput == false and search.magnifier.alpha == 1)
assert(search.border.alpha == 0 and not Frame.note.skin)
assert(search.Left.alpha == 0 and search.Middle.alpha == 0, "InputBoxTemplate edges came back")
-- Info column: not there at the build; attached with the first page, then its
-- Dialog NineSlice is faded for EUI's border and its item icon squared.
assert(InfoPanel.frame == nil and Tree.search == nil)
InfoPanel.Attach(frame)
-- "Search sources": built after the window pass, styled from Tree.Attach; template edges stay faded.
Tree.Attach(frame)
assert(Tree.search.skin == "EditBox" and Tree.search.opts.padInput == false)
assert(Tree.search.Left.alpha == 0 and Tree.search.Right.alpha == 0 and Tree.search.searchIcon.alpha == 1)
local column = InfoPanel.frame
assert(column.art.skin == "FadeNineSlice" and column.art.TopLeftCorner.alpha == 0 and column.icon.skin == "SquareIcon")
-- Portrait: ring faded; an item page shows its icon square, another page the native portrait.
assert(Frame.ring.alpha == 0)
Frame.Open("item:4593")
local own
for _, r in ipairs(frame.regions) do if r.sublevel == 6 then own = r end end
assert(own.path == "icon-4593" and own.shown and own.width == 28 and own.skin == "SquareIcon")
assert(Frame.portrait.alpha == 0)
assert(own.coords[1] == 0.08)
-- A creature: ItemTree's portrait drawn on the square, cropped to the square inside its circle.
Frame.Open("npc:4532")
assert(own.shown and own.path == "portrait-npc:4532" and Frame.portrait.alpha == 0)
assert(math.abs(own.coords[1] - (0.5 - 0.5 / math.sqrt(2))) < 1e-9 and math.abs(own.coords[2] - (0.5 + 0.5 / math.sqrt(2))) < 1e-9)
-- Back to an item: the icon crop again. A page with no square portrait keeps the native one.
Frame.Open("item:4593"); assert(own.coords[1] == 0.08)
Frame.Open("npc:0")
assert(not own.shown and Frame.portrait.alpha == 1)
Frame.Open("zone:12")
assert(not own.shown and Frame.portrait.alpha == 1)

-- ItemTree_Professions loads after the skin activated: its border is hooked on its ADDON_LOADED.
ItemTree.ProfessionsSkin = Skin
-- Bar.Draw draws the rank bar and, last, the skill tag with its gold input-border pieces (shown).
local Bar = {}
function Bar.Draw(strip)
    for _, piece in ipairs({strip.tag.left, strip.tag.middle, strip.tag.right}) do piece:Show() end
end
ItemTree.ProfessionsBar = Bar
events.ADDON_LOADED.scripts.OnEvent(events.ADDON_LOADED, "ADDON_LOADED", "SomethingElse")
events.ADDON_LOADED.scripts.OnEvent(events.ADDON_LOADED, "ADDON_LOADED", "ItemTree_Professions")
-- Professions card: the bevel faded, a flat 1px edge in the card's own edge colour, the fill widened.
local card = CreateFrame("Frame", nil, frame)
Skin.Border(card, 200, 80, {edge = "ITEMTREE_COLOR_PROFESSION_CARD_EDGE", fill = "ITEMTREE_COLOR_PROFESSION_CARD_FILL"})
local pieces = card.borderPieces
assert(pieces.TL.alpha == 0 and pieces.BOTTOM.alpha == 0 and pieces.FACE.alpha == 1)
local px = 768 / 1080
assert(math.abs(pieces.FACE.point[4] - px) < 1e-9 and math.abs(pieces.FACE.width - (200 - 2 * px)) < 1e-9)
local edges = {}
for _, r in ipairs(card.regions) do if r.sublevel == -2 then edges[#edges + 1] = r end end
assert(#edges == 4 and edges[1].fill[1] == 0.43 and math.abs(edges[1].height - px) < 1e-9 and edges[1].width == 200)
assert(math.abs(edges[4].point[4] - (200 - px)) < 1e-9)
Skin.Border(card, 200, 80, {edge = "ITEMTREE_COLOR_PROFESSION_CARD_EDGE"})
-- The rank bar: flat, no border. Its gold frame and rounded background art are faded, an owned
-- flat background takes the background's place, and the skill tag above loses its gold edge.
local strip = CreateFrame("Frame", nil, frame)
strip.tag = CreateFrame("Frame", nil, strip)
strip.tag.left, strip.tag.middle, strip.tag.right = strip.tag:CreateTexture(), strip.tag:CreateTexture(), strip.tag:CreateTexture()
local rank = CreateFrame("Frame", nil, strip)
colors.ITEMTREE_COLOR_PROFESSION_BAR_EMPTY = {r = 0, g = 0, b = 0, a = 0.85}
Skin.ThreeSlice(rank, "PROFESSION_BAR_BG", 0, 4, 300, 14, "bgPieces", "BACKGROUND", 1)
Skin.ThreeSlice(rank, "PROFESSION_BAR_FRAME", 0, 4, 300, 14, "framePieces", "OVERLAY", 0)
assert(rank.framePieces.LEFT.alpha == 0 and rank.framePieces.MIDDLE.alpha == 0 and rank.bgPieces.RIGHT.alpha == 0)
local back
for _, r in ipairs(rank.regions) do if r.layer == "BACKGROUND" and r.sublevel == 1 then back = r end end
assert(back and back.fill[4] == 0.85 and back.point[5] == -4 and back.width == 300)
for _, r in ipairs(rank.regions) do assert(not (r.layer == "OVERLAY" and r.sublevel == 7), "a border on the bar") end
assert(strip.tag.left.alpha == 0 and strip.tag.middle.alpha == 0 and strip.tag.right.alpha == 0)
-- Bar.Draw shows the tag's pieces again; they are hidden after every draw.
Bar.Draw(strip)
assert(not strip.tag.left.shown and not strip.tag.middle.shown and not strip.tag.right.shown)
-- The fill: the flipbook's rounded left cap is cropped off.
local fill = rank:CreateTexture()
function fill:GetTexCoord() local c = self.coords; return c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8] end
function fill:SetTexCoord(l, r, t, b) self.coords = {l, t, l, b, r, t, r, b} end
ItemTree.ProfessionsSkin.Flipbook(fill, "PROFESSION_BAR_FILL_DEFAULT", 0.5)
assert(math.abs(fill.coords[1] - 0.5 * 8 / 374) < 1e-9 and fill.coords[5] == 0.25)
local untouched = rank:CreateTexture()
function untouched:GetTexCoord() return 0, 0, 0, 1, 1, 0, 1, 1 end
function untouched:SetTexCoord() error("not a bar fill") end
ItemTree.ProfessionsSkin.Flipbook(untouched, "SOMETHING_ELSE", 1)
local other = CreateFrame("Frame", nil, frame)
Skin.ThreeSlice(other, "SOMETHING_ELSE", 0, 0, 50, 10, "framePieces")
assert(other.framePieces.LEFT.alpha == 1)
local count = 0; for _, r in ipairs(card.regions) do if r.sublevel == -2 then count = count + 1 end end
assert(count == 4, "edges made twice")

-- Boss loot, built when its tab is first selected: EUI scroll bar, creature column.
local boss = CreateFrame("Frame", nil, frame)
local bar = CreateFrame("EventFrame", nil, boss)
bar.kind = "EventFrame"; bar.Track, bar.Back, bar.Forward = {}, {}, {}
Frame.SelectTab("BossLoot")
assert(bar.skin == "ScrollBar")
-- The creature column, built when a boss is first chosen (InfoPanel.NewSurface), after that walk.
local creatureRegion = CreateFrame("Frame", nil, boss)
local creature = InfoPanel.NewSurface(creatureRegion).frame
assert(creature.art.skin == "FadeNineSlice" and creature.art.TopLeftCorner.alpha == 0)
Frame.SelectTab("Tree")
-- The ring round the list's creature portraits is faded as it is applied.
local ring = boss:CreateTexture(nil, "OVERLAY"); Assets.Apply(ring, "PORTRAIT_RING"); assert(ring.alpha == 0)

-- Warm: the build is not repeated, nothing new is made or hooked.
local warm = {calls, frames, textures, hooks}
for _ = 1, 20 do
    Frame.Build(); Assets.Apply(dice.plate.normal, "BUTTON_UP"); RunTimers()
    frame.scripts.OnShow(frame); Frame.SelectTab("Tree")
end
assert(calls == warm[1] and frames == warm[2] and textures == warm[3] and hooks == warm[4])

-- A plate button built in combat is styled after it.
locked = true
local late = region("Button", frame)
late.plate = {normal = late:CreateTexture(nil, "BACKGROUND")}
Assets.Apply(late.plate.normal, "BUTTON_UP")
RunTimers()
assert(not late.skin)
locked = false
events.PLAYER_REGEN_ENABLED.scripts.OnEvent(events.PLAYER_REGEN_ENABLED)
assert(late.skin == "Button")

-- Theme change: tokens and owned fill follow; in combat it waits.
accent = {0.9, 0.3, 0.1}; panel = {0.2, 0.2, 0.2}
looks[1]()
assert(colors.ITEMTREE_COLOR_TEXT_SELECTED.r == 0.9 and backing.fill[1] == 0.2)
assert(Frame.builtTabs[2].Text.color[1] == 0.9 and Frame.builtTabs[1].Text.color[1] == 1)
assert(Frame.recent.label.color[1] == 0.9)
locked = true; panel = {0.3, 0.3, 0.3}; looks[1](); locked = false
assert(backing.fill[1] == 0.2)
events.PLAYER_REGEN_ENABLED.scripts.OnEvent(events.PLAYER_REGEN_ENABLED)
assert(backing.fill[1] == 0.3)

-- A disabled skin leaves new art alone.
enabled = false
local before = calls
local other = frame:CreateTexture(nil, "BORDER")
Assets.Apply(other, "INFO_FRAME_EDGE_TOP"); module.refresh(); looks[1](); RunTimers()
assert(calls == before and other.alpha == 1)

print("PASS: ItemTree EUI tokens before the build (quality/semantic/money kept, no shared tables mutated), EUI font (localized faces kept), window chrome, EUI tabs with accent underline, template and plate buttons keep their glyph, EUI tick boxes, search boxes, info column border and square item icons, flat 1px Professions card edges, Boss loot scroll bars and creature column, combat, theme and disabled skin")
for _, key in ipairs(globals) do _G[key] = saved[key] end
end
