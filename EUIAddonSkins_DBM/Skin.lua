local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end

local function Window() return _G.DBM_GUI_OptionsFrame end
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
    available = function() return type(_G.DBM_GUI) == "table" and Window() ~= nil end,
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
        for _, name in ipairs({"CreateNewPanel", "CreateBossModPanel", "CreateDropdown"}) do
            C.H.Hook(_G.DBM_GUI, name, C.RefreshNow)
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
