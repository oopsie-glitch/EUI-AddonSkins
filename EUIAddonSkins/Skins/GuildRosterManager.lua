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
    local nativeArt, checks, roles, mainPages = {}, {}, {}, {}
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
    local function ReadableColour(text)
        if not text.GetTextColor then return end
        local r, g, b, a = text:GetTextColor()
        if not r or a == 0 then return end
        local gold = r == 1 and (g == 1 or math.abs(g - 0.82) < 0.001) and b == 0
        local missing = math.abs(r - 0.64) < 0.001 and math.abs(g - 0.102) < 0.001 and math.abs(b - 0.102) < 0.001
        -- Roster class colours, good/unknown states and disabled labels need no
        -- ancestry inspection or colour write on repeated native updates.
        if not gold and not missing then return end
        local parent = text.GetParent and text:GetParent()
        local legendItem = false
        for _ = 1, 16 do
            -- Log event categories have deliberately different legend colours.
            if parent == ui.GRM_RosterCheckBoxSideFrame then
                if legendItem then return end
                break
            end
            if not parent then break end
            if parent.GetObjectType and parent:GetObjectType() == "CheckButton" then legendItem = true end
            parent = parent.GetParent and parent:GetParent()
        end
        if gold then
            text:SetTextColor(0.9, 0.9, 0.9, a)
        elseif missing then
            -- Retain GRM's red missing-data state, with readable luminance.
            text:SetTextColor(1, 0.32, 0.32, a)
        end
    end
    local function Font(text)
        if not H.Allowed(text) or visual[text] or not text.GetFont then return end
        local entry = fonts[text]
        if not entry then
            entry = {}; fonts[text] = entry
            local function Restore() Run(Font, text) end
            H.Hook(text, "SetFont", Restore)
            H.Hook(text, "SetFontObject", Restore)
            H.Hook(text, "SetTextColor", function() Run(ReadableColour, text) end)
        end
        local path, size, flags = text:GetFont()
        if not path then return end
        local face, outline = S.GetFont()
        if path ~= face or flags ~= (outline or "") or entry.generation ~= generation then
            S.Font(text) -- Keep native point size, inline links and semantic colours.
            entry.generation = generation
        end
        ReadableColour(text)
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
        r, g, b = math.min(1, r + 0.08), math.min(1, g + 0.08), math.min(1, b + 0.08)
        Gradient(d.left, 0, 0.18, r, g, b); Gradient(d.right, 0.18, 0, r, g, b)
    end
    local function StripArt(art, depth)
        if H.Texture(art) then H.Fade(art); return end
        if depth > 2 or not H.Allowed(art) or art:GetObjectType() ~= "Frame" or not art.GetRegions then return end
        visual[art] = true
        for _, region in ipairs(H.Regions(art)) do if H.Texture(region) then H.Fade(region) end end
        for _, child in ipairs(H.Children(art)) do StripArt(child, depth + 1) end
    end
    local function Chrome(f)
        local textures = nativeArt[f]
        if not textures then
            textures = {}; nativeArt[f] = textures
            for _, region in ipairs(H.Regions(f)) do
                if H.Texture(region) and region ~= f.Icon then textures[#textures + 1] = region end
            end
            for _, method in ipairs({"SetNormalTexture", "SetPushedTexture", "SetDisabledTexture", "SetHighlightTexture"}) do
                H.Hook(f, method, function() Run(Chrome, f) end)
            end
        end
        for _, texture in ipairs(textures) do H.Fade(texture) end
        for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture"}) do
            local texture = f[getter] and H.Texture(f[getter](f))
            if texture then H.Fade(texture) end
        end
        -- GameMenuButtonTemplate and TranslucentFrameTemplate carry some art
        -- in child frames, outside GetRegions(). Leave controls and hit areas alone.
        for _, key in ipairs({"NineSlice", "Border", "BorderFrame", "NormalTexture", "PushedTexture", "DisabledTexture"}) do
            StripArt(f[key], 0)
        end
    end
    local function PageButton(f, glyph)
        if not H.Allowed(f) then return end
        roles[f] = "arrow"; Chrome(f); soft.SoftPageButton(f, glyph)
    end
    local function Scroll(f)
        local inner = H.Allowed(f.Slider) and f.Slider or f
        local horizontal = inner.GetOrientation and inner:GetOrientation() == "HORIZONTAL"
        local thumb = inner.GetThumbTexture and H.Texture(inner:GetThumbTexture())
        if thumb then
            H.LegacySlider(inner); thumb:SetVertexColor(1, 1, 1, 1)
            if horizontal then thumb:SetSize(8, 14) else thumb:SetWidth(5) end
        else S.ScrollBar(inner, true) end
        PageButton(f.Back, horizontal and "<" or "^")
        PageButton(f.Forward, horizontal and ">" or "v")
        PageButton(f.ScrollUpButton, "^"); PageButton(f.ScrollDownButton, "v")
    end
    local function Check(f)
        local entry = checks[f]
        if not entry then
            local before, children = {}, {}
            for _, region in ipairs(H.Regions(f)) do before[region] = true end
            for _, child in ipairs(H.Children(f)) do children[child] = true end
            S.Checkbox(f, {borderInset = 4, hover = 0.05})
            entry = {art = {}, borders = {}}; checks[f] = entry
            for _, region in ipairs(H.Regions(f)) do
                if not before[region] and H.Texture(region) then entry.art[#entry.art + 1] = region end
            end
            for _, child in ipairs(H.Children(f)) do
                if not children[child] and H.Allowed(child) and child:GetObjectType() == "Frame" then
                    entry.borders[#entry.borders + 1] = child; visual[child] = true
                end
            end
        end
        -- Keep native frame geometry/hit rectangles, but make the visible box
        -- consistently 14 UI units (or smaller for GRM's tiny radio controls).
        local size = math.min(14, f:GetWidth(), f:GetHeight())
        for _, art in ipairs(entry.art) do
            art:ClearAllPoints(); art:SetPoint("CENTER", f, "CENTER"); art:SetSize(size, size)
        end
        for _, border in ipairs(entry.borders) do
            border:ClearAllPoints(); border:SetPoint("CENTER", f, "CENTER"); border:SetSize(size, size)
        end
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and H.Texture(f[getter](f))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then local r, g, b = S.GetAccentColor(); mark:SetColorTexture(r, g, b, 1)
                else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("CENTER", f, "CENTER")
                mark:SetSize(math.max(2, size - 4), math.max(2, size - 4))
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
        if H.Allowed(f.CloseButton) then roles[f.CloseButton] = "close" end
        if kind == "CheckButton" then
            Check(f)
            H.Hook(f, "SetSize", function() Run(Check, f) end)
            H.Hook(f, "SetCheckedTexture", function() Run(Check, f) end)
            H.Hook(f, "SetDisabledCheckedTexture", function() Run(Check, f) end)
        elseif kind == "Slider" then Scroll(f)
        elseif kind == "EditBox" then
            if not (f.IsMultiLine and f:IsMultiLine()) then soft.EditBox(f) end
            Font(f)
        elseif kind == "DropdownButton" then soft.Dropdown(f)
        elseif kind == "Button" then
            if roles[f] == "close" or name:find("CloseButton$", 1) then Chrome(f); S.CloseButton(f)
            elseif roles[f] == "arrow" then Chrome(f)
            elseif name:match("Tab$") then
                local originalLabels
                if not nativeArt[f] then
                    originalLabels = {}
                    for _, region in ipairs(H.Regions(f)) do originalLabels[region] = true end
                end
                Chrome(f)
                -- Older GRM export tabs use a custom FontString instead of Text.
                if not f.Text and not (f.GetFontString and f:GetFontString()) then
                    local label = f[name .. "Text"]
                    if H.Allowed(label) then f.Text = label end
                end
                if selected[f] == nil and f.IsHighlightLocked then selected[f] = f:IsHighlightLocked() end
                H.Tab(f, selected[f] == true)
                if originalLabels then
                    for _, region in ipairs(H.Regions(f)) do
                        -- EUI owns the replacement label and its selected accent,
                        -- including user-selected colours matching Blizzard gold.
                        if region:GetObjectType() == "FontString" and not originalLabels[region] then visual[region] = true end
                    end
                end
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
            if not colourControl and (backdrop or topLevel or f.NineSlice or f == ui.GRM_RosterCheckBoxSideFrame or name:match("Selected$")) then
                Chrome(f)
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
    local function SelectMainPage(page)
        for tab, target in pairs(mainPages) do
            local active = target == page
            if selected[tab] ~= active then selected[tab] = active; H.Tab(tab, active) end
        end
    end
    local function BindMainPages()
        local root = ui.GRM_RosterChangeLogFrame
        if not H.Allowed(root) then return end
        local mapping = {GRM_LogTab = "GRM_LogFrame", GRM_AddEventTab = "GRM_EventsFrame",
            GRM_BanListTab = "GRM_CoreBanListFrame", GRM_AddonUsersTab = "GRM_AddonUsersFrame",
            GRM_OptionsTab = "GRM_OptionsFrame", GRM_GuildAuditTab = "GRM_AuditFrame"}
        local current, visible = nil, 0
        for key, pageKey in pairs(mapping) do
            local tab, page = root[key], root[pageKey]
            if H.Allowed(tab) and H.Allowed(page) and not mainPages[tab] then
                mainPages[tab] = page
                H.Hook(page, "Show", function() Run(SelectMainPage, page) end)
            end
            if mainPages[tab] and page:IsShown() and page:GetAlpha() == 1 then
                current, visible = page, visible + 1
            end
        end
        if visible == 1 then SelectMainPage(current) end
    end
    Roots = function(complete)
        -- The GRM UI registry contains its roots and launch buttons. Do not
        -- enumerate globals, guild data, UIParent or Blizzard's guild frames.
        for _, f in pairs(ui) do
            if H.Allowed(f) then Discover(f, 0, complete) end
        end
        BindMainPages()
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
    -- BuildLogFrames updates checkbox values, permissions, text and fonts.
    -- Their local setters/factories already keep the skin current; it must not
    -- trigger a full interface repaint on each native settings/rank refresh.
    local function BuiltRoots() Run(Roots, true) end
    for _, method in ipairs({"PreAddonLoadUI", "GR_MetaDataInitializeUIFirst", "GR_MetaDataInitializeUISecond",
        "GR_MetaDataInitializeUIThird", "MetaDataInitializeUIrosterLog1", "MetaDataInitializeUIrosterLog2",
        "ReloadAllFrames", "LoadToolFrames"}) do H.Hook(ui, method, BuiltRoots) end
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
