local ADDON, ns = ...
local function DefineSkin()
local WHITE = "Interface\\Buttons\\WHITE8X8"
-- Guildy's own gold (UI/Widgets.lua W.GOLD[1]); a box border at or above 95% of it
-- marks a selected card/slot or a hovered control, anything dimmer is resting.
local GOLD_LIT = 0.79 * 0.95
local selected = setmetatable({}, {__mode = "k"})
local boxes = setmetatable({}, {__mode = "k"})
local groups = setmetatable({}, {__mode = "k"})

local function OwnedTab(tab)
    local name = tab and tab.GetName and tab:GetName()
    local parent = tab and tab.GetParent and tab:GetParent()
    if not name or not parent or _G[name] ~= tab then return false end
    return (parent == _G.GuildyFrame and name:match("^GuildyFrameTab%d+$") ~= nil)
        or (parent == _G.GuildyOptions and name:match("^GuildyOptionsTab%d+$") ~= nil)
end
local function Ready(C)
    if InCombatLockdown and InCombatLockdown() then
        C.RefreshNow() -- Scoped records a pending refresh for PLAYER_REGEN_ENABLED.
        return false
    end
    return true
end
local function Tooltip(path)
    return type(path) == "string" and path:lower():find("ui%-tooltip%-border") ~= nil
end
-- Guild colours ----------------------------------------------------------------
-- The guild tabard's background, border and emblem colours. Guildy's window
-- uses them in place of the EUI accent; nil (no guild, or a tabard without a
-- design) keeps the EUI look.
local function RGB(color)
    if type(color) ~= "table" then return end
    if type(color.GetRGB) == "function" then return color:GetRGB() end
    if color.r then return color.r, color.g, color.b end
end
local function Luminance(c) return 0.299 * c[1] + 0.587 * c[2] + 0.114 * c[3] end
local function GuildColors(emblem)
    if not emblem then return end
    local api = C_GuildInfo and C_GuildInfo.GetGuildTabardInfo
    if not api then return end
    local ok, info = pcall(api, "player")
    if not ok or type(info) ~= "table" then return end
    local colors = {}
    for key, field in pairs({background = "backgroundColor", border = "borderColor", emblem = "emblemColor"}) do
        local r, g, b = RGB(info[field])
        if not r then return end
        colors[key] = {r, g, b}
    end
    -- Accent: the emblem colour, else the border, else the background; a colour
    -- too dark to read on the dark panels falls through to the next one.
    for _, key in ipairs({"emblem", "border", "background"}) do
        if Luminance(colors[key]) >= 0.2 then colors.accent = colors[key]; break end
    end
    colors.key = table.concat({colors.background[1], colors.background[2], colors.background[3],
        colors.border[1], colors.border[2], colors.border[3], colors.emblem[1], colors.emblem[2], colors.emblem[3]}, ",")
    return colors
end
-- Four inner edge textures of size px around anchor, drawn on owner.
local function Edges(owner, anchor, size)
    local edges = {}
    for i, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local t = owner:CreateTexture(nil, "OVERLAY", nil, 7)
        if side == "TOP" or side == "BOTTOM" then
            t:SetPoint(side .. "LEFT", anchor, side .. "LEFT"); t:SetPoint(side .. "RIGHT", anchor, side .. "RIGHT"); t:SetHeight(size)
        else
            t:SetPoint("TOP" .. side, anchor, "TOP" .. side); t:SetPoint("BOTTOM" .. side, anchor, "BOTTOM" .. side); t:SetWidth(size)
        end
        edges[i] = t
    end
    return edges
end
local function PaintEdges(edges, color)
    for _, t in ipairs(edges) do
        if color then t:SetColorTexture(color[1], color[2], color[3], 1) end
        t:SetShown(color ~= nil)
    end
end
-- The corner emblem, inside the window's top left corner: the
-- guild's banner from Blizzard's guild finder cards when the client has its art
-- (the background and border atlases, which SetLargeGuildTabardTextures tints
-- with the tabard colours while it draws the emblem on top), else a 60px square
-- in the tabard colours; Guildy's logo when there is no tabard, never both. The
-- round ring and circular mask Guildy uses are never shown. It lives on its own
-- frame at Guildy's emblem level, above the window's title bar and panels.
local LOGO = "Interface\\Icons\\INV_Shirt_GuildTabard_01"
local EMBLEM_SIZE = 60
local BANNER = "guildfinder-card-guildbanner-"
local BANNER_WIDTH = 70 -- the banner atlases are 246 x 168; drawn narrower than that
local function HasBanner()
    local info = C_Texture and C_Texture.GetAtlasInfo
    return info and info(BANNER .. "background") ~= nil and info(BANNER .. "border") ~= nil or false
