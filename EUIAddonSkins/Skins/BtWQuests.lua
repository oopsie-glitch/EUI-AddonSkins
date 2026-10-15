local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("BtWQuests", "BtWQuests", function()
    return _G.BtWQuests ~= nil and _G.BtWQuestsFrame ~= nil
end, function(S, module)
    local H = ns.CreateSkinHelper(S, module)
    local soft = ns.CreateSoftSkin(S, module, function(f)
        return f.Cover ~= nil or f.Tick ~= nil or (f.Active ~= nil and f.Subtext ~= nil)
    end)
    local root = _G.BtWQuestsFrame
    local styled, menus, panels, scrolls = {}, {}, {}, {}
    local painting, waiting = false, false
    local surfaces = {}
    local Paint, Walk, Menu, BindMenu
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")

    local function Run(fn, ...)
        if painting or not ns.IsEnabled(module) then return end
        if InCombatLockdown() then waiting = true; return end
        painting = true
        H.Safe(fn, ...)
        painting = false
    end
    local function Fonts(f, white)
        for _, region in ipairs(H.Regions(f)) do
            if white then H.Font(region, 0.92, 0.92, 0.94) else H.Font(region) end
        end
    end
    local function Strip(f)
        if not H.Allowed(f) then return end
        if S.Inset then S.Inset(f) end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
    end
    local function Scroll(f)
        if not H.Allowed(f) then return end
        if not scrolls[f] then
            if f.GetThumbTexture then
                local thumb = f:GetThumbTexture()
                if not thumb then return end -- Retry after a lazy template initializes.
                for _, region in ipairs(H.Regions(f)) do
                    if region ~= thumb and H.Texture(region) then H.Fade(region) end
                end
                if thumb then
                    thumb:SetColorTexture(1, 1, 1, 0.3)
                    thumb:SetWidth(4) -- Keep native height, drag range and hit area.
                end
                for _, key in ipairs({"ScrollUpButton", "ScrollDownButton"}) do
                    local button = f[key]
                    if H.Allowed(button) then for _, region in ipairs(H.Regions(button)) do if H.Texture(region) then H.Fade(region) end end end
                end
            else S.ScrollBar(f) end
            scrolls[f] = true
        end
    end
    local function Button(f, keep)
        if not H.Allowed(f) then return end
        S.Button(f, keep)
        Fonts(f)
        if S.StateButtonLabel then S.StateButtonLabel(f) end
    end
    -- Customize only textures created by the public Button primitive. Keep
    -- native hit rectangles, pooled item geometry and semantic regions intact.
    local function FlatButton(f, keep, inset, opacity)
        local surface = surfaces[f]
        local before
        if not surface then
            before = {}
            for _, region in ipairs(H.Regions(f)) do before[region] = true end
        end
        soft.Button(f, keep)
        if before then
            surface = {}
            surfaces[f] = surface
            for _, region in ipairs(H.Regions(f)) do
                if not before[region] and H.Texture(region) then
                    local layer = region:GetDrawLayer()
                    if layer == "BACKGROUND" or layer == "HIGHLIGHT" then
                        surface[#surface + 1] = {region, layer}
                    end
                end
            end
        end
        local r, g, b = S.GetPanelColor()
        -- A restrained warm lift matches quest-log headers without turning
        -- the controls into opaque grey slabs over the textured shell.
        r, g, b = math.min(r + 0.085, 1), math.min(g + 0.075, 1), math.min(b + 0.055, 1)
        for _, entry in ipairs(surface) do
            local region = entry[1]
            region:ClearAllPoints()
            region:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset)
            region:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset)
            if entry[2] == "BACKGROUND" then region:SetColorTexture(r, g, b, opacity)
            else region:SetColorTexture(1, 1, 1, 0.08) end
        end
    end
    local function Title(text, limit)
        H.Font(text)
        if not H.Allowed(text) or not text.GetFont then return end
        local path, size, flags = text:GetFont()
        if path and size and size > limit then text:SetFont(path, limit, flags) end
    end
    local function IconButton(button, path, atlas)
        if not button.euiJournalIcon then
            local icon = button:CreateTexture(nil, "OVERLAY")
            button.euiJournalIcon = icon
            icon:SetSize(14, 14)
            icon:SetPoint("CENTER", button, "CENTER")
            if atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
                icon:SetAtlas(atlas)
            else icon:SetTexture(path) end
            icon:SetDesaturated(true)
            icon:SetVertexColor(0.92, 0.92, 0.94)
        end
        Button(button, {"euiJournalIcon"})
        local function EnabledIcon()
            if button.IsEnabled then button.euiJournalIcon:SetAlpha(button:IsEnabled() and 1 or 0.4) end
        end
        H.Script(button, "OnEnable", EnabledIcon)
        H.Script(button, "OnDisable", EnabledIcon)
        EnabledIcon()
    end
    local NODE_KEEP = {"Tick", "TagTexture", "HeroicTexture", "MythicTexture", "ActiveTexture", "IsNext"}
    local CARD_KEEP = {"Tick", "Major", "Acive"} -- Acive is the target addon's field spelling.
    local function Row(f)
        if not H.Allowed(f) then return end
        if f.Cover and f.Name then
            FlatButton(f, NODE_KEEP, 1, 0.80)
            H.Fade(f.Icon); H.Fade(f.Cover)
            Fonts(f) -- Preserve status colours, spoiler visibility and fade animations.
        elseif f.Name and f.Tick then
            FlatButton(f, CARD_KEEP, 3, 0.72)
            H.Fade(f.Background)
            H.Font(f.Name, 0.92, 0.92, 0.94)
            H.Font(f.Subtext, 0.7, 0.7, 0.72)
            Title(f.Name, 14)
            if H.Texture(f.Acive) then
                local r, g, b = S.GetAccentColor()
                f.Acive:SetColorTexture(r, g, b, 0.10)
                f.Acive:ClearAllPoints()
                f.Acive:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3)
                f.Acive:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
            end
        elseif f.Name then
            local r, g, b = S.GetAccentColor()
            H.Font(f.Name, r, g, b)
            for _, child in ipairs(H.Children(f)) do H.Fade(child.Background) end
        end
        if not styled[f] then
            styled[f] = true
            for _, method in ipairs({"Set", "Update"}) do
                H.Hook(f, method, function() Run(Row, f) end)
            end
        end
    end
    local function Graph()
        local chain = root.Chain and root.Chain.Scroll
        local child = chain and chain.Child
        if not H.Allowed(child) then return end
        Scroll(chain.ScrollBar)
        -- Inspect direct connector regions only, never their pooled children.
        -- Leave endpoints, state visibility, colours and animations native.
        for _, node in ipairs(H.Children(child)) do
            if H.Allowed(node) then
                if node:GetObjectType() == "Button" and node.Cover then Row(node)
                elseif node.Background and node.Active and node.Complete then
                    for _, key in ipairs({"Background", "Active", "Complete"}) do
                        local line = node[key]
                        if H.Allowed(line) and line:GetObjectType() == "Line" and line.SetThickness then
                            line:SetTexture("Interface\\Buttons\\WHITE8X8")
                            line:SetThickness(2)
                            if key == "Background" then line:SetVertexColor(0.25, 0.25, 0.27) end
                        end
                    end
                end
            end
        end
    end
    Menu = function(list)
        if not H.Allowed(list) then return end
        if not panels[list] then
            panels[list] = true
            S.Panel(list, {noBorder = true})
            Strip(list.Backdrop); Strip(list.MenuBackdrop)
        end
        for _, row in ipairs(H.Children(list)) do
            if H.Allowed(row) and row:GetObjectType() == "Button" then
                -- Keep check/radio visibility, class-coloured names, delete and
                -- swatch controls. Native hover scripts still own Highlight.
                H.Font(row.NormalText)
                if H.Texture(row.Highlight) then row.Highlight:SetColorTexture(1, 1, 1, 0.08) end
                if H.Texture(row.Check) then
                    local r, g, b = S.GetAccentColor()
                    row.Check:SetVertexColor(r, g, b)
                end
                if H.Texture(row.UnCheck) then row.UnCheck:SetVertexColor(0.4, 0.4, 0.4) end
            end
        end
    end
    BindMenu = function(f)
        if not H.Allowed(f) or type(f.GetListFrame) ~= "function" then return end
        if not menus[f] then
            menus[f] = true
            -- GetListFrame is lazy. Observe it; never call it or force creation.
            H.Hook(f, "GetListFrame", function() Run(Menu, f.list) end)
            H.Hook(f, "Open", function() Run(Menu, f.list) end)
        end
        if f.list then Menu(f.list) end
        if f.displayMode ~= "MENU" then
            local icon = H.Texture(f.Icon)
            local alpha = icon and icon:GetAlpha()
            S.Dropdown(f)
            if icon then icon:SetAlpha(alpha) end
            H.Font(f.Text)
            -- The custom arrow button is separate from the dropdown's regions.
            if H.Allowed(f.Button) then
                for _, region in ipairs(H.Regions(f.Button)) do if H.Texture(region) then H.Fade(region) end end
            end
        end
    end
    Walk = function(f, depth)
        if depth > 12 or not H.Allowed(f) then return end
        local kind = f:GetObjectType()
        if kind == "GameTooltip" or kind == "PlayerModel" or kind == "ModelScene" then return end
        local canvas = root.Chain and root.Chain.Scroll and root.Chain.Scroll.Child
        if f == canvas then Graph(); return end
        if f.Cover and f.Name or f.Name and f.Tick then Row(f)
        elseif kind == "Button" and f.Name and not f.Icon then
            -- Category headers and search results have Name, not ButtonText.
            if f.link or f.resultType then soft.Button(f); Fonts(f, true)
            else Row(f) end
        elseif type(f.GetListFrame) == "function" then BindMenu(f)
        elseif kind == "EditBox" then S.EditBox(f); if S.Font then S.Font(f) end
        elseif kind == "CheckButton" then S.Checkbox(f)
        elseif kind == "StatusBar" and S.ApplyBarFill then S.ApplyBarFill(f)
        elseif kind == "Slider" then Scroll(f)
        elseif kind == "Button" and f.MenuArrowButton then
            Button(f, {"selected"})
            if H.Texture(f.selected) then
                local r, g, b = S.GetAccentColor()
                f.selected:SetColorTexture(r, g, b, 0.12)
            end
            if H.Allowed(f.MenuArrowButton) then S.PageButton(f.MenuArrowButton, "v") end
        elseif kind == "Button" and f.Active and f.Subtext then
            FlatButton(f, {"Active"}, 2, 0.72)
            Fonts(f)
            if S.StateButtonLabel then S.StateButtonLabel(f) end
            if f.GetFontString then Title(f:GetFontString(), 13) end
            if H.Texture(f.Active) then
                if not styled[f] then
                    f.Active:ClearAllPoints()
                    f.Active:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
                    f.Active:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
                    styled[f] = true
                end
                local r, g, b = S.GetAccentColor()
                f.Active:SetColorTexture(r, g, b, 0.12)
            end
        elseif kind == "Button" and f.GetFontString and f:GetFontString() then Button(f) end
        Fonts(f)
        if f.ScrollBar then Scroll(f.ScrollBar) end
        if f.scrollBar then Scroll(f.scrollBar) end
        if f.CloseButton and H.Allowed(f.CloseButton) then S.CloseButton(f.CloseButton) end
        if f.Background and f.Base and f.AutoLoad then
            -- Expansion artwork identifies the expansion; remove its frame,
            -- leaving the image and auto-load behaviour in their native layout.
            H.Fade(f.Base)
            H.Font(f.Name, 0.92, 0.92, 0.94)
        end
        for _, child in ipairs(H.Children(f)) do Walk(child, depth + 1) end
    end
    local function Surface(f)
        if not H.Allowed(f) then return end
        if not panels[f] then
            panels[f] = true
            -- Separate search overlays need a fill; content inside the main
            -- journal inherits its existing textured/Modern shell instead.
            S.Panel(f, {noBorder = true})
        end
        Walk(f, 0)
    end
    local function Setup()
        if styled[root] then return end
        styled[root] = true
        S.Shell(root, {noBorder = true})
        if root.NineSlice then S.FadeNineSlice(root.NineSlice) end
        Strip(root.Inset)
        local portrait = root.PortraitContainer
        if H.Allowed(portrait) then
            for _, region in ipairs(H.Regions(portrait)) do if H.Texture(region) then H.Fade(region) end end
        end
        H.Fade(root.portrait)
        if root.CloseButton then S.CloseButton(root.CloseButton) end
        local previous
        for _, entry in ipairs({{"NavBack", "<"}, {"NavForward", ">"}, {"NavHere"}}) do
            local button = root[entry[1]]
            if H.Allowed(button) then
                if entry[2] then S.PageButton(button, entry[2])
                else IconButton(button, "Interface\\WorldMap\\WorldMapArrow", "Waypoint-MapPin-ChatIcon") end
                button:SetSize(22, 22); button:ClearAllPoints()
                if previous then button:SetPoint("LEFT", previous, "RIGHT", 3, 0)
                else button:SetPoint("TOPLEFT", root, "TOPLEFT", 8, -2) end
                previous = button
            end
        end
        if H.Allowed(root.OptionsButton) then
            local button = root.OptionsButton
            IconButton(button, "Interface\\AddOns\\EllesmereUI\\media\\icons\\sidebar\\settings-ig-2.png")
            button:SetSize(22, 22); button:ClearAllPoints()
            button:SetPoint("TOPRIGHT", root, "TOPRIGHT", -30, -2)
        end
        if H.Allowed(root.CharacterDropDown) and H.Allowed(root.OptionsButton) then
            root.CharacterDropDown:SetHeight(22)
            root.CharacterDropDown:ClearAllPoints()
            root.CharacterDropDown:SetPoint("RIGHT", root.OptionsButton, "LEFT", -6, 0)
        end
        if H.Allowed(root.navBar) then
            Strip(root.navBar)
            for _, region in ipairs(H.Regions(root.navBar)) do
                if H.Texture(region) then H.Fade(region) end
            end
            H.Hook(root.navBar, "AddButtons", function() Run(Walk, root.navBar, 0) end)
        end
        if root.ExpansionList then
            for _, entry in ipairs({{"Left", "<"}, {"Right", ">"}}) do
                local button = root.ExpansionList[entry[1]]
                if H.Allowed(button) then button:SetSize(22, 22); S.PageButton(button, entry[2]) end
            end
        end
        for _, method in ipairs({"DisplayExpansionList", "DisplayItemList", "DisplayCurrentChain"}) do
            H.Hook(root, method, function() Run(Paint) end)
        end
        H.Hook(root, "UpdateCurrentChain", function() Run(Graph) end)
        local chain = root.Chain and root.Chain.Scroll
        if chain then
            H.Hook(chain, "SetChain", function() Run(Graph) end)
            H.Hook(chain, "Update", function() Run(Graph) end)
        end
        for _, key in ipairs({"SearchPreview", "SearchResults"}) do
            local f = root[key]
            if H.Allowed(f) then
                for _, method in ipairs({"UpdateResults", "UpdateSearch"}) do
                    H.Hook(f, method, function() Run(Surface, f) end)
                end
            end
        end
        H.Script(root, "OnShow", function() Run(Paint) end)
    end
    Paint = function()
        waiting = false
        Setup()
        Walk(root, 0)
        for _, key in ipairs({"SearchPreview", "SearchResults"}) do Surface(root[key]) end
        BindMenu(_G.BtWQuestsOptionsMenu)
        soft.RefreshSoftBorders()
    end
    module.refresh = function() H.Queue(module, function() Run(Paint) end) end
    events:SetScript("OnEvent", function() if waiting then Run(Paint) end end)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    Run(Paint)
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("BtWQuests", DefineSkin)
else DefineSkin() end
