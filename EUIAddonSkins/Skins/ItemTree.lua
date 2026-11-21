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
}

-- Gold metal frame art ItemTree applies through Assets.Apply.
local FADE_ASSETS = {
    INFO_FRAME_CORNER_TL = true, INFO_FRAME_CORNER_TR = true,
    INFO_FRAME_CORNER_BL = true, INFO_FRAME_CORNER_BR = true,
    INFO_FRAME_EDGE_TOP = true, INFO_FRAME_EDGE_BOTTOM = true,
    INFO_FRAME_EDGE_LEFT = true, INFO_FRAME_EDGE_RIGHT = true,
    -- the search boxes' input border (S.EditBox draws EUI's)
    INPUT_BORDER_LEFT = true, INPUT_BORDER_RIGHT = true, INPUT_BORDER_MIDDLE = true,
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
        local edges = setmetatable({}, {__mode = "k"})
        local portrait
        local SkinCheck
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
            end
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
            plate:SetColorTexture(TAB_PLATE[1], TAB_PLATE[2], TAB_PLATE[3], TAB_PLATE[4])
            tabs[tab] = Underline(tab)
            local text = tab.tabText or tab.Text
            if H.Allowed(text) and S.Font then S.Font(text) end
        end

        local function TopSelection()
            local current = type(Frame.Tab) == "function" and Frame.Tab() or nil
            for _, tab in ipairs(type(Frame.builtTabs) == "table" and Frame.builtTabs or {}) do
                if tabs[tab] then tabs[tab]:SetShown(tab.tabName == current) end
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
        local function SkinInfo()
            local info = it.UI.InfoPanel
            local column = type(info) == "table" and info.frame
            if done.info or not H.Allowed(column) then return end
            done.info = true
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

        -- The portrait: ItemTree bakes the item icon into a round portrait
        -- (SetPortraitToTexture). For an item page the same icon is drawn
        -- square in the title bar instead; other pages keep the native one.
        local function Portrait()
            local native = H.Texture(Frame.portrait)
            if not (native and portrait) then return end
            local id = type(Frame.ItemId) == "function" and Frame.ItemId(Frame.rootKey) or nil
            local icon = id and type(it.Assets.ItemIcon) == "function" and it.Assets.ItemIcon(id) or nil
            if icon then
                portrait:SetTexture(icon)
                portrait:Show()
                native:SetAlpha(0)
            else
                portrait:Hide()
                native:SetAlpha(1)
            end
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
        H.Hook(Frame, "SelectTab", function() TopSelection(); Portrait() end)
        H.Hook(Frame, "Open", Portrait)
        -- The tree pane is built when the first page needs it (Tree.Attach),
        -- with its own search box ("Search sources").
        if type(it.UI.Tree) == "table" then
            H.Hook(it.UI.Tree, "Attach", function()
                if Locked() then pending = true; return end
                if H.Allowed(it.UI.Tree.search) then SkinEditBox(it.UI.Tree.search) end
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
        recovery:SetScript("OnEvent", function()
            if pending or looksPending then Refresh() end
        end)
        module.refresh = Refresh
        Refresh()
    end)
end

ns.RegisterSkinDefinition("ItemTree", DefineSkin)
