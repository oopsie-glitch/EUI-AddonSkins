local _, ns = ...

-- ItemTree draws its own design system: colours come from the token table
-- ItemTree.Theme.colors, read as each part is built and redrawn, and art goes
-- through ItemTree.Assets.Apply. The skin swaps the frame, border, text and
-- state tokens for EUI's before the window is built (ItemTree builds it a tick
-- after the first PLAYER_ENTERING_WORLD), fades the gold metal frame art as it
-- is applied, gives the red panel buttons EUI's button and styles the
-- window's PortraitFrameTemplate chrome. Item quality, semantic (New, Changed,
-- Predicted ...), money and badge colours are left as they are.

-- Token -> EUI colour. "panel" / "inset" follow the EUI panel colour, "accent"
-- the accent colour; tables are fixed colours.
local TOKENS = {
    ITEMTREE_COLOR_SURFACE_FRAME = "panel",
    ITEMTREE_COLOR_SURFACE_INSET = "inset",
    ITEMTREE_COLOR_SURFACE_STICKY = "inset",
    ITEMTREE_COLOR_SURFACE_FRAME_NOISE = {0, 0, 0, 0},
    ITEMTREE_COLOR_BORDER_GOLD = {0.32, 0.32, 0.34, 1},
    ITEMTREE_COLOR_BORDER_GOLD_DIM = {0.2, 0.2, 0.22, 1},
    ITEMTREE_COLOR_BORDER_DIVIDER = {0.18, 0.18, 0.2, 1},
    ITEMTREE_COLOR_TEXT_TITLE = {1, 1, 1, 1},
    ITEMTREE_COLOR_TEXT_BODY = {0.88, 0.88, 0.88, 1},
    ITEMTREE_COLOR_TEXT_MUTED = {0.6, 0.6, 0.62, 1},
    ITEMTREE_COLOR_TEXT_DISABLED = {0.4, 0.4, 0.42, 1},
    ITEMTREE_COLOR_TEXT_SELECTED = "accent",
    ITEMTREE_COLOR_TEXT_SELECTED_MUTED = "accent",
    ITEMTREE_COLOR_BAND_WORD = "accent",
    ITEMTREE_COLOR_STATE_HOVER = {1, 1, 1, 0.06},
    ITEMTREE_COLOR_STATE_SELECTED = "accent18",
    ITEMTREE_COLOR_STATE_FOCUS = "accent",
    ITEMTREE_COLOR_BUTTON_FACE = {0.12, 0.12, 0.13, 1},
    ITEMTREE_COLOR_BUTTON_FACE_HOVER = {0.18, 0.18, 0.2, 1},
    ITEMTREE_COLOR_BUTTON_ACCENT = {0.2, 0.2, 0.22, 1},
    ITEMTREE_COLOR_BUTTON_ACCENT_DIM = {0.15, 0.15, 0.17, 1},
    ITEMTREE_FRAME_ORNAMENT_OUTER = {0.05, 0.05, 0.06, 1},
    ITEMTREE_FRAME_ORNAMENT_INNER = {0.2, 0.2, 0.22, 1},
    ITEMTREE_LIST_STATE_HOVER = {1, 1, 1, 0.06},
    ITEMTREE_LIST_STATE_SELECTED = "accent18",
    ITEMTREE_LIST_GUIDE = {0.22, 0.22, 0.24, 1},
    ITEMTREE_COLOR_INFO_FILL_ALT = {1, 1, 1, 0.05},
    ITEMTREE_COLOR_INFO_FILL = {1, 1, 1, 0.04},
    ITEMTREE_COLOR_INFO_FILL_SOFT = {1, 1, 1, 0.03},
    -- Boss loot's level bands
    ITEMTREE_COLOR_BAND_FILL = {0.14, 0.14, 0.15, 1},
    ITEMTREE_COLOR_BAND_EDGE = {0.22, 0.22, 0.24, 1},
    -- The Professions tab (ItemTree_Professions): its pane surfaces follow
    -- EUI. Its cards, level bands, tags and route marks keep ItemTree's own
    -- colours (they carry state: recommended, locked); only their borders
    -- become EUI's flat 1px edge (see FlatBorder).
    ITEMTREE_COLOR_PROFESSION_PANEL_FILL = "panel",
    ITEMTREE_COLOR_PROFESSION_TOP_FILL = "inset",
    -- the skill tag above the rank bar (only Bar.lua uses it)
    ITEMTREE_COLOR_PROFESSION_TAG_FILL = {0.08, 0.08, 0.09, 0.96},
}

