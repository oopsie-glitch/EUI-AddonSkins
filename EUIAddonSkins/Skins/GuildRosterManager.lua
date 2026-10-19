local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("GuildRosterManager", "Guild Roster Manager", function()
    return type(_G.GRM_UI) == "table" and type(_G.GRM) == "table"
end, function(S, module)
    local ui = _G.GRM_UI
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(setmetatable({PageButton = soft.SoftPageButton}, {__index = S}), module)
    local known, painted, fonts, visual, surfaces, selected = {}, {}, {}, {}, {}, {}
    local pendingRoots, generation = {}, 1
    local painting, waiting = false, false
    local Discover, Paint, Refresh, Roots
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("ADDON_LOADED")
    local function Run(fn, ...)
        if painting or not ns.IsEnabled(module) then return end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return end
        painting = true; H.Safe(fn, ...); painting = false
    end
    local function Name(f) return f.GetName and f:GetName() or "" end
    local function Font(text)
        if not H.Allowed(text) or not text.GetFont then return end
        local entry = fonts[text]
        if not entry then
            entry = {}; fonts[text] = entry
            local function Restore() Run(Font, text) end
            H.Hook(text, "SetFont", Restore)
            H.Hook(text, "SetFontObject", Restore)
        end
        local path, size, flags = text:GetFont()
        if not path then return end
        local face, outline = S.GetFont()
        if path ~= face or flags ~= (outline or "") or entry.generation ~= generation then
            S.Font(text) -- Keep native point size, inline links and semantic colours.
            entry.generation = generation
        end
    end
    local function Gradient(t, first, last, r, g, b)
        t:SetColorTexture(1, 1, 1, 1)
        if t.SetGradient and CreateColor then
            t:SetGradient("HORIZONTAL", CreateColor(r, g, b, first), CreateColor(r, g, b, last))
        elseif t.SetGradientAlpha then t:SetGradientAlpha("HORIZONTAL", r, g, b, first, r, g, b, last)
        else t:SetColorTexture(r, g, b, math.max(first, last) * 0.5) end
    end
    local function Background(f)
        local d = surfaces[f]
        if not d then
            local layer = CreateFrame("Frame", nil, f); visual[layer] = true
            layer:SetAllPoints(f); layer:EnableMouse(false); layer:SetFrameLevel(f:GetFrameLevel())
            d = {layer = layer}; surfaces[f] = d
            d.left = layer:CreateTexture(nil, "BACKGROUND", nil, -3)
            d.left:SetPoint("TOPLEFT"); d.left:SetPoint("BOTTOMRIGHT", layer, "BOTTOM")
            d.right = layer:CreateTexture(nil, "BACKGROUND", nil, -3)
            d.right:SetPoint("TOPLEFT", layer, "TOP"); d.right:SetPoint("BOTTOMRIGHT")
        end
        local r, g, b = S.GetPanelColor()
        r, g, b = math.min(1, r + 0.15), math.min(1, g + 0.15), math.min(1, b + 0.15)
        Gradient(d.left, 0, 0.45, r, g, b); Gradient(d.right, 0.45, 0, r, g, b)
    end
    local function Scroll(f)
        local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
        if thumb then
            H.LegacySlider(f); thumb:SetVertexColor(1, 1, 1, 1)
            local horizontal = f.GetOrientation and f:GetOrientation() == "HORIZONTAL"
            if horizontal then thumb:SetSize(8, 14) else thumb:SetWidth(5) end
        else
            S.ScrollBar(f, true)
            if H.Allowed(f.Back) then soft.SoftPageButton(f.Back, "^") end
            if H.Allowed(f.Forward) then soft.SoftPageButton(f.Forward, "v") end
        end
    end
    local function Check(f)
        S.Checkbox(f, {borderInset = 4, hover = 0.05})
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and H.Texture(f[getter](f))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then local r, g, b = S.GetAccentColor(); mark:SetColorTexture(r, g, b, 1)
                else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
                mark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
            end
        end
    end
    local function Highlight(f)
        local t = f.GetHighlightTexture and H.Texture(f:GetHighlightTexture())
        if t then t:SetColorTexture(1, 1, 1, 0.10) end
    end
    Paint = function(f, force)
        if not H.Allowed(f) or visual[f] then return end
        local kind, name = f:GetObjectType(), Name(f)
        if kind == "FontString" then Font(f); return end
        if kind == "Texture" then return end
        if kind == "GameTooltip" or kind == "PlayerModel" or kind == "ModelScene" then return end
        if painted[f] == generation and not force then return end
        painted[f] = generation
        if kind == "CheckButton" then Check(f)
        elseif kind == "Slider" then Scroll(f)
        elseif kind == "EditBox" then
            if not (f.IsMultiLine and f:IsMultiLine()) then soft.EditBox(f) end
            Font(f)
        elseif kind == "DropdownButton" then soft.Dropdown(f)
        elseif kind == "Button" then
            if name:find("CloseButton$", 1) then S.CloseButton(f)
            elseif name:match("Tab$") then
                -- Older GRM export tabs use a custom FontString instead of Text.
                if not f.Text and not (f.GetFontString and f:GetFontString()) then
                    local label = f[name .. "Text"]
                    if H.Allowed(label) then f.Text = label end
                end
                if selected[f] == nil and f.IsHighlightLocked then selected[f] = f:IsHighlightLocked() end
                H.Tab(f, selected[f] == true)
                if H.Allowed(f.Text) then H.Fade(f.Text) end
                H.Hook(f, "LockHighlight", function() selected[f] = true; Run(H.Tab, f, true) end)
                H.Hook(f, "UnlockHighlight", function() selected[f] = false; Run(H.Tab, f, false) end)
            else
                local label = f.GetFontString and f:GetFontString()
                local own = f[name .. "Text"]
                if H.Allowed(label) or H.Allowed(own) then
                    soft.Button(f, {"Icon", "icon", "Text", name .. "Text"})
                    if H.Allowed(label) and S.StateButtonLabel then S.StateButtonLabel(f) end
                else Highlight(f) end
            end
        elseif kind == "Frame" then
            local colourControl = name:find("ColorPicker", 1, true) or name:find("Swatch", 1, true)
            local backdrop = f.GetBackdrop and f:GetBackdrop()
            local topLevel = f.GetParent and f:GetParent() == UIParent
            if not colourControl and (backdrop or topLevel or f.NineSlice or name:match("Selected$")) then
                S.Panel(f, {noBorder = true})
                if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
                if f.SetBackdrop then f:SetBackdrop(nil) end
                if topLevel then Background(f) end
            elseif name:find("ScrollBorder", 1, true) or name:match("ScrollFrameBorder$") then
                S.Inset(f); if f.SetBackdrop then f:SetBackdrop(nil) end
            end
        end
        if surfaces[f] then Background(f) end
        for _, region in ipairs(H.Regions(f)) do Font(region) end
    end
    local function Flush()
        for f in pairs(pendingRoots) do pendingRoots[f] = nil; Discover(f, 0, true) end
    end
    local function FlushQueued() Run(Flush) end
    local function Queue(f)
        if not H.Allowed(f) then return end
        pendingRoots[f] = true
        H.Queue(pendingRoots, FlushQueued)
    end
    Discover = function(f, depth, complete)
        if depth > 16 or not H.Allowed(f) or visual[f] then return end
        local kind = f:GetObjectType()
        if kind == "FontString" then Font(f); return end
        if kind == "Texture" then return end
        if kind == "GameTooltip" or kind == "PlayerModel" or kind == "ModelScene" then return end
        if not known[f] then
            known[f] = true
            H.Script(f, "OnShow", function() Run(Discover, f, 0, false) end)
            H.Hook(f, "SetBackdrop", function(_, value) if value then Run(Paint, f, true) end end)
            H.Hook(f, "SetHighlightTexture", function() Run(Highlight, f) end)
        end
        Paint(f, complete)
        local count = f.GetNumChildren and f:GetNumChildren()
        if not complete and count and known[f] == count then return end
        if count then known[f] = count end
        for _, child in ipairs(H.Children(f)) do Discover(child, depth + 1, complete) end
    end
    Roots = function(complete)
        -- The GRM UI registry contains its roots and launch buttons. Do not
        -- enumerate globals, guild data, UIParent or Blizzard's guild frames.
        for _, f in pairs(ui) do
            if H.Allowed(f) then Discover(f, 0, complete) end
        end
    end
    Refresh = function()
        waiting = false; generation = generation + 1
        Roots(true); soft.RefreshSoftBorders()
    end
    local function Built(name, parent)
        if type(name) ~= "string" or type(parent) ~= "table" and type(parent) ~= "userdata" then return end
        local f = parent[name]
        Run(Discover, f, 0, false); Queue(f)
    end
    for _, method in ipairs({"CreateCoreFrame", "CreateButton", "CreateCheckBox", "CreateEditBox", "CreateOptionsSlider"}) do
        H.Hook(ui, method, Built)
    end
    H.Hook(ui, "CreateString", function(name, parent) if parent then Run(Font, parent[name]) end end)
    H.Hook(ui, "CreateRadialButtons", function(_, parent) Queue(parent) end)
    H.Hook(ui, "CreateHybridScrollFrame", function(_, parent) Queue(parent) end)
    H.Hook(ui, "CreateDropDownMenu", function(name, parent)
        if not parent then return end
        Run(Discover, parent[name .. "Selected"], 0, true)
        Run(Discover, parent[name .. "Menu"], 0, true)
    end)
    H.Hook(ui, "BuildDropDownOptions", function(_, menu) Run(Discover, menu, 0, true) end)
    local function BuiltRoots() Run(Roots, true) end
    for _, method in ipairs({"PreAddonLoadUI", "GR_MetaDataInitializeUIFirst", "GR_MetaDataInitializeUISecond",
        "GR_MetaDataInitializeUIThird", "MetaDataInitializeUIrosterLog1", "MetaDataInitializeUIrosterLog2",
        "ReloadAllFrames", "LoadToolFrames", "BuildLogFrames"}) do H.Hook(ui, method, BuiltRoots) end
    H.Hook(_G.GRM_R, "BuildRosterFrames", BuiltRoots)
    H.Hook(_G.GRM and _G.GRM.Export, "LoadExportUI", BuiltRoots)
    H.Hook(_G.GRM, "OptionTabFrameControl", function(tab)
        if not H.Allowed(tab) then return end
        selected[tab] = true; Run(H.Tab, tab, true)
    end)
    module.refresh = function() H.Queue(module, function() Run(Refresh) end) end
    events:SetScript("OnEvent", function(_, event, addon)
        if event == "PLAYER_REGEN_ENABLED" and waiting then Run(Refresh)
        elseif event == "ADDON_LOADED" and type(addon) == "string"
            and (addon == "Guild_Roster_Manager" or addon:find("Guild_Roster_Manager_", 1, true) == 1) then module.refresh() end
    end)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    Run(Roots, true)
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("GuildRosterManager", DefineSkin)
else DefineSkin() end