end
-- The game reports the border colour at the depth of the cloth's shading (a teal
-- border comes back near black): lift a coloured border to full strength, keep
-- greys, white and black as they are.
local function BorderTint(c)
    local hi, lo = math.max(c[1], c[2], c[3]), math.min(c[1], c[2], c[3])
    if hi <= 0 or (hi - lo) / hi < 0.2 then return c[1], c[2], c[3] end
    local k = math.max(1, 0.8 / hi)
    return c[1] * k, c[2] * k, c[3] * k
end
local function Tabard(C, main, logoPath)
    local inGuild = IsInGuild and IsInGuild()
    local emblem = inGuild and GetGuildLogoInfo and select(10, GetGuildLogoInfo())
    local colors = GuildColors(emblem)
    local changed = (colors and colors.key) ~= (C.guild and C.guild.key)
    C.guild = colors
    local b1, b2, e1, e2, r1, r2
    if inGuild and GetGuildTabardFiles then
        local ok
        ok, b1, b2, e1, e2, r1, r2 = pcall(GetGuildTabardFiles)
        if not ok then b1 = nil end
    end
    local key = table.concat({tostring(inGuild), tostring(emblem), colors and colors.key or "",
        tostring(b1), tostring(b2), tostring(e1), tostring(e2), tostring(r1), tostring(r2)}, ":")
    local tabard = main.euiGuildyTabard
    if not tabard then
        local banner = HasBanner()
        local holder = CreateFrame("Frame", nil, main)
        holder:SetSize(banner and BANNER_WIDTH or EMBLEM_SIZE, EMBLEM_SIZE)
        holder:SetPoint("TOPLEFT", main, "TOPLEFT", 4, -4) -- inside the window frame
        tabard = {Frame = holder, banner = banner}
        tabard.Logo = holder:CreateTexture(nil, "ARTWORK", nil, 1)
        tabard.Logo:SetSize(EMBLEM_SIZE, EMBLEM_SIZE)
        tabard.Logo:SetPoint("TOPLEFT", holder, "TOPLEFT")
        tabard.Logo:SetTexture(logoPath or LOGO)
        if C.S.SquareIcon then C.S.SquareIcon(tabard.Logo) end
        tabard.Background = holder:CreateTexture(nil, "ARTWORK", nil, 2)
        tabard.Background:SetAllPoints(holder)
        tabard.Border = holder:CreateTexture(nil, "ARTWORK", nil, banner and 3 or 0)
        tabard.Emblem = holder:CreateTexture(nil, "ARTWORK", nil, 4)
        if banner then
            tabard.Border:SetAllPoints(holder)
            tabard.Emblem:SetSize(46, 46)
            -- Centred on the pennant's visual middle (its point makes it bottom-light).
            tabard.Emblem:SetPoint("CENTER", holder, "CENTER", 0, 11)
        else
            -- Receives the API's ring art; never shown.
            tabard.Border:SetSize(1, 1)
            tabard.Border:SetPoint("TOPLEFT", holder, "TOPLEFT")
            tabard.Border:SetAlpha(0)
            -- Guildy's emblem proportions (56 x 64 in its 60px holder), kept inside the square.
            tabard.Emblem:SetSize(EMBLEM_SIZE * 52 / 60, EMBLEM_SIZE * 58 / 60)
            tabard.Emblem:SetPoint("CENTER", holder, "CENTER", 0, -1)
            tabard.Edges = Edges(holder, holder, 2)
        end
        main.euiGuildyTabard = tabard
        -- Guildy redraws its emblem when the guild or its tabard changes
        -- (UpdateTitle); new colours repaint the whole window.
        if main.Emblem then
            C.H.Hook(main.Emblem, "Update", function()
                if not C.H.Allowed(main) or main.IsVisible and not main:IsVisible() or not Ready(C) then return end
                if main.Emblem:GetAlpha() ~= 0 then main.Emblem:SetAlpha(0) end
                if Tabard(C, main) and C.refresh then C.refresh() end
            end)
        end
    end
    local level = main:GetFrameLevel() + 300
    if tabard.Frame:GetFrameLevel() ~= level then tabard.Frame:SetFrameLevel(level) end
    if tabard.key == key then return changed end
    tabard.key = key
    if tabard.banner then
        tabard.Background:SetAtlas(BANNER .. "background")
        tabard.Border:SetAtlas(BANNER .. "border")
    else
        -- A white square takes the tabard background colour the API applies.
        tabard.Background:SetTexture(WHITE)
        tabard.Background:SetTexCoord(0, 1, 0, 1)
    end
    local set = _G.SetLargeGuildTabardTextures
    local ok = set ~= nil and inGuild and (emblem or not GetGuildLogoInfo)
        and pcall(set, "player", tabard.Emblem, tabard.Background, tabard.Border) or false
    if tabard.banner then
        -- The API may swap in its own ring art; the banner keeps its border.
        tabard.Border:SetAtlas(BANNER .. "border")
        if ok and colors then
            local r, g, b = BorderTint(colors.border)
            tabard.Border:SetVertexColor(r, g, b)
        end
        tabard.Border:SetShown(not not ok)
    else
        if ok and colors then
            local c = colors.background
            tabard.Background:SetVertexColor(1, 1, 1, 1) -- the API's tint would multiply the fill
            tabard.Background:SetColorTexture(c[1], c[2], c[3], 1)
        end
        tabard.Border:Hide()
        PaintEdges(tabard.Edges, ok and colors and colors.border or nil)
    end
    tabard.Background:SetShown(ok and true or false)
    tabard.Emblem:SetShown(ok and true or false)
    tabard.Logo:SetShown(not ok)
    tabard.ok = ok
    return changed