-- Two-stop fades (a pair of colours): ItemTree's brown header and red button
-- gradients.
local FADES = {
    ITEMTREE_FADE_HEADER = {{0.12, 0.12, 0.13, 1}, {0.07, 0.07, 0.08, 1}},
    ITEMTREE_FADE_BUTTON = {{0.18, 0.18, 0.2, 1}, {0.1, 0.1, 0.11, 1}},
}

-- Gold metal frame art ItemTree applies through Assets.Apply.
local FADE_ASSETS = {
    INFO_FRAME_CORNER_TL = true, INFO_FRAME_CORNER_TR = true,
    INFO_FRAME_CORNER_BL = true, INFO_FRAME_CORNER_BR = true,
    INFO_FRAME_EDGE_TOP = true, INFO_FRAME_EDGE_BOTTOM = true,
    INFO_FRAME_EDGE_LEFT = true, INFO_FRAME_EDGE_RIGHT = true,
    -- the search boxes' input border (S.EditBox draws EUI's)
    INPUT_BORDER_LEFT = true, INPUT_BORDER_RIGHT = true, INPUT_BORDER_MIDDLE = true,
    -- the bevelled ring round creature portraits (Boss loot's lists)
    PORTRAIT_RING = true,
}
-- The red panel button plate: its button gets EUI's button.
local BUTTON_ASSETS = {BUTTON_UP = true, BUTTON_DOWN = true}
-- UIPanelButtonTemplate's own art, never kept when such a button gets EUI's.
local TEMPLATE_PARTS = {Left = true, Middle = true, Right = true}
-- The plate EllesmereUI's own tabs draw (S.Tab), for ItemTree's tabs.
local TAB_PLATE = {0.068, 0.056, 0.052, 1}
-- The top tabs' plate height: the template tab is taller than EUI's tabs.
local TAB_HEIGHT = 24

