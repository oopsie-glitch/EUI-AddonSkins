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
    local function Icon(parent, icon, border, r, g, b)
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
        if not r then r, g, b = S.GetAccentColor() end
        for _, edge in ipairs(d.edge) do edge:SetColorTexture(r, g, b, 0.85) end
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
            if H.Texture(bg) then bg:SetColorTexture(0.055, 0.055, 0.06, 0.85) end
            local spark = _G[name .. "BarSpark"]
            if H.Texture(spark) then H.Fade(spark) end
            for _, side in ipairs({"Top", "Bottom", "Left", "Right"}) do
                local border = _G[name .. "BarBorder" .. side]
                if H.Texture(border) then H.Fade(border) end
            end
            Font(_G[name .. "BarName"]); Font(_G[name .. "BarTimer"])
            for i = 1, 2 do
                local icon = _G[name .. "BarIcon" .. i]
                if H.Texture(icon) then Icon(obj.frame, icon) end
            end
            local d = bars[obj]
            if not d.line then
                d.line = bar:CreateTexture(nil, "OVERLAY")
                d.line:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
                d.line:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT"); d.line:SetHeight(1)
            end
            local r, g, b = S.GetAccentColor()
            d.line:SetColorTexture(r, g, b, 0.8)
        end)
        active = false
    end
    local function BindBar(obj)
        if type(obj) ~= "table" or obj.isSecret or not Allowed(obj.frame) then return end
        if not bars[obj] then
            bars[obj] = {}
            H.Hook(obj, "ApplyStyle", PaintBar)
            H.Hook(obj, "SetIcon", PaintBar)
        end
        PaintBar(obj)
    end
    local TYPES = {"Magic", "Curse", "Disease", "Poison", "Bleed"}
    local function Preview(f)
        if not Allowed(f) then return end
        for i, icon in ipairs(f.Textures or {}) do
            local border = f.BorderTextures and f.BorderTextures[i]
            local color = border and border.IsShown and border:IsShown()
                and DebuffTypeColor and DebuffTypeColor[TYPES[(i - 1) % #TYPES + 1]]
            Icon(f.OverlayFrames and f.OverlayFrames[i] or f, icon, border,
                color and color.r, color and color.g, color and color.b)
            Font(f.DurationTexts and f.DurationTexts[i]); Font(f.StackTexts and f.StackTexts[i])
        end
        if Allowed(f.Border) and f.Border.SetBackdropBorderColor then
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