end
-- Tabs: EUI's S.Tab hides Blizzard's label (transparent text colour) and draws
-- its own unwrapped one. Blizzard's tab select/deselect resets that label's
-- font object, which brings it back as a second, wrapping copy; keep it faded
-- by region alpha, which a font reset never changes. EUI's label can also keep
-- a width measured before the game font loaded (narrower than its text), and
-- then wraps its last letter; pin it to one line at its real text width.
-- EUI owns the sole selection underline and its accent-bar visibility.
local fitted = setmetatable({}, {__mode = "k"})
local labelWidths = setmetatable({}, {__mode = "k"})
local function FitLabel(label)
    if not labelWidths[label] and label.SetWordWrap then label:SetWordWrap(false) end
    local width = label.GetStringWidth and label:GetStringWidth()
    if not width or width <= 0 then return end
    width = math.ceil(width) + 4
    if labelWidths[label] ~= width then
        labelWidths[label] = width
        label:SetWidth(width)
    end
end
local function PaintTab(C, tab, on)
    local H = C.H
    local styled = H.Tab(tab, on)
    if styled then
        local native = tab.Text or (tab.GetFontString and tab:GetFontString())
        if native and native:GetAlpha() ~= 0 then native:SetAlpha(0) end
        for _, region in ipairs(H.Regions(tab)) do
            if region ~= native and region.GetObjectType and region:GetObjectType() == "FontString" then
                if not fitted[region] then
                    fitted[region] = true
                    H.Hook(region, "SetText", function()
                        if H.Allowed(region) and Ready(C) then FitLabel(region) end
                    end)
                end
                FitLabel(region)
            end
        end
    end
    return styled
end
-- "<guild> · Guildy" becomes "<guild>"; a bare "Guildy" (no guild) stays.
local function TrimTitle(C, text)
    local guard = false
    local function Trim(_, value)
        if guard or type(value) ~= "string" then return end
        -- Guildy joins them with its locale separator (" · "); match any short
        -- token between spaces, independent of the client's character classes.
        local trimmed, separator = value:match("^(.-%S)%s+(%S+)%s+Guildy%s*$")
        if trimmed and #separator <= 3 and C.H.Allowed(text) and Ready(C) then
            guard = true; text:SetText(trimmed); guard = false
        end
    end
    C.H.Hook(text, "SetText", Trim)
    Trim(nil, text:GetText())