local function DefineSkin()
    ns.RegisterModule("ItemTree", "ItemTree", function()
        local it = _G.ItemTree
        return type(it) == "table" and type(it.Theme) == "table" and type(it.Theme.colors) == "table"
            and type(it.Assets) == "table" and type(it.Assets.Apply) == "function"
            and type(it.UI) == "table" and type(it.UI.Frame) == "table"
    end, function(S, module)
        local it = _G.ItemTree
        local Frame = it.UI.Frame
        local colors = it.Theme.colors
        local H = ns.CreateSkinHelper(S, module)
        local buttons = setmetatable({}, {__mode = "k"})
        local tabs = setmetatable({}, {__mode = "k"})
        local checks = setmetatable({}, {__mode = "k"})
        local boxes = setmetatable({}, {__mode = "k"})
        local fills = {}
        local hovers = {}
        local accented = setmetatable({}, {__mode = "k"})
        local scrolls = setmetatable({}, {__mode = "k"})
        local borders = setmetatable({}, {__mode = "k"})
        local edges = setmetatable({}, {__mode = "k"})
        local portrait
        local SkinCheck
        local SkinColumn
        local underlines = {}
        local fontSet
        local waiting = setmetatable({}, {__mode = "k"})
        local done = {}
        local backing
        local pending, looksPending

        local function Locked() return InCombatLockdown and InCombatLockdown() end

        -- Replace the tokens with new tables: Theme.Hex reads a token's .hex
        -- first, so the original tables (with their hex) must not be reused.
        local function SetTokens()
            local pr, pg, pb = 0.06, 0.06, 0.07
            if S.GetPanelColor then pr, pg, pb = S.GetPanelColor() end
            local ar, ag, ab = 1, 0.82, 0
            if S.GetAccentColor then ar, ag, ab = S.GetAccentColor() end
            for key, value in pairs(TOKENS) do
                if colors[key] then
                    local r, g, b, a
                    if value == "panel" then r, g, b, a = pr, pg, pb, 1
                    elseif value == "inset" then r, g, b, a = pr * 0.75, pg * 0.75, pb * 0.75, 1
                    elseif value == "accent" then r, g, b, a = ar, ag, ab, 1
                    elseif value == "accent18" then r, g, b, a = ar, ag, ab, 0.18
                    else r, g, b, a = value[1], value[2], value[3], value[4] end
                    colors[key] = {r = r, g = g, b = b, a = a}
                end
            end
            for key, stops in pairs(FADES) do
                if type(colors[key]) == "table" then
                    local fade = {}
                    for i, c in ipairs(stops) do fade[i] = {r = c[1], g = c[2], b = c[3], a = c[4]} end
                    colors[key] = fade
                end
            end
        end

        -- ItemTree's faces (Theme.fonts) take EUI's font. A client whose
        -- alphabet ItemTree's own files lack draws in the game's face for it
        -- (ItemTree's Theme.ChooseFonts); that one is kept.
        local function SetFonts()
            local theme = it.Theme
            if not (S.GetFont and type(theme.fonts) == "table" and type(theme.OWN_FONTS) == "table") then return end
            local path = S.GetFont()
            if type(path) ~= "string" or path == "" then return end
            for key, own in pairs(theme.OWN_FONTS) do
                local face = theme.fonts[key]
                if face == own or (fontSet and face == fontSet) then theme.fonts[key] = path end
            end
            fontSet = path
        end

        local function PaintBacking()
            if backing and S.GetPanelColor then
                local r, g, b = S.GetPanelColor()
                backing:SetColorTexture(r, g, b, 1)
            end
            if S.GetAccentColor then
                local r, g, b = S.GetAccentColor()
                for _, line in ipairs(underlines) do line:SetColorTexture(r, g, b, 1) end
                for _, fill in ipairs(fills) do fill:SetColorTexture(r, g, b, 1) end
                for _, hover in ipairs(hovers) do hover:SetColorTexture(r, g, b, 0.15) end
                for _, paint in pairs(accented) do paint() end
            end
        end

        -- A hover in the accent colour, where the template's gold glow was.
        local function Hover(tab, anchor)
            local hover = tab:CreateTexture(nil, "HIGHLIGHT")
            if anchor then
                hover:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
                hover:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
            else
                hover:SetAllPoints(tab)
            end
            hovers[#hovers + 1] = hover
            return hover
        end

        local function Underline(tab)
            local line = tab:CreateTexture(nil, "OVERLAY", nil, 7)
            line:SetHeight(2)
            line:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
            line:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
            line:Hide()
            underlines[#underlines + 1] = line
            PaintBacking()
            return line
        end

        -- The view tabs and the Keep switch: ItemTree's flat tabs. The outline
        -- goes; the open one (its label in the title colour) gets the underline.
        local function FlatTab(tab)
            if tabs[tab] or not H.Allowed(tab) or not tab.CreateTexture then return end
            for _, edge in ipairs(type(tab.edges) == "table" and tab.edges or {}) do H.Fade(H.Texture(edge)) end
            Hover(tab)
            local line = Underline(tab)
            tabs[tab] = line
            local label = tab.label
            if not H.Allowed(label) then return end
            local function Track()
                local r, g, b = label:GetTextColor()
                line:SetShown(r and r > 0.95 and g > 0.95 and b > 0.95 or false)
            end
            H.Hook(label, "SetTextColor", Track)
            Track()
        end

        -- The top tabs are the client's tab template: its art goes, EUI's
        -- plate and underline take its place; the glyph and label stay.
        local function TopTab(tab)
            if tabs[tab] or not H.Allowed(tab) or not tab.CreateTexture then return end
            for _, region in ipairs(H.Regions(tab)) do
                if region ~= tab.icon and H.Texture(region) then H.Fade(region) end
            end
            local plate = tab:CreateTexture(nil, "BACKGROUND", nil, -8)
            plate:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
            plate:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
            plate:SetHeight(TAB_HEIGHT)
            Hover(tab, plate)
            plate:SetColorTexture(TAB_PLATE[1], TAB_PLATE[2], TAB_PLATE[3], TAB_PLATE[4])
            tabs[tab] = Underline(tab)
            local text = tab.tabText or tab.Text
            if H.Allowed(text) and S.Font then S.Font(text) end
        end

        -- The open tab's label white, the others in EUI's accent (the template
        -- draws them gold); ItemTree tints each tab's glyph from its label, so
        -- the glyph follows.
        local function TopSelection()
            local current = type(Frame.Tab) == "function" and Frame.Tab() or nil
            local ar, ag, ab = 1, 0.82, 0
            if S.GetAccentColor then ar, ag, ab = S.GetAccentColor() end
            for _, tab in ipairs(type(Frame.builtTabs) == "table" and Frame.builtTabs or {}) do
                if tabs[tab] then
                    local open = tab.tabName == current
                    tabs[tab]:SetShown(open)
                    local r, g, b = 1, 1, 1
                    if not open then r, g, b = ar, ag, ab end
                    local text = tab.tabText or tab.Text
                    if H.Allowed(text) then text:SetTextColor(r, g, b) end
                    local glyph = H.Texture(tab.icon)
                    if glyph then glyph:SetVertexColor(r, g, b, 1) end
                end
            end
        end

        -- The plate's glyph (dice, clock ...) is a texture on the same button:
        -- every texture the button names, other than the plate, is kept.
        local function SkinButton(button)
            if buttons[button] or not H.Allowed(button) or not S.Button then return end
            if Locked() then waiting[button] = true; pending = true; return end
            waiting[button] = nil
            if button:GetObjectType() ~= "Button" then return end
            buttons[button] = true
            local plate = {}
            if type(button.plate) == "table" then
                for _, texture in pairs(button.plate) do plate[texture] = true end
            end
            local keep = {}
            for key, value in pairs(button) do
                if type(key) == "string" and not TEMPLATE_PARTS[key] and not plate[value] and H.Texture(value) then
                    keep[#keep + 1] = key
                end
            end
            S.Button(button, keep)
            local label = button.GetFontString and button:GetFontString()
            if H.Allowed(label) and S.Font then S.Font(label) end
            -- A labelled button's gold label (Recent, Add note) and its glyph:
            -- the accent while enabled, grey while not.
            if H.Allowed(label) and (label:GetText() or "") ~= "" then
                local glyph = H.Texture(button.icon)
                local function paint()
                    local r, g, b = 0.5, 0.5, 0.5
                    if not button.IsEnabled or button:IsEnabled() then
                        r, g, b = 1, 0.82, 0
                        if S.GetAccentColor then r, g, b = S.GetAccentColor() end
                    end
                    label:SetTextColor(r, g, b)
                    if glyph then glyph:SetVertexColor(r, g, b, 1) end
                end
                accented[button] = paint
                H.Script(button, "OnEnable", paint)
                H.Script(button, "OnDisable", paint)
                paint()
            end
        end

        -- UIPanelButtonTemplate buttons (Recent, Add note, the band squares,
        -- the step arrows ...), found in the window as it is built and shown.
        -- A search box: EUI's box. ItemTree's own art on it (magnifier, key
        -- hint) is kept; InputBoxTemplate's Left/Middle/Right are not, and an
        -- input border ItemTree draws is faded through Assets.Apply.
        local function SkinEditBox(box)
            if boxes[box] or not H.Allowed(box) or not S.EditBox then return end
            if box.IsMultiLine and box:IsMultiLine() then return end
            boxes[box] = true
            local template = {}
            for key in pairs(TEMPLATE_PARTS) do if box[key] then template[box[key]] = true end end
            local shown = {}
            for _, region in ipairs(H.Regions(box)) do
                if H.Texture(region) and not template[region] then shown[region] = region:GetAlpha() end
            end
            S.EditBox(box, {padInput = false})
            for region, alpha in pairs(shown) do region:SetAlpha(alpha) end
        end

        local Walk
        function Walk(f, depth)
            if depth > 12 then return end
            for _, child in ipairs(H.Children(f)) do
                if H.Allowed(child) then
                    local kind = child:GetObjectType()
                    if kind == "Button" and child.Left and child.Right and child.Middle
                        and not tabs[child] and child.tabName == nil then
                        SkinButton(child)
                    elseif kind == "Button" and child.square and child.check then
                        SkinCheck(child)
                    elseif kind == "EditBox" then
                        SkinEditBox(child)
                    elseif child.Track and child.Back and child.Forward and not scrolls[child] and S.ScrollBar then
                        -- MinimalScrollBar (Boss loot's lists)
                        scrolls[child] = true
                        S.ScrollBar(child)
                    elseif type(child.art) == "table" and child.art.TopLeftCorner and child.icon then
                        SkinColumn(child)
                    end
                    if kind ~= "PlayerModel" and kind ~= "ModelScene" then Walk(child, depth + 1) end
                end
            end
        end

        -- ItemTree's tick boxes (buildCheckBox: a Button with .square and
        -- .check): EUI's dark box with a 1px edge, the tick an accent fill.
        -- One physical pixel in a region's own units. ItemTree scales its
        -- window (Window scale), so a 1-unit line can round to 0 or 2 pixels.
        local function Pixel(region)
            local _, height = 0, 768
            if GetPhysicalScreenSize then _, height = GetPhysicalScreenSize() end
            local scale = region.GetEffectiveScale and region:GetEffectiveScale() or 1
            if not (height and height > 0 and scale and scale > 0) then return 1 end
            return 768 / height / scale
        end
        local function SizeEdges()
            for line, vertical in pairs(edges) do
                local px = Pixel(line)
                if vertical then line:SetWidth(px) else line:SetHeight(px) end
            end
        end
        local function Edge(parent, anchor, layer)
            local function line(a, b, vertical)
                local t = parent:CreateTexture(nil, layer, nil, 1)
                t:SetPoint(a, anchor, a); t:SetPoint(b, anchor, b)
                t:SetColorTexture(0.25, 0.25, 0.27, 1)
                if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
                if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
                edges[t] = vertical
                local px = Pixel(t)
                if vertical then t:SetWidth(px) else t:SetHeight(px) end
            end
            line("TOPLEFT", "TOPRIGHT", false); line("BOTTOMLEFT", "BOTTOMRIGHT", false)
            line("TOPLEFT", "BOTTOMLEFT", true); line("TOPRIGHT", "BOTTOMRIGHT", true)
        end
        function SkinCheck(button)
            if checks[button] or not H.Allowed(button) or not button.CreateTexture then return end
            local square, tick = H.Texture(button.square), H.Texture(button.check)
            if not (square and tick) then return end
            checks[button] = true
            H.Fade(square)
            H.Fade(tick)
            local bg = button:CreateTexture(nil, "ARTWORK", nil, 0)
            bg:SetAllPoints(square)
            bg:SetColorTexture(0.06, 0.06, 0.07, 1)
            Edge(button, square, "ARTWORK")
            local fill = button:CreateTexture(nil, "OVERLAY", nil, 2)
            fill:SetPoint("TOPLEFT", square, "TOPLEFT", 3, -3)
            fill:SetPoint("BOTTOMRIGHT", square, "BOTTOMRIGHT", -3, 3)
            fills[#fills + 1] = fill
            PaintBacking()
            local function Track() fill:SetShown(tick:IsShown() and true or false) end
            H.Hook(tick, "Show", Track)
            H.Hook(tick, "Hide", Track)
            H.Hook(tick, "SetShown", Track)
            Track()
        end

        -- After Assets.Apply: fade the metal frame; the red plate's button is
        -- restyled a frame later, once the rest of it (its glyph) is built.
        local function Applied(texture, key)
            if not ns.IsEnabled(module) or type(key) ~= "string" then return end
            if FADE_ASSETS[key] then
                H.Fade(H.Texture(texture))
            elseif key == "CHECKBOX_UP" and H.Texture(texture) then
                local button = texture:GetParent()
                if H.Allowed(button) and not checks[button] then
                    H.Queue(button, function() if not Locked() then SkinCheck(button) end end)
                end
            elseif BUTTON_ASSETS[key] and H.Texture(texture) then
                local button = texture:GetParent()
                if H.Allowed(button) and not buttons[button] then
                    H.Queue(button, function() SkinButton(button) end)
                end
            end
        end

        -- The window is a PortraitFrameTemplate whose body surface is a texture
        -- on the window itself, so it is not given S.Shell (its restrip fades
        -- every texture on the frame); the template art is faded and an owned
        -- fill and border frame take its place.
        -- The item info column: its Dialog NineSlice goes for EUI's border, and
        -- its item icon is cropped square (ItemTree's quality frame stays).
        local columns = setmetatable({}, {__mode = "k"})
        function SkinColumn(column)
            if columns[column] or not H.Allowed(column) then return end
            columns[column] = true
            local art = column.art
            if H.Allowed(art) then
                if S.FadeNineSlice then S.FadeNineSlice(art) end
                for _, region in ipairs(H.Regions(art)) do if H.Texture(region) then H.Fade(region) end end
            end
            if S.Panel and column.CreateTexture then
                local edge = CreateFrame("Frame", nil, column)
                edge:SetAllPoints(column)
                edge:EnableMouse(false)
                S.Panel(edge, {noBg = true})
            end
            if H.Texture(column.icon) and S.SquareIcon then S.SquareIcon(column.icon) end
        end
        -- The item column (UI/InfoPanel.lua); Boss loot's creature column is a
        -- surface InfoPanel builds the same way, found by the walk.
        local function SkinInfo()
            local info = it.UI.InfoPanel
            local column = type(info) == "table" and info.frame
            if H.Allowed(column) then SkinColumn(column) end
        end

        -- The portrait: ItemTree draws it round (SetPortraitToTexture for an
        -- item, SetPortraitTexture / ...FromCreatureDisplayID for a creature).
        -- It is drawn again square in the title bar: an item's icon cropped
        -- like EUI's icons, a creature's portrait cropped to the square inside
        -- its circle (ItemTree's own Frame.DrawCreaturePortrait draws it).
        -- Any other page keeps the native portrait.
        local INNER = 0.5 - 0.5 / math.sqrt(2) -- the square inscribed in a circle
        local function Portrait()
            local native = H.Texture(Frame.portrait)
            if not (native and portrait) then return end
            local key = Frame.rootKey
            local drawn = false
            local id = type(Frame.ItemId) == "function" and Frame.ItemId(key) or nil
            local icon = id and type(it.Assets.ItemIcon) == "function" and it.Assets.ItemIcon(id) or nil
            if icon then
                portrait:SetTexture(icon)
                portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                drawn = true
            elseif key and type(Frame.IsCreatureRoot) == "function" and Frame.IsCreatureRoot(key)
                and type(Frame.DrawCreaturePortrait) == "function" then
                local ok, done = pcall(Frame.DrawCreaturePortrait, portrait, key)
                if ok and done then
                    portrait:SetTexCoord(INNER, 1 - INNER, INNER, 1 - INNER)
                    drawn = true
                end
            end
            portrait:SetShown(drawn)
            native:SetAlpha(drawn and 0 or 1)
        end
        local function SkinPortrait(frame)
            local native = H.Texture(Frame.portrait)
            if portrait or not native or not frame.CreateTexture then return end
            local container = frame.PortraitContainer
            if H.Allowed(container) then
                for _, region in ipairs(H.Regions(container)) do
                    if region ~= native and H.Texture(region) then H.Fade(region) end
                end
            end
            portrait = frame:CreateTexture(nil, "OVERLAY", nil, 6)
            portrait:SetSize(28, 28)
            portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
            if S.SquareIcon then
                local holder = CreateFrame("Frame", nil, frame)
                holder:SetAllPoints(portrait)
                holder:EnableMouse(false)
                S.SquareIcon(portrait, holder)
            end
            Portrait()
        end

        local SkinParts
        local function SkinWindow()
            local frame = Frame.frame
            if done.main or not H.Allowed(frame) then return end
            if Locked() then pending = true; return end
            done.main = true
            if frame.NineSlice and S.FadeNineSlice then S.FadeNineSlice(frame.NineSlice) end
            H.Fade(H.Texture(frame.Bg))
            H.Fade(H.Texture(frame.TopTileStreaks))
            local title = frame.TitleContainer
            if type(title) == "table" then H.Fade(H.Texture(title.TitleBg)) end
            if frame.CreateTexture then
                backing = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
                backing:SetAllPoints(frame)
                PaintBacking()
            end
            if S.Panel then
                local edge = CreateFrame("Frame", nil, frame)
                edge:SetAllPoints(frame)
                edge:EnableMouse(false)
                S.Panel(edge, {noBg = true})
            end
            local close = Frame.closeButton or frame.CloseButton
            if H.Allowed(close) and S.CloseButton then S.CloseButton(close) end
            if H.Allowed(Frame.title) and S.Font then S.Font(Frame.title) end
            SkinPortrait(frame)
            SkinParts()
            -- (The window scale may have changed while it was closed.)
            H.Script(frame, "OnShow", function() if not Locked() then SkinParts(); Portrait(); SizeEdges() end end)
        end

        -- Tabs first (a tab template also has Left/Middle/Right), then buttons.
        function SkinParts()
            for _, tab in ipairs(type(Frame.builtTabs) == "table" and Frame.builtTabs or {}) do TopTab(tab) end
            TopSelection()
            for _, list in ipairs({Frame.viewTabs, Frame.keepSegments}) do
                if type(list) == "table" then
                    for _, tab in pairs(list) do FlatTab(tab) end
                end
            end
            SkinInfo()
            if Frame.frame then Walk(Frame.frame, 0) end
        end

        local function ApplyLooks()
            if Locked() then looksPending = true; return end
            looksPending = nil
            SetTokens()
            SetFonts()
            PaintBacking()
            TopSelection()
        end

        local function Refresh()
            if not ns.IsEnabled(module) then return end
            if Locked() then pending = true; return end
            pending = nil
            SkinWindow()
            if done.main then
                SkinInfo()
                if type(it.UI.Tree) == "table" and H.Allowed(it.UI.Tree.search) then SkinEditBox(it.UI.Tree.search) end
            end
            for button in pairs(waiting) do SkinButton(button) end
            if looksPending then ApplyLooks() end
        end

        -- Before the window exists: everything it builds reads the EUI tokens.
        SetTokens()
        SetFonts()
        H.Hook(it.Assets, "Apply", Applied)
        H.Hook(Frame, "SelectTab", function()
            TopSelection(); Portrait()
            if done.main and not Locked() then SkinParts() end
        end)
        H.Hook(Frame, "Open", Portrait)
        -- Four lines one physical pixel wide round x, y, w, h on frame (from its
        -- top left), kept per frame and slot; colour nil hides them.
        local function EdgeLines(frame, slot, x, y, w, h, colour, layer)
            borders[frame] = borders[frame] or {}
            local lines = borders[frame][slot]
            if not lines then
                lines = {}
                for i = 1, 4 do
                    local line = frame:CreateTexture(nil, layer or "BACKGROUND", nil, layer == "OVERLAY" and 7 or -2)
                    if line.SetSnapToPixelGrid then line:SetSnapToPixelGrid(false) end
                    if line.SetTexelSnappingBias then line:SetTexelSnappingBias(0) end
                    lines[i] = line
                end
                borders[frame][slot] = lines
            end
            local px = Pixel(frame)
            local spots = {{x, y, w, px}, {x, y - (h - px), w, px}, {x, y, px, h}, {x + w - px, y, px, h}}
            for i, line in ipairs(lines) do
                if colour then
                    local s = spots[i]
                    line:ClearAllPoints()
                    line:SetPoint("TOPLEFT", frame, "TOPLEFT", s[1], s[2])
                    line:SetSize(s[3], s[4])
                    line:SetColorTexture(colour.r, colour.g, colour.b, colour.a or 1)
                    line:Show()
                else
                    line:Hide()
                end
            end
        end

        -- ItemTree_Professions draws each card's border from the client's
        -- tooltip art (ProfessionsSkin.Border): a soft 7px bevel. After each
        -- draw the bevel is faded, a flat edge one physical pixel wide is drawn
        -- in the card's own edge colour and the fill is widened to meet it.
        local function FlatBorder(frame, w, h, style)
            local skin = it.ProfessionsSkin
            if type(skin) ~= "table" or not H.Allowed(frame) or not frame.CreateTexture then return end
            w, h = tonumber(w), tonumber(h)
            if not (w and h and w > 0 and h > 0) then return end
            style = type(style) == "table" and style or {}
            local pieces = rawget(frame, style.store and (style.store .. "Border") or "borderPieces")
            if type(pieces) ~= "table" then return end
            for _, name in ipairs(type(skin.BORDER_ORDER) == "table" and skin.BORDER_ORDER or {}) do
                if H.Texture(pieces[name]) then H.Fade(pieces[name]) end
            end
            local px = Pixel(frame)
            local face = H.Texture(pieces.FACE)
            if face and face:IsShown() then
                face:ClearAllPoints()
                face:SetPoint("TOPLEFT", frame, "TOPLEFT", px, -px)
                face:SetSize(math.max(0, w - 2 * px), math.max(0, h - 2 * px))
            end
            local edge = type(skin.Colour) == "function" and skin.Colour(style.edge) or nil
            EdgeLines(frame, "card", 0, 0, w, h, edge, style.layer == "OVERLAY" and "OVERLAY" or "BACKGROUND")
        end
        -- The rank bar, flat and borderless: the client's profession bar art
        -- (ThreeSlice "PROFESSION_BAR_FRAME", the gold frame, and
        -- "PROFESSION_BAR_BG", the background with rounded end caps) is faded;
        -- an owned flat background in ItemTree's empty-bar colour takes the
        -- background's place. The skill tag above the bar loses its gold edge.
        local barBacks = setmetatable({}, {__mode = "k"})
        local function FlatBarFrame(frame, key, x, y, w, h, store)
            if (key ~= "PROFESSION_BAR_FRAME" and key ~= "PROFESSION_BAR_BG") or not H.Allowed(frame)
                or not frame.CreateTexture then return end
            x, y, w, h = tonumber(x) or 0, tonumber(y) or 0, tonumber(w), tonumber(h)
            if not (w and h and w > 0 and h > 0) then return end
            local pieces = type(store) == "string" and rawget(frame, store) or nil
            if type(pieces) == "table" then
                for _, piece in pairs(pieces) do if H.Texture(piece) then H.Fade(piece) end end
            end
            if key == "PROFESSION_BAR_BG" then
                local back = barBacks[frame]
                if not back then
                    back = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
                    barBacks[frame] = back
                end
                local c = colors.ITEMTREE_COLOR_PROFESSION_BAR_EMPTY or {r = 0, g = 0, b = 0, a = 0.85}
                back:ClearAllPoints()
                back:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y) -- (ItemTree's y runs down)
                back:SetSize(w, h)
                back:SetColorTexture(c.r, c.g, c.b, c.a or 1)
                back:Show()
            end
            local strip = frame.GetParent and frame:GetParent()
            local tag = type(strip) == "table" and rawget(strip, "tag") or nil
            if type(tag) == "table" then
                for _, piece in ipairs({tag.left, tag.middle, tag.right}) do
                    if H.Texture(piece) then H.Fade(piece) end
                end
            end
        end
        -- The bar's fill is the first frame of the client's flipbook art, whose
        -- left end is a rounded cap: its texture coordinates start past the cap.
        local FILL_CAP = 8 / 374 -- the cap, of the art's 374 texel width
        local function FlatFill(texture, key, fraction)
            if type(key) ~= "string" or not key:find("^PROFESSION_BAR_FILL") or not H.Texture(texture) then return end
            if not texture.GetTexCoord then return end
            fraction = tonumber(fraction)
            if not (fraction and fraction > 0) then return end
            local l, t, _, b, r = texture:GetTexCoord()
            if not (l and r and t and b and r > l) then return end
            local whole = (r - l) / math.min(fraction, 1)
            texture:SetTexCoord(math.min(l + whole * FILL_CAP, r), r, t, b)
        end
        local function HookProfessions()
            local skin = it.ProfessionsSkin
            if type(skin) == "table" then
                H.Hook(skin, "Border", FlatBorder)
                H.Hook(skin, "ThreeSlice", FlatBarFrame)
                H.Hook(skin, "Flipbook", FlatFill)
            end
            -- The skill tag above the rank bar ("Blacksmithing 185/225") is drawn
            -- inside Bar.Draw with a gold input-border edge: hidden after each draw.
            local bar = it.ProfessionsBar
            if type(bar) == "table" then
                H.Hook(bar, "Draw", function(strip)
                    local tag = type(strip) == "table" and rawget(strip, "tag") or nil
                    if type(tag) ~= "table" then return end
                    for _, piece in ipairs({tag.left, tag.middle, tag.right}) do
                        if H.Texture(piece) then H.Fade(piece); piece:Hide() end
                    end
                end)
            end
        end
        HookProfessions()

        -- The tree pane is built when the first page needs it (Tree.Attach),
        -- with its own search box ("Search sources").
        if type(it.UI.Tree) == "table" then
            H.Hook(it.UI.Tree, "Attach", function()
                if Locked() then pending = true; return end
                if H.Allowed(it.UI.Tree.search) then SkinEditBox(it.UI.Tree.search) end
            end)
        end
        -- Boss loot's creature column: InfoPanel.NewSurface(region) builds it
        -- when a boss is first chosen; its column frame is a child of region.
        if type(it.UI.InfoPanel) == "table" then
            H.Hook(it.UI.InfoPanel, "NewSurface", function(region)
                if not H.Allowed(region) then return end
                if Locked() then pending = true; return end
                for _, child in ipairs(H.Children(region)) do
                    if H.Allowed(child) and type(child.art) == "table" and child.art.TopLeftCorner then SkinColumn(child) end
                end
            end)
        end
        -- The info column is built when the first page needs it (InfoPanel.Attach).
        if type(it.UI.InfoPanel) == "table" then
            H.Hook(it.UI.InfoPanel, "Attach", function()
                if Locked() then pending = true else SkinInfo() end
            end)
        end
        H.Hook(Frame, "Build", function() if Frame.frame and not done.main then Refresh() end end)
        if S.OnLooksChanged then
            S.OnLooksChanged(function()
                if ns.IsEnabled(module) then ApplyLooks() end
            end)
        end
        local recovery = CreateFrame("Frame")
        recovery:RegisterEvent("PLAYER_REGEN_ENABLED")
        -- ItemTree_Professions is an addon of its own and loads after ItemTree,
        -- so usually after this skin has activated: hook its border then.
        recovery:RegisterEvent("ADDON_LOADED")
        recovery:SetScript("OnEvent", function(_, event, name)
            if event == "ADDON_LOADED" then
                if name == "ItemTree_Professions" and ns.IsEnabled(module) then HookProfessions() end
                return
            end
            if pending or looksPending then Refresh() end
        end)
        module.refresh = Refresh
        Refresh()
    end)
end

ns.RegisterSkinDefinition("ItemTree", DefineSkin)
