local ADDON, ns = ...
local function DefineSkin()

local function Window() return _G.DBM_GUI_OptionsFrame end
-- HUD work is independent of the load-on-demand options window. Hooks follow
-- DBT's object lifecycle, never its countdown Update/OnUpdate hot path.
local function HUD(C)
    if C.dbmHUD then return C.dbmHUD end
    local H, S = C.H, C.S
    local WHITE = "Interface\\Buttons\\WHITE8X8"
    local bars, icons = {}, {}
    local active, pending = false, false
    local function Allowed(f)
        return H.Allowed(f) and not (f.IsProtected and f:IsProtected())
    end
    local function Font(text)
        if Allowed(text) and text.GetFont then S.Font(text) end
    end
    local function Shadow(text)
        if text.SetShadowColor then text:SetShadowColor(0, 0, 0, 0.9) end
        if text.SetShadowOffset then text:SetShadowOffset(1, -1) end
    end
    local function Edges(parent, icon)
        local d = icons[icon]
        if d then return d end
        -- A sibling layer follows the icon's current size without changing its
        -- native anchor, cooldown or click target. It accepts no mouse input.
        local layer = CreateFrame("Frame", nil, parent)
        layer:SetPoint("TOPLEFT", icon, "TOPLEFT")
        layer:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
        if layer.EnableMouse then layer:EnableMouse(false) end
        local edge = {}
        for i, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
            local t = layer:CreateTexture(nil, "OVERLAY")
            if i <= 2 then
                t:SetPoint(side .. "LEFT"); t:SetPoint(side .. "RIGHT"); t:SetHeight(1)
            else
                t:SetPoint("TOP" .. side); t:SetPoint("BOTTOM" .. side); t:SetWidth(1)
            end
            edge[i] = t
        end
        d = {layer = layer, edge = edge}; icons[icon] = d
        return d
    end
    local function Icon(parent, icon, border, r, g, b, neutral)
        if not Allowed(parent) or not H.Texture(icon) then return end
        -- Do not modify masked/private icons or guess the meaning of a border.
        if icon.GetNumMaskTextures and icon:GetNumMaskTextures() > 0 then return end
        S.SquareIcon(icon)
        local d = Edges(parent, icon)
        local visible = not icon.IsShown or icon:IsShown()
        if border and border.IsShown and border:IsShown() and not r then visible = false end
        d.layer:SetShown(visible)
        if r then
            if H.Texture(border) then
                if d.nativeBorderAlpha == nil then d.nativeBorderAlpha = border:GetAlpha() end
                border:SetAlpha(0)
            end
        elseif H.Texture(border) and d.nativeBorderAlpha ~= nil then
            border:SetAlpha(d.nativeBorderAlpha)
            d.nativeBorderAlpha = nil
        end
        if not r then
            if neutral then r, g, b = 0.16, 0.16, 0.18
            else r, g, b = S.GetAccentColor() end
        end
        for _, edge in ipairs(d.edge) do edge:SetColorTexture(r, g, b, 0.85) end
        return d
    end
    local function PaintVariance(obj)
        if type(obj) ~= "table" or obj.isSecret or not Allowed(obj.frame) then return end
        local name = obj.frame:GetName()
        if not name then return end
        local variance, boundary = _G[name .. "BarVariance"], _G[name .. "BarVarianceBorder"]
        -- This region conveys timing uncertainty. Keep DBT's native width,
        -- anchors and visibility; only replace its additive gradient artwork.
        if H.Texture(variance) then
            variance:SetTexture(WHITE)
            variance:SetBlendMode("BLEND")
            variance:SetVertexColor(0.14, 0.14, 0.16, 0.65)
            -- DBT calculates this width from the full row. The concept layout
            -- uses a narrower progress strip; retain the same time proportion.
            local bar = _G[name .. "Bar"]
            if Allowed(bar) and type(obj.varianceDuration) == "number" and type(obj.totalTime) == "number" and obj.totalTime > 0 then
                variance:SetWidth(bar:GetWidth() * obj.varianceDuration / obj.totalTime)
            end
        end
        if H.Texture(boundary) then boundary:SetVertexColor(0.25, 0.25, 0.27, 0.65) end
    end
    local function BarLayout(obj, bar, d, name)
        local options = _G.DBT and _G.DBT.Options or {}
        local prefix = obj.enlarged and "Huge" or ""
        local height = options[prefix .. "Height"] or obj.frame:GetHeight()
        local rowHeight = math.max(8, height - 2)
        local compact = rowHeight < 16 or obj.frame:GetWidth() < 150
        local iconSize = math.max(6, rowHeight - 2)
        local left, right = _G[name .. "BarIcon1"], _G[name .. "BarIcon2"]
        local leftSpace = H.Texture(left) and left:IsShown() and iconSize + 8 or 0
        local rightSpace = H.Texture(right) and right:IsShown() and iconSize + 8 or 0
        for i = 1, 2 do
            local icon = i == 1 and left or right
            if H.Texture(icon) then
                icon:SetSize(iconSize, iconSize); icon:ClearAllPoints()
                icon:SetPoint(i == 1 and "RIGHT" or "LEFT", obj.frame, i == 1 and "LEFT" or "RIGHT", i == 1 and -4 or 4, 0)
            end
        end
        -- Keep each native mechanic texture and visibility state. Four-symbol
        -- mode remains a compact two-by-two group; other modes use one row.
        local count = 0
        for i = 1, 4 do
            local icon = _G[name .. "BarIJIcons" .. (i == 1 and "" or i)]
            if H.Texture(icon) and icon:IsShown() then count = count + 1 end
        end
        local stacked = options.JournalIcons == 4
        local symbolSize = math.min(16, rowHeight * (stacked and 0.36 or 0.62), obj.frame:GetWidth() / 12)
        -- Reserve the configured symbol capacity, even when a timer has fewer
        -- populated icons. Labels, strips and countdowns then align per size.
        local capacity = type(options.JournalIcons) == "number" and math.max(0, math.min(4, options.JournalIcons)) or count
        local mechanicSpace = capacity > 0 and ((stacked and math.min(capacity, 2) or capacity) * (symbolSize + 2) + 4) or 0
        local slot = 0
        for i = 1, 4 do
            local icon = _G[name .. "BarIJIcons" .. (i == 1 and "" or i)]
            if H.Texture(icon) and icon:IsShown() then
                local column = stacked and slot % 2 or slot
                icon:SetSize(symbolSize, symbolSize); icon:ClearAllPoints()
                if stacked then
                    icon:SetPoint("TOPRIGHT", obj.frame, "RIGHT", -3 - column * (symbolSize + 2), rowHeight / 2 - 1 - math.floor(slot / 2) * (symbolSize + 2))
                else
                    icon:SetPoint("RIGHT", obj.frame, "RIGHT", -3 - column * (symbolSize + 2), 0)
                end
                slot = slot + 1
            end
        end
        local label, timer = _G[name .. "BarName"], _G[name .. "BarTimer"]
        local nativeSize
        if Allowed(label) then local _, size = label:GetFont(); nativeSize = size end
        if nativeSize and nativeSize ~= d.labelSize then d.nativeTextSize = nativeSize end
        nativeSize = options.FontSize or d.nativeTextSize or 10
        d.labelSize = math.max(8, math.min(nativeSize, rowHeight * 0.56))
        local timerSize = math.min(rowHeight * 0.82, math.max(12, nativeSize * 1.25))
        local timerSpace = math.max(40, timerSize * 4)
        -- DBT permits rows as small as 100x10. Keep a readable single-line
        -- fallback at those sizes rather than overlap a two-line panel.
        if compact then
            d.labelSize = math.max(6, math.min(nativeSize, rowHeight * 0.7, obj.frame:GetWidth() * 0.07))
            timerSize = d.labelSize
            timerSpace = math.max(24, timerSize * 3.5)
        end
        -- Both horizontal anchors constrain the native StatusBar during DBT's
        -- AnimateEnlarge SetWidth calls; its parent remains the native stack row.
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOMLEFT", obj.frame, "LEFT", 6, -height / 2 + 3)
        bar:SetPoint("BOTTOMRIGHT", obj.frame, "RIGHT", -timerSpace - mechanicSpace - 6, -height / 2 + 3)
        bar:SetHeight(compact and rowHeight - 2 or math.max(2, math.min(6, rowHeight * 0.22)))
        if not d.panel then
            d.panel = obj.frame:CreateTexture(nil, "BACKGROUND")
            d.edges = {}
            for i, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                local edge = obj.frame:CreateTexture(nil, "BORDER")
                if i <= 2 then
                    edge:SetPoint(side .. "LEFT", d.panel, side .. "LEFT"); edge:SetPoint(side .. "RIGHT", d.panel, side .. "RIGHT"); edge:SetHeight(1)
                else
                    edge:SetPoint("TOP" .. side, d.panel, "TOP" .. side); edge:SetPoint("BOTTOM" .. side, d.panel, "BOTTOM" .. side); edge:SetWidth(1)
                end
                d.edges[i] = edge
            end
        end
        d.panel:ClearAllPoints()
        -- Center-relative offsets also support DBT's unlocked-icon mode, where
        -- the native hit frame can retain a different height from the bar.
        d.panel:SetPoint("TOPLEFT", obj.frame, "LEFT", -leftSpace, rowHeight / 2)
        d.panel:SetPoint("BOTTOMRIGHT", obj.frame, "RIGHT", rightSpace, -rowHeight / 2)
        d.panel:SetColorTexture(0.035, 0.035, 0.038, 0.94)
        local r, g, b = S.GetAccentColor()
        d.edges[1]:SetColorTexture(r, g, b, 0.2)
        for i = 2, 4 do d.edges[i]:SetColorTexture(0.07, 0.075, 0.08, 0.75) end
        local x, y = options[prefix .. "TextXOffset"] or 0, options[prefix .. "TextYOffset"] or 0
        local path, flags = S.GetFont()
        if Allowed(timer) then
            timer:SetFont(path, timerSize, flags or "")
            timer:ClearAllPoints(); timer:SetPoint("RIGHT", obj.frame, "RIGHT", -mechanicSpace - 5 + x, y)
            Shadow(timer)
        end
        if Allowed(label) and Allowed(timer) then
            label:SetFont(path, d.labelSize, flags or "")
            label:ClearAllPoints()
            if compact then
                label:SetPoint("LEFT", obj.frame, "LEFT", 6 + x, y)
                label:SetPoint("RIGHT", obj.frame, "RIGHT", -timerSpace - mechanicSpace - 6 + x, y)
            else
                label:SetPoint("TOPLEFT", obj.frame, "LEFT", 6 + x, rowHeight / 2 - 1 + y)
                label:SetPoint("TOPRIGHT", obj.frame, "RIGHT", -timerSpace - mechanicSpace - 6 + x, rowHeight / 2 - 1 + y)
            end
            Shadow(label)
        end
    end
    local function PaintBar(obj)
        if not ns.IsEnabled(C.module) or active then return end
        -- Ordinary DBT timer frames are insecure and need styling when created
        -- during a fight. Protected/secret timers are excluded below.
        if type(obj) ~= "table" or obj.isSecret or not Allowed(obj.frame) then return end
        local name = obj.frame:GetName()
        if not name then return end
        local bar = _G[name .. "Bar"]
        if not Allowed(bar) or not bar.GetStatusBarTexture then return end
        active = true
        H.Safe(function()
            -- ApplyBarFill registers a permanent accent recolor in EUI; DBM
            -- fills instead retain native mechanic colors and urgency changes.
            local fill = bar:GetStatusBarTexture()
            if H.Texture(fill) and fill:GetTexture() ~= WHITE then
                local r, g, b, a = fill:GetVertexColor()
                if not (issecretvalue and (issecretvalue(r) or issecretvalue(g) or issecretvalue(b) or issecretvalue(a))) then
                    bar:SetStatusBarTexture(WHITE)
                    bar:GetStatusBarTexture():SetVertexColor(r, g, b, a)
                end
            end
            local bg = _G[name .. "BarBackground"]
            if H.Texture(bg) then bg:SetColorTexture(0.045, 0.045, 0.05, 0.95) end
            local spark = _G[name .. "BarSpark"]
            if H.Texture(spark) then H.Fade(spark) end
            for _, side in ipairs({"Top", "Bottom", "Left", "Right"}) do
                local border = _G[name .. "BarBorder" .. side]
                if H.Texture(border) then H.Fade(border) end
            end
            Font(_G[name .. "BarName"]); Font(_G[name .. "BarTimer"])
            local d = bars[obj]
            BarLayout(obj, bar, d, name)
            PaintVariance(obj)
            for i = 1, 2 do
                local icon = _G[name .. "BarIcon" .. i]
                if H.Texture(icon) then Icon(obj.frame, icon, nil, nil, nil, nil, true) end
            end
            -- A cached neutral tint follows the native fill region itself.
            -- DBT can change its color/value every tick without a skin callback;
            -- text and semantic overlays draw above this ARTWORK sublevel.
            fill = bar:GetStatusBarTexture()
            if H.Texture(fill) then
                if not d.tint then d.tint = bar:CreateTexture(nil, "ARTWORK", nil, 2) end
                d.tint:SetAllPoints(fill)
                d.tint:SetColorTexture(0.045, 0.045, 0.05, 0.28)
            end
        end)
        active = false
    end
    local function BindBar(obj)
        if type(obj) ~= "table" or obj.isSecret or not Allowed(obj.frame) then return end
        if not bars[obj] then
            bars[obj] = {}
            H.Hook(obj, "ApplyStyle", PaintBar)
            H.Hook(obj, "SetIcon", PaintBar)
            H.Hook(obj, "SetVariance", PaintVariance)
        end
        PaintBar(obj)
    end
    local TYPES = {"Magic", "Curse", "Disease", "Poison", "Bleed"}
    local selectionBackdrop = {edgeFile = WHITE, edgeSize = 1}
    local function Preview(f)
        if not Allowed(f) then return end
        for i, icon in ipairs(f.Textures or {}) do
            local border = f.BorderTextures and f.BorderTextures[i]
            local dispelType = TYPES[(i - 1) % #TYPES + 1]
            -- Retail removed the legacy DebuffTypeColor global. Resolve the
            -- preview's known demo type through AuraUtil, never live aura data.
            local color
            if border and border.IsShown and border:IsShown() then
                color = AuraUtil and AuraUtil.GetAuraBorderColor and AuraUtil.GetAuraBorderColor(dispelType)
                    or DebuffTypeColor and DebuffTypeColor[dispelType]
            end
            local d = Icon(f.OverlayFrames and f.OverlayFrames[i] or f, icon, border,
                color and color.r, color and color.g, color and color.b)
            if d then
                -- The large protruding glyph is part of Blizzard's border
                -- atlas. Replace it with the matching standalone native atlas.
                if color and AuraUtil and AuraUtil.SetAuraDispelTypeIcon then
                    if not d.symbol then d.symbol = d.layer:CreateTexture(nil, "OVERLAY") end
                    local size = math.max(10, math.min(18, icon:GetWidth() * 0.24))
                    AuraUtil.SetAuraDispelTypeIcon(d.symbol, dispelType)
                    d.symbol:SetSize(size, size)
                    d.symbol:ClearAllPoints(); d.symbol:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -2, -2)
                    d.symbol:SetShown(not icon.IsShown or icon:IsShown())
                elseif d.symbol then d.symbol:Hide() end
            end
            local duration, stack = f.DurationTexts and f.DurationTexts[i], f.StackTexts and f.StackTexts[i]
            Font(duration); Font(stack)
            local durationSize = Allowed(duration) and select(2, duration:GetFont()) or 20
            if Allowed(duration) then
                duration:ClearAllPoints(); duration:SetPoint("CENTER", icon, "CENTER", 0, 1)
                Shadow(duration)
            end
            if Allowed(stack) then
                local path, size, flags = stack:GetFont()
                stack:SetFont(path, math.min(size or 12, math.max(8, (durationSize or 20) * 0.55)), flags)
                stack:ClearAllPoints(); stack:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -3, 3)
                Shadow(stack)
            end
            -- Keep native colorblind abbreviations; do not replace their text.
            local symbol = f.Symbols and f.Symbols[i]
            if Allowed(symbol) then
                Font(symbol)
                symbol:ClearAllPoints(); symbol:SetPoint("TOPLEFT", icon, "TOPLEFT", 2, -2)
                Shadow(symbol)
            end
        end
        if Allowed(f.Border) and f.Border.SetBackdropBorderColor then
            if f.Border.SetBackdrop then f.Border:SetBackdrop(selectionBackdrop) end
            f.Border:ClearAllPoints()
            f.Border:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
            f.Border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
            local r, g, b = S.GetAccentColor(); f.Border:SetBackdropBorderColor(r, g, b, 0.8)
        end
        Font(f.NameLabel)
    end
    local function PaintAuras()
        if not ns.IsEnabled(C.module) then return end
        if InCombatLockdown and InCombatLockdown() then pending = true; return end
        local auras = _G.DBM and _G.DBM.Auras
        if type(auras) ~= "table" then return end
        Preview(auras.PlayerPreview); Preview(auras.CoTankPreview); Preview(auras.CoTankPreview2)
        -- Restricted live aura containers are Blizzard-managed. Do not read or
        -- hook their buttons, bindings or secret duration/dispel data.
        if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then return end
        for _, state in pairs(auras.AuraTrackingState or {}) do
            for button, regions in pairs(state.buttonRegions or {}) do
                if Allowed(button) then
                    -- Preserve the live dispel artwork/symbol rather than infer
                    -- a dispel type from inaccessible aura information.
                    Icon(button, regions.icon, regions.dispelBorder)
                    Font(regions.durationText); Font(regions.countText)
                end
            end
        end
    end
    local warnings = {}
    local function BindWarning(text)
        if not Allowed(text) or not text.GetFont then return end
        local state = warnings[text]
        if not state then
            state = {}; warnings[text] = state
            state.font = function()
                if state.painting or not ns.IsEnabled(C.module) or not Allowed(text) then return end
                state.painting = true
                H.Safe(function()
                    local _, size = text:GetFont()
                    local path, flags = S.GetFont()
                    if path and size then text:SetFont(path, size, flags or ""); Shadow(text) end
                end)
                state.painting = false
            end
            state.icons = function()
                if state.painting or not ns.IsEnabled(C.module) or not Allowed(text) then return end
                local value = text:GetText()
                if issecretvalue and issecretvalue(value) then return end
                if type(value) ~= "string" or not value:find("|T", 1, true) then return end
                -- DBM's own warning icons use exactly :12:12. Leave other
                -- inline art (raid markers, timeline glyphs, custom crops) intact.
                local cropped = value:gsub("|T([^:|]+):12:12|t", "|T%1:12:12:0:0:64:64:5:59:5:59|t")
                if cropped == value then return end
                state.painting = true
                H.Safe(text.SetText, text, cropped)
                state.painting = false
            end
            H.Hook(text, "SetFont", state.font)
            H.Hook(text, "SetFontObject", state.font)
            H.Hook(text, "SetText", state.icons)
        end
        state.font(); state.icons()
    end
    local function PaintWarnings()
        for i = 1, 3 do BindWarning(_G["DBMWarning" .. i]) end
        for i = 1, 2 do BindWarning(_G["DBMSpecialWarning" .. i]) end
    end
    local function Refresh()
        if not ns.IsEnabled(C.module) then return end
        if InCombatLockdown and InCombatLockdown() then pending = true; return end
        pending = false
        local dbt = _G.DBT
        if type(dbt) == "table" then
            H.Hook(dbt, "CreateBar", function(self, _, id)
                if self.GetBar then BindBar(self:GetBar(id)) end
            end)
            if dbt.GetBarIterator then for obj in dbt:GetBarIterator() do BindBar(obj) end end
        end
        local auras = _G.DBM and _G.DBM.Auras
        for _, method in ipairs({"PreviewToggle", "OnSettingsChange", "UpdateAuraAnchors", "RegisterAllUnits"}) do
            H.Hook(auras, method, PaintAuras)
        end
        H.Hook(_G.DBM, "UpdateWarningOptions", PaintWarnings)
        H.Hook(_G.DBM, "UpdateSpecialWarningOptions", PaintWarnings)
        PaintWarnings()
        PaintAuras()
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function(_, event)
        if event == "ADDON_LOADED" or pending then H.Queue(events, Refresh) end
    end)
    if S.OnLooksChanged then S.OnLooksChanged(Refresh) end
    C.dbmHUD = Refresh
    return Refresh