end
-- Guildy's dark boxes (W.Box): keep the backdrop so its own border-colour
-- updates still show selection and hover, but redraw it as a flat EUI panel.
local function Box(C, f)
    local S = C.S
    local entry = boxes[f]
    if not entry then
        entry = {}; boxes[f] = entry
        entry.border = function(_, r, g, b)
            if entry.painting or not C.H.Allowed(f) then return end
            if r then entry.lit = r >= GOLD_LIT and (g or 0) >= GOLD_LIT * 0.8 and (b or 0) < r * 0.8 end
            if not Ready(C) then return end
            entry.painting = true
            if entry.lit then local ar, ag, ab = S.GetAccentColor(); f:SetBackdropBorderColor(ar, ag, ab, 1)
            else f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1) end
            entry.painting = false
        end
        C.H.Hook(f, "SetBackdropBorderColor", entry.border)
        C.H.Hook(f, "SetBackdrop", function(_, value)
            if value and value.edgeFile ~= WHITE and not entry.painting and C.H.Allowed(f) and Ready(C) then
                C.H.Safe(Box, C, f)
            end
        end)
        local r, g, b = f:GetBackdropBorderColor()
        entry.lit = r ~= nil and r >= GOLD_LIT and (g or 0) >= GOLD_LIT * 0.8 and (b or 0) < r * 0.8
    end
    local backdrop = f:GetBackdrop()
    if backdrop and backdrop.edgeFile ~= WHITE then
        -- BackdropTemplateMixin:SetBackdrop resets the border to white through
        -- SetBackdropBorderColor; that reset is ours, not a Guildy highlight.
        entry.painting = true
        f:SetBackdrop({bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}})
        entry.painting = false
    end
    local r, g, b = S.GetPanelColor()
    f:SetBackdropColor(math.min(r + 0.02, 1), math.min(g + 0.02, 1), math.min(b + 0.02, 1), 0.9)
    entry.border()
end
-- W.Segmented: the chosen option is its disabled button.
local function Segment(C, button)
    local H, S = C.H, C.S
    local on = button.IsEnabled and not button:IsEnabled()
    H.Selection(button, on)
    local label = button.GetFontString and button:GetFontString()
    if on then H.Font(label, 1, 1, 1) end
    if S.StateButtonLabel and not on then S.StateButtonLabel(button) end
end
-- The chat timeline rail (UI/ChatTimeline.lua): a 2px gold track plus a child
-- thumb button (black edge, gold fill, highlight). Returns its textures once found.
local rails = setmetatable({}, {__mode = "k"})
local function Rail(C, f)
    if rails[f] then return rails[f] end
    local H, found = C.H, false
    local regions = H.Regions(f)
    local track = #regions == 1 and H.Texture(regions[1])
    -- The client reports the 2px track's width in scaled units, not exactly 2.
    local width = track and track:GetWidth()
    if track and track:GetDrawLayer() == "BACKGROUND" and width and width > 0 and width < 4 then
        for _, child in ipairs(H.Children(f)) do
            if H.Allowed(child) and child:GetObjectType() == "Button" then
                local layers = {}
                for _, region in ipairs(H.Regions(child)) do
                    if H.Texture(region) then layers[region:GetDrawLayer()] = region end
                end
                if layers.BACKGROUND and layers.ARTWORK and layers.HIGHLIGHT then
                    found = {track = track, fill = layers.ARTWORK, hover = layers.HIGHLIGHT, thumb = child}
                    break
                end
            end
        end
    end
    if found then rails[f] = found end
    return found
end
local function PaintRail(C, rail)
    local r, g, b = C.S.GetAccentColor()
    rail.track:SetColorTexture(r, g, b, 0.35)
    rail.fill:SetColorTexture(r, g, b, 1)
    rail.hover:SetColorTexture(1, 1, 1, 0.25)
end
local function SegmentGroup(button)
    local group = button.GetParent and button:GetParent()
    if type(group) == "table" and type(group.buttons) == "table" and type(group.SetValue) == "function" then
        for _, member in ipairs(group.buttons) do if member == button then return group end end
    end
end

local function Visible(frame)
    return not frame.IsVisible or frame:IsVisible()
end

local function Exclusions()
    local exclude = {}
    local editor = _G.CommunitiesGuildTextEditFrame
    if editor and editor.Container then exclude[editor.Container] = true end
    local main = _G.GuildyFrame
    if main and main.Emblem then exclude[main.Emblem] = true end
    return exclude
end

local function RefreshContent(C, frame)
    if frame and Visible(frame) then C.RefreshControls(frame, Exclusions()) end
end

local function PaintPage(C, page)
    if Visible(page) then C.RefreshControlsNow(page, Exclusions()) end
end

local function WatchList(C, scroll)
    -- Guildy's ScrollList creates visible rows in SetItems, which a tab can
    -- call after its panel's OnShow. Only scan when that call adds children.
    if type(scroll.SetItems) ~= "function" or type(scroll.rows) ~= "table" or not scroll.GetScrollChild then return end
    local child = scroll:GetScrollChild()
    if not C.H.Allowed(child) or not child.GetNumChildren then return end
    local count = child:GetNumChildren()
    C.H.Hook(scroll, "SetItems", function()
        if not Visible(scroll) or not C.H.Allowed(child) then return end
        local current = child:GetNumChildren()
        if current ~= count then
            count = current
            C.RefreshControlsNow(child, Exclusions())
        end
    end)
end

ns.RegisterScopedSkin("Guildy", "Guildy", {
    softBorders = true, preserveTextColors = true,
    rootShow = function(C, root)
        if root == _G.GuildyFrame and Ready(C) and Tabard(C, root) then C.refresh() end
    end,
    scanOptions = function(C)
        return {
            explicitVisibility = true,
            skip = function(frame)
                local main = _G.GuildyFrame
                local options = _G.GuildyOptions
                local page = main and main.Content and frame:GetParent() == main.Content
                if not page and options and options.Panels then
                    for _, panel in pairs(options.Panels) do
                        if frame == panel then page = true; break end
                    end
                end
                if page then
                    C.H.Script(frame, "OnShow", function(self) PaintPage(C, self) end)
                    return not Visible(frame)
                end
            end,
        }
    end,
    controlRefresh = function(C, root, source)
        -- Clicking the cog can construct the separate Options root.
        if _G.GuildyFrame and source == _G.GuildyFrame.OptionsButton
            and _G.GuildyOptions and not C.optionsDiscovered then
            C.refresh()
            return
        end
        if source and source.GetObjectType and source:GetObjectType() == "ScrollFrame" then
            RefreshContent(C, source)
            return
        end
        local main = _G.GuildyFrame
        if root == main and main.Content then root = main.Content end
        RefreshContent(C, root)
    end,
    available = function() return SlashCmdList ~= nil and SlashCmdList.GUILDY ~= nil end,
    hooks = function(C, refresh)
        local H = C.H
        C.refresh = refresh
        if not C.guildAccent then
            -- Guildy-only accent: this skin's own getter (lit borders, timeline
            -- rail, segment selection) returns the guild colour when there is
            -- one. EUI's own primitives and every other window keep the EUI accent.
            C.guildAccent = true
            local base = C.S.GetAccentColor
            C.S.GetAccentColor = function()
                local accent = C.guild and C.guild.accent
                if accent then return accent[1], accent[2], accent[3] end
                return base()
            end
        end
        -- Guildy builds its window the first time Blizzard's guild window opens
        -- (Blizzard_Communities loads on demand) and lives inside it.
        local function Opened()
            local main = _G.GuildyFrame
            if H.Allowed(main) and Visible(main) and not main.euiGuildyTabard then C.RefreshNow() end
        end
        H.Hook(_G, "ToggleGuildFrame", Opened)
        if SlashCmdList then H.Hook(SlashCmdList, "GUILDY", Opened) end
        H.Hook(_G, "ToggleCommunitiesFrame", Opened)
        if _G.CommunitiesFrame then H.Script(_G.CommunitiesFrame, "OnShow", Opened) end
        if not C.guildBankEvents then
            local events = CreateFrame("Frame")
            events:RegisterEvent("GUILDBANKFRAME_OPENED")
            events:SetScript("OnEvent", function()
                -- Guildy 1.8 builds its standalone window in a peer event
                -- handler. Inspect the owned root after that dispatch finishes.
                if not ns.IsEnabled(C.module) then return end
                local main = _G.GuildyFrame
                if not main or not main.euiGuildyTabard or not Visible(main) then refresh() end
            end)
            C.guildBankEvents = events
        end
        H.Hook(_G, "PanelTemplates_SelectTab", function(tab)
            if H.Allowed(tab) and OwnedTab(tab) then
                selected[tab] = true
                if Ready(C) then PaintTab(C, tab, true) end
            end
        end)
        H.Hook(_G, "PanelTemplates_DeselectTab", function(tab)
            if H.Allowed(tab) and OwnedTab(tab) then
                selected[tab] = false
                if Ready(C) then PaintTab(C, tab, false) end
            end
        end)
    end,
    roots = function(C)
        local exclude = Exclusions()
        -- Copy and confirmation dialogs are standalone and their constructors
        -- live in Guildy's private namespace. Preserve their native first open.
        local result = {}
        for _, name in ipairs({"GuildyFrame", "GuildyOptions"}) do
            local f = _G[name]
            if C.H.Allowed(f) then
                result[#result + 1] = {frame = f, exclude = exclude, options = {noAccent = true}}
            end
        end
        return result
    end,
    visit = function(C, f, kind, refresh)
        local H, S = C.H, C.S
        if kind == "ScrollFrame" then
            if not C.guildyLists then C.guildyLists = setmetatable({}, {__mode = "k"}) end
            if not C.guildyLists[f] then
                C.guildyLists[f] = true
                WatchList(C, f)
            end
        end
        if f == _G.GuildyFrame then
            -- A small square title-bar icon like other EUI windows, instead of the
            -- round portrait and the 60px guild emblem Guildy draws over it.
            local pc = f.PortraitContainer
            local portrait = pc and pc.portrait or f.portrait
            local logoPath = H.Texture(portrait) and portrait:GetTexture() or nil
            if type(logoPath) ~= "string" and type(logoPath) ~= "number" then logoPath = nil end
            if pc and pc.GetRegions then
                for _, region in ipairs(H.Regions(pc)) do
                    if H.Texture(region) and region:GetAlpha() ~= 0 then region:SetAlpha(0) end
                end
            end
            if H.Texture(portrait) and portrait:GetAlpha() ~= 0 then portrait:SetAlpha(0) end
            if H.Allowed(f.Emblem) and f.Emblem:GetAlpha() ~= 0 then f.Emblem:SetAlpha(0) end
            Tabard(C, f, logoPath)
            -- Refresh the outer edge only when the tabard colours change.
            local edgeKey = C.guild and C.guild.key or false
            if not f.euiGuildyEdges then f.euiGuildyEdges = Edges(f, f, 1) end
            if f.euiGuildyEdgeKey ~= edgeKey then
                f.euiGuildyEdgeKey = edgeKey
                PaintEdges(f.euiGuildyEdges, C.guild and C.guild.border or nil)
            end
            local title = (f.TitleContainer and f.TitleContainer.TitleText) or f.TitleText
            if H.Allowed(title) and title:GetObjectType() == "FontString" then TrimTitle(C, title) end
            return
        end
        if f == _G.GuildyOptions then
            C.optionsDiscovered = true
            -- The options window hides its portrait; drop any leftover ring art.
            local pc = f.PortraitContainer
            if pc and pc.GetRegions then
                local portrait = pc.portrait
                for _, region in ipairs(H.Regions(pc)) do
                    if region ~= portrait and H.Texture(region) and region:GetAlpha() ~= 0 then region:SetAlpha(0) end
                end
            end
            return
        end
        if kind == "Button" and OwnedTab(f) then
            local value = selected[f]
            if value == nil then
                local owner = f.GetParent and f:GetParent()
                value = owner and owner.selectedTab ~= nil and f.GetID and owner.selectedTab == f:GetID() or false
            end
            return PaintTab(C, f, value)
        end
        if f.sideTab then return true end -- profession-style side tabs keep their native art
        if kind == "Frame" and f.GetBackdrop then
            local backdrop = f:GetBackdrop()
            if boxes[f] or backdrop and Tooltip(backdrop.edgeFile) then Box(C, f); return true end
        end
        if kind == "Button" then
            local main = _G.GuildyFrame
            if main and f == main.OptionsButton then
                S.Button(f, {"Icon"}); return true
            end
            local group = SegmentGroup(f)
            if group then
                if not groups[group] then
                    groups[group] = true
                    H.Hook(group, "SetValue", function()
                        if not H.Allowed(group) or not Ready(C) then return end
                        for _, member in ipairs(group.buttons) do
                            if H.Allowed(member) then Segment(C, member) end
                        end
                    end)
                end
                Segment(C, f); return true
            end
            -- Only real template buttons are controls. Guildy's custom buttons are
            -- data: sort headers, overview cells, bar rows, cards and timeline marks.
            if not (f.GetFontString and f:GetFontString()) then
                local rail = boxes[f:GetParent()] and Rail(C, f)
                if rail then PaintRail(C, rail); return true end
                -- The window's resize grip (W.ResizeGrip) is its only direct anonymous button.
                if main and f.GetParent and f:GetParent() == main then H.Resize(f) end
                return true
            end
        end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Guildy", DefineSkin)
else DefineSkin() end