end
local nativeTabs = setmetatable({}, {__mode = "k"})
local fontPaints = setmetatable({}, {__mode = "k"})
local function Fonts(C, f, kind)
    local H, S = C.H, C.S
    local function Bind(text, html)
        if fontPaints[text] then fontPaints[text](); return end
        local painting = false
        local function Paint()
            if painting then return end
            if InCombatLockdown and InCombatLockdown() then C.module.refresh(); return end
            painting = true
            H.Safe(function()
                if html and S.GetFont then
                    -- SimpleHTML regenerates its text regions when DBM resizes
                    -- a page. Style its paragraph font, not the transient regions.
                    local _, size = text:GetFont("p")
                    local path, flags = S.GetFont()
                    text:SetFont("p", path, size or 12, flags or "")
                elseif not html then H.Font(text) end
            end)
            painting = false
        end
        fontPaints[text] = Paint
        Paint()
        H.Hook(text, "SetFontObject", Paint)
        H.Hook(text, "SetFont", Paint)
    end
    if kind == "SimpleHTML" then Bind(f, true); return true end
    for _, text in ipairs(H.Regions(f)) do
        if H.Allowed(text) and text:GetObjectType() == "FontString" then Bind(text, false) end
    end
end

ns.RegisterScopedSkin("DBM", "Deadly Boss Mods", {
    softBorders = true,
    -- DBM-GUI is load-on-demand. Never force it to load just to apply a skin.
    available = function() return type(_G.DBM) == "table" or type(_G.DBM_GUI) == "table" and Window() ~= nil end,
    preserveTextColors = true,
    immediateShow = true,
    panelOptions = {noBorder = true},
    roots = function(C)
        local f = Window()
        local exclude = setmetatable({}, {__index = function(_, child)
            -- Font/warning previews and creature models show DBM's settings.
            return child:GetObjectType() == "ScrollingMessageFrame" or child.mytype == "modelframe"
        end})
        if f and f.searchHighlightFrame then exclude[f.searchHighlightFrame] = true end
        -- MinimalTabTemplate has child frames holding the Classic tab artwork.
        -- Skin tabs before generic discovery can assign them a button backdrop.
        for i in ipairs(f and f.tabs or {}) do
            local tab = _G["DBM_GUI_OptionsFrameTab" .. i]
            if C.H.Allowed(tab) then
                if not nativeTabs[tab] then
                    nativeTabs[tab] = {}
                    for _, region in ipairs(C.H.Regions(tab)) do
                        if C.H.Texture(region) then nativeTabs[tab][#nativeTabs[tab] + 1] = region end
                    end
                end
                for _, region in ipairs(nativeTabs[tab]) do C.H.Fade(region) end
                local function Strip(child, depth)
                    if depth > 4 or not C.H.Allowed(child) then return end
                    for _, region in ipairs(C.H.Regions(child)) do if C.H.Texture(region) then C.H.Fade(region) end end
                    for _, nested in ipairs(C.H.Children(child)) do Strip(nested, depth + 1) end
                end
                for _, child in ipairs(C.H.Children(tab)) do Strip(child, 0); exclude[child] = true end
                C.H.Tab(tab, f.tab == i)
            end
        end
        local list = _G.DBM_GUI_OptionsFrameList
        local wrapper = C.H.Allowed(list) and list:GetParent()
        if C.H.Allowed(wrapper) and wrapper ~= f then
            C.Panel(wrapper)
            wrapper:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -72)
        end
        local roots = {}
        if C.H.Allowed(f) then roots[1] = {frame = f, options = {bottomBar = 36}, exclude = exclude} end
        -- Older DBM versions use a private popup instead of Blizzard's Menu API.
        local popup = _G.DBM_GUI_DropDown
        if C.H.Allowed(popup) then roots[#roots + 1] = {frame = popup, exclude = exclude} end
        return roots
    end,
    hooks = function(C, refresh)
        HUD(C)()
        for _, name in ipairs({"CreateNewPanel", "CreateBossModPanel", "CreateDropdown"}) do
            C.H.Hook(_G.DBM_GUI, name, refresh)
        end
        for _, name in ipairs({"ShowTab", "DisplayFrame", "UpdateMenuFrame", "ClearSelection"}) do
            C.H.Hook(Window(), name, C.RefreshNow)
        end
        local f = Window()
        C.H.Hook(f and f.tabsGroup, "SelectAtIndex", C.RefreshNow)
    end,
    visit = function(C, f, kind)
        local H, S = C.H, C.S
        if Fonts(C, f, kind) then return true end
        local name = f.GetName and f:GetName() or ""
        local tab = tonumber(name:match("^DBM_GUI_OptionsFrameTab(%d+)$"))
        if tab then H.Tab(f, Window().tab == tab); return true end
        if kind == "Slider" then H.LegacySlider(f); return true end
        if kind == "Button" then
            if name == "DBM_GUI_OptionsFrameClosePanelButton" then S.CloseButton(f); return true end
            -- Do not fade or recolour DBM's colour-picker swatch textures.
            if type(f.SetColorRGB) == "function" then
                for _, region in ipairs(H.Regions(f)) do H.Font(region) end
                return true
            end
            if f.element and H.Allowed(f.toggle) then
                local window = Window()
                local page = window.tabs and window.tabs[window.tab]
                local selected = window.searchQuery and window.searchQuery ~= ""
                    and _G.DBM_GUI.currentViewing or page and page.selection
                if not f.euiSelection then
                    f.euiSelection = f:CreateTexture(nil, "BACKGROUND")
                    f.euiSelection:SetAllPoints(f)
                end
                local r, g, b = S.GetAccentColor()
                f.euiSelection:SetColorTexture(r, g, b, selected == f.element and 0.2 or 0)
                local highlight = f.GetHighlightTexture and H.Texture(f:GetHighlightTexture())
                if highlight then highlight:SetColorTexture(r, g, b, 0.08) end
                H.Font(f.text)
                H.Toggle(f.toggle, f.element.showSub)
                return true
            end
            H.Resize(f)
        end
        if f.mytype == "dropdown" or f.mytype == "dropdown2" then
            S.Dropdown(f)
            return true
        end
        if f.mytype == "area" then C.Panel(f) end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("DBM", DefineSkin)
else DefineSkin() end
